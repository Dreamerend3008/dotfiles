# config ssh github 
ssh-keygen -t ed25519 -C "harry"

Config for ssh with diferent port

Host github.com
        Hostname ssh.github.com
        Port 443
        User git

eval "$(ssh-agent -s)"

# install Neovim Ubuntu
sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt update
sudo apt install neovim


