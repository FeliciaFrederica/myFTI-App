-- Add avatarUrl if it does not exist yet.
ALTER TABLE "User"
ADD COLUMN IF NOT EXISTS "avatarUrl" TEXT;

-- Add transaction PIN hash.
ALTER TABLE "User"
ADD COLUMN IF NOT EXISTS "pinHash" TEXT;