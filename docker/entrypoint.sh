#!/bin/sh
set -e

cd /var/www

# Ensure .env exists
if [ ! -f .env ]; then
    echo "No .env found. Copying from .env.example..."
    cp .env.example .env
fi

# Ensure APP_KEY exists
if ! grep -q "APP_KEY=" .env || [ -z "$(grep APP_KEY .env | cut -d '=' -f2)" ]; then
    echo "Generating APP_KEY..."
    php artisan key:generate --force
    php artisan config:clear
fi

# Wait for DB if DB_HOST is set
if [ -n "$DB_HOST" ]; then
    echo "Waiting for database at ${DB_HOST}..."
    until php -r "try { new PDO('mysql:host=${DB_HOST};dbname=${DB_DATABASE}', '${DB_USERNAME}', '${DB_PASSWORD}'); exit(0); } catch (Exception \$e) { exit(1); }"; do
        sleep 3
    done
    echo "Database is ready!"
fi

# Run migrations
if [ -n "$DB_HOST" ]; then
    echo "Running migrations..."
    php artisan migrate --force
fi

exec "$@"
