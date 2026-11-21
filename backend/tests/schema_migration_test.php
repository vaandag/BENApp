<?php
declare(strict_types=1);

require __DIR__ . '/../public/lib/schema.php';

$pdo = new PDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

ben_migrate($pdo);

// Simulate a deployment where ALTER TABLE succeeded but the migration record
// was not persisted. Running migrations again must not break API requests.
$pdo->exec("DELETE FROM schema_migrations WHERE version IN ('004_live_realtime', '005_memory_client_id')");
ben_migrate($pdo);

$checks = [
  'lives.host_peer_id' => ben_schema_column_exists($pdo, 'lives', 'host_peer_id'),
  'memories.client_id' => ben_schema_column_exists($pdo, 'memories', 'client_id'),
];
foreach ($checks as $name => $exists) {
  if (!$exists) {
    throw new RuntimeException("Expected schema column missing: $name");
  }
}

echo "Schema migrations remain safe when column changes pre-exist their migration records.\n";
