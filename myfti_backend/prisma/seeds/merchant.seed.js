require('dotenv/config');

const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const prisma = require('../../src/config/prisma');

const merchants = [
  {
    fullName: 'Alleyway',
    email: 'alleyway@myfti.test',
    category: 'ALLEYWAY',
  },
  {
    fullName: 'Print Shop',
    email: 'printshop@myfti.test',
    category: 'PRINT',
  },
  {
    fullName: 'Kantin Teknik',
    email: 'kantinteknik@myfti.test',
    category: 'KANTIN',
  },
  {
    fullName: 'CP Jukel & PO',
    email: 'jukelpo@myfti.test',
    category: 'JUKEL_PO',
  },
  {
    fullName: 'Akademik',
    email: 'akademik@myfti.test',
    category: 'AKADEMIK',
  },
];

function generateWalletId() {
  return `FTI${new Date().getFullYear()}${crypto
    .randomInt(0, 1000000)
    .toString()
    .padStart(6, '0')}`;
}

async function main() {
  const password = process.env.MERCHANT_PASSWORD;

  if (!password) {
    throw new Error('MERCHANT_PASSWORD must be set in .env');
  }

  if (password.length < 8) {
    throw new Error('Merchant password must be at least 8 characters');
  }

  const passwordHash = await bcrypt.hash(password, 12);

  await prisma.$transaction(async (tx) => {
    for (const item of merchants) {
      const email = item.email.trim().toLowerCase();

      const existing = await tx.user.findUnique({
        where: { email },
      });

      if (existing && existing.role !== 'MERCHANT') {
        throw new Error(
          `This email already belongs to a Student account: ${email}`,
        );
      }

      let merchant;

      if (existing) {
        merchant = await tx.user.update({
          where: { id: existing.id },
          data: {
            fullName: item.fullName,
            passwordHash,
            merchantCategory: item.category,
          },
        });
      } else {
        merchant = await tx.user.create({
          data: {
            fullName: item.fullName,
            email,
            passwordHash,
            nim: null,
            role: 'MERCHANT',
            merchantCategory: item.category,
          },
        });
      }

      const wallet = await tx.wallet.findUnique({
        where: { userId: merchant.id },
      });

      if (!wallet) {
        await tx.wallet.create({
          data: {
            userId: merchant.id,
            walletId: generateWalletId(),
            balance: 0,
          },
        });
      }

      console.log(`Merchant ready: ${merchant.email}`);
    }
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