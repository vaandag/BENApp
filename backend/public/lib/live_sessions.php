<?php
declare(strict_types=1);

/**
 * End live rooms whose host heartbeat has expired and remove orphaned peers/signals.
 * Host heartbeats arrive every 12 seconds; 45 seconds tolerates short network gaps.
 */
function ben_prune_stale_live_sessions(PDO $pdo): int {
  $pdo->beginTransaction();
  try {
    $pdo->exec(
      "UPDATE lives SET status='ended'
       WHERE status='live'
         AND NOT EXISTS (
           SELECT 1 FROM live_peers host
           WHERE host.live_id=lives.id AND host.role='host'
             AND host.last_seen_at > datetime('now','-45 seconds')
         )"
    );
    $ended = (int)$pdo->query('SELECT changes()')->fetchColumn();
    $pdo->exec(
      "DELETE FROM live_peers
       WHERE live_id IN (SELECT id FROM lives WHERE status <> 'live')"
    );
    $pdo->exec(
      "DELETE FROM live_peers WHERE last_seen_at < datetime('now','-90 seconds')"
    );
    $pdo->exec(
      "DELETE FROM live_signals
       WHERE live_id IN (SELECT id FROM lives WHERE status <> 'live')
          OR NOT EXISTS (
            SELECT 1 FROM live_peers p
            WHERE p.live_id=live_signals.live_id AND p.peer_id=live_signals.from_peer
          )
          OR NOT EXISTS (
            SELECT 1 FROM live_peers p
            WHERE p.live_id=live_signals.live_id AND p.peer_id=live_signals.to_peer
          )"
    );
    $pdo->commit();
    return $ended;
  } catch (Throwable $error) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    throw $error;
  }
}

/** Confirm the host is still present before accepting a viewer's signaling poll. */
function ben_live_has_active_host(PDO $pdo, int $liveId): bool {
  if ($liveId <= 0) return false;
  $statement = $pdo->prepare(
    "SELECT 1 FROM lives l
     JOIN live_peers host ON host.live_id=l.id AND host.role='host'
     WHERE l.id=? AND l.status='live'
       AND host.last_seen_at > datetime('now','-45 seconds')
     LIMIT 1"
  );
  $statement->execute([$liveId]);
  return $statement->fetchColumn() !== false;
}


/**
 * Register or refresh a peer without allowing one account to replace another's
 * peer identifier. Repeated joins from the same owner/room/role are idempotent.
 */
function ben_register_live_peer(
  PDO $pdo,
  string $peerId,
  int $liveId,
  int $userId,
  string $role
): void {
  if ($peerId === '' || strlen($peerId) > 100 || $liveId <= 0 || $userId <= 0 ||
      !in_array($role, ['host', 'viewer'], true)) {
    throw new DomainException('Geçersiz canlı bağlantı kimliği.', 422);
  }

  $existing = $pdo->prepare(
    'SELECT live_id,user_id,role FROM live_peers WHERE peer_id=?'
  );
  $existing->execute([$peerId]);
  $row = $existing->fetch(PDO::FETCH_ASSOC);
  if ($row) {
    if ((int)$row['live_id'] !== $liveId ||
        (int)$row['user_id'] !== $userId ||
        $row['role'] !== $role) {
      throw new DomainException('Bu canlı bağlantı kimliği zaten kullanımda.', 409);
    }
    $pdo->prepare(
      'UPDATE live_peers SET last_seen_at=CURRENT_TIMESTAMP WHERE peer_id=? AND user_id=?'
    )->execute([$peerId, $userId]);
    return;
  }

  $pdo->prepare(
    'INSERT INTO live_peers(peer_id,live_id,user_id,role) VALUES(?,?,?,?)'
  )->execute([$peerId, $liveId, $userId, $role]);
}

/**
 * Remove only the requesting account's own peer and its pending signals.
 */
function ben_remove_live_peer(PDO $pdo, string $peerId, int $liveId, int $userId): bool {
  $pdo->beginTransaction();
  try {
    $delete = $pdo->prepare(
      'DELETE FROM live_peers WHERE peer_id=? AND live_id=? AND user_id=?'
    );
    $delete->execute([$peerId, $liveId, $userId]);
    if ($delete->rowCount() === 0) {
      $pdo->commit();
      return false;
    }
    $pdo->prepare(
      'DELETE FROM live_signals WHERE live_id=? AND (from_peer=? OR to_peer=?)'
    )->execute([$liveId, $peerId, $peerId]);
    $pdo->commit();
    return true;
  } catch (Throwable $error) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    throw $error;
  }
}
