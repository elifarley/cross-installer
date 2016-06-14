install_base() {
  curl -fsSL https://raw.githubusercontent.com/elifarley/docker-dev-env/master/entry.sh -o /entry.sh && \
  curl -fsSL https://raw.githubusercontent.com/elifarley/docker-dev-env/master/env-vars.sh -o /env-vars.sh && \
  curl -fsSL https://raw.githubusercontent.com/elifarley/docker-dev-env/master/keytool-import-certs.sh -o /keytool-import-certs.sh && \
  chmod +x /*.sh
}

configure_sshd_alpine() {
  sed -e '/Port/d;/UsePrivilegeSeparation/d;/PermitRootLogin/d;/PermitUserEnvironment/d;/UsePAM/d;/UseDNS/d;/PasswordAuthentication/d;/ChallengeResponseAuthentication/d;/Banner/d;/PrintMotd/d;/PrintLastLog/d' \
    /etc/ssh/sshd_config > /etc/ssh/sshd_config.tmp || return
  printf "\nPort 2200\nUsePrivilegeSeparation no\nPermitRootLogin no\nPasswordAuthentication no\nChallengeResponseAuthentication no\nPermitUserEnvironment yes\nUseDNS no\nPrintMotd no\n\n#---\n" \
    > /etc/ssh/sshd_config || return
  cat /etc/ssh/sshd_config.tmp >> /etc/ssh/sshd_config || return
  rm /etc/ssh/sshd_config.tmp || return
  cp -a /etc/ssh /etc/ssh.cache
}

configure_sshd_debian() {
  sed -e '/Port/d;/UsePrivilegeSeparation/d;/PermitRootLogin/d;/PermitUserEnvironment/d;/UsePAM/d;/PasswordAuthentication/d;/ChallengeResponseAuthentication/d;/Banner/d' /etc/ssh/sshd_config > /etc/ssh/sshd_config.tmp || return
  printf "\nPort 2200\nUsePrivilegeSeparation no\nPermitRootLogin no\nUsePAM no\nPasswordAuthentication no\nChallengeResponseAuthentication no\nPermitUserEnvironment yes\n\n#---\n" > /etc/ssh/sshd_config || return
  cat /etc/ssh/sshd_config.tmp >> /etc/ssh/sshd_config && rm /etc/ssh/sshd_config.tmp && \
  cp -a /etc/ssh /etc/ssh.cache
}

configure_rsyslog() {
  cat >/etc/rsyslog.conf <<EOF
$ModLoad imuxsock # provides support for local system logging

# See http://www.rsyslog.com/doc/v8-stable/configuration/templates.html
template(name="def" type="list") {
  property(name="timegenerated" dateFormat="rfc3339")
  constant(value="<")
  property(name="pri")
  constant(value=">")
  constant(value="@")
  property(name="hostname")
  constant(value="#")
  property(name="syslogtag")
  constant(value=";")
  property(name="msg" spifno1stsp="on" )
  property(name="msg" droplastlf="on" )
  constant(value="\n")
}

$ActionFileDefaultTemplate def

$FileOwner root
$FileGroup adm
$FileCreateMode 0640
$DirCreateMode 0755
$Umask 0022

# Where to place spool and state files
$WorkDirectory /var/spool/rsyslog

$IncludeConfig /etc/rsyslog.d/*.conf

# Check config syntax on startup and abort if unclean (default off)
$AbortOnUncleanConfig on

# Reduce repeating messages (default off)
$RepeatedMsgReduction on

*.debug;mail.none;authpriv.none       /dev/console
EOF
}

add_user_alpine() {
  local user="$1"; shift

  adduser -D -h "$HOME" -s /bin/bash "$user" || return
  # Disable sudo: echo 'auth requisite  pam_deny.so' > /etc/pam.d/su
  { getent group "sudo" || addgroup -S sudo ;} || return
  printf '%sudo   ALL=(ALL:ALL) ALL\n' >> /etc/sudoers || return
  gpasswd -a "$user" sudo || return
  printf "$user ALL=(ALL) NOPASSWD: ALL\n" >> /etc/sudoers || return

  mkdir -p "$HOME"/.ssh && \
  chmod go-w "$HOME" && \
  chmod 700 "$HOME"/.ssh && \
  chown -R "$user:$user" "$HOME"
}

add_user_debian() {
  local user="$1"; shift

  adduser --disabled-password --home "$HOME" --shell /bin/bash --gecos "" "$user" || return
  gpasswd -a "$user" sudo || return $?
  printf "$user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers || return
  mkdir -p $HOME/.ssh && \
  chmod go-w $HOME && \
  chmod 700 $HOME/.ssh && \
  chown -R "$user:$user" "$HOME"
}

install_tini() {
  test $# = 2 || {
    echo "Usage: $0 install tini <version> <sha1>"
    return 1
  }
  local version="$1"; shift
  local sha="$1"; shift
  local url=https://github.com/krallin/tini/releases/download/"$version"/tini-static
  curl -fsSL "$url" -o /bin/tini || {
    echo "Please check URL '$url'"
    return 1
  }
  chmod +x /bin/tini && echo "$sha  /bin/tini" | sha1sum -wc -
}

install_gosu() {
  test $# = 2 || {
    echo "Usage: $0 install tini <version> <sha1>"
    return 1
  }
  local version="$1"; shift
  local sha="$1"; shift
  curl -fsSL https://github.com/tianon/gosu/releases/download/"$version"/gosu-amd64 -o /bin/gosu && \
    chmod 755 /bin/gosu && echo "$sha  /bin/gosu" | sha1sum -wc -
}

cleanup() {

  if hascmd apk ; then
    cleanup_alpine "$@" || return
  elif hascmd apt-get ; then
    cleanup_debian "$@" || return
  fi

  local rm_items='/tmp/* /var/tmp/* /var/backups/* /usr/share/man /usr/share/doc'
  echo Removing $rm_items
  rm -rf $rm_items

}

cleanup_alpine() {
  rm -rf /var/cache/apk/*
}

cleanup_debian() {
  #ENV RM_APT='/var/lib/apt/lists/* /var/lib/apt /var/lib/dpkg'
  apt-get autoremove --purge -y && apt-get clean && \
  rm -rf /etc/cron.daily/{apt,passwd}
}
