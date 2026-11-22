<?php
declare(strict_types=1);

/**
 * Persist a direct message and create its recipient notification atomically.
 * The caller is responsible for authentication and rate limiting.
 */
function ben_send_message(PDO $pdo, int $senderId, int $receiverId, string $body): int {
  $body = trim($body);
  if ($senderId <= 0 || $receiverId <= 0 || $senderId === $receiverId ||
      $body === '' || strlen($body) > 5000) {
    ben_error('Geçerli bir alıcı ve 1-5000 karakterlik mesaj gerekli.', 422, 'INVALID_MESSAGE');
  }

  $recipient = $pdo->prepare('SELECT username FROM users WHERE id=?');
  $recipient->execute([$receiverId]);
  if ($recipient->fetchColumn() === false) {
    ben_error('Alıcı bulunamadı.', 404, 'RECIPIENT_NOT_FOUND');
  }

  $blocked = $pdo->prepare(
    'SELECT 1 FROM user_blocks
     WHERE (blocker_id=? AND blocked_id=?) OR (blocker_id=? AND blocked_id=?)'
  );
  $blocked->execute([$senderId, $receiverId, $receiverId, $senderId]);
  if ($blocked->fetchColumn()) {
    ben_error('Bu kullanıcıyla mesajlaşma engellendi.', 403, 'USER_BLOCKED');
  }

  $sender = $pdo->prepare('SELECT username FROM users WHERE id=?');
  $sender->execute([$senderId]);
  $senderName = $sender->fetchColumn();
  if ($senderName === false) {
    ben_error('Gönderen kullanıcı bulunamadı.', 404, 'SENDER_NOT_FOUND');
  }

  $pdo->beginTransaction();
  try {
    $insert = $pdo->prepare(
      'INSERT INTO messages(sender_id,receiver_id,body) VALUES(?,?,?)'
    );
    $insert->execute([$senderId, $receiverId, $body]);
    $messageId = (int)$pdo->lastInsertId();

    $preview = substr($body, 0, 120);
    $notification = $pdo->prepare(
      'INSERT INTO notifications(user_id,type,text) VALUES(?,?,?)'
    );
    $notification->execute([
      $receiverId,
      'message',
      '@' . $senderName . ': ' . $preview,
    ]);

    $pdo->commit();
    return $messageId;
  } catch (Throwable $error) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    throw $error;
  }
}
