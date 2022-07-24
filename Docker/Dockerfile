FROM			ubuntu:latest
MAINTAINER		Carson Longhorn <dockerfiles@unrelated.net.au>
ENV				DEBIAN_FRONTEND=noninteractive LANGUAGE=en_US.UTF-8 LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
RUN				echo Start > /dev/null && \
				echo 'Acquire::http { Proxy "http://172.17.0.1:3142"; };' >> /etc/apt/apt.conf.d/01proxy && \
				echo 'Acquire::https { Proxy "http://172.17.0.1:3142"; };' >> /etc/apt/apt.conf.d/01proxy && \
				apt-get update && \
				apt-get --no-install-recommends -y install locales && \
				locale-gen $LANG && \
				update-locale && \
				apt-get --no-install-recommends -y install \
					ca-certificates \
					cpanminus \
					curl \
					gettext-base \
					git \
					gnupg \
					libdbd-mysql-perl \
					libgeoip2-perl \
					libmaxmind-db-reader-perl \
					libssl-dev \
					libsyntax-keyword-try-perl \
					openssl \
					php-cli \
					php-ctype \
					php-curl \
					php-dev \
					php-fpm \
					php-gd \
					php-json \
					php-mbstring \
					php-mysql \
					php-mysqli \
					php-opcache \
					php-pear \
					php-pgsql \
					php-xml \
					rsync \
					unzip \
					zlib1g-dev \
				&& \
				. /etc/lsb-release && \
				curl https://nginx.org/packages/keys/nginx_signing.key | apt-key add -a && \
				echo "deb http://nginx.org/packages/mainline/ubuntu/ ${DISTRIB_CODENAME} nginx" >> /etc/apt/sources.list && \
				apt-get update && \
				apt-get --no-install-recommends -y install \
					nginx \
					nginx-module-xslt \
					nginx-module-geoip \
					nginx-module-image-filter \
					nginx-module-perl \
					nginx-module-njs \
				&& \
				apt-get clean && \
				rm -rf /var/lib/apt/lists/* /var/cache/* /var/log/apt/* /tmp/* && \
				sed -i 's/^listen = .*/listen = 0.0.0.0:9000/g' /etc/php/*/fpm/pool.d/www.conf && \
				sed -i '/^;catch_workers_output/ccatch_workers_output = yes' /etc/php/*/fpm/pool.d/www.conf && \
				sed -i '/^;access.log/caccess.log = /proc/self/fd/2' /etc/php/*/fpm/pool.d/www.conf && \
				sed -i '/^;php_flag\[display_errors\]/cphp_flag[display_errors] = off' /etc/php/*/fpm/pool.d/www.conf && \
				sed -i '/^;php_admin_value\[error_log\]/cphp_admin_value[error_log] = /proc/self/fd/2' /etc/php/*/fpm/pool.d/www.conf && \
				sed -i '/^;php_admin_flag\[log_errors\]/cphp_admin_flag[log_errors] = on' /etc/php/*/fpm/pool.d/www.conf && \
				sed -i '/^;php_flag\[display_errors\]/cphp_flag[display_errors] = on' /etc/php/*/fpm/pool.d/www.conf && \
				mkdir -p /run/php && \
				sed -i 's/remote_addr/remote_addr "$http_x_forwarded_for"/g' /etc/nginx/nginx.conf && \
				ln -sf /dev/stdout /var/log/nginx/access.log && \
				ln -sf /dev/stderr /var/log/nginx/error.log && \
				mkdir /var/cache/nginx/ && \
				mkdir -p /srv/ && \
				git clone https://github.com/carsonl/hlstatsx /srv/hlstatsx/ && \
				chmod +x /srv/hlstatsx/scripts/hlstats-awards.pl /srv/hlstatsx/scripts/hlstats.pl /srv/hlstatsx/scripts/hlstats-resolve.pl /srv/hlstatsx/scripts/run_hlstats && \
				rm -rf /srv/hlstatsx/web/updater/ && \
				echo Finished > /dev/null
COPY			root/ /
ENTRYPOINT		["/docker-entrypoint.bash"]
CMD				["exit 255"]
HEALTHCHECK CMD	["/docker-entrypoint.bash","healthcheck"]
#sed -i 's|define("DB_DEBUG", true);|//define("DB_DEBUG", true);|g' config.php
#sed -i 's|//define("DB_DEBUG", true);|define("DB_DEBUG", true);|g' config.php
#mysql -h172.17.0.1 -u<user> -p<pass> <db>
