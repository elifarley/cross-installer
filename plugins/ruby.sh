add_ruby_apt() {
  RUBY_VERSION="${1:-${RUBY_VERSION:-2.3.0}}"
  RUBY_MAJOR="${RUBY_VERSION%.*}"

  APT_PACKAGES="\
gcc g++ make patch binutils libc6-dev \
  libjemalloc-dev libffi-dev libssl-dev libyaml-dev zlib1g-dev libgmp-dev libxml2-dev \
  libxslt1-dev libreadline-dev libsqlite3-dev \
  libpq-dev unixodbc unixodbc-dev unixodbc-bin ruby-odbc freetds-bin freetds-common freetds-dev postgresql-client \
  git \
"

  apt-get update && apt-get -y dist-upgrade && \
  apt-get install -y --no-install-recommends $APT_PACKAGES && \
  apt-get remove --purge -y $APT_REMOVE_PACKAGES && apt-get autoremove --purge -y && apt-get clean && \
  ( curl -fsSL "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR}/ruby-${RUBY_VERSION}.tar.gz" | \
    tar -xzC /tmp && \
    cd /tmp/ruby-${RUBY_VERSION} && \
    ./configure --enable-shared --with-jemalloc --disable-install-doc && \
    make -j4 && make install && \
    rm /usr/local/lib/libruby-static.a && \
    cd /tmp && rm -rf /tmp/* \
  )

}
