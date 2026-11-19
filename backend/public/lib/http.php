<?php
declare(strict_types=1);

function ben_env(string $key, ?string $default = null): ?string {
  $value = getenv($key);
  return $value === false || $value === '' ? $default : $value;
}

/**
 * Detect an upload's MIME type without requiring PHP's optional fileinfo
 * extension. Prefer fileinfo when available, then verify common media
 * signatures so the local Windows development server works even when the
 * extension is not enabled.
 */
function ben_detect_mime(string $path): string {
  if (!is_file($path) || !is_readable($path)) {
    return '';
  }

  $allowed = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'video/mp4',
    'video/quicktime',
    'video/webm',
  ];

  if (class_exists(\finfo::class)) {
    try {
      $finfo = new \finfo(FILEINFO_MIME_TYPE);
      $detected = $finfo->file($path);
      if (is_string($detected) && in_array($detected, $allowed, true)) {
        return $detected;
      }
    } catch (\Throwable $error) {
      // Continue with signature detection if fileinfo is unavailable or fails.
    }
  }

  $handle = @fopen($path, 'rb');
  if ($handle === false) {
    return '';
  }

  try {
    $header = fread($handle, 64);
  } finally {
    fclose($handle);
  }

  if (!is_string($header)) {
    return '';
  }

  if (substr($header, 0, 3) === "\xFF\xD8\xFF") {
    return 'image/jpeg';
  }
  if (substr($header, 0, 8) === "\x89PNG\r\n\x1A\n") {
    return 'image/png';
  }
  if (
    substr($header, 0, 4) === 'RIFF'
    && substr($header, 8, 4) === 'WEBP'
  ) {
    return 'image/webp';
  }
  if (substr($header, 0, 4) === "\x1A\x45\xDF\\xA3") {
    return 'video/webm';
  }
  if (strlen($header) >= 12 && substr($header, 4, 4) === 'ftyp') {
    return substr($header, 8, 4) === 'qt  '
      ? 'video/quicktime'
      : 'video/mp4';
  }

  return '';
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
