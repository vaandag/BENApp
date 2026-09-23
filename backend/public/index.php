<?php
require __DIR__ . '/db.php';
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$pdo = db();
$pdo->exec("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE NOT NULL, email TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, xp INTEGER NOT NULL DEFAULT 0, coins INTEGER NOT NULL DEFAULT 0, bio TEXT NOT NULL DEFAULT '', avatar_url TEXT NOT NULL DEFAULT '', bio_font TEXT NOT NULL DEFAULT 'default', bio_color INTEGER NOT NULL DEFAULT 12307199, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)");
$pdo->exec("CREATE TABLE IF NOT EXISTS memories (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, title TEXT NOT NULL, body TEXT NOT NULL DEFAULT '', lat REAL, lng REAL, media_type TEXT NOT NULL DEFAULT 'text', privacy TEXT NOT NULL DEFAULT 'public', post_type TEXT NOT NULL DEFAULT 'memory', expires_at TEXT NULL, media_url TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)");
$pdo->exec("CREATE TABLE IF NOT EXISTS comments (id INTEGER PRIMARY KEY AUTOINCREMENT, memory_id INTEGER NOT NULL, user_id INTEGER NOT NULL, body TEXT NOT NULL, updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)");
$pdo->exec("CREATE TABLE IF NOT EXISTS messages (id INTEGER PRIMARY KEY AUTOINCREMENT, sender_id INTEGER NOT NULL, receiver_id INTEGER NOT NULL, body TEXT NOT NULL, is_read INTEGER NOT NULL DEFAULT 0, edited_at TEXT, deleted_at TEXT, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)");
try { $pdo->exec("ALTER TABLE users ADD COLUMN bio TEXT NOT NULL DEFAULT ''"); } catch (Throwable $e) {}
try { $pdo->exec("ALTER TABLE users ADD COLUMN avatar_url TEXT NOT NULL DEFAULT ''"); } catch (Throwable $e) {}
try { $pdo->exec("ALTER TABLE users ADD COLUMN bio_font TEXT NOT NULL DEFAULT 'default'"); } catch (Throwable $e) {}
try { $pdo->exec("ALTER TABLE users ADD COLUMN bio_color INTEGER NOT NULL DEFAULT 12307199"); } catch (Throwable $e) {}

$pdo->exec("CREATE TABLE IF NOT EXISTS follows (follower_id INTEGER NOT NULL, following_id INTEGER NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(follower_id, following_id))");
$pdo->exec("CREATE TABLE IF NOT EXISTS notifications (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, type TEXT NOT NULL, text TEXT NOT NULL, is_read INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)");
$pdo->exec("CREATE TABLE IF NOT EXISTS lives (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, title TEXT NOT NULL, place TEXT, status TEXT NOT NULL DEFAULT 'live', viewers INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)");
$pdo->exec("CREATE TABLE IF NOT EXISTS sessions (token TEXT PRIMARY KEY, user_id INTEGER NOT NULL, expires_at TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)");
$pdo->exec("CREATE TABLE IF NOT EXISTS coin_transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, from_user INTEGER, to_user INTEGER, amount INTEGER NOT NULL, type TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)");
$pdo->exec("CREATE TABLE IF NOT EXISTS memory_likes (memory_id INTEGER NOT NULL, user_id INTEGER NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(memory_id,user_id))");
$pdo->exec("CREATE TABLE IF NOT EXISTS memory_saves (memory_id INTEGER NOT NULL, user_id INTEGER NOT NULL, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(memory_id,user_id))");

$path = trim(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH), '/');
$path = preg_replace('#^api/?#', '', $path);
$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true) ?: [];

