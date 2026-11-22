<?php
declare(strict_types=1);

function ben_unread_notification_count(PDO $pdo, int $userId): int {
  if ($userId <= 0) return 0;
  $statement = $pdo->prepare(
    'SELECT COUNT(*) FROM notifications WHERE user_id=? AND is_read=0'
  );
  $statement->execute([$userId]);
  return (int)$statement->fetchColumn();
}
