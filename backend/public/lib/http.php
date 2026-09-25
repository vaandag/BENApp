<?php
declare(strict_types=1);

function ben_env(string $key, ?string $default = null): ?string {
  $value = getenv($key);
  return $value === false || $value === '' ? $default : $value;
}

function ben_request_id(): string {
  $incoming = trim((string)($_SERVER['HTTP_X_REQUEST_ID'] ?? ''));
  if ($incoming !== '' && preg_match('/^[A-Za-z0-9._:-]{1,128}$/', $incoming)) {
    return $incoming;
  }
  return bin2hex(random_bytes(12));
}

function ben_bootstrap_http(): string {
  $requestId = ben_request_id();
  header('Content-Type: application/json; charset=utf-8');
  header('X-Request-Id: ' . $requestId);
  header('Cache-Control: no-store');

  $origin = ben_env('BEN_ALLOWED_ORIGIN');
  if ($origin !== null) {
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Vary: Origin');
  } else {
    header('Access-Control-Allow-Origin: *');
  }
  header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Request-Id');
  header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');

  return $requestId;
}

function ben_json(mixed $payload, int $status = 200): never {
  http_response_code($status);
  echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
  exit;
}

function ben_ok(array $payload = []): never {
  ben_json(['ok' => true, ...$payload]);
}

function ben_error(string $message, int $status = 400, ?string $code = null): never {
  ben_json(array_filter([
    'ok' => false,
    'message' => $message,
    'code' => $code,
  ], static fn($value) => $value !== null), $status);
}
