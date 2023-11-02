############################################################
# (1)基础镜像
############################################################
# (1.1)基础镜像
FROM alpine:3.13 as build-nginx
# (1.2)作者
LABEL maintainer="wanglg95"

############################################################
# (2)配置信息
############################################################
# (2.1)设置nginx和nginx-http-flv-module版本
ENV NGINX_VERSION nginx-1.23.2
ENV NGINX_HTTP_FLV_MODULE_VERSION 1.2.11

# (2.2)安装相关依赖软件
RUN apk add --update \
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

############################################################
# (3)安装nginx
############################################################
# (3.1)下载Nginx
RUN mkdir -p /tmp/build/nginx && cd /tmp/build/nginx \
 && wget -O ${NGINX_VERSION}.tar.gz https://nginx.org/download/${NGINX_VERSION}.tar.gz \
 && tar -zxf ${NGINX_VERSION}.tar.gz

# (3.2)下载RTMP module
RUN mkdir -p /tmp/build/nginx-http-flv-module && cd /tmp/build/nginx-http-flv-module   \
 && wget -O  nginx-http-flv-module.tar.gz https://github.com/winshining/nginx-http-flv-module/archive/refs/tags/${NGINX_HTTP_FLV_MODULE_VERSION}.tar.gz \
 && tar -zxf nginx-http-flv-module.tar.gz

# (3.3)编译nginx(Build and install Nginx)
RUN cd /tmp/build/nginx/${NGINX_VERSION} \
 && ./configure \
    --sbin-path=/usr/local/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --pid-path=/var/run/nginx/nginx.pid \
    --lock-path=/var/lock/nginx/nginx.lock \
    --http-log-path=/var/log/nginx/access.log \
    --http-client-body-temp-path=/tmp/nginx-client-body \
    --with-http_ssl_module \
    --with-threads \
    --with-ipv6 \
    --add-module=/tmp/build/nginx-http-flv-module/nginx-http-flv-module \
 && make -j $(getconf _NPROCESSORS_ONLN) \
 && make install \
 && mkdir /var/lock/nginx && rm -rf /tmp/build

# (3.4)Forward logs to Docker
RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log

############################################################
# (4)启动nginx
############################################################
# Set up config file
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 1935
CMD ["nginx", "-g", "daemon off;"]
