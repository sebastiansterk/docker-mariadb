FROM alpine:latest
MAINTAINER Sebastian Sterk <sebastian@wiuwiu.de>

RUN apk --update add --no-cache \
  mariadb \
  mariadb-client \
  pwgen \
  sed -i "s/skip-networking//g" /etc/my.cnf.d/mariadb-server.cnf

COPY run.sh /srv/run.sh
VOLUME ["/var/lib/mysql"]
EXPOSE 3306

CMD ["sh", "/srv/run.sh"]
