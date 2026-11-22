<?php
declare(strict_types=1);

require __DIR__ . '/../public/lib/schema.php';
require __DIR__ . '/../public/lib/live_sessions.php';

$pdo = new PDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
ben_migrate($pdo);
$live = $pdo->prepare("INSERT INTO lives(user_id,title,place,status,host_peer_id) VALUES(?,?,?,'live',?)");
$peer = $pdo->prepare('INSERT INTO live_peers(peer_id,live_id,user_id,role) VALUES(?,?,?,?)');
$signal = $pdo->prepare('INSERT INTO live_signals(live_id,from_peer,to_peer,kind,payload) VALUES(?,?,?,?,?)');

$live->execute([1,'Stale host','Istanbul','host-stale']);
$staleId = (int)$pdo->lastInsertId();
$peer->execute(['host-stale',$staleId,1,'host']);
$peer->execute(['viewer-stale-live',$staleId,2,'viewer']);
$signal->execute([$staleId,'host-stale','viewer-stale-live','offer','{}']);
$pdo->exec("UPDATE live_peers SET last_seen_at=datetime('now','-120 seconds') WHERE peer_id='host-stale'");

$live->execute([3,'Healthy host','Istanbul','host-fresh']);
$freshId = (int)$pdo->lastInsertId();
$peer->execute(['host-fresh',$freshId,3,'host']);
$peer->execute(['viewer-fresh',$freshId,4,'viewer']);
$peer->execute(['viewer-expired',$freshId,5,'viewer']);
$signal->execute([$freshId,'host-fresh','viewer-fresh','offer','{}']);
$signal->execute([$freshId,'host-fresh','viewer-expired','offer','{}']);
$pdo->exec("UPDATE live_peers SET last_seen_at=datetime('now','-120 seconds') WHERE peer_id='viewer-expired'");

$ended = ben_prune_stale_live_sessions($pdo);
$staleStatus = $pdo->query("SELECT status FROM lives WHERE id=$staleId")->fetchColumn();
$freshStatus = $pdo->query("SELECT status FROM lives WHERE id=$freshId")->fetchColumn();
$stalePeers = (int)$pdo->query("SELECT COUNT(*) FROM live_peers WHERE live_id=$staleId")->fetchColumn();
$freshPeers = (int)$pdo->query("SELECT COUNT(*) FROM live_peers WHERE live_id=$freshId")->fetchColumn();
$signals = (int)$pdo->query("SELECT COUNT(*) FROM live_signals")->fetchColumn();
$checks = [
  'expired host ends its live room' => $ended === 1 && $staleStatus === 'ended',
  'ended room releases all peer rows' => $stalePeers === 0,
  'active host remains live' => $freshStatus === 'live' && ben_live_has_active_host($pdo, $freshId),
  'expired viewer removed without ending the room' => $freshPeers === 2,
  'signals to removed or ended peers are pruned' => $signals === 1,
  'pruning is idempotent' => ben_prune_stale_live_sessions($pdo) === 0,
];
foreach ($checks as $name => $passed) {
  if (!$passed) throw new RuntimeException("Live session cleanup test failed: $name");
}
echo "Live cleanup ends abandoned rooms and removes stale peers/signals safely.\n";
