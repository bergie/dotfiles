file { "/home/${id}/.vimrc":
 ensure => link,
 target => "/home/${id}/Projects/dotfiles/vimrc",
}
file { "/home/${id}/.vim":
 ensure => link,
 target => "/home/${id}/Projects/dotfiles/vim",
}
file { "/home/${id}/.gitconfig":
 ensure => link,
 target => "/home/${id}/Projects/dotfiles/gitconfig",
}
file { "/home/${id}/.zshrc":
 ensure => link,
 target => "/home/${id}/Projects/dotfiles/zshrc",
}
file { "/home/${id}/.tmux.conf":
  ensure => link,
  target => "/home/${id}/Projects/dotfiles/tmux.conf",
}
