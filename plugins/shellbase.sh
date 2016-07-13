add_shellbasedeps() {

  APK_PACKAGES='tar sed vim less findutils git build-base' \
  APT_PACKAGES='vim exuberant-ctags less findutils mlocate git' \
  main add-pkg || return

  hascmd apt-get || { main add ctags || return ;}

  main cleanup
}

add_ctags() {
  main add-pkg autoconf automake && \
  curl -fsSL https://github.com/universal-ctags/ctags/archive/master.tar.gz | tar -zxC /tmp && \
  (cd /tmp/ctags-master && ./autogen.sh ./configure && make && make install && cd && apk del build-base && rm -rf /tmp/*) && \
  main remove-pkg autoconf automake
}

add_shellbase() {
  local version="$1"; shift

  curl -fsSL https://github.com/elifarley/shellbase/archive/"$version".tar.gz \
  | tar --exclude README.md --exclude LICENSE --strip=1 --overwrite -zxvC "$HOME" || return

  sed -i '/^set listchars=tab/d' "$HOME"/.vimrc || return
  
  curl -fsSL https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.ansi-dark \
    > "$HOME"/.dircolors || return
  
  printf "PATH=$PATH\n" >> "$HOME"/.ssh/environment || return
  printf ". '$HOME'/.ssh/environment\npwd" >> "$HOME"/.bashrc
}

export VIM_EXTRA_URLS='
https://github.com/tpope/vim-eunuch/archive/master.tar.gz
https://github.com/altercation/vim-colors-solarized/archive/master.tar.gz
https://github.com/tpope/vim-obsession/archive/master.tar.gz
https://github.com/justinmk/vim-dirvish/archive/master.tar.gz
https://github.com/tpope/vim-vinegar/archive/master.tar.gz
https://github.com/ervandew/supertab/archive/master.tar.gz
https://github.com/ctrlpvim/ctrlp.vim/archive/master.tar.gz
https://github.com/majutsushi/tagbar/archive/master.tar.gz
https://github.com/tpope/vim-fugitive/archive/master.tar.gz
https://github.com/tpope/vim-rails/archive/master.tar.gz
https://github.com/tpope/vim-bundler/archive/master.tar.gz
'

add_shellbasevimextra() {

  # Install Pathogen - https://github.com/tpope/vim-pathogen
  mkdir -p "$HOME"/.vim/autoload "$HOME"/.vim/bundle "$HOME"/.vim/colors || return
  curl -fsSL https://raw.githubusercontent.com/sjl/badwolf/master/colors/badwolf.vim > "$HOME"/.vim/colors/badwolf.vim || return
  curl -fsSL https://raw.githubusercontent.com/jnurmine/Zenburn/master/colors/zenburn.vim > "$HOME"/.vim/colors/zenburn.vim || return
  curl -fsSL https://tpo.pe/pathogen.vim > "$HOME"/.vim/autoload/pathogen.vim || return

  sed -i '1 i\execute pathogen#infect()\ncall pathogen#helptags()\n' "$HOME"/.vimrc || return

  ( cd ~/.vim/bundle && mkdir -p csapprox && curl -fsSL https://github.com/godlygeek/csapprox/archive/4.00.tar.gz \
      | tar --strip 1 -zxC csapprox && \
    for url in $(echo $VIM_EXTRA_URLS);
      do echo "Downloading $url..." && curl -fsSL "$url" | tar -zx &
    done && wait && mv vim-vinegar-* vim-vinegar~ || return
  )

  chown -R $_USER:$_USER "$HOME" && updatedb
}
