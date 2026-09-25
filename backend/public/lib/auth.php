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
