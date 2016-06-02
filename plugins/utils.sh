utils_install_tar() {
  hascmd apt-get && { utils_install_tar_debian "$@"; return ;}
  hascmd apk && { utils_install_tar_alpine "$@"; return ;}
  os_version && return 1
}

utils_install_tar_debian() {
  curl -fsSL http://ftp.debian.org/debian/pool/main/t/tar/tar_1.29-1_amd64.deb -o /tmp/tar.deb && \
  dpkg -i /tmp/tar.deb
}
