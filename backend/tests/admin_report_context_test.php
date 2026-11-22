<?php
declare(strict_types=1);

require __DIR__ . '/../public/lib/schema.php';
require __DIR__ . '/../public/lib/moderation.php';

$pdo = new PDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
ben_migrate($pdo);

$user = $pdo->prepare(
  'INSERT INTO users(username,email,password_hash) VALUES(?,?,?)'
);
$user->execute(['reporter', 'reporter@example.test', 'hash']);
$reporterId = (int)$pdo->lastInsertId();
$user->execute(['target', 'target@example.test', 'hash']);
$targetUserId = (int)$pdo->lastInsertId();

$memory = $pdo->prepare(
  'INSERT INTO memories(user_id,title,body) VALUES(?,?,?)'
);
$memory->execute([$targetUserId, 'Gün batımı', 'Sahilde çektiğim fotoğraf']);
$memoryId = (int)$pdo->lastInsertId();

$comment = $pdo->prepare(
  'INSERT INTO comments(memory_id,user_id,body) VALUES(?,?,?)'
);
$comment->execute([$memoryId, $targetUserId, 'Merhaba yorum']);
$commentId = (int)$pdo->lastInsertId();

$live = $pdo->prepare(
  'INSERT INTO lives(user_id,title) VALUES(?,?)'
);
$live->execute([$targetUserId, 'Akşam yayını']);
$liveId = (int)$pdo->lastInsertId();

$report = $pdo->prepare(
  'INSERT INTO content_reports(reporter_id,target_type,target_id,reason,details) VALUES(?,?,?,?,?)'
);
foreach ([
  ['user', $targetUserId],
  ['memory', $memoryId],
  ['comment', $commentId],
  ['live', $liveId],
] as [$type, $targetId]) {
  $report->execute([$reporterId, $type, $targetId, 'other', 'Test ayrıntısı']);
}

$rows = ben_admin_report_rows($pdo, 'open');
$byType = [];
foreach ($rows as $row) {
  $byType[$row['target_type']] = $row;
}

$checks = [
  'all four target types returned' => count($byType) === 4,
  'user target preview' => ($byType['user']['target_preview'] ?? '') === '@target',
  'memory content preview' => ($byType['memory']['target_preview'] ?? '') === 'Gün batımı',
  'comment content preview' => ($byType['comment']['target_preview'] ?? '') === 'Merhaba yorum',
  'live title preview' => ($byType['live']['target_preview'] ?? '') === 'Akşam yayını',
  'memory owner included' => ($byType['memory']['target_author_username'] ?? '') === 'target',
  'comment author included' => ($byType['comment']['target_author_username'] ?? '') === 'target',
  'invalid filter safely defaults to open' => count(ben_admin_report_rows($pdo, 'invalid')) === 4,
];

foreach ($checks as $name => $passed) {
  if (!$passed) {
    throw new RuntimeException("Admin report context check failed: $name");
  }
}

echo "Admin report queue includes bounded target previews and author context.\n";
