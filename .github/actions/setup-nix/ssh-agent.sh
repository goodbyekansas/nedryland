#! /usr/bin/env sh

# user ssh config
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cp "$SSH_CONFIG" ~/.ssh/config
echo "$BUILDERS_ACCESS_KEY" >~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# root ssh config
root_home=$(sudo -i -H bash -c 'echo $HOME')  # So the shell doesn't exand too early.

echo "using $root_home for root's home"
sudo mkdir -p "$root_home/.ssh"
sudo chmod 700 "$root_home/.ssh"
sudo cp "$SSH_CONFIG" "$root_home/.ssh/config"
echo "$BUILDERS_ACCESS_KEY" | sudo tee "$root_home/.ssh/id_rsa" >/dev/null
sudo chmod 600 "$root_home/.ssh/id_rsa"
