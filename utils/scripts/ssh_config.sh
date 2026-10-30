# Configuration for ssh in github
ssh-keygen -t ed25519 -C "harry"

echo "Host github.com
        Hostname ssh.github.com
        Port 443
        User git" > ~/.ssh/config

eval "$(ssh-agent -s)"

echo "Your ssh to copy in Github: "

cat ~/.ssh/id_ed25519.pub
