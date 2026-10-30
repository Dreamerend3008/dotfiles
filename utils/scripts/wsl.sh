# bash script to config this repo using wsl
set -euo pipefail

echo "Instaling dotfiles into wsl!!"

echo "Updating & Upgrading system"

sudo apt update
sudo apt upgrade

echo "Instaling Neovim"

sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt update
sudo apt install neovim

echo "Cloning the repo"

git clone https://github.com/Dreamerend3008/dotfiles.git ~/dotfiles
cd ~/dotfiles

echo "Instaling Nix & Repo" 

sh <(curl -L https://nixos.org/nix/install) --no-daemon

mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

nix run home-manager/master -- switch --flake .#harry
