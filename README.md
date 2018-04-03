My Unix dotfiles
================

Mostly used for Node.js and CoffeeScript development.

## Running via Docker

There is a Docker image available for this setup. Run it with:

```shell
docker run --name shell -it bergie/shell
```

### Updating the container

```shell
sudo docker rm -f shell
docker run --name shell -it bergie/shell
```

## Installation

These dotfiles are easiest to deploy with [GNU Stow](https://www.gnu.org/software/stow/). Install it for the appropriate operating system:

```term
$ sudo apt-get install stow # Debian derivatives
$ sudo pacman -S stow       # Arch
$ brew install stow         # MacOS
$ apt install stow          # Termux
```

Then apply the configuration bundles you want:

```term
$ stow zsh                  # zsh and tmux configuration
$ stow git                  # git configuration
$ stow vim                  # vim configuration
```

For vim you'll also want to fetch the plugins:

```term
$ git submodule update --init
```
