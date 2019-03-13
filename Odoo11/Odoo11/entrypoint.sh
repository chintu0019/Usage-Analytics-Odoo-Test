#!/bin/bash
set -e
cd /
if [ ! -e /usr/lib/python3/dist-packages/odoo/__init__.py ] ;then
    echo "Copying odoo code in the host"
    HOST_USER="${HOST_USER:=root}"
    echo rsync --owner --group --chown="$HOST_USER":"$HOST_USER" -rtu --delete /usr/lib/python3/dist-packages/odoo.untouched/'*' /usr/lib/python3/dist-packages/odoo.orig
    rsync --owner --group --chown="$HOST_USER":"$HOST_USER" -rtu --delete /usr/lib/python3/dist-packages/odoo.untouched/* /usr/lib/python3/dist-packages/odoo.orig
    echo rsync --owner --group --chown="$HOST_USER":"$HOST_USER" -rtu --delete /usr/lib/python3/dist-packages/odoo.untouched/'*' /usr/lib/python3/dist-packages/odoo
    rsync --owner --group --chown="$HOST_USER":"$HOST_USER" -rtu --delete /usr/lib/python3/dist-packages/odoo.untouched/* /usr/lib/python3/dist-packages/odoo
    cd /usr/lib/python3/dist-packages
    patch -p0 <./analyzer.patch
    cd /
fi

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if ! grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        DB_ARGS+=("--${param}")
        DB_ARGS+=("${value}")
   fi;
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec odoo "$@"
        else
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1