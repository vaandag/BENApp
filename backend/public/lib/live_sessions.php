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
