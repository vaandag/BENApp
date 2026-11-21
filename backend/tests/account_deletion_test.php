<?php
declare(strict_types=1);

require __DIR__ . '/../public/lib/schema.php';
require __DIR__ . '/../public/lib/account_deletion.php';

function expect_true(bool $condition, string $message): void {
  if (!$condition) {
    throw new RuntimeException($message);
  }
}

function row_count(PDO $pdo, string $table, string $where = '1=1', array $params = []): int {
  $statement = $pdo->prepare("SELECT COUNT(*) FROM \"$table\" WHERE $where");
  $statement->execute($params);
  return (int)$statement->fetchColumn();
}

$pdo = new PDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
ben_migrate($pdo);

$users = $pdo->prepare('INSERT INTO users(id,username,email,password_hash) VALUES(?,?,?,?)');
foreach ([
  [1, 'deleted', 'deleted@example.test'],
  [2, 'other', 'other@example.test'],
  [3, 'unrelated', 'unrelated@example.test'],
] as [$id,$username,$email]) {
  $users->execute([$id,$username,$email,password_hash('pass', PASSWORD_DEFAULT)]);
}

$pdo->exec("INSERT INTO memories(id,user_id,title,body) VALUES
  (11,1,'Deleted memory','owned by deleted account'),
  (22,2,'Other memory','must remain')");

$pdo->exec("INSERT INTO comments(id,memory_id,user_id,body) VALUES
  (101,11,1,'owned comment'),
  (102,11,2,'comment on deleted memory'),
  (202,22,2,'unrelated comment')");

$pdo->exec("INSERT INTO memory_likes(memory_id,user_id) VALUES
  (11,2),(22,1),(22,3)");
$pdo->exec("INSERT INTO memory_saves(memory_id,user_id) VALUES
  (11,2),(22,1),(22,3)");

$pdo->exec("INSERT INTO lives(id,user_id,title) VALUES
  (31,1,'Deleted live'),(32,2,'Other live')");
$pdo->exec("INSERT INTO live_peers(peer_id,live_id,user_id,role) VALUES
  ('deleted-host',31,1,'host'),
  ('other-viewer',31,2,'viewer'),
  ('other-host',32,2,'host')");
$pdo->exec("INSERT INTO live_signals(live_id,from_peer,to_peer,kind,payload) VALUES
  (31,'other-viewer','deleted-host','candidate','{}'),
  (32,'other-host','unrelated-peer','candidate','{}')");

$pdo->exec("INSERT INTO messages(sender_id,receiver_id,body) VALUES
  (1,2,'outbound'),
  (2,1,'inbound'),
  (2,3,'keep')");
$pdo->exec("INSERT INTO follows(follower_id,following_id) VALUES
  (1,2),(2,1),(2,3)");
$pdo->exec("INSERT INTO notifications(user_id,type,text) VALUES
  (1,'test','delete inbox'),(2,'test','keep inbox')");
$pdo->exec("INSERT INTO regional_messages(room_id,user_id,body) VALUES
  (1,1,'delete regional'),(1,2,'keep regional')");
$pdo->exec("INSERT INTO coin_transactions(from_user,to_user,amount,type) VALUES
  (1,2,5,'gift'),(2,3,7,'gift')");
$pdo->exec("INSERT INTO user_blocks(blocker_id,blocked_id) VALUES
  (1,2),(2,1)");
$pdo->exec("INSERT INTO sessions(token,user_id,expires_at) VALUES
  ('deleted-session',1,datetime('now','+1 day')),
  ('other-session',2,datetime('now','+1 day'))");

$reports = $pdo->prepare(
  'INSERT INTO content_reports(reporter_id,target_type,target_id,reason) VALUES(?,?,?,?)'
);
foreach ([
  [1,'user',2,'other'],
  [2,'user',1,'other'],
  [3,'memory',11,'other'],
  [3,'comment',101,'other'],
  [3,'comment',102,'other'],
  [3,'live',31,'other'],
  [3,'user',2,'other'],
] as $report) {
  $reports->execute($report);
}

$root = sys_get_temp_dir() . '/ben_account_delete_' . bin2hex(random_bytes(5));
$avatars = $root . '/avatars';
$media = $root . '/media';
mkdir($avatars, 0775, true);
mkdir($media, 0775, true);
file_put_contents($avatars . '/u_1_avatar.jpg', 'avatar');
file_put_contents($avatars . '/u_2_avatar.jpg', 'keep');
file_put_contents($media . '/u_1_memory.jpg', 'media');
file_put_contents($media . '/u_2_memory.jpg', 'keep');

try {
  ben_delete_account_data($pdo, 1, $avatars, $media);

  expect_true(row_count($pdo,'users','id=1') === 0, 'Deleted account remains.');
  expect_true(row_count($pdo,'users','id=2') === 1, 'Unrelated account was removed.');
  expect_true(row_count($pdo,'memories','user_id=1') === 0, 'Owned memories remain.');
  expect_true(row_count($pdo,'memories','id=22') === 1, 'Unrelated memory was removed.');
  expect_true(row_count($pdo,'comments','user_id=1 OR memory_id=11') === 0, 'Owned comments or comments on owned memories remain.');
  expect_true(row_count($pdo,'comments','id=202') === 1, 'Unrelated comment was removed.');
  expect_true(row_count($pdo,'memory_likes','user_id=1 OR memory_id=11') === 0, 'Like records remain.');
  expect_true(row_count($pdo,'memory_saves','user_id=1 OR memory_id=11') === 0, 'Save records remain.');
  expect_true(row_count($pdo,'messages','sender_id=1 OR receiver_id=1') === 0, 'Direct messages remain.');
  expect_true(row_count($pdo,'messages','sender_id=2 AND receiver_id=3') === 1, 'Unrelated messages were removed.');
  expect_true(row_count($pdo,'follows','follower_id=1 OR following_id=1') === 0, 'Follow records remain.');
  expect_true(row_count($pdo,'notifications','user_id=1') === 0, 'Account inbox notifications remain.');
  expect_true(row_count($pdo,'notifications','user_id=2') === 1, 'Unrelated notifications were removed.');
  expect_true(row_count($pdo,'regional_messages','user_id=1') === 0, 'Regional messages remain.');
  expect_true(row_count($pdo,'regional_messages','user_id=2') === 1, 'Unrelated regional messages were removed.');
  expect_true(row_count($pdo,'lives','user_id=1') === 0, 'Owned live sessions remain.');
  expect_true(row_count($pdo,'live_peers',"peer_id='deleted-host' OR peer_id='other-viewer'") === 0, 'Live peers for owned live remain.');
  expect_true(row_count($pdo,'live_signals','live_id=31') === 0, 'Live signaling records remain.');
  expect_true(row_count($pdo,'live_signals','live_id=32') === 1, 'Unrelated live signaling was removed.');
  expect_true(row_count($pdo,'coin_transactions','from_user=1 OR to_user=1') === 0, 'Coin transactions remain.');
  expect_true(row_count($pdo,'user_blocks','blocker_id=1 OR blocked_id=1') === 0, 'Block records remain.');
  expect_true(row_count($pdo,'sessions','user_id=1') === 0, 'Sessions remain.');
  expect_true(row_count($pdo,'sessions','user_id=2') === 1, 'Unrelated sessions were removed.');
  expect_true(row_count($pdo,'content_reports',"target_id=11 OR (target_type='user' AND target_id=1) OR reporter_id=1") === 0, 'Reports about deleted account content or filed by the account remain.');
  expect_true(row_count($pdo,'content_reports','reporter_id=3 AND target_type=\'user\' AND target_id=2') === 1, 'Unrelated moderation report was removed.');
  expect_true(!is_file($avatars . '/u_1_avatar.jpg'), 'Account avatar file remains.');
  expect_true(!is_file($media . '/u_1_memory.jpg'), 'Account media file remains.');
  expect_true(is_file($avatars . '/u_2_avatar.jpg'), 'Another account avatar file was removed.');
  expect_true(is_file($media . '/u_2_memory.jpg'), 'Another account media file was removed.');
} finally {
  foreach ([$avatars, $media, $root] as $directory) {
    foreach (glob($directory . '/*') ?: [] as $file) {
      if (is_file($file)) @unlink($file);
    }
    if (is_dir($directory)) @rmdir($directory);
  }
}

echo "Account deletion removes owned records and files while preserving unrelated accounts.\n";
