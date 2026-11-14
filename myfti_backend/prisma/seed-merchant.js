require('dotenv/config');

const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const prisma = require('../src/config/prisma');

function generateWalletId() {
  return `FTI${new Date().getFullYear()}${crypto.randomInt(0, 1000000).toString().padStart(6, '0')}`;
}

async function main() {
  const email = process.env.MERCHANT_EMAIL?.trim().toLowerCase();
  const password = process.env.MERCHANT_PASSWORD;
  const fullName = process.env.MERCHANT_NAME || 'MyFTI Merchant';

  if (!email || !password) {
    throw new Error('MERCHANT_EMAIL and MERCHANT_PASSWORD must be set in .env');
  }

  if (password.length < 8) {
    throw new Error('Merchant password must be at least 8 characters');
  }

  const passwordHash = await bcrypt.hash(password, 12);

  await prisma.$transaction(async (tx) => {
    const existing = await tx.user.findUnique({ where: { email } });

    if (existing && existing.role !== 'MERCHANT') {
      throw new Error('This email already belongs to a Student account.');
    }

    let merchant;

    if (existing) {
      merchant = await tx.user.update({
        where: { id: existing.id },
        data: { fullName, passwordHash },
        include: { wallet: true },
      });
    } else {
      merchant = await tx.user.create({
        data: {
          fullName,
          email,
          passwordHash,
          nim: null,
          role: 'MERCHANT',
          wallet: {
            create: {
              walletId: generateWalletId(),
              balance: 0,
            },
          },
        },
        include: { wallet: true },
      });
    }

    if (!merchant.wallet) {
      await tx.wallet.create({
        data: {
          userId: merchant.id,
          walletId: generateWalletId(),
          balance: 0,
        },
      });
    }

    console.log(`Merchant ready: ${merchant.email}`);
  });
}

main()
  .catch((error) => {
    console.error('Merchant seed failed:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
