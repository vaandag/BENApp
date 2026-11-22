<?php
declare(strict_types=1);

/**
 * Return a bounded report queue enriched with the current target content.
 * This function is called only after the HTTP route has verified admin access.
 *
 * @return array<int, array<string, mixed>>
 */
function ben_admin_report_rows(PDO $pdo, string $status): array {
  if (!in_array($status, ['open', 'resolved', 'rejected'], true)) {
    $status = 'open';
  }

  $sql = <<<'SQL'
SELECT
  r.*,
  reporter.username AS reporter_username,
  substr(
    CASE r.target_type
      WHEN 'user' THEN
        CASE WHEN target_user.id IS NULL THEN 'Kullanıcı bulunamadı'
             ELSE '@' || target_user.username END
      WHEN 'memory' THEN
        COALESCE(NULLIF(target_memory.title, ''), NULLIF(target_memory.body, ''), 'Anı bulunamadı')
      WHEN 'comment' THEN
        COALESCE(NULLIF(target_comment.body, ''), 'Yorum bulunamadı')
      WHEN 'live' THEN
        COALESCE(NULLIF(target_live.title, ''), 'Canlı yayın bulunamadı')
      ELSE 'İçerik bulunamadı'
    END,
    1,
    500
  ) AS target_preview,
  CASE r.target_type
    WHEN 'user' THEN target_user.username
    WHEN 'memory' THEN memory_owner.username
    WHEN 'comment' THEN comment_owner.username
    WHEN 'live' THEN live_owner.username
    ELSE NULL
  END AS target_author_username
FROM content_reports r
LEFT JOIN users reporter ON reporter.id = r.reporter_id
LEFT JOIN users target_user
  ON r.target_type = 'user' AND target_user.id = r.target_id
LEFT JOIN memories target_memory
  ON r.target_type = 'memory' AND target_memory.id = r.target_id
LEFT JOIN users memory_owner ON memory_owner.id = target_memory.user_id
LEFT JOIN comments target_comment
  ON r.target_type = 'comment' AND target_comment.id = r.target_id
LEFT JOIN users comment_owner ON comment_owner.id = target_comment.user_id
LEFT JOIN lives target_live
  ON r.target_type = 'live' AND target_live.id = r.target_id
LEFT JOIN users live_owner ON live_owner.id = target_live.user_id
WHERE r.status = ?
ORDER BY r.created_at ASC, r.id ASC
LIMIT 200
SQL;

  $statement = $pdo->prepare($sql);
  $statement->execute([$status]);
  return $statement->fetchAll(PDO::FETCH_ASSOC);
}
