install_mongodb() {
  hascmd apt-get && { install_mongodb_apt; return ;}
  hascmd yum && { install_mongodb_yum; return ;}
  os_version
  exit 1
}

install_mongodb_apt() {
  hascmd apt-key && apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
  local apt_src_file='/etc/apt/sources.list.d/mongodb-org-3.0.list'
  test -e "$apt_src_file" && grep -q 'mongodb-org/3.0' "$apt_src_file" || if os_version ubuntu; then
    test -f /etc/lsb-release && . /etc/lsb-release
    echo "deb http://repo.mongodb.org/apt/ubuntu $DISTRIB_CODENAME/mongodb-org/3.0 multiverse" | tee "$apt_src_file" && \
    apt-get update
  else
    echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/3.0 main" | tee "$apt_src_file" && \
    apt-get update
  fi
  apt-get install -y mongodb-org
}

install_mongodb_yum() {
  cat >/etc/yum.repos.d/mongodb-org-3.0.repo <<EOF
[mongodb-org-3.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.0/x86_64/
gpgcheck=0
enabled=1
EOF
  yum install -y mongodb-org
}
