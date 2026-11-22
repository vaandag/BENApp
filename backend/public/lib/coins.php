<?php
declare(strict_types=1);

/**
 * Transfer coins atomically. A failed debit/credit never leaves a partial transfer.
 */
function ben_send_coin_gift(PDO $pdo, int $senderId, int $recipientId, int $amount): void {
  if ($senderId <= 0 || $recipientId <= 0 || $recipientId === $senderId ||
      $amount <= 0 || $amount > 100000) {
    throw new DomainException('Geçerli hediye bilgisi gerekli.', 422);
  }

  $pdo->beginTransaction();
  try {
    $recipient = $pdo->prepare('SELECT 1 FROM users WHERE id=?');
    $recipient->execute([$recipientId]);
    if (!$recipient->fetchColumn()) {
      throw new DomainException('Hediye gönderilecek kullanıcı bulunamadı.', 404);
    }

    // Make the balance condition part of the UPDATE to avoid read-then-write races.
    $debit = $pdo->prepare(
      'UPDATE users SET coins=coins-? WHERE id=? AND coins>=?'
    );
    $debit->execute([$amount, $senderId, $amount]);
    if ($debit->rowCount() !== 1) {
      throw new DomainException('Yetersiz coin.', 422);
    }

    $credit = $pdo->prepare('UPDATE users SET coins=coins+? WHERE id=?');
    $credit->execute([$amount, $recipientId]);
    if ($credit->rowCount() !== 1) {
      throw new DomainException('Hediye gönderilecek kullanıcı bulunamadı.', 404);
    }

    $transaction = $pdo->prepare(
      "INSERT INTO coin_transactions(from_user,to_user,amount,type) VALUES(?,?,?,'gift')"
    );
    $transaction->execute([$senderId, $recipientId, $amount]);
    $pdo->commit();
  } catch (Throwable $error) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    throw $error;
  }
}
