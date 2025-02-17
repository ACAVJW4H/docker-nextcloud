FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:latest

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN printf "I am running on ${BUILDPLATFORM:-linux/amd64}, building for ${TARGETPLATFORM:-linux/amd64}\n$(uname -a)\n"

LABEL maintainer="ACAVJW4H" \
  org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.url="https://github.com/ACAVJW4H/docker-nextcloud" \
  org.opencontainers.image.source="https://github.com/ACAVJW4H/docker-nextcloud" \
  org.opencontainers.image.version=$VERSION \
  org.opencontainers.image.revision=$VCS_REF \
  org.opencontainers.image.vendor="ACAVJW4H" \
  org.opencontainers.image.title="Nextcloud" \
  org.opencontainers.image.description="Nextcloud" \
  org.opencontainers.image.licenses="MIT"

RUN apk --update --no-cache add \
  bash \
  ca-certificates \
  curl \
  ffmpeg \
  imagemagick \
  libressl \
  libsmbclient \
  libxml2 \
  nginx \
  php7 \
  php7-apcu \
  php7-bcmath \
  php7-bz2 \
  php7-cli \
  php7-ctype \
  php7-curl \
  php7-dom \
  php7-exif \
  php7-fileinfo \
  php7-fpm \
  php7-ftp \
  php7-gd \
  php7-gmp \
  php7-iconv \
  php7-imagick \
  php7-intl \
  php7-json \
  php7-ldap \
  php7-mbstring \
  php7-mcrypt \
  php7-memcached \
  php7-opcache \
  php7-openssl \
  php7-pcntl \
  php7-pdo \
  php7-pdo_mysql \
  php7-pdo_pgsql \
  php7-pdo_sqlite \
  php7-posix \
  php7-redis \
  php7-session \
  php7-simplexml \
  php7-sqlite3 \
  php7-xml \
  php7-xmlreader \
  php7-xmlwriter \
  php7-zip \
  php7-zlib \
  python3 \
  py3-pip \
  su-exec \
  tzdata \
  && apk --update --no-cache add -t build-dependencies \
  autoconf \
  automake \
  build-base \
  libtool \
  pcre-dev \
  php7-dev \
  php7-pear \
  samba-dev \
  tar \
  wget \
  && cd /tmp \
  && wget -q https://pecl.php.net/get/smbclient-1.0.0.tgz \
  && pecl install smbclient-1.0.0.tgz \
  && S6_ARCH=$(case ${TARGETPLATFORM:-linux/amd64} in \
  "linux/amd64")   echo "amd64"   ;; \
  "linux/arm/v6")  echo "arm"     ;; \
  "linux/arm/v7")  echo "armhf"   ;; \
  "linux/arm64")   echo "aarch64" ;; \
  "linux/386")     echo "x86"     ;; \
  "linux/ppc64le") echo "ppc64le" ;; \
  *)               echo ""        ;; esac) \
  && echo "S6_ARCH=$S6_ARCH" \
  && wget -q "https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-${S6_ARCH}.tar.gz" -qO "/tmp/s6-overlay-${S6_ARCH}.tar.gz" \
  && tar xzf /tmp/s6-overlay-${S6_ARCH}.tar.gz -C / \
  && s6-echo "s6-overlay installed" \
  && apk del build-dependencies \
  && rm -rf /tmp/* /var/cache/apk/* /var/www/*

ENV  S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
  NEXTCLOUD_VERSION="21.0.0" \
  TZ="UTC" \
  PUID="1000" \
  PGID="1000"

RUN apk --update --no-cache add \
  aria2 \
  p7zip \
  unrar \
  youtube-dl\
  && mkdir /var/log/aria2c \
  && mkdir /var/local/aria2c \
  && touch /var/log/aria2c/aria2c.log \
  && touch /var/local/aria2c/aria2c.sess

RUN apk --update --no-cache add -t build-dependencies \
  gnupg \
  && cd /tmp \
  && curl -SsOL https://download.nextcloud.com/server/releases/nextcloud-21.0.0.tar.bz2 \
  && curl -SsOL https://download.nextcloud.com/server/releases/nextcloud-21.0.0.tar.bz2.asc \
  && curl -SsOL https://nextcloud.com/nextcloud.asc \
  && gpg --import nextcloud.asc \
  && gpg --verify --batch --no-tty nextcloud-21.0.0.tar.bz2.asc nextcloud-21.0.0.tar.bz2 \
  && tar -xjf nextcloud-21.0.0.tar.bz2 --strip 1 -C /var/www \
  && rm -f nextcloud-21.0.0.tar* nextcloud.asc \
  && chown -R nobody.nogroup /var/www \
  && apk del build-dependencies \
  && rm -rf /root/.gnupg /tmp/* /var/cache/apk/* /var/www/updater

COPY rootfs /

RUN chmod a+x /usr/local/bin/* \
  && addgroup -g ${PGID} nextcloud \
  && adduser -D -h /home/nextcloud -u ${PUID} -G nextcloud -s /bin/sh nextcloud

EXPOSE 8000
WORKDIR /var/www
VOLUME [ "/data" ]

ENTRYPOINT [ "/init" ]

HEALTHCHECK --interval=10s --timeout=5s --start-period=20s \
  CMD /usr/local/bin/healthcheck
