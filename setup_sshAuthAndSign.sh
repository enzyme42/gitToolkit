#!/bin/sh

git config --global user.name "First Last"
git config --global user.email "first.last@domain.tld"

ssh-keygen -t ed25519 -C "first.last@domain.tld"

cat ~/.ssh/id_ed25519.pub

# Returns PUBLIC_KEY - add it to your SSH keys (auth and sign) on Github

ssh-add ~/.ssh/id_ed25519

git config --global gpg.format ssh
git config --global user.signingKey "PUBLIC_KEY"

git config --global commit.gpgSign true
git config --global tag.gpgSign true
