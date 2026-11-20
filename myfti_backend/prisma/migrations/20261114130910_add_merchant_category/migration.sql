-- CreateEnum
CREATE TYPE "MerchantCategory" AS ENUM ('ALLEYWAY', 'PRINT', 'KANTIN', 'JUKEL_PO', 'AKADEMIK');

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "merchantCategory" "MerchantCategory";