try {
  try { $pdo->exec("ALTER TABLE memories ADD COLUMN privacy TEXT NOT NULL DEFAULT 'public'"); } catch (Throwable $e) {}
  try { $pdo->exec("ALTER TABLE memories ADD COLUMN post_type TEXT NOT NULL DEFAULT 'memory'"); } catch (Throwable $e) {}
  try { $pdo->exec("ALTER TABLE memories ADD COLUMN expires_at TEXT NULL"); } catch (Throwable $e) {}
  try { $pdo->exec("ALTER TABLE memories ADD COLUMN media_url TEXT NOT NULL DEFAULT ''"); } catch (Throwable $e) {}
  if ($path === 'health' || $path === '') { echo json_encode(['ok'=>true,'service'=>'BEN API','version'=>'104']); exit; }
  if ($path === 'auth/me' && $method === 'GET') {
    $h=$_SERVER['HTTP_AUTHORIZATION']??'';
    if (!preg_match('/Bearer\s+(.+)/i',$h,$mm)) { http_response_code(401); echo json_encode(['ok'=>false,'message'=>'Oturum gerekli.']); exit; }
    $st=$pdo->prepare('SELECT user_id FROM sessions WHERE token=? AND expires_at>CURRENT_TIMESTAMP'); $st->execute([trim($mm[1])]); $uid=(int)$st->fetchColumn();
    if (!$uid) { http_response_code(401); echo json_encode(['ok'=>false,'message'=>'Oturum süresi dolmuş.']); exit; }
    $st=$pdo->prepare('SELECT id,username,email,xp,coins,bio,avatar_url,bio_font,bio_color,created_at FROM users WHERE id=?'); $st->execute([$uid]); $u=$st->fetch(); echo json_encode(['ok'=>true,'user'=>$u]); exit;
  }
  if ($path === 'uploads/avatar' && $method === 'POST') {
    $uid=0; $h=$_SERVER['HTTP_AUTHORIZATION']??'';
    if(preg_match('/Bearer\s+(.+)/i',$h,$mm)){ $st=$pdo->prepare('SELECT user_id FROM sessions WHERE token=? AND expires_at>CURRENT_TIMESTAMP');$st->execute([trim($mm[1])]);$uid=(int)$st->fetchColumn(); }
    if($uid<=0){http_response_code(401);echo json_encode(['ok'=>false,'message'=>'Oturum gerekli.']);exit;}
    if(!isset($_FILES['avatar'])||$_FILES['avatar']['error']!==UPLOAD_ERR_OK){http_response_code(422);echo json_encode(['ok'=>false,'message'=>'Profil fotoğrafı alınamadı.']);exit;}
    $tmp=$_FILES['avatar']['tmp_name'];$info=@getimagesize($tmp);
    if(!$info||!in_array(strtolower((string)$info['mime']),['image/jpeg','image/png','image/webp'],true)){http_response_code(415);echo json_encode(['ok'=>false,'message'=>'Desteklenmeyen profil fotoğrafı.']);exit;}
    $dir=__DIR__.'/uploads/avatars';if(!is_dir($dir))mkdir($dir,0775,true);$name='u_'.$uid.'_'.bin2hex(random_bytes(8)).'.jpg';$target=$dir.'/'.$name;
    if(!move_uploaded_file($tmp,$target)){http_response_code(500);echo json_encode(['ok'=>false,'message'=>'Profil fotoğrafı kaydedilemedi.']);exit;}
    $scheme=(!empty($_SERVER['HTTPS'])&&$_SERVER['HTTPS']!=='off')?'https':'http';$url=$scheme.'://'.($_SERVER['HTTP_HOST']??'localhost').'/uploads/avatars/'.rawurlencode($name);echo json_encode(['ok'=>true,'url'=>$url]);exit;
  }
  if ($path === 'uploads/media' && $method === 'POST') {
    $uid=0;$h=$_SERVER['HTTP_AUTHORIZATION']??'';if(preg_match('/Bearer\s+(.+)/i',$h,$mm)){ $st=$pdo->prepare('SELECT user_id FROM sessions WHERE token=? AND expires_at>CURRENT_TIMESTAMP');$st->execute([trim($mm[1])]);$uid=(int)$st->fetchColumn(); }
    if($uid<=0){http_response_code(401);echo json_encode(['ok'=>false,'message'=>'Oturum gerekli.']);exit;}
    if(!isset($_FILES['media'])||$_FILES['media']['error']!==UPLOAD_ERR_OK){http_response_code(422);echo json_encode(['ok'=>false,'message'=>'Medya alınamadı.']);exit;}
    $tmp=$_FILES['media']['tmp_name'];$mime=@mime_content_type($tmp)?:'';$allowed=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp','video/mp4'=>'mp4','video/quicktime'=>'mov','video/webm'=>'webm'];
    if(!isset($allowed[$mime])){http_response_code(415);echo json_encode(['ok'=>false,'message'=>'Desteklenmeyen medya türü.']);exit;}
    $dir=__DIR__.'/uploads/media';if(!is_dir($dir))mkdir($dir,0775,true);$name='u_'.$uid.'_'.bin2hex(random_bytes(10)).'.'.$allowed[$mime];$target=$dir.'/'.$name;if(!move_uploaded_file($tmp,$target)){http_response_code(500);echo json_encode(['ok'=>false,'message'=>'Medya kaydedilemedi.']);exit;}
    $scheme=(!empty($_SERVER['HTTPS'])&&$_SERVER['HTTPS']!=='off')?'https':'http';$url=$scheme.'://'.($_SERVER['HTTP_HOST']??'localhost').'/uploads/media/'.rawurlencode($name);echo json_encode(['ok'=>true,'url'=>$url]);exit;
  }
  if ($path === 'auth/logout' && $method === 'POST') { $h=$_SERVER['HTTP_AUTHORIZATION']??''; if (preg_match('/Bearer\s+(.+)/i',$h,$mm)) { $pdo->prepare('DELETE FROM sessions WHERE token=?')->execute([trim($mm[1])]); } echo json_encode(['ok'=>true]); exit; }
  if ($path === 'users/profile' && $method === 'POST') {
    $uid=(int)($input['user_id']??0); $username=trim((string)($input['username']??'')); $bio=trim((string)($input['bio']??'')); $avatar=trim((string)($input['avatar_url']??'')); $bioFont=trim((string)($input['bio_font']??'default')); $bioColor=(int)($input['bio_color']??12307199);
    if ($uid<=0 || strlen($username)<3) { http_response_code(422); echo json_encode(['ok'=>false,'message'=>'Geçerli kullanıcı adı gerekli.']); exit; }
    try { $st=$pdo->prepare('UPDATE users SET username=?, bio=?, avatar_url=?, bio_font=?, bio_color=? WHERE id=?'); $st->execute([$username,$bio,$avatar,$bioFont,$bioColor,$uid]); } catch (Throwable $e) { http_response_code(409); echo json_encode(['ok'=>false,'message'=>'Kullanıcı adı kullanılıyor.']); exit; }
    $st=$pdo->prepare('SELECT id,username,email,xp,coins,bio,avatar_url,bio_font,bio_color,created_at FROM users WHERE id=?'); $st->execute([$uid]); echo json_encode(['ok'=>true,'user'=>$st->fetch()]); exit;
  }
  if ($path === 'users/followers' && $method === 'GET') { $uid=(int)($_GET['user_id']??0); $st=$pdo->prepare('SELECT u.id,u.username,u.bio,u.avatar_url FROM users u JOIN follows f ON f.follower_id=u.id WHERE f.following_id=? ORDER BY f.created_at DESC'); $st->execute([$uid]); echo json_encode($st->fetchAll()); exit; }
  if ($path === 'users/following' && $method === 'GET') { $uid=(int)($_GET['user_id']??0); $st=$pdo->prepare('SELECT u.id,u.username,u.bio,u.avatar_url FROM users u JOIN follows f ON f.following_id=u.id WHERE f.follower_id=? ORDER BY f.created_at DESC'); $st->execute([$uid]); echo json_encode($st->fetchAll()); exit; }
  if ($path === 'auth/register' && $method === 'POST') {
    $username = trim((string)($input['username'] ?? ''));
    $email = strtolower(trim((string)($input['email'] ?? '')));
    $password = (string)($input['password'] ?? '');
    if (strlen($username) < 3) { http_response_code(422); echo json_encode(['ok'=>false,'message'=>'Kullanıcı adı en az 3 karakter olmalı.']); exit; }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) { http_response_code(422); echo json_encode(['ok'=>false,'message'=>'Geçerli bir e-posta gir.']); exit; }
    if (strlen($password) < 6) { http_response_code(422); echo json_encode(['ok'=>false,'message'=>'Şifre en az 6 karakter olmalı.']); exit; }
    $check=$pdo->prepare('SELECT id FROM users WHERE email=? OR username=?'); $check->execute([$email,$username]);
    if ($check->fetchColumn()) { http_response_code(409); echo json_encode(['ok'=>false,'message'=>'E-posta veya kullanıcı adı zaten kayıtlı.']); exit; }
    $s=$pdo->prepare('INSERT INTO users(username,email,password_hash) VALUES(?,?,?)'); $s->execute([$username,$email,password_hash($password,PASSWORD_DEFAULT)]);
    $id=(int)$pdo->lastInsertId();
    $token=bin2hex(random_bytes(32)); $pdo->prepare("INSERT INTO sessions(token,user_id,expires_at) VALUES(?,?,datetime('now','+30 days'))")->execute([$token,$id]); echo json_encode(['ok'=>true,'token'=>$token,'user'=>['id'=>$id,'username'=>$username,'email'=>$email,'xp'=>0,'coins'=>0,'bio'=>'','avatar_url'=>'','bio_font'=>'default','bio_color'=>12307199]]); exit;
  }
  if ($path === 'auth/login' && $method === 'POST') {
    $email = strtolower(trim((string)($input['email'] ?? ''))); $password=(string)($input['password'] ?? '');
    $s=$pdo->prepare('SELECT id,username,email,password_hash,xp,coins,bio,avatar_url,bio_font,bio_color FROM users WHERE email=?'); $s->execute([$email]); $u=$s->fetch();
    if (!$u || !password_verify($password,$u['password_hash'])) { http_response_code(401); echo json_encode(['ok'=>false,'message'=>'E-posta veya şifre hatalı.']); exit; }
    unset($u['password_hash']);
    $token=bin2hex(random_bytes(32)); $pdo->prepare("INSERT INTO sessions(token,user_id,expires_at) VALUES(?,?,datetime('now','+30 days'))")->execute([$token,(int)$u['id']]); echo json_encode(['ok'=>true,'token'=>$token,'user'=>$u]); exit;
  }
  if ($path === 'users' && $method === 'GET') {
    $q=trim((string)($_GET['q']??'')); $s=$pdo->prepare('SELECT id,username,email,avatar_url,xp,coins,created_at FROM users WHERE username LIKE ? ORDER BY username LIMIT 30'); $s->execute(['%'.$q.'%']); echo json_encode($s->fetchAll()); exit;
  }
  if (preg_match('#^users/(\d+)$#',$path,$m) && $method==='GET') {
    $s=$pdo->prepare('SELECT id,username,email,xp,coins,bio,avatar_url,bio_font,bio_color,created_at FROM users WHERE id=?'); $s->execute([(int)$m[1]]); $u=$s->fetch();
    if (!$u) { http_response_code(404); echo json_encode(['ok'=>false,'message'=>'Kullanıcı bulunamadı']); exit; }
    $f=$pdo->prepare('SELECT COUNT(*) FROM follows WHERE following_id=?'); $f->execute([(int)$m[1]]); $u['followers']=(int)$f->fetchColumn();
    $f=$pdo->prepare('SELECT COUNT(*) FROM follows WHERE follower_id=?'); $f->execute([(int)$m[1]]); $u['following']=(int)$f->fetchColumn();
    $viewer=(int)($_GET['viewer_id']??0); $f=$pdo->prepare('SELECT 1 FROM follows WHERE follower_id=? AND following_id=?'); $f->execute([$viewer,(int)$m[1]]); $u['following_me']=(bool)$f->fetchColumn();
    echo json_encode($u); exit;
  }

  if ($path === 'memories' && $method === 'GET') {
    $uid=(int)($_GET['user_id']??1);
    $scope=trim((string)($_GET['scope']??'discover'));
    $where="(m.expires_at IS NULL OR m.expires_at > CURRENT_TIMESTAMP)";
    if($scope==='following') $where.=" AND (m.user_id=$uid OR EXISTS (SELECT 1 FROM follows f WHERE f.follower_id=$uid AND f.following_id=m.user_id))";
    else $where.=" AND (m.privacy='public' OR m.user_id=$uid OR (m.privacy='followers' AND EXISTS (SELECT 1 FROM follows f WHERE f.follower_id=$uid AND f.following_id=m.user_id)))";
    $sql="SELECT m.*,u.username AS username,u.avatar_url AS avatar_url,(SELECT COUNT(*) FROM memory_likes l WHERE l.memory_id=m.id) AS likes_count,(SELECT COUNT(*) FROM memory_saves s WHERE s.memory_id=m.id) AS saves_count,(SELECT COUNT(*) FROM comments c WHERE c.memory_id=m.id) AS comments_count FROM memories m LEFT JOIN users u ON u.id=m.user_id WHERE $where ORDER BY m.id DESC";
    $rows = $pdo->query($sql)->fetchAll();
    $likeStmt=$pdo->prepare('SELECT 1 FROM memory_likes WHERE memory_id=? AND user_id=?');
    $saveStmt=$pdo->prepare('SELECT 1 FROM memory_saves WHERE memory_id=? AND user_id=?');
    foreach ($rows as &$r) {
      $likeStmt->execute([(int)$r['id'],$uid]); $r['liked']=(bool)$likeStmt->fetchColumn();
      $saveStmt->execute([(int)$r['id'],$uid]); $r['saved']=(bool)$saveStmt->fetchColumn();
    }
    echo json_encode($rows); exit;
  }
  if ($path === 'memories' && $method === 'POST') { $s=$pdo->prepare('INSERT INTO memories(user_id,title,body,lat,lng,media_type,privacy,post_type,expires_at,media_url) VALUES(?,?,?,?,?,?,?,?,?,?)'); $s->execute([(int)($input['user_id']??1),(string)($input['title']??'Yeni BEN Anısı'),(string)($input['body']??''),$input['lat']??null,$input['lng']??null,(string)($input['type'] ?? $input['media_type'] ?? 'text'),(string)($input['privacy']??'public'),(string)($input['post_type']??'memory'),$input['expires_at']??null,(string)($input['media_url']??'')]); echo json_encode(['ok'=>true,'id'=>$pdo->lastInsertId()]); exit; }
  
  if (preg_match('#^memories/(\d+)/(like|save)$#',$path,$m) && $method==='POST') {
    $memoryId=(int)$m[1]; $userId=(int)($input['user_id']??1); $table=$m[2]==='like'?'memory_likes':'memory_saves';
    $exists=$pdo->prepare("SELECT 1 FROM $table WHERE memory_id=? AND user_id=?"); $exists->execute([$memoryId,$userId]);
    if ($exists->fetchColumn()) { $s=$pdo->prepare("DELETE FROM $table WHERE memory_id=? AND user_id=?"); $s->execute([$memoryId,$userId]); $active=false; }
    else { $s=$pdo->prepare("INSERT INTO $table(memory_id,user_id) VALUES(?,?)"); $s->execute([$memoryId,$userId]); $active=true; if ($m[2]==='like') { $owner=$pdo->prepare('SELECT user_id FROM memories WHERE id=?'); $owner->execute([$memoryId]); $to=(int)$owner->fetchColumn(); if ($to && $to!==$userId) { $who=$pdo->prepare('SELECT username FROM users WHERE id=?'); $who->execute([$userId]); $name=(string)$who->fetchColumn(); $pdo->prepare("INSERT INTO notifications(user_id,type,text) VALUES(?,?,?)")->execute([$to,'like',$name.' anını beğendi.']); } } }
    $count=$pdo->prepare("SELECT COUNT(*) FROM $table WHERE memory_id=?"); $count->execute([$memoryId]);
    echo json_encode(['ok'=>true,'active'=>$active,'count'=>(int)$count->fetchColumn()]); exit;
  }
  if (preg_match('#^memories/(\d+)/comments$#',$path,$m) && $method==='GET') {
    $s=$pdo->prepare('SELECT c.*, u.username, u.avatar_url FROM comments c LEFT JOIN users u ON u.id=c.user_id WHERE c.memory_id=? ORDER BY c.id ASC'); $s->execute([(int)$m[1]]); echo json_encode($s->fetchAll()); exit;
  }
  if ($path === 'comments' && $method === 'POST') { $mid=(int)$input['memory_id']; $uid=(int)($input['user_id']??1); $body=trim((string)$input['body']); if ($body==='') { http_response_code(422); echo json_encode(['ok'=>false,'message'=>'Yorum boş olamaz.']); exit; } $s=$pdo->prepare('INSERT INTO comments(memory_id,user_id,body) VALUES(?,?,?)'); $s->execute([$mid,$uid,$body]); $owner=$pdo->prepare('SELECT user_id FROM memories WHERE id=?'); $owner->execute([$mid]); $to=(int)$owner->fetchColumn(); if ($to && $to!==$uid) { $who=$pdo->prepare('SELECT username FROM users WHERE id=?'); $who->execute([$uid]); $name=(string)$who->fetchColumn(); $pdo->prepare("INSERT INTO notifications(user_id,type,text) VALUES(?,?,?)")->execute([$to,'comment',$name.' anına yorum yaptı.']); } echo json_encode(['ok'=>true,'id'=>$pdo->lastInsertId()]); exit; }
  if ($path === 'messages/conversations' && $method === 'GET') {
    $uid=(int)($_GET['user_id']??0);
    $sql="SELECT u.id,u.username,u.avatar_url,m.body AS preview,m.created_at,m.sender_id,m.is_read FROM users u JOIN (SELECT CASE WHEN sender_id=$uid THEN receiver_id ELSE sender_id END AS other_id,MAX(id) AS last_id FROM messages WHERE sender_id=$uid OR receiver_id=$uid GROUP BY other_id) x ON x.other_id=u.id JOIN messages m ON m.id=x.last_id ORDER BY m.id DESC";
    echo json_encode($pdo->query($sql)->fetchAll());exit;
  }
  if ($path === 'messages' && $method === 'GET') { $uid=(int)($_GET['user_id']??1);$other=(int)($_GET['with_user_id']??0);if($other>0){$s=$pdo->prepare('SELECT * FROM messages WHERE (sender_id=? AND receiver_id=?) OR (sender_id=? AND receiver_id=?) ORDER BY id');$s->execute([$uid,$other,$other,$uid]);}else{$s=$pdo->prepare('SELECT * FROM messages WHERE sender_id=? OR receiver_id=? ORDER BY id');$s->execute([$uid,$uid]);}echo json_encode($s->fetchAll());exit; }
  if ($path === 'messages' && $method === 'POST') { $s=$pdo->prepare('INSERT INTO messages(sender_id,receiver_id,body) VALUES(?,?,?)'); $s->execute([(int)($input['sender_id']??1),(int)$input['receiver_id'],(string)$input['body']]); echo json_encode(['ok'=>true,'id'=>$pdo->lastInsertId()]); exit; }
  if (preg_match('#^messages/(\\d+)/edit$#',$path,$m) && $method==='POST') {
    $uid=(int)($input['user_id']??0);$body=trim((string)($input['body']??''));if($uid<=0||$body===''){http_response_code(422);echo json_encode(['ok'=>false,'message'=>'Geçerli mesaj gerekli.']);exit;}
    $s=$pdo->prepare('UPDATE messages SET body=?,edited_at=CURRENT_TIMESTAMP WHERE id=? AND sender_id=? AND deleted_at IS NULL');$s->execute([$body,(int)$m[1],$uid]);echo json_encode(['ok'=>true]);exit;
  }
  if (preg_match('#^messages/(\\d+)$#',$path,$m) && $method==='DELETE') { $s=$pdo->prepare('UPDATE messages SET deleted_at=CURRENT_TIMESTAMP, body=? WHERE id=?'); $s->execute(['Bu mesaj silindi',$m[1]]); echo json_encode(['ok'=>true]); exit; }
  if ($path === 'messages/read' && $method === 'POST') { $uid=(int)($input['user_id']??1);$other=(int)($input['with_user_id']??0);if($other>0){$s=$pdo->prepare('UPDATE messages SET is_read=1 WHERE receiver_id=? AND sender_id=?');$s->execute([$uid,$other]);}else{$s=$pdo->prepare('UPDATE messages SET is_read=1 WHERE receiver_id=?');$s->execute([$uid]);}echo json_encode(['ok'=>true]);exit; }
  if ($path === 'follow' && $method === 'POST') {
    $from=(int)$input['follower_id']; $to=(int)$input['following_id'];
    if ($from === $to) { http_response_code(422); echo json_encode(['ok'=>false,'message'=>'Kendi hesabını takip edemezsin.']); exit; }
    $e=$pdo->prepare('SELECT 1 FROM follows WHERE follower_id=? AND following_id=?'); $e->execute([$from,$to]);
    if ($e->fetchColumn()) { $s=$pdo->prepare('DELETE FROM follows WHERE follower_id=? AND following_id=?'); $s->execute([$from,$to]); $active=false; }
    else { $s=$pdo->prepare('INSERT INTO follows(follower_id,following_id) VALUES(?,?)'); $s->execute([$from,$to]); $active=true; $n=$pdo->prepare("INSERT INTO notifications(user_id,type,text) VALUES(?,?,?)"); $who=$pdo->prepare('SELECT username FROM users WHERE id=?'); $who->execute([$from]); $name=(string)$who->fetchColumn(); $n->execute([$to,'follow',$name.' seni takip etti.']); }
    echo json_encode(['ok'=>true,'active'=>$active]); exit;
  }
  if ($path === 'notifications/read' && $method === 'POST') { $uid=(int)($input['user_id']??0); $pdo->prepare('UPDATE notifications SET is_read=1 WHERE user_id=?')->execute([$uid]); echo json_encode(['ok'=>true]); exit; }
  if ($path === 'notifications' && $method === 'GET') { $s=$pdo->prepare('SELECT * FROM notifications WHERE user_id=? ORDER BY id DESC'); $s->execute([(int)($_GET['user_id']??1)]); echo json_encode($s->fetchAll()); exit; }
  if ($path === 'live' && $method === 'GET') { echo json_encode($pdo->query("SELECT * FROM lives WHERE status='live' ORDER BY id DESC")->fetchAll()); exit; }
  if ($path === 'live' && $method === 'POST') {
    $h=$_SERVER['HTTP_AUTHORIZATION']??''; $uid=0;
    if (preg_match('/Bearer\s+(.+)/i',$h,$mm)) { $st=$pdo->prepare('SELECT user_id FROM sessions WHERE token=? AND expires_at>CURRENT_TIMESTAMP'); $st->execute([trim($mm[1])]); $uid=(int)$st->fetchColumn(); }
    if ($uid<=0) { $uid=(int)($input['user_id']??0); }
    if ($uid<=0) { http_response_code(401); echo json_encode(['ok'=>false,'message'=>'CANLI başlatmak için giriş yapmalısın.']); exit; }
    $check=$pdo->prepare('SELECT 1 FROM users WHERE id=?'); $check->execute([$uid]); if (!$check->fetchColumn()) { http_response_code(401); echo json_encode(['ok'=>false,'message'=>'Kullanıcı bulunamadı.']); exit; }
    $s=$pdo->prepare('INSERT INTO lives(user_id,title,place) VALUES(?,?,?)'); $s->execute([$uid,(string)($input['title']??'BEN CANLI'),(string)($input['place']??'')]); echo json_encode(['ok'=>true,'id'=>$pdo->lastInsertId(),'user_id'=>$uid]); exit;
  }
  if ($path === 'coins/gift' && $method === 'POST') { $s=$pdo->prepare('INSERT INTO coin_transactions(from_user,to_user,amount,type) VALUES(?,?,?,?)'); $s->execute([(int)$input['from_user'],(int)$input['to_user'],(int)$input['amount'],'gift']); echo json_encode(['ok'=>true]); exit; }
  http_response_code(404); echo json_encode(['ok'=>false,'message'=>'Endpoint bulunamadı']);
} catch (Throwable $e) { http_response_code(500); echo json_encode(['ok'=>false,'message'=>$e->getMessage()]); }
