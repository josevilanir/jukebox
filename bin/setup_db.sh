#!/bin/bash
set -e

echo "Creating PostgreSQL role..."
sudo -u postgres psql -c "CREATE ROLE rails WITH LOGIN CREATEDB PASSWORD 'rails';" || echo "Role might already exist."

echo "Setting up Rails database..."
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
bin/rails db:create db:migrate db:seed

echo "Database configured successfully!"
