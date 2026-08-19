if status is-interactive
    and type -q tmux
    and not set -q TMUX
    and not string match -q -r '^(screen|tmux)' $TERM
    and not set -q SSH_CLIENT
    exec tmux
end

set fish_greeting

if test -d /opt/homebrew
  fish_add_path -p /opt/homebrew/bin
end
if test -d /opt/homebrew/Cellar/ruby@3.4/3.4.9/bin
  fish_add_path -p /opt/homebrew/Cellar/ruby@3.4/3.4.9/bin
end
if test -d $HOME/.local/bin
  if type -q fish_add_path
    # Uses the modern, preferred method (Fish 3.2.0+)
    fish_add_path $HOME/.local/bin
  else
    # Fallback for Fish 3.1.2 and older
    if not contains $HOME/.local/bin $PATH
        set -gx PATH $HOME/.local/bin $PATH
    end
  end
end
if test -d $HOME/.deno/bin
  fish_add_path $HOME/.deno/bin
end
if test -d $HOME/.bun/bin
  fish_add_path $HOME/.bun/bin
end

set -Ux EDITOR nvim
set -Ux VISUAL nvim

function vi -d 'Run neovim instead of vim if nvim is installed'
  if command -q nvim
    command nvim $argv
  else
    command vim $argv
  end
end

function vim -d 'Run neovim instead of vim if nvim is installed'
  if command -q nvim
    command nvim $argv
  else
    command vim $argv
  end
end

if type -q starship
  starship init fish | source
end

# Termux-specific: Ansible temp directories (Android W^X restrictions)
if test -n "$TERMUX_VERSION"
  set -gx ANSIBLE_LOCAL_TEMP "$PREFIX/tmp/.ansible/tmp"
  set -gx ANSIBLE_REMOTE_TMP "$PREFIX/tmp/.ansible/tmp"
end
