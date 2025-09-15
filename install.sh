#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Setting up development environment on Ubuntu..."

# --- Update apt and install essentials ---
echo "📦 Updating apt and installing required packages..."
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    make \
    g++ \
    git \
    curl \
    unzip \
    pkg-config \
    libssl-dev \
    snapd

# --- Install chezmoi if not present ---
if ! command -v chezmoi &>/dev/null; then
    echo "📥 Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
fi

# --- Apply chezmoi configs ---
echo "⚙️ Applying chezmoi dotfiles..."
chezmoi apply

# --- Install Neovim using snap ---
if ! command -v nvim &>/dev/null; then
    echo "📥 Installing Neovim (snap)..."
    sudo snap install nvim --classic
else
    echo "✅ Neovim already installed: $(nvim --version | head -n 1)"
fi


