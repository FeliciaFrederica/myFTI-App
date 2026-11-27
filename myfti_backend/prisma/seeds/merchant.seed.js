require('dotenv/config');

const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const prisma = require('../../src/config/prisma');

const merchants = [
  {
    fullName: 'Alleyway',
    previousEmail: 'alleyway@myfti.test',
    email: 'alleyway@gmail.com',
    category: 'ALLEYWAY',
    bankCode: 'ABC',
    accountNumber: '250012250022',
  },
  {
    fullName: 'Print Shop',
    previousEmail: 'printshop@myfti.test',
    email: 'print@gmail.com',
    category: 'PRINT',
    bankCode: 'MANDIRIW',
    accountNumber: '250025250027',
  },
  {
    fullName: 'Kantin',
    previousEmail: 'kantinteknik@myfti.test',
    email: 'kantin@gmail.com',
    category: 'KANTIN',
    bankCode: 'BNN',
    accountNumber: '250039250027',
  },
  {
    fullName: 'Jukel & PO',
    previousEmail: 'jukelpo@myfti.test',
    email: 'jukel@gmail.com',
    category: 'JUKEL_PO',
    bankCode: 'ABC',
    accountNumber: '250025250022',
  },
  {
    fullName: 'Akademik',
    previousEmail: 'akademik@myfti.test',
    email: 'akademik@gmail.com',
    category: 'AKADEMIK',
    bankCode: 'BNN',
    accountNumber: '1234567890',
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
      const emailsToFind = [
        email,
        ...(item.previousEmail ? [item.previousEmail.trim().toLowerCase()] : []),
      ];

      const existing = await tx.user.findFirst({
        where: { email: { in: emailsToFind } },
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
            email,
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

    await tx.bankAccount.upsert({
      where: {
        userId_bankCode_accountNumber: {
          userId: merchant.id,
          bankCode: item.bankCode,
          accountNumber: item.accountNumber,
        },
      },
      update: {},
      create: {
        userId: merchant.id,
        bankCode: item.bankCode,
        accountNumber: item.accountNumber,
      },
    });

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