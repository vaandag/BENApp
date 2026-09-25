<?php
declare(strict_types=1);

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
      'ALTER TABLE memories ADD COLUMN media_url TEXT NOT NULL DEFAULT \'\'',
    ],
  ];

  foreach ($migrations as $version => $statements) {
    $check = $pdo->prepare('SELECT 1 FROM schema_migrations WHERE version=?');
    $check->execute([$version]);
    if ($check->fetchColumn()) continue;

    $pdo->beginTransaction();
    try {
      foreach ($statements as $sql) {
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
