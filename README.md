My Unix dotfiles
================

Mostly used for Node.js and IoT development.

## Running via Docker

There is a multi-arch Docker image available for this setup (linux/amd64, linux/arm64). Run it with:

```shell
$ docker run -v ~/Projects:/projects -v workstation:/home/bergie -v ~/.ssh:/keys --name workstation --rm -it bergie/shell
```

### Updating the container

```shell
$ docker volume rm workstation && docker volume create workstation
$ docker pull bergie/shell
```

### Requirements

* Terminal application (xterm, ghostty, whatever)
* Docker

## Installation on host

These dotfiles can be deployed in two ways:

### Option 1: Ansible (recommended, cross-platform)

A comprehensive Ansible playbook is available that installs developer tools **and** sets up dotfiles. It supports Linux, macOS, and Termux.

```bash
# Install Ansible requirements
ansible-galaxy collection install -r requirements.yml

# Run the full setup (packages + dotfiles)
ansible-playbook -i localhost, -c local setup.yml
```

See [ANSIBLE.md](ANSIBLE.md) for detailed documentation.

### Option 2: GNU Stow (traditional)

Install stow for your operating system:

```term
$ sudo apt-get install stow # Debian derivatives
$ sudo pacman -S stow       # Arch
$ brew install stow         # MacOS
$ pkg install stow          # Termux
```

Note that the repo needs to be directly under the home directory for stow to do the right thing.

Then apply the configuration bundles you want:

```term
$ stow fish                 # fish and tmux configuration
$ stow git                  # git configuration
$ stow nvim                 # neovim configuration
$ stow pi                   # pi coding agent configuration
```

For neovim you'll also want to fetch the plugins:

```term
$ git submodule update --init
```
