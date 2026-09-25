<?php
declare(strict_types=1);

function db(): PDO {
  $dir = dirname(__DIR__) . '/data';
  if (!is_dir($dir) && !mkdir($dir, 0770, true) && !is_dir($dir)) {
    throw new RuntimeException('Veritabanı klasörü oluşturulamadı.');
  }

  $pdo = new PDO('sqlite:' . $dir . '/ben.sqlite');
  $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
  $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
  $pdo->exec('PRAGMA foreign_keys = ON');
  $pdo->exec('PRAGMA busy_timeout = 5000');
  $pdo->exec('PRAGMA journal_mode = WAL');
  return $pdo;
}
