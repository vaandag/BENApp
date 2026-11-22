<?php
declare(strict_types=1);

require __DIR__ . '/../public/lib/schema.php';
require __DIR__ . '/../public/lib/notifications.php';

$pdo = new PDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
ben_migrate($pdo);
$insert = $pdo->prepare('INSERT INTO notifications(user_id,type,text,is_read) VALUES(?,?,?,?)');
$insert->execute([1,'like','Yeni beğeni',0]);
$insert->execute([1,'announcement',"BEN duyurusu\nMerhaba",0]);
$insert->execute([1,'follow','Yeni takipçi',1]);
$insert->execute([2,'comment','Başka kullanıcı bildirimi',0]);

if (ben_unread_notification_count($pdo, 1) !== 2 ||
    ben_unread_notification_count($pdo, 2) !== 1 ||
    ben_unread_notification_count($pdo, 999) !== 0 ||
    ben_unread_notification_count($pdo, 0) !== 0) {
  throw new RuntimeException('Unread notification counts are not isolated by user/read status.');
}
echo "Unread notification counts are scoped to the authenticated account.\n";
