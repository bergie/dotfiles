if status is-interactive
# Commands to run in interactive sessions can go here
and type -q tmux
and not set -q TMUX
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
  fish_add_path $HOME/.local/bin
end
if test -d $HOME/.deno/bin
  fish_add_path $HOME/.deno/bin
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
