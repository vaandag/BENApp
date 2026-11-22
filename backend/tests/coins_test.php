<?php
declare(strict_types=1);

require __DIR__ . '/../public/lib/schema.php';
require __DIR__ . '/../public/lib/coins.php';

$pdo = new PDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
ben_migrate($pdo);
$insert = $pdo->prepare('INSERT INTO users(username,email,password_hash,coins) VALUES(?,?,?,?)');
$insert->execute(['sender','sender@example.test','hash',200]);
$sender = (int)$pdo->lastInsertId();
$insert->execute(['recipient','recipient@example.test','hash',25]);
$recipient = (int)$pdo->lastInsertId();

ben_send_coin_gift($pdo, $sender, $recipient, 50);
$balances = $pdo->prepare('SELECT coins FROM users WHERE id=?');
$balances->execute([$sender]);
$senderAfter = (int)$balances->fetchColumn();
$balances->execute([$recipient]);
$recipientAfter = (int)$balances->fetchColumn();
$txCount = (int)$pdo->query('SELECT COUNT(*) FROM coin_transactions')->fetchColumn();

$insufficientRejected = false;
try { ben_send_coin_gift($pdo, $sender, $recipient, 999); }
catch (DomainException $error) { $insufficientRejected = (int)$error->getCode() === 422; }
$missingRejected = false;
try { ben_send_coin_gift($pdo, $sender, 9999, 1); }
catch (DomainException $error) { $missingRejected = (int)$error->getCode() === 404; }
$selfRejected = false;
try { ben_send_coin_gift($pdo, $sender, $sender, 1); }
catch (DomainException $error) { $selfRejected = (int)$error->getCode() === 422; }

$checks = [
  'successful transfer debits and credits the right accounts' =>
    $senderAfter === 150 && $recipientAfter === 75,
  'successful transfer creates one ledger row' => $txCount === 1,
  'insufficient balance rejected without partial transfer' => $insufficientRejected,
  'missing recipient rejected without partial transfer' => $missingRejected,
  'self transfer rejected' => $selfRejected,
  'failed transfers do not write ledger rows' =>
    (int)$pdo->query('SELECT COUNT(*) FROM coin_transactions')->fetchColumn() === 1,
  'failed transfers leave balances untouched' => (function() use ($pdo, $sender, $recipient): bool {
    $q = $pdo->prepare('SELECT coins FROM users WHERE id=?');
    $q->execute([$sender]); $a = (int)$q->fetchColumn();
    $q->execute([$recipient]); $b = (int)$q->fetchColumn();
    return $a === 150 && $b === 75;
  })(),
];
foreach ($checks as $name => $passed) {
  if (!$passed) throw new RuntimeException("Coin gift test failed: $name");
}
echo "Coin gifts are atomic and validate recipients and sender balance.\n";
