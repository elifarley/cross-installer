add_activemq() {
  test $# -ge 2 || {
    echo "Usage: $0 add activemq <version> <sha1> [<prefix>=/usr/local]"
    return 1
  }

  local url_activemq='http://www.mirrorservice.org/sites/ftp.apache.org/activemq/%s/apache-activemq-%s-bin.tar.gz'

  local version="$1"; shift
  local sha="$1"; shift
  local prefix="${1:-/usr/local}"; test $# -gt 0 && shift
  local url="$(printf "$url_activemq" "$version" "$version")"
  untar_url "$url" "$version" "$sha" "$prefix" && \
  ( cd "$prefix"/apache-activemq && pwd && ls -Falk && \
    mv conf/activemq.xml conf/activemq.xml.orig && \
    awk '/.*stomp.*/{print "            <transportConnector name=\"stompssl\" uri=\"stomp+nio+ssl://0.0.0.0:61612?transport.enabledCipherSuites=SSL_RSA_WITH_RC4_128_SHA,SSL_DH_anon_WITH_3DES_EDE_CBC_SHA\" />"}1' \
    conf/activemq.xml.orig >> conf/activemq.xml
  ) && { cat >"$prefix"/bin/activemq-nowrapper <<-EOF
#!/bin/sh
exec java -Xms1G -Xmx1G -Djava.util.logging.config.file=logging.properties -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote \
-Djava.io.tmpdir=/tmp/activemq \
-Dactivemq.classpath="$prefix"/apache-activemq/conf \
-Dactivemq.home="$prefix"/apache-activemq \
-Dactivemq.base="$prefix"/apache-activemq \
-Dactivemq.conf="$prefix"/apache-activemq/conf \
-Dactivemq.data="$prefix"/apache-activemq/data \
-jar "$prefix"/apache-activemq/bin/activemq.jar start
EOF
} && chmod +x "$prefix"/bin/activemq-nowrapper
  
}
