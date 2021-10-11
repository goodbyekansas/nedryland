#! /usr/bin/env sh
which ssh-agent || (apt-get update -y && apt-get install openssh-client -y)
##
## Run ssh-agent (inside the build environment)
##
eval "$(ssh-agent -s)"
##
## Add the SSH key stored in SSH_PRIVATE_KEY variable to the agent store
## We're using tr to fix line endings which makes ed25519 keys work
## without extra base64 encoding.
## https://gitlab.com/gitlab-examples/ssh-private-key/issues/1#note_48526556
##
echo "$SSH_KEY_BUILDERS" | tr -d '\r' | ssh-add -
##

echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >>"$GITHUB_ENV"
echo "NIX_SSHOPTS='-o ServerAliveInterval=15 -o ServerAliveCountMax=150'" >>"$GITHUB_ENV"

# set up for root
sudo mkdir -p /root/.ssh
sudo chmod 700 /root/.ssh
echo "$SSH_KEY_BUILDERS" | sudo tee /root/.ssh/id_rsa >/dev/null
sudo chmod 600 /root/.ssh/id_rsa

ssh-add -L
