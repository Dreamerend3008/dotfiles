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
    neovim \
    git \
    curl

# --- Install chezmoi if not present ---
if ! command -v chezmoi &>/dev/null; then
    echo "📥 Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
fi

# --- Apply chezmoi configs ---
echo "⚙️ Applying chezmoi dotfiles..."
chezmoi apply

# --- Ensure ~/.bash_aliase is sourced in .bashrc ---
if ! grep -q 'source ~/.bash_aliase' "$HOME/.bashrc"; then
    echo "📎 Adding ~/.bash_aliase sourcing to .bashrc"
    echo '[ -f ~/.bash_aliase ] && source ~/.bash_aliase' >> "$HOME/.bashrc"
fi

echo "✅ Setup complete. Restart your shell or run: source ~/.bashrc"

