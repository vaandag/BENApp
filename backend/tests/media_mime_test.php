<?php
declare(strict_types=1);

require __DIR__ . '/../public/lib/http.php';

$cases = [
  'jpeg' => ["\xFF\xD8\xFF\xE0BEN", 'image/jpeg'],
  'png' => ["\x89PNG\r\n\x1A\nBEN", 'image/png'],
  'webp' => ['RIFF' . pack('V', 4) . 'WEBP', 'image/webp'],
  'webm' => ["\x1A\x45\xDF\xA3BEN", 'video/webm'],
  'mp4' => [pack('N', 16) . 'ftypisom', 'video/mp4'],
  'quicktime' => [pack('N', 16) . 'ftypqt  ', 'video/quicktime'],
];

foreach ($cases as $label => [$bytes, $expected]) {
  $path = tempnam(sys_get_temp_dir(), 'ben_mime_');
  if ($path === false) {
    throw new RuntimeException('Temporary file could not be created.');
  }

  try {
    if (file_put_contents($path, $bytes) === false) {
      throw new RuntimeException("Could not write $label fixture.");
    }

    $actual = ben_detect_mime($path);
    if ($actual !== $expected) {
      throw new RuntimeException("$label MIME mismatch: expected $expected, got " . ($actual !== '' ? $actual : '(empty)'));
    }
  } finally {
    @unlink($path);
  }
}

echo "BEN MIME detection tests passed (" . count($cases) . " cases)." . PHP_EOL;
