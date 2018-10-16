jdkURL() {
  local jdkVersion=${JAVA_VERSION:-$1}
  local jdkUpdate=${JAVA_UPDATE:-$2}
  local jdkBuild=${JAVA_BUILD:-$3}

  local jdk_hashes="
8u162-b12 0da788060d494f5095bf8624735fa2f1
8u181-b13 96a7b8442fe848ef90c96a2fad6ed6d1
8u191-b12 2787e4a523244c269598db4e85c51e0c
10.0.2+13 19aef61b38124481863b1413dce1855f
11+28 55eed80b163941c8885ad9298e6d786a
"

  local jdkv; test ${jdkVersion%%.*} -le 8 && jdkv="${jdkVersion}u${jdkUpdate}-b${jdkBuild}" || jdkv="${jdkVersion}+${jdkUpdate}"
  local jdkh="$(grep -m1 "$jdkv" <<EOF
$jdk_hashes
EOF
)"; test "$jdkh" && jdkh="/${jdkh##* }"
    local jdkfile; test ${jdkVersion%%.*} -le 8 && jdkfile="jdk-${jdkVersion}u${jdkUpdate}-linux-x64.tar.gz" || jdkfile="jdk-${jdkVersion}_linux-x64_bin.tar.gz"
    echo "http://download.oracle.com/otn-pub/java/jdk/$jdkv$jdkh/$jdkfile"
}

# See https://github.com/frol/docker-alpine-oraclejdk8/blob/cleaned/Dockerfile
configure_java_nodesktop() {(
  test "$JAVA_HOME" && test -d "$JAVA_HOME" || { echo "Invalid JAVA_HOME: '$JAVA_HOME'" && return 1 ;}
  cd "$JAVA_HOME" || return
  echo "[configure_java_nodesktop] JAVA_HOME: '$(pwd)'"
  rm -rfv \
    *src.zip \
    db/javadoc \
    db/docs \
    db/demo \
    man \
    jmods/java.desktop.jmod \
    jmods/javafx.* \
    jmods/jdk.javaws.jmod \
    jmods/jdk.plugin.jmod \
    jmods/java.corba.jmod \
    lib/libjfxwebkit.so \
    lib/src.zip \
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
  rm -rfv \
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
    JAVA_UPDATE=${JAVA_UPDATE:-191} \
    JAVA_BUILD=${JAVA_BUILD:-12} \
    JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/default-jvm}"

    local jdkURL="$(jdkURL)"
    echo "jdk URL: '$jdkURL'"; local jdkTmpDir="/tmp/xinstaller-jdk-$JAVA_VERSION-$JAVA_UPDATE-$JAVA_BUILD"
    mkdir "$jdkTmpDir" && \
    curl -fsSLo- --header "Cookie: oraclelicense=accept-securebackup-cookie;" "$jdkURL" | tar -xz -C "$jdkTmpDir" && \
    mkdir -p "/usr/lib/jvm" && \
    mv "$jdkTmpDir/"* "/usr/lib/jvm/java-${JAVA_VERSION}-oracle" && \
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
  rm -rf /tmp/* /var/cache/oracle-jdk6-installer || return

  test "$remove_spc" && { main remove-pkg software-properties-common || return ;}

  export JAVA_HOME=/usr/lib/jvm/java-6-oracle && \
  echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile.d/java.sh && \
  configure_java_nodesktop
}
