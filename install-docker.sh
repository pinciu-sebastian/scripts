#!/usr/bin/env bash
# --------------------------------------------------------------------
# Docker Engine Installation Script for Ubuntu 24.04 (Noble Numbat)
# --------------------------------------------------------------------
# This script:
# 1. Removes old/conflicting Docker packages
# 2. Adds Docker’s official APT repository
# 3. Installs Docker Engine + CLI + plugins
# 4. Verifies installation
# --------------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

log() {
  echo -e "\n\033[1;34m[INFO]\033[0m $1"
}

error_exit() {
  echo -e "\n\033[1;31m[ERROR]\033[0m $1" >&2
  exit 1
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    error_exit "Please run this script as root (use: sudo bash $0)"
  fi
}

main() {
  check_root

  log "1️⃣ Removing old or conflicting Docker packages..."
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    apt-get remove -y "$pkg" >/dev/null 2>&1 || true
  done
  log "Old packages removed (if any)."

  log "2️⃣ Installing prerequisites..."
  apt-get update -qq || error_exit "apt-get update failed."
  apt-get install -y ca-certificates curl gnupg lsb-release || error_exit "Failed to install prerequisites."

  log "Creating keyrings directory..."
  install -m 0755 -d /etc/apt/keyrings || error_exit "Failed to create /etc/apt/keyrings."

  log "Adding Docker’s GPG key..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc || error_exit "Failed to download Docker GPG key."
  chmod a+r /etc/apt/keyrings/docker.asc || error_exit "Failed to set permissions on GPG key."

  log "Adding Docker’s APT repository..."
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo ${UBUNTU_CODENAME:-$VERSION_CODENAME}) stable" \
    | tee /etc/apt/sources.list.d/docker.list >/dev/null || error_exit "Failed to add Docker repository."

  log "Updating package index..."
  apt-get update -qq || error_exit "apt-get update failed after adding Docker repo."

  log "3️⃣ Installing Docker Engine and components..."
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || error_exit "Docker installation failed."

  log "4️⃣ Verifying Docker service status..."
  systemctl enable --now docker || error_exit "Failed to enable/start Docker service."

  if systemctl is-active --quiet docker; then
    log "✅ Docker is installed and running!"
    docker --version
  else
    error_exit "Docker service is not running."
  fi

  log "🎉 Installation completed successfully!"
}

main "$@"
