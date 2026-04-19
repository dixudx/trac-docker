#!/bin/sh
set -eu

: "${TRAC_DIR:=/var/local/trac}"
: "${TRAC_PROJECT_NAME:=trac_project}"
: "${DB_LINK:=sqlite:db/trac.db}"
: "${TRAC_ADMIN_NAME:=trac_admin}"

log() { printf '[trac-entrypoint] %s\n' "$*" >&2; }

mkdir -p "${TRAC_DIR}"

if [ ! -f "${TRAC_DIR}/VERSION" ]; then
    log "initializing Trac env at ${TRAC_DIR} (project=${TRAC_PROJECT_NAME})"
    trac-admin "${TRAC_DIR}" initenv "${TRAC_PROJECT_NAME}" "${DB_LINK}"
    trac-admin "${TRAC_DIR}" deploy /tmp/trac-deploy
    cp -a /tmp/trac-deploy/. "${TRAC_DIR}/"
    rm -rf /tmp/trac-deploy
fi

if [ ! -f "${TRAC_DIR}/.htpasswd" ]; then
    if [ -z "${TRAC_ADMIN_PASSWD:-}" ]; then
        log "ERROR: no .htpasswd exists and TRAC_ADMIN_PASSWD is unset"
        log "set -e TRAC_ADMIN_PASSWD=... on first run, or mount a pre-built .htpasswd"
        exit 1
    fi
    log "creating admin user ${TRAC_ADMIN_NAME}"
    htpasswd -b -c "${TRAC_DIR}/.htpasswd" "${TRAC_ADMIN_NAME}" "${TRAC_ADMIN_PASSWD}"
    chmod 640 "${TRAC_DIR}/.htpasswd"
    trac-admin "${TRAC_DIR}" permission add "${TRAC_ADMIN_NAME}" TRAC_ADMIN || true
fi

sed -e "s|\${AUTH_NAME}|${TRAC_PROJECT_NAME}|g" \
    -e "s|\${TRAC_DIR}|${TRAC_DIR}|g" \
    /etc/apache2/trac.conf.template > /etc/apache2/conf.d/trac.conf

chown -R apache:apache "${TRAC_DIR}"

unset TRAC_ADMIN_PASSWD

exec "$@"
