<?php
declare(strict_types=1);

/**
 * Remove an account and all records owned by it or attached to its content.
 *
 * The caller must authenticate the user and verify the current password
 * before invoking this function. File removal happens after the database
 * transaction commits so a rollback never leaves a live account without
 * its database records.
 */
function ben_delete_account_data(
  PDO $pdo,
  int $userId,
  string $avatarDirectory,
  string $mediaDirectory
): void {
  if ($userId <= 0) {
    throw new InvalidArgumentException('A positive user ID is required.');
  }

  $pdo->beginTransaction();
  try {
    // Remove signaling and peer rows while the account's live IDs still exist.
    $pdo->prepare(
      'DELETE FROM live_signals
       WHERE live_id IN (SELECT id FROM lives WHERE user_id=?)
          OR from_peer IN (SELECT peer_id FROM live_peers WHERE user_id=?)
          OR to_peer IN (SELECT peer_id FROM live_peers WHERE user_id=?)'
    )->execute([$userId, $userId, $userId]);

    $pdo->prepare(
      'DELETE FROM live_peers
       WHERE user_id=? OR live_id IN (SELECT id FROM lives WHERE user_id=?)'
    )->execute([$userId, $userId]);

    // Remove both reports filed by the account and reports about its content.
    $pdo->prepare(
      "DELETE FROM content_reports
       WHERE reporter_id=?
          OR (target_type='user' AND target_id=?)
          OR (target_type='memory' AND target_id IN (SELECT id FROM memories WHERE user_id=?))
          OR (target_type='comment' AND target_id IN (
                SELECT id FROM comments
                WHERE user_id=? OR memory_id IN (SELECT id FROM memories WHERE user_id=?)
             ))
          OR (target_type='live' AND target_id IN (SELECT id FROM lives WHERE user_id=?))"
    )->execute([$userId, $userId, $userId, $userId, $userId, $userId]);

    $pdo->prepare(
      'DELETE FROM comments
       WHERE user_id=? OR memory_id IN (SELECT id FROM memories WHERE user_id=?)'
    )->execute([$userId, $userId]);

    $pdo->prepare(
      'DELETE FROM memory_likes
       WHERE user_id=? OR memory_id IN (SELECT id FROM memories WHERE user_id=?)'
    )->execute([$userId, $userId]);

    $pdo->prepare(
      'DELETE FROM memory_saves
       WHERE user_id=? OR memory_id IN (SELECT id FROM memories WHERE user_id=?)'
    )->execute([$userId, $userId]);

    $pdo->prepare('DELETE FROM memories WHERE user_id=?')->execute([$userId]);
    $pdo->prepare('DELETE FROM messages WHERE sender_id=? OR receiver_id=?')->execute([$userId, $userId]);
    $pdo->prepare('DELETE FROM follows WHERE follower_id=? OR following_id=?')->execute([$userId, $userId]);
    $pdo->prepare('DELETE FROM notifications WHERE user_id=?')->execute([$userId]);
    $pdo->prepare('DELETE FROM regional_messages WHERE user_id=?')->execute([$userId]);
    $pdo->prepare('DELETE FROM lives WHERE user_id=?')->execute([$userId]);
    $pdo->prepare('DELETE FROM coin_transactions WHERE from_user=? OR to_user=?')->execute([$userId, $userId]);
    $pdo->prepare('DELETE FROM user_blocks WHERE blocker_id=? OR blocked_id=?')->execute([$userId, $userId]);
    $pdo->prepare('DELETE FROM sessions WHERE user_id=?')->execute([$userId]);
    $pdo->prepare('DELETE FROM users WHERE id=?')->execute([$userId]);

    $pdo->commit();
  } catch (Throwable $error) {
    if ($pdo->inTransaction()) {
      $pdo->rollBack();
    }
    throw $error;
  }

  foreach ([
    [$avatarDirectory, 'u_' . $userId . '_*'],
    [$mediaDirectory, 'u_' . $userId . '_*'],
  ] as [$directory, $pattern]) {
    if (!is_dir($directory)) {
      continue;
    }
    foreach (glob(rtrim($directory, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . $pattern) ?: [] as $file) {
      if (is_file($file)) {
        @unlink($file);
      }
    }
  }
}
