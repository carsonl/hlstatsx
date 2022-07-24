#!/usr/bin/env bash

function rewrite_config {
    sed -i 's/DBHost ".*"/DBHost "'"${DB_ADDR:?Variable not set, bailing.}"'"/' /srv/hlstatsx/scripts/hlstats.conf
    sed -i 's/DBUsername ".*"/DBUsername "'"${DB_USER:?Variable not set, bailing.}"'"/' /srv/hlstatsx/scripts/hlstats.conf
    sed -i 's/DBPassword ".*"/DBPassword "'"${DB_PASS:?Variable not set, bailing.}"'"/' /srv/hlstatsx/scripts/hlstats.conf
    sed -i 's/DBName ".*"/DBName "'"${DB_NAME:?Variable not set, bailing.}"'"/' /srv/hlstatsx/scripts/hlstats.conf
    sed -i 's/define("DB_ADDR", ".*");/define("DB_ADDR", "'"${DB_ADDR:?Variable not set, bailing.}"'");/' /srv/hlstatsx/web/config.php
    sed -i 's/define("DB_NAME", ".*");/define("DB_NAME", "'"${DB_NAME:?Variable not set, bailing.}"'");/' /srv/hlstatsx/web/config.php
    sed -i 's/define("DB_USER", ".*");/define("DB_USER", "'"${DB_USER:?Variable not set, bailing.}"'");/' /srv/hlstatsx/web/config.php
    sed -i 's/define("DB_PASS", ".*");/define("DB_PASS", "'"${DB_PASS:?Variable not set, bailing.}"'");/' /srv/hlstatsx/web/config.php
}

if [ "${1}" == "daemon" ]; then
    rewrite_config || exit 2
    cd /srv/hlstatsx/scripts/
    exec perl ./hlstats.pl
    #Kill once a day?
    #./run_hlstats restart > /proc/1/fd/1 2> /proc/1/fd/2
elif [ "${1}" == "cron" ]; then
    rewrite_config || exit 2
    while true; do
        # Generate awards and cleanup
        #May need to talk directly to daemon, and thus need to run in the same container :(
        cd /srv/hlstatsx/scripts/
        ./hlstats-awards.pl

        # Auto remove old Daemon logs (90 days)
        find /srv/logs/ -type f -mtime +90 -delete
        sleep 1845
    done
elif [ "${1}" == "php" ]; then
    rewrite_config || exit 2
    mkdir -p /usr/share/nginx/html/
    rsync -av /srv/hlstatsx/web/ /usr/share/nginx/html/
    chown -R www-data /usr/share/nginx/html/
    exec /usr/sbin/php-fpm* -F -O -e
elif [ "${1}" == "web" ]; then
    mkdir -p /usr/share/nginx/html/
    rsync -av /srv/hlstatsx/web/ /usr/share/nginx/html/
    chown -R www-data /usr/share/nginx/html/
    exec nginx -g 'daemon off;'
elif [ "${1}" == "healthcheck" ]; then
    #Test which is running, and health check appropriately
    exit 0
    rewrite_config || exit 2
    perl /app/scripts/run_hlstats status || exit 1
else
    exec "${@}"
fi
