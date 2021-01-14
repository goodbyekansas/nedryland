sudo --preserve-env=SSH_AUTH_SOCK \
ssh -T -o StrictHostKeyChecking=accept-new \
root@nix-builders.goodbyekansas.com 'nix-store --version && echo "connection successful"'
