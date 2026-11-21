<?php
declare(strict_types=1);

function ben_schema_column_exists(PDO $pdo, string $table, string $column): bool {
  if (!preg_match('/^[a-z_][a-z0-9_]*$/i', $table) ||
      !preg_match('/^[a-z_][a-z0-9_]*$/i', $column)) {
    throw new InvalidArgumentException('Invalid schema identifier.');
  }

  $statement = $pdo->query('PRAGMA table_info("' . $table . '")');
  foreach ($statement->fetchAll(PDO::FETCH_ASSOC) as $row) {
    if ((string)($row['name'] ?? '') === $column) return true;
  }
  return false;
}

function ben_migrate(PDO $pdo): void {
  $pdo->exec('CREATE TABLE IF NOT EXISTS schema_migrations (version TEXT PRIMARY KEY, applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)');

  $migrations = [
    '001_core' => [
      "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE NOT NULL, email TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, xp INTEGER NOT NULL DEFAULT 0, coins INTEGER NOT NULL DEFAULT 0, bio TEXT NOT NULL DEFAULT '', avatar_url TEXT NOT NULL DEFAULT '', bio_font TEXT NOT NULL DEFAULT 'default', bio_color INTEGER NOT NULL DEFAULT 12307199, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)",
      "CREATE TABLE IF NOT EXISTS memories (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, title TEXT NOT NULL, body TEXT NOT NULL DEFAULT '', lat REAL, lng REAL, location_accuracy REAL, media_type TEXT NOT NULL DEFAULT 'text', privacy TEXT NOT NULL DEFAULT 'public', post_type TEXT NOT NULL DEFAULT 'memory', expires_at TEXT NULL, media_url TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)",
      "CREATE TABLE IF NOT EXISTS comments (id INTEGER PRIMARY KEY AUTOINCREMENT, memory_id INTEGER NOT NULL, user_id INTEGER NOT NULL, body TEXT NOT NULL, updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)",
      "CREATE TABLE IF NOT EXISTS messages (id INTEGER PRIMARY KEY AUTOINCREMENT, sender_id INTEGER NOT NULL, receiver_id INTEGER NOT NULL, body TEXT NOT NULL, is_read INTEGER NOT NULL DEFAULT 0, edited_at TEXT, deleted_at TEXT, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)",
      "CREATE TABLE IF NOT EXISTS follows (follower_id INTEGER NOT NULL, following_id INTEGER NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(follower_id, following_id))",
      "CREATE TABLE IF NOT EXISTS notifications (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, type TEXT NOT NULL, text TEXT NOT NULL, is_read INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)",
      "CREATE TABLE IF NOT EXISTS lives (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, title TEXT NOT NULL, place TEXT, status TEXT NOT NULL DEFAULT 'live', viewers INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)",
      "CREATE TABLE IF NOT EXISTS sessions (token TEXT PRIMARY KEY, user_id INTEGER NOT NULL, expires_at TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)",
      "CREATE TABLE IF NOT EXISTS coin_transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, from_user INTEGER, to_user INTEGER, amount INTEGER NOT NULL, type TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)",
      "CREATE TABLE IF NOT EXISTS memory_likes (memory_id INTEGER NOT NULL, user_id INTEGER NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(memory_id,user_id))",
      "CREATE TABLE IF NOT EXISTS memory_saves (memory_id INTEGER NOT NULL, user_id INTEGER NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(memory_id,user_id))",
      "CREATE TABLE IF NOT EXISTS regional_rooms (id INTEGER PRIMARY KEY AUTOINCREMENT, slug TEXT UNIQUE NOT NULL, name TEXT NOT NULL, country TEXT NOT NULL DEFAULT 'TR', created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)",
      "CREATE TABLE IF NOT EXISTS regional_messages (id INTEGER PRIMARY KEY AUTOINCREMENT, room_id INTEGER NOT NULL, user_id INTEGER NOT NULL, body TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)",
    ],
    '002_indexes' => [
      'CREATE INDEX IF NOT EXISTS idx_memories_created_id ON memories(created_at DESC, id DESC)',
      'CREATE INDEX IF NOT EXISTS idx_memories_user_created ON memories(user_id, created_at DESC, id DESC)',
      'CREATE INDEX IF NOT EXISTS idx_memories_location ON memories(lat, lng)',
      'CREATE INDEX IF NOT EXISTS idx_comments_memory_id ON comments(memory_id, id)',
      'CREATE INDEX IF NOT EXISTS idx_messages_pair ON messages(sender_id, receiver_id, id)',
      'CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, id DESC)',
      'CREATE INDEX IF NOT EXISTS idx_sessions_expiry ON sessions(expires_at)',
      'CREATE INDEX IF NOT EXISTS idx_regional_messages_room ON regional_messages(room_id, id)',
    ],
    '003_legacy_columns' => [
      'ALTER TABLE memories ADD COLUMN location_accuracy REAL',
      "ALTER TABLE memories ADD COLUMN media_url TEXT NOT NULL DEFAULT ''",
    ],
    '004_live_realtime' => [
      "ALTER TABLE lives ADD COLUMN host_peer_id TEXT",
      "CREATE TABLE IF NOT EXISTS live_peers (peer_id TEXT PRIMARY KEY, live_id INTEGER NOT NULL, user_id INTEGER NOT NULL, role TEXT NOT NULL, joined_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, last_seen_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)",
      "CREATE TABLE IF NOT EXISTS live_signals (id INTEGER PRIMARY KEY AUTOINCREMENT, live_id INTEGER NOT NULL, from_peer TEXT NOT NULL, to_peer TEXT NOT NULL, kind TEXT NOT NULL, payload TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)",
      'CREATE INDEX IF NOT EXISTS idx_live_peers_live ON live_peers(live_id, last_seen_at)',
      'CREATE INDEX IF NOT EXISTS idx_live_peers_user ON live_peers(user_id, live_id)',
      'CREATE INDEX IF NOT EXISTS idx_live_signals_to_peer ON live_signals(live_id, to_peer, id)',
    ],
    '005_memory_client_id' => [
      'ALTER TABLE memories ADD COLUMN client_id TEXT',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_memories_user_client_id ON memories(user_id, client_id)',
    ],
    '006_auth_rate_limits' => [
      'CREATE TABLE IF NOT EXISTS auth_rate_limits (bucket_key TEXT PRIMARY KEY, attempts INTEGER NOT NULL, reset_at INTEGER NOT NULL)',
      'CREATE INDEX IF NOT EXISTS idx_auth_rate_limits_reset ON auth_rate_limits(reset_at)',
    ],
    '007_safety_moderation' => [
      "CREATE TABLE IF NOT EXISTS user_blocks (blocker_id INTEGER NOT NULL, blocked_id INTEGER NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(blocker_id, blocked_id), CHECK(blocker_id <> blocked_id))",
      'CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked ON user_blocks(blocked_id, blocker_id)',
      "CREATE TABLE IF NOT EXISTS content_reports (id INTEGER PRIMARY KEY AUTOINCREMENT, reporter_id INTEGER NOT NULL, target_type TEXT NOT NULL, target_id INTEGER NOT NULL, reason TEXT NOT NULL, details TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'open', reviewed_by INTEGER, reviewed_at TEXT, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)",
      'CREATE INDEX IF NOT EXISTS idx_content_reports_status_created ON content_reports(status, created_at DESC)',
      'CREATE INDEX IF NOT EXISTS idx_content_reports_target ON content_reports(target_type, target_id)',
    ],
  ];

  foreach ($migrations as $version => $statements) {
    $check = $pdo->prepare('SELECT 1 FROM schema_migrations WHERE version=?');
    $check->execute([$version]);
    if ($check->fetchColumn()) continue;

    $pdo->beginTransaction();
    try {
      foreach ($statements as $sql) {
        // A previous deployment may have added a column before its migration
        // record was committed. Skip that ALTER instead of failing every API
        // request on the already-existing column.
        if (preg_match('/^ALTER TABLE ([a-z_][a-z0-9_]*) ADD COLUMN ([a-z_][a-z0-9_]*)/i', trim($sql), $columnMatch) &&
            ben_schema_column_exists($pdo, $columnMatch[1], $columnMatch[2])) {
          continue;
        }

        try {
          $pdo->exec($sql);
        } catch (Throwable $e) {
          // Legacy ALTER TABLE statements are intentionally idempotent.
          if ($version === '003_legacy_columns') continue;
          throw $e;
        }
      }
      $pdo->prepare('INSERT INTO schema_migrations(version) VALUES(?)')->execute([$version]);
      $pdo->commit();
    } catch (Throwable $e) {
      if ($pdo->inTransaction()) $pdo->rollBack();
      throw $e;
    }
  }
}
