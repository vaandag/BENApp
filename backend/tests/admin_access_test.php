<?php
declare(strict_types=1);

require __DIR__ . '/../public/lib/http.php';

putenv('BEN_ADMIN_USER_IDS=7, 12,7,invalid,0,-4');

$checks = [
  'allow first admin' => ben_is_admin_user(7),
  'allow second admin' => ben_is_admin_user(12),
  'reject non-admin' => !ben_is_admin_user(8),
  'reject zero' => !ben_is_admin_user(0),
  'reject negative' => !ben_is_admin_user(-4),
  'filter to unique positive IDs' => ben_admin_user_ids() === [7, 12],
];

foreach ($checks as $name => $passed) {
  if (!$passed) {
    throw new RuntimeException("Admin access check failed: $name");
  }
}

putenv('BEN_ADMIN_USER_IDS');
echo "Admin allowlist accepts only unique positive user IDs.\n";
