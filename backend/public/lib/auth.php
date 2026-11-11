<?php
declare(strict_types=1);

function ben_bearer_token(): ?string {
  $header = trim((string)($_SERVER['HTTP_AUTHORIZATION'] ?? ''));
  if ($header === '' || !preg_match('/^Bearer\s+([A-Za-z0-9._~-]{20,512})$/i', $header, $m)) {
    return null;
  }
  return $m[1];
}

function ben_optional_user_id(PDO $pdo): int {
  static $resolved;
  if ($resolved !== null) return $resolved;
  $token = ben_bearer_token();
  if ($token === null) return $resolved = 0;
  $st = $pdo->prepare('SELECT user_id FROM sessions WHERE token=? AND expires_at>CURRENT_TIMESTAMP');
  $st->execute([$token]);
  return $resolved = (int)$st->fetchColumn();
}

function ben_require_user_id(PDO $pdo): int {
  $uid = ben_optional_user_id($pdo);
  if ($uid <= 0) ben_error('Oturum gerekli.', 401, 'AUTH_REQUIRED');
  return $uid;
}

/**
 * Apply a fixed-window rate limit. Buckets contain only hashes, never raw
 * email addresses or IP addresses. SQLite upsert keeps the counter atomic.
 */
function ben_enforce_rate_limit(PDO $pdo, string $bucket, int $limit, int $windowSeconds): void {
  $now = time();
  $key = hash('sha256', $bucket);
  $resetAt = $now + max(1, $windowSeconds);

  $sql = "INSERT INTO auth_rate_limits(bucket_key,attempts,reset_at) VALUES(?,1,?)
          ON CONFLICT(bucket_key) DO UPDATE SET
            attempts = CASE
              WHEN auth_rate_limits.reset_at <= ? THEN 1
              ELSE auth_rate_limits.attempts + 1
            END,
            reset_at = CASE
              WHEN auth_rate_limits.reset_at <= ? THEN excluded.reset_at
              ELSE auth_rate_limits.reset_at
            END";
  $pdo->prepare($sql)->execute([$key, $resetAt, $now, $now]);

  $st = $pdo->prepare('SELECT attempts,reset_at FROM auth_rate_limits WHERE bucket_key=?');
  $st->execute([$key]);
  $row = $st->fetch(PDO::FETCH_ASSOC) ?: ['attempts' => 1, 'reset_at' => $resetAt];

  if ((int)$row['attempts'] > $limit) {
    $retryAfter = max(1, (int)$row['reset_at'] - $now);
    header('Retry-After: ' . (string)$retryAfter);
    ben_error('Çok fazla deneme yapıldı. Lütfen bir süre sonra tekrar dene.', 429, 'RATE_LIMITED');
  }

  // Occasional bounded cleanup; raw identifiers are never stored.
  if (($now % 300) === 0) {
    $cutoff = $now - 86400;
    $pdo->prepare('DELETE FROM auth_rate_limits WHERE reset_at < ?')->execute([$cutoff]);
  }
}
