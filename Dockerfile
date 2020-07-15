FROM alpine:3.12.0

LABEL maintainer="Guido Rugo <guido.rugo@gmail.com>"

ENV IMAGE_VERSION 0.01
ENV NGINX_VERSION 1.19.1
ENV NGINX_RTMP_VERSION 1.2.1

RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community gnu-libiconv
RUN apk add --no-cache --virtual .build-deps \
  build-base \
  ca-certificates \
  curl \
  gcc \
  libc-dev \
  libgcc \
  linux-headers \
  make \
  musl-dev \
  openssl \
  openssl-dev \
  pcre \
  pcre-dev \
  pkgconf \
  pkgconfig \
  zlib-dev

ARG CACHEBUST=1
RUN addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx

RUN mkdir -p /etc/nginx /var/log/nginx /var/www \
    && chown -R nginx:nginx /var/log/nginx /var/www \
    && chmod -R 775 /var/log/nginx /var/www

ARG CACHEBUST=1 
RUN cd /tmp \
    && wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar zxf nginx-${NGINX_VERSION}.tar.gz \
    && rm nginx-${NGINX_VERSION}.tar.gz

ARG CACHEBUST=1 
RUN cd /tmp \
    && wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz \
    && tar zxvf v${NGINX_RTMP_VERSION}.tar.gz \
    && rm v${NGINX_RTMP_VERSION}.tar.gz

RUN cd /tmp/nginx-${NGINX_VERSION}/ \
    && ./configure \
    --prefix=/usr/local/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --with-threads \
    --with-file-aio \
    --with-http_ssl_module \
    --with-debug \
    --with-ipv6 \
    --with-cc-opt="-Wimplicit-fallthrough=0" \
    --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_VERSION}

ARG CACHEBUST=1 
RUN cd /tmp/nginx-${NGINX_VERSION}/ \
    && make -Werror -j $(getconf _NPROCESSORS_ONLN) -

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

COPY nginx.conf /etc/nginx/nginx.conf
RUN chmod 444 /etc/nginx/nginx.conf

EXPOSE 1935