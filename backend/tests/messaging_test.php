<?php
declare(strict_types=1);

require __DIR__ . '/../public/lib/http.php';
require __DIR__ . '/../public/lib/schema.php';
require __DIR__ . '/../public/lib/messaging.php';

$pdo = new PDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
ben_migrate($pdo);

$user = $pdo->prepare('INSERT INTO users(username,email,password_hash) VALUES(?,?,?)');
$user->execute(['sender', 'sender@example.test', 'hash']);
$senderId = (int)$pdo->lastInsertId();
$user->execute(['receiver', 'receiver@example.test', 'hash']);
$receiverId = (int)$pdo->lastInsertId();

$messageId = ben_send_message($pdo, $senderId, $receiverId, 'Merhaba BEN!');
$message = $pdo->prepare('SELECT sender_id,receiver_id,body FROM messages WHERE id=?');
$message->execute([$messageId]);
$saved = $message->fetch(PDO::FETCH_ASSOC);

$notification = $pdo->prepare('SELECT user_id,type,text,is_read FROM notifications ORDER BY id DESC LIMIT 1');
$notification->execute();
$notice = $notification->fetch(PDO::FETCH_ASSOC);

$checks = [
  'message persisted with correct parties' =>
    (int)$saved['sender_id'] === $senderId &&
    (int)$saved['receiver_id'] === $receiverId &&
    $saved['body'] === 'Merhaba BEN!',
  'recipient notification created' =>
    (int)$notice['user_id'] === $receiverId &&
    $notice['type'] === 'message' &&
    str_starts_with($notice['text'], '@sender: Merhaba BEN!') &&
    (int)$notice['is_read'] === 0,
  'message and notification committed together' => !$pdo->inTransaction(),
];

$pdo->prepare('INSERT INTO user_blocks(blocker_id,blocked_id) VALUES(?,?)')
  ->execute([$receiverId, $senderId]);

$blockedRejected = false;
try {
  ben_send_message($pdo, $senderId, $receiverId, 'Engeli aşmaya çalışma');
} catch (RuntimeException $error) {
  $blockedRejected = str_contains($error->getMessage(), 'Bu kullanıcıyla mesajlaşma engellendi.');
}

$invalidRejected = false;
try {
  ben_send_message($pdo, $senderId, $senderId, 'Kendime');
} catch (RuntimeException $error) {
  $invalidRejected = str_contains($error->getMessage(), 'Geçerli bir alıcı');
}

$checks['blocked pair cannot message'] = $blockedRejected;
$checks['self message rejected'] = $invalidRejected;
$count = (int)$pdo->query('SELECT COUNT(*) FROM messages')->fetchColumn();
$checks['rejected sends do not create messages'] = $count === 1;

foreach ($checks as $name => $passed) {
  if (!$passed) throw new RuntimeException("Messaging test failed: $name");
}
echo "Direct messages create recipient notifications and respect block rules.\n";
