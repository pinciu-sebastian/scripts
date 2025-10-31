#!/bin/bash

set -e  # Exit on error
set -u  # Treat unset vars as error

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

echo "✅ MicroCeph installed and updates are held."

# 🔎 Check MicroCeph version
echo "📌 Checking MicroCeph version..."
MICROCEPH_VERSION=$(snap info microceph | grep installed | awk '{print $2}')

if [[ -n "$MICROCEPH_VERSION" ]]; then
    echo "✅ MicroCeph is installed. Version: $MICROCEPH_VERSION"
else
    echo "❌ Could not determine MicroCeph version."
    exit 1
fi
