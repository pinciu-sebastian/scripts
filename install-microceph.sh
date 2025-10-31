#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error

echo "🔧 Updating package list..."
sudo apt update

echo "📦 Installing snapd..."
sudo apt install -y snapd

echo "⚙️ Enabling snapd.socket..."
sudo systemctl enable --now snapd.socket

echo "🔍 Verifying snap version..."
snap version

echo "📦 Installing MicroCeph via snap..."
sudo snap install microceph

echo "⏸️ Holding MicroCeph updates..."
sudo snap refresh --hold microceph

echo "✅ MicroCeph installation complete and updates are held."
