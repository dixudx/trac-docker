FROM alpine:3.20

LABEL org.opencontainers.image.authors="Di Xu <stephenhsu90@gmail.com>" \
      org.opencontainers.image.source="https://github.com/dixudx/trac-docker" \
      org.opencontainers.image.title="trac" \
      org.opencontainers.image.description="Trac issue tracker on Alpine + Apache/mod_wsgi"

ENV TRAC_ADMIN_NAME=trac_admin \
    TRAC_PROJECT_NAME=trac_project \
    TRAC_DIR=/var/local/trac \
    TRAC_INI=/var/local/trac/conf/trac.ini \
    DB_LINK=sqlite:db/trac.db \
    TRAC_VERSION=1.6

EXPOSE 8123
VOLUME ["/var/local/trac"]

RUN set -eux; \
    apk add --no-cache \
        apache2 \
        apache2-mod-wsgi \
        apache2-utils \
        ca-certificates \
        python3 \
        py3-pip \
        py3-babel \
        tini; \
    pip3 install --no-cache-dir --break-system-packages "Trac==${TRAC_VERSION}"; \
    mkdir -p /run/apache2; \
    echo "Listen 8123" >> /etc/apache2/httpd.conf

COPY trac.conf /etc/apache2/trac.conf.template
COPY entrypoint.sh /usr/local/bin/trac-entrypoint
RUN chmod 0755 /usr/local/bin/trac-entrypoint

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s \
    CMD wget -S -O /dev/null --tries=1 http://127.0.0.1:8123/ 2>&1 | \
        grep -qE 'HTTP/[0-9.]+ (200|401)'

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/trac-entrypoint"]
CMD ["httpd", "-D", "FOREGROUND"]
