#!/bin/bash
set -e

echo "Installing system prerequisites..."
sudo apt-get update
sudo apt-get install -y git curl libssl-dev libreadline-dev zlib1g-dev \
    autoconf bison build-essential libyaml-dev libncurses5-dev \
    libffi-dev libgdbm-dev

echo "Installing PostgreSQL..."
sudo apt-get install -y postgresql postgresql-contrib libpq-dev

echo "Installing Node.js & Yarn..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install --global yarn

echo "System dependencies installed successfully!"
