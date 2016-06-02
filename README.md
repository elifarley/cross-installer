# cross-installer
Helps in installing software in multiple linux distros

Useful when creating **Docker** images based on different Linux distributions.

Here's an example of a **Dockerfile** using **Cross Installer**'s *xinstall* command:

    FROM debian:jessie
    MAINTAINER someone
    ENV BASE_IMAGE=debian:jessie
    
    ENV \
    APTGET_PACKAGES="openssh-server sudo ca-certificates curl rsync" \
    TINI_VERSION='v0.5.0' TINI_SHA=066ad710107dc7ee05d3aa6e4974f01dc98f3888 \
    GOSU_VERSION='1.5' GOSU_SHA=18cced029ed8f0bf80adaa6272bf1650ab68f7aa \
    _USER=app \
    LANG=en_US.UTF-8 TZ=${TZ:-Brazil/East} \
    TERM=xterm-256color
    ENV HOME=/$_USER JAVA_TOOL_OPTIONS="-Duser.timezone=$TZ"
    
    # SSHD
    EXPOSE 2200
    
    ENTRYPOINT ["/bin/tini", "--", "/entry.sh"]
    CMD ["/usr/sbin/sshd", "-D", "-f", "/etc/ssh/sshd_config"]
    
    ADD https://github.com/elifarley/cross-installer/archive/master.tar.gz /tmp/cross-installer.tgz
    ADD https://raw.githubusercontent.com/elifarley/cross-installer/master/install.sh /tmp/cross-installer.sh
    RUN sh /tmp/cross-installer.sh /usr/local && \
      xinstall update-pkg-list && \
      xinstall install timezone && \
      xinstall save-image-info && \
      xinstall install-pkg && \
      xinstall configure sshd && \
      xinstall cleanup

    RUN \
      xinstall install tini "$TINI_VERSION" "$TINI_SHA" && \
      xinstall install gosu "$GOSU_VERSION" "$GOSU_SHA"
    
    RUN xinstall add-user "$_USER"

    RUN xinstall install-base
