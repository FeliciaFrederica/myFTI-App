-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('STUDENT', 'MERCHANT');

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "role" "UserRole" NOT NULL DEFAULT 'STUDENT';
