file { "/home/${id}/.vimrc":
 ensure => link,
 target => "/home/${id}/Projects/dotfiles/vimrc",
}
file { "/home/${id}/.vim":
 ensure => link,
 target => "/home/${id}/Projects/dotfiles/vim",
}
