<?php
declare(strict_types=1);

/**
 * Search a small, privacy-safe set of accounts for the admin recipient picker.
 * The HTTP route must verify administrator access before calling this helper.
 *
 * @return array<int, array{id:int,username:string,avatar_url:string}>
 */
function ben_admin_search_users(PDO $pdo, string $query): array {
  $query = trim($query);
  if ($query === '') return [];

  $statement = $pdo->prepare(
    "SELECT id, username, avatar_url
     FROM users
     WHERE username LIKE ?
     ORDER BY username COLLATE NOCASE ASC, id ASC
     LIMIT 30"
  );
  $statement->execute(['%' . $query . '%']);
  return $statement->fetchAll(PDO::FETCH_ASSOC);
}

/**
 * Create a BEN announcement for all accounts or one selected account.
 * The caller must authenticate the admin and apply rate limiting.
 *
 * @return array{recipient_count:int}
 */
function ben_admin_send_announcement(
  PDO $pdo,
  int $adminId,
  string $audience,
  ?int $targetUserId,
  string $title,
  string $body
): array {
  $title = trim($title);
  $body = trim($body);

  if ($adminId <= 0) {
    throw new DomainException('Yönetici oturumu gerekli.', 401);
  }
  if (!in_array($audience, ['all', 'user'], true)) {
    throw new DomainException('Geçersiz bildirim hedefi.', 422);
  }
  if ($title === '' || strlen($title) > 200 || $body === '' || strlen($body) > 3000) {
    throw new DomainException('Başlık ve mesaj zorunlu. Başlık en fazla 200, mesaj 3000 bayt olabilir.', 422);
  }

  if ($audience === 'user') {
    if ($targetUserId === null || $targetUserId <= 0) {
      throw new DomainException('Bildirim gönderilecek kullanıcı seçilmedi.', 422);
    }
    $exists = $pdo->prepare('SELECT 1 FROM users WHERE id=?');
    $exists->execute([$targetUserId]);
    if (!$exists->fetchColumn()) {
      throw new DomainException('Seçilen kullanıcı bulunamadı.', 404);
    }
  }

  $notificationText = $title . "\n" . $body;
  $pdo->beginTransaction();
  try {
    if ($audience === 'all') {
      $insert = $pdo->prepare(
        "INSERT INTO notifications(user_id, type, text)
         SELECT id, 'announcement', ? FROM users"
      );
      $insert->execute([$notificationText]);
    } else {
      $insert = $pdo->prepare(
        "INSERT INTO notifications(user_id, type, text) VALUES(?, 'announcement', ?)"
      );
      $insert->execute([$targetUserId, $notificationText]);
    }

    $count = $insert->rowCount();
    $pdo->commit();
    return ['recipient_count' => $count];
  } catch (Throwable $error) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    throw $error;
  }
}
