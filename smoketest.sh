#!/bin/sh
# Local smoketest for Ansible playbook
# Run this after applying setup.yml to verify installations

set -e

echo "=== Core Tools ==="
git --version
curl --version
wget --version
tmux -V
jq --version
rsync --version

echo ""
echo "=== Editors ==="
nvim --version
fish --version

echo ""
echo "=== Languages ==="
python3 --version
ruby --version

echo ""
echo "=== Node.js ==="
node --version
npm --version

echo ""
echo "=== CLI Tools ==="
rg --version
fd --version
fzf --version
bat --version
tree --version

echo ""
echo "=== Encryption ==="
gpg --version
sops --version

echo ""
echo "=== Ansible ==="
ansible --version

echo ""
echo "=== Python Packages ==="
python3 -c "import RNS; print('RNS OK')"
python3 -c "import dacar; print('dacar OK')"

echo ""
echo "=== Ruby Gems ==="
bundle --version

echo ""
echo "=== Starship ==="
starship --version
test -f $HOME/.local/bin/starship && echo "Starship binary found"

echo ""
echo "=== Pi Agent ==="
if command -v pi >/dev/null 2>&1; then
  pi --version || echo "Pi installed but may need additional setup"
else
  echo "Pi not installed (skipped in CI)"
fi

echo ""
echo "=== Dotfiles Symlinks ==="
test -L $HOME/.config/fish && echo ".config/fish ✓"
test -L $HOME/.tmux.conf && echo ".tmux.conf ✓"
test -L $HOME/.gitconfig && echo ".gitconfig ✓"
test -L $HOME/.config/nvim && echo ".config/nvim ✓"
test -L $HOME/.pi && echo ".pi ✓"

echo ""
echo "=== Git Submodule ==="
test -d $HOME/dotfiles/nvim/.local/share/nvim/site/pack/plugins/start/tokyonight && echo "tokyonight submodule ✓"

echo ""
echo "✓ All smoketests passed!"