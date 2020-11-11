#!/bin/bash

set -e

if [[ "$(id -u)" != "0" ]]; then
    echo "You are not root, run this script with sudo."
    exit 1
fi


if [ -z "${WORDPRESS_PUBLIC_IP}" ]; then
    read -p "Enter WordPress VM's public IP: " wordpress_public_ip

    echo "Using http://${wordpress_public_ip}/ as URL for WordPress."
    read -p "Is this correct? (y/n) " confirm_addr

    case "${confirm_addr}" in
        y|yes) ;;
        *)
            echo "Cancelling installation."
            exit 1
            ;;
    esac

    export WORDPRESS_PUBLIC_IP="${wordpress_public_ip}"
fi

export DEBIAN_FRONTEND=noninteractive

echo "Installing MariaDB"
{
    debconf-set-selections <<< "mariadb-server-10.3 mysql-server/root_password password insecurerootpass"
    debconf-set-selections <<< "mariadb-server-10.3 mysql-server/root_password_again password insecurerootpass"

    apt-get update -y
    apt-get install -y --no-install-recommends mariadb-server-10.3
} >/dev/null

echo "Configuring MariaDB"
{
    cat > /etc/mysql/root.cnf <<EOF
[client]
user = root
password = insecurerootpass
EOF

    sed -i 's/^bind-address .*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
    systemctl restart mariadb.service
} >/dev/null

echo "Creating WordPress database and user"
{
    mysql --defaults-file=/etc/mysql/root.cnf --batch --execute="\
CREATE DATABASE IF NOT EXISTS wordpress;\
GRANT ALL PRIVILEGES on wordpress.* TO 'wordpress'@'localhost' IDENTIFIED BY 'insecurewppass';\
GRANT ALL PRIVILEGES on wordpress.* TO 'wordpress'@'10.0.0.100' IDENTIFIED BY 'insecurewppass';\
FLUSH PRIVILEGES"
} >/dev/null

echo "Importing initial database"
{
    curl -sL https://{WORKSHOP_SERVER}/_static/104_wp_dump.sql.gz \
        | gzip -d \
        | sed "s/{{SERVER_IP_ADDR}}/${WORDPRESS_PUBLIC_IP}/g" \
        | mysql --defaults-file=/etc/mysql/root.cnf wordpress
} >/dev/null

echo "Done"
echo
echo "You can now proceed to WordPress's installation."
