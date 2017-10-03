#!/usr/bin/env bash
# Better Nix UI
# Usage: source ./nixez.sh

function docker-load-nix() {
  if grep -q Microsoft /proc/version; then
    DIR=$(pwd | sed 's|/mnt/\(.\)|\1:|' | sed 's|/|\\|g')
  else
    DIR=$(pwd)
  fi

  IMAGE=$(docker load < result | awk '{print $3}')

  if [[ $1 == "interactive" ]]; then
    ARGS="-ti --rm"
  else
    ARGS=""
  fi

  docker run $ARGS -v "$DIR:/data" "$IMAGE" /bin/sh
}

function nixez() {
  case $1 in
    shell) nix-shell ;;
    search) nix-env -qaP ".*$2.*" ;;
    install) nix-env -f "$(pwd)" -iA "$2" ;;
    remove) nix-env -e "$2" ;;
    list) nix-env -q;;
    build) nix-build "$(pwd)" -A "$2" ;;
    docker)
      nix-build "$(pwd)" -A dockerTar --argstr pkg "$2" &&
      docker-load-nix interactive
    ;;
    singularity)
      nix-build "$(pwd)" -A dockerTar --argstr pkg "$2" &&
      docker-load-nix &&
      NAME=$(docker ps -l --format "{{.Image}}" | sed 's|:|_|')
      docker export "$(docker ps -lq)" | gzip > "$NAME.tar.gz"
    ;;
    setup)
      read -r -p "This will install Nix, are you sure? [y/N]" response
      case "$response" in
        [yY][eE][sS]|[yY])
          curl -o install-nix-1.11.15 https://nixos.org/nix/install
          curl -o install-nix-1.11.15.sig https://nixos.org/nix/install.sig
          gpg --recv-keys B541D55301270E0BCF15CA5D8170B4726D7198DE
          gpg --verify ./install-nix-1.11.15.sig && sh ./install-nix-1.11.15
        ;;
        *)
          echo "Canceled"
        ;;
      esac
    ;;
    unsafe-setup)
      read -r -p "This will install Nix without checking signature, are you sure? [y/N]" response
      case "$response" in
        [yY][eE][sS]|[yY])
          curl https://nixos.org/nix/install | sh
        ;;
        *)
          echo "Canceled"
        ;;
      esac
    ;;
    * ) echo "Options: shell, search, install, remove, list, build, docker, singularity" ;;
  esac
}
