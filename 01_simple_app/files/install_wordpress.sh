#!/bin/bash

set -e

if [[ "$(id -u)" != "0" ]]; then
    echo "You are not root, run this script with sudo."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "Installing Apache & PHP"
{
    apt-get update -y
    apt-get install -y --no-install-recommends \
        apache2 \
        libapache2-mod-php7.3 \
        php7.3 \
        php7.3-cli \
        php7.3-common \
        php7.3-curl \
        php7.3-gd \
        php7.3-intl \
        php7.3-ldap \
        php7.3-mbstring \
        php7.3-mysql \
        php7.3-soap \
        php7.3-xml \
        php7.3-xmlrpc \
        php7.3-zip
} >/dev/null

echo "Installing WordPress"
{
    wget -qO - https://wordpress.org/latest.tar.gz | tar -C /var/www/html -xz
    cat > /var/www/html/wordpress/wp-config.php <<EOF
<?php
define( 'DB_NAME', 'wordpress' );
define( 'DB_USER', 'wordpress' );
define( 'DB_PASSWORD', 'insecurewppass' );
define( 'DB_HOST', '10.0.0.101' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );
define( 'AUTH_KEY',         'J_wj\`2Xlvi}K<TR|? 5i6:(2.uz@6r:84I<kW<G{}VBMD0=[:]z}F?T@d>=y\$K5#' );
define( 'SECURE_AUTH_KEY',  '/}ExCpwAay/] =8vF,.pOVzsV0(Jq5(HlFJ<eX O/kK9@rR*#b}]Rj@80fag@7>%' );
define( 'LOGGED_IN_KEY',    '54_wQeG>lKD?,=OQ@?2 %PBVRjtF@ec9KwS}!G{$>/2vqobYA0?o E)F!#ku<0b+' );
define( 'NONCE_KEY',        'e<xOaOKN*bI5YvJ[\$B<CXp!V{b}]YZi.-MP4?@\$b;U;lu2zW3:R4qOkRA_>n+#u=' );
define( 'AUTH_SALT',        '7FdiC%[k0qyKPixC-vn,A{/&4%=V3V-(He\$jVbR}tqOY9Ipzhgcc;@r 7Rye4-D@' );
define( 'SECURE_AUTH_SALT', '/4ry;9p4/{X*+VX?^NPI=|@V&#^bX>qQP@gHj8_~ir}n$&h_Zm[+hggy9.p0ipMm' );
define( 'LOGGED_IN_SALT',   'tDx<G1Xz6NDRgqke{Zr+1rxW!|+:dwcXhD0{oC349,B}==G4cyp3!63D#\$*!$&Yo' );
define( 'NONCE_SALT',       '~phR+Pwhs!Qr%PewAw0EusW8s>[[!wm@mRQB;l<DAUnVj8B4(\$LW}L,dzMFmyF\`:' );
define( 'WP_DEBUG', false );

\$table_prefix = 'wp_';
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
EOF
} >/dev/null

echo "Configuring Apache"
{
    cat > /etc/apache2/sites-available/wordpress.conf <<EOF
<VirtualHost *:80>
     DocumentRoot /var/www/html/wordpress
     <Directory /var/www/html/wordpress>
          Options FollowSymlinks
          AllowOverride All
          Require all granted
     </Directory>
     ErrorLog \${APACHE_LOG_DIR}/demo_error.log
     CustomLog \${APACHE_LOG_DIR}/demo_access.log combined
</VirtualHost>
EOF

    a2dissite 000-default >/dev/null
    a2ensite wordpress >/dev/null
    a2enmod rewrite >/dev/null
    systemctl restart apache2
} >/dev/null

echo "Done"
echo
echo "You can now use WordPress by browsing to:"
echo "  http://$(ip route get 1.1.1.1 | awk 'NR == 1 { print $7 }')/"
