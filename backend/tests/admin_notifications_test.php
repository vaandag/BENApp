<?php
declare(strict_types=1);

require __DIR__ . '/../public/lib/schema.php';
require __DIR__ . '/../public/lib/admin_notifications.php';

$pdo = new PDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
ben_migrate($pdo);

$user = $pdo->prepare('INSERT INTO users(username,email,password_hash) VALUES(?,?,?)');
foreach ([['admin','admin@example.test'],['alice','alice@example.test'],['bob','bob@example.test']] as [$username,$email]) {
  $user->execute([$username,$email,'hash']);
}
$all = ben_admin_send_announcement($pdo, 1, 'all', null, 'BEN yenilikleri', 'Yeni özellikler yayında.');
$allRows = $pdo->query("SELECT user_id,type,text,is_read FROM notifications WHERE type='announcement' ORDER BY user_id")->fetchAll(PDO::FETCH_ASSOC);
$single = ben_admin_send_announcement($pdo, 1, 'user', 3, 'Hesap bilgilendirmesi', 'Sana özel bir bilgilendirme.');
$singleRows = $pdo->prepare("SELECT user_id,text FROM notifications WHERE type='announcement' AND text LIKE ?");
$singleRows->execute(["Hesap bilgilendirmesi%"]);
$singleRow = $singleRows->fetch(PDO::FETCH_ASSOC);
$search = ben_admin_search_users($pdo, 'ali');
$history = ben_admin_announcement_history($pdo, 10);

$checks = [
  'broadcast reaches every account' => $all['recipient_count'] === 3 && count($allRows) === 3,
  'broadcast notifications are unread and correctly typed' =>
    count(array_filter($allRows, static fn(array $row): bool =>
      $row['type'] === 'announcement' && (int)$row['is_read'] === 0 &&
      str_starts_with($row['text'], "BEN yenilikleri\n")
    )) === 3,
  'single-account announcement reaches only its target' =>
    $single['recipient_count'] === 1 && (int)$singleRow['user_id'] === 3 &&
    str_starts_with($singleRow['text'], 'Hesap bilgilendirmesi'),
  'admin user search returns matching username only' =>
    count($search) === 1 && (int)$search[0]['id'] === 2 && $search[0]['username'] === 'alice',
  'history records sender audience and recipient count' =>
    count($history) === 2 && (int)$history[0]['id'] === $single['announcement_id'] &&
    $history[0]['audience'] === 'user' && $history[0]['admin_username'] === 'admin' &&
    $history[0]['target_username'] === 'bob' && (int)$history[0]['recipient_count'] === 1 &&
    (int)$history[1]['recipient_count'] === 3,
];

$before = (int)$pdo->query("SELECT COUNT(*) FROM notifications WHERE type='announcement'")->fetchColumn();
$missingUserRejected = false;
try { ben_admin_send_announcement($pdo, 1, 'user', 9999, 'Test', 'Test'); }
catch (DomainException $error) { $missingUserRejected = (int)$error->getCode() === 404; }
$invalidTextRejected = false;
try { ben_admin_send_announcement($pdo, 1, 'all', null, '', 'Boş başlık'); }
catch (DomainException $error) { $invalidTextRejected = (int)$error->getCode() === 422; }
$after = (int)$pdo->query("SELECT COUNT(*) FROM notifications WHERE type='announcement'")->fetchColumn();

$checks['unknown target rejected'] = $missingUserRejected;
$checks['empty announcement rejected'] = $invalidTextRejected;
$checks['rejected announcements do not create notifications or history'] =
  $before === $after && count(ben_admin_announcement_history($pdo, 10)) === 2;

foreach ($checks as $name => $passed) {
  if (!$passed) throw new RuntimeException("Admin announcement test failed: $name");
}
echo "Admin announcements support broadcasts, selected users, history, validation, and safe user search.\n";
