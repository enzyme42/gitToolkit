#!/bin/bash

GIT_VERSION=$(git --version | cut -d " " -f 3-)
REQUIRE_VER="2.34.0"

VERSION_CHECK=$(echo "$GIT_VERSION\n$REQUIRE_VER" | sort -rV | head -n 1)

printf "Github authorization and commit signing configuration script\n\nChecking for git version: $REQUIRE_VER+\nInstalled git version:    $GIT_VERSION\n"

if [ $VERSION_CHECK = $GIT_VERSION ]
then
  printf "Your git version: $GIT_VERSION is compatible with SSH signing.\n\n"
  GPG_FALLBACK=false
else
  printf "Your git version: $GIT_VERSION is not compatible with SSH signing. Falling back to GPG signing.\n\n"
  GPG_FALLBACK=true
fi

read -p "> Enter your Github name: " NAME
read -p "> Enter your Github e-mail address: " EMAIL

if [ ! -z "$NAME" ] && [ ! -z "$EMAIL" ]
then
  git config --global user.name "$NAME"
  git config --global user.email "$EMAIL"

  ssh-keygen -t ed25519 -C "$EMAIL" -f $HOME/.ssh/id_ed25519

  SSH_PUB_KEY=$(cat $HOME/.ssh/id_ed25519.pub)

  ssh-add $HOME/.ssh/id_ed25519

  if ! $GPG_FALLBACK
  then
    git config --global gpg.format ssh
    git config --global user.signingKey "$SSH_PUB_KEY"
    printf "Please add following SSH public key to your Github account as both AUTH and SIGN:\n\n$SSH_PUB_KEY\n"
  else
    gpg --full-generate-key
    git config --global --unset gpg.format
    GPG_KEYID=$(gpg --list-secret-keys --keyid-format=LONG | grep sec | cut -d " " -f 4 | cut -d "/" -f 2)
    git config --global user.signingKey $GPG_KEYID
    GPG_PUB_KEY=$(gpg --armor --export $GPG_KEYID)

    export GPG_TTY=$(tty)
    [ -f $HOME/.bashrc ] && echo 'export GPG_TTY=$(tty)' >> $HOME/.bashrc

    printf "Please add following SSH public key to your Github account as AUTH:\n\n$SSH_PUB_KEY\n\nand the following GPG public key as SIGN:\n\n$GPG_PUB_KEY\n\n"
  fi

  git config --global commit.gpgSign true
  git config --global tag.gpgSign true

else
  printf "\nMissing name or e-mail\n"
fi
