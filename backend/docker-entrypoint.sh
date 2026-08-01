#!/bin/sh
set -e

echo "Running Prisma db push..."
npx prisma db push --accept-data-loss 2>&1

echo "Seeding database..."
npx tsx prisma/seed.ts 2>&1 || echo "Seed skipped (may already exist)"

echo "Starting application..."
exec node dist/index.js
