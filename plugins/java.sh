# See https://github.com/frol/docker-alpine-oraclejdk8/blob/cleaned/Dockerfile
configure_java_nodesktop() {( cd "$JAVA_HOME" || return
  rm -rf \
    *src.zip \
    db/javadoc \
    db/docs \
    db/demo \
    man \
    lib/missioncontrol \
    lib/visualvm \
    lib/*javafx* \
    jre/lib/plugin.jar \
    jre/lib/ext/jfxrt.jar \
    "$(type 2>/dev/null javaws | grep -o '/.*' || echo not-found)" \
    bin/javaws \
    jre/javaws \
    jre/bin/javaws* \
    jre/lib/javaws.jar \
    jre/lib/security/javaws.policy \
    jre/lib/desktop \
    jre/lib/images \
    jre/plugin \
    jre/lib/deploy* \
    jre/lib/*javafx* \
    jre/lib/*jfx* \
    jre/lib/amd64/libjava_crw_demo.so \
    jre/lib/amd64/libjavaplugin_jni.so \
    jre/lib/amd64/libdecora_sse.so \
    jre/lib/amd64/libprism_*.so \
    jre/lib/amd64/libfxplugins.so \
    jre/lib/amd64/libglass.so \
    jre/lib/amd64/libgstreamer-lite.so \
    jre/lib/amd64/libjavafx*.so \
    jre/lib/amd64/libjfx*.so && \
  rm -rf \
    /usr/share/applications/JB-java*.desktop \
    /usr/share/pixmaps/*java*.* \
    /usr/lib/mozilla/plugins/libjavaplugin.so \
    /etc/alternatives/mozilla-javaplugin.so \
    /var/lib/dpkg/alternatives/mozilla-javaplugin.so \
    /usr/lib/jvm/java*/jre/lib/*/libnpjp2.so \
    /var/lib/dpkg/alternatives/javaws \
    /etc/alternatives/javaws* \
    /etc/alternatives/*java*.1* \
    /usr/share/mime-info/*java*-web-start* \
    /usr/share/application-registry/oracle-java6-web-start.applications \
    /etc/apt/trusted.gpg.d/*java*~
)}

add_jdk_8_nodesktop() {
  export JAVA_VERSION=${JAVA_VERSION:-8} \
    JAVA_UPDATE=${JAVA_UPDATE:-92} \
    JAVA_BUILD=${JAVA_BUILD:-14} \
    JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/default-jvm}"

    cd "/tmp" && \
    curl -fsSLO --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
        "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}u${JAVA_UPDATE}-b${JAVA_BUILD}/jdk-${JAVA_VERSION}u${JAVA_UPDATE}-linux-x64.tar.gz" && \
    tar -xzf "jdk-${JAVA_VERSION}u${JAVA_UPDATE}-linux-x64.tar.gz" && \
    mkdir -p "/usr/lib/jvm" && \
    mv "/tmp/jdk1.${JAVA_VERSION}.0_${JAVA_UPDATE}" "/usr/lib/jvm/java-${JAVA_VERSION}-oracle" && \
    ln -s "java-${JAVA_VERSION}-oracle" "$JAVA_HOME" && \
    ln -s "$JAVA_HOME/bin/"* "/usr/bin/" && \
    echo "export JAVA_HOME=$JAVA_HOME" > /etc/profile.d/java.sh && \
    configure_java_nodesktop && rm -rf /tmp/*
}

add_jdk_6_nodesktop_apt() {
  local remove_spc=''
  hascmd add-apt-repository || {
    remove_spc=1
    main add-pkg software-properties-common || return
  }
  echo 'oracle-java6-installer shared/accepted-oracle-license-v1-1 select true' | \
  debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  main add-pkg oracle-java6-installer && \
  configure_java_nodesktop && \
  rm -rf /tmp/* /var/cache/oracle-jdk6-installer || return

  test "$remove_spc" && { main remove-pkg software-properties-common || return ;}

  export JAVA_HOME=/usr/lib/jvm/java-6-oracle && \
  echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile.d/java.sh
}
