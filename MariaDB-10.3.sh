#!/bin/bash

##################################################
#               Script Description               #
##################################################
#       This script will automatically setup     #
#            MariaDB-10.3 & go through           #
#           'mysql_secure_installation'          #
##################################################

##############################################
#                 How To Use                 #
##############################################
#    Login to database server user account   #
#              wget this script              #
#                  chmod +x                  #
#          then run sudo ./MariaDB...        #
##############################################

#######################################
#     Colour Codes (do not change)    #
#######################################
RED="\033[1;31m"                      #
REDBLINK="\033[31;5;7m"               #
GREEN="\033[1;32m"                    #
GREENBLINK="\033[32;5;7m"             #
BLUE="\033[0;34m"                     #
GREENBORDER_BLACKTEXT="\033[30;42m"   #
REDBORDER_BLACKTEXT="\033[30;41m"     #
NOCOLOR="\033[0m"                     #
export PATH="/usr/games:$PATH"        #
#######################################

####################################
#   User Variables (change these)  #
####################################
SERVER_HOSTNAME=mariadb.domain.com #
MARIADB_ROOT_PASSWORD=changeme     #
MARIADB_BIND_IP=192.168.1.8        #
####################################

function intro()
{
  echo
  echo "Created by:"
  echo "
  ██╗   ██╗██████╗ ███████╗██╗   ██╗
  ██║   ██║██╔══██╗╚══███╔╝╚██╗ ██╔╝
  ██║   ██║██████╔╝  ███╔╝  ╚████╔╝
  ██║   ██║██╔══██╗ ███╔╝    ╚██╔╝
  ╚██████╔╝██████╔╝███████╗   ██║
   ╚═════╝ ╚═════╝ ╚══════╝   ╚═╝
  " | lolcat
  echo -e "${NOCOLOR}"
}

function top()
{
  clear
  printf '|%*s' "${COLUMNS:-$(tput cols)}" | tr ' ' - | sed 's/-$//' | sed s'/\(.*\)\(.\)$/\1|/g' | lolcat -f
  echo "Ubzy Ubuntu Script v18.04 LTS Setup Script" | /etc/update-motd.d/center.sh | lolcat -f
  printf '|%*s' "${COLUMNS:-$(tput cols)}" | tr ' ' - | sed 's/-$//' | sed s'/\(.*\)\(.\)$/\1|/g' | lolcat -f
  echo -e "\n"
}

function prerequisites()
{
  TAG=Prerequisites
  echo -e "${RED}[$TAG] ${TAG}${NOCOLOR}\n"

  packagestoinstall="lolcat expect software-properties-common dirmngr apt-transport-https ca-certificates"

  for pkg in $packagestoinstall; do
    if dpkg --get-selections | grep -q "^$pkg[[:space:]]*install$" >/dev/null; then
      :
    else
      sudo DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -qq git "$pkg"  < /dev/null > /dev/null
      echo -e "${GREEN}[$TAG]Successfully installed $pkg ${NOCOLOR}"
      sleep 1
    fi
  done

  tee << 'EOF' > /etc/update-motd.d/center.sh
#!/bin/bash
readarray message < <(expand)

width="${1:-$(tput cols)}"

margin=$(awk -v "width=$width" '
    { max_len = length > width ? width : length > max_len ? length : max_len }
    END { printf "%" int((width - max_len + 1) / 2) "s", "" }
' <<< "${message[@]}")

printf "%s" "${message[@]/#/$margin}"
EOF
  sudo chmod +x /etc/update-motd.d/*

  echo -e "${GREEN}[$TAG] Setting MariaDB Server hostname permanently${NOCOLOR}"
  hostnamectl set-hostname $SERVER_HOSTNAME
}

function mariadb()
{
  TAG=MariaDB
  echo -e "${RED}[$TAG] ${TAG}${NOCOLOR}\n"

  packagestoinstall="mariadb-server-10.3"
  for pkg in $packagestoinstall; do
    if dpkg --get-selections | grep -q "${pkg}[[:space:]]*install$" >/dev/null; then
      echo -e "${GREENBORDER_BLACKTEXT}[$TAG] $pkg is already installed - No changes made!${NOCOLOR}"
      clear
      sleep 2
    else
    echo -e "${RED}[$TAG] $pkg is not installed! Now installing..."

    echo -e "${BLUE}[$TAG] Adding repository keys"
    sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 &> /dev/null

    echo -e "${BLUE}[$TAG] Adding updated PPA"
    sudo sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirror.sax.uk.as61049.net/mariadb/repo/10.3/debian stretch main' &> /dev/null

    echo -e "${GREEN}[$TAG] Updating to newer sources"
    sudo -- sh -c 'apt-get update; apt-get upgrade -y; apt-get dist-upgrade -y; apt-+get autoremove -y; apt-get autoclean -y' &> /dev/null

    echo -e "${GREEN}[$TAG] Installing MariaDB"
    sudo sh -c 'apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server-10.3' &> /dev/null

    echo -e "${GREEN}[$TAG] Configuring MariaDB"
    sudo tee << "EOF" > /etc/mysql/my.cnf
# MariaDB database server configuration file.
#
# You can copy this file to one of:
# - "/etc/mysql/my.cnf" to set global options,
# - "~/.my.cnf" to set user-specific options.
#
# One can use all long options that the program supports.
# Run program with --help to get a list of available options and with
# --print-defaults to see which it would actually understand and use.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

# This will be passed to all mysql clients
# It has been reported that passwords should be enclosed with ticks/quotes
# escpecially if they contain "#" chars...
# Remember to edit /etc/mysql/debian.cnf when changing the socket location.
[client]
port            = 3306
socket          = /var/run/mysqld/mysqld.sock

# Here is entries for some specific programs
# The following values assume you have at least 32M ram

# This was formally known as [safe_mysqld]. Both versions are currently parsed.
[mysqld_safe]
socket          = /var/run/mysqld/mysqld.sock
nice            = 0

[mysqld]
#
# * Basic Settings
#
user            = mysql
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
port            = 3306
basedir         = /usr
datadir         = /var/lib/mysql
tmpdir          = /tmp
lc_messages_dir = /usr/share/mysql
lc_messages     = en_US
skip-external-locking
#
# Instead of skip-networking the default is now to listen only on
# localhost which is more compatible and is not less secure.
##bind-address
#
# * Fine Tuning
#
max_connections         = 100
connect_timeout         = 5
wait_timeout            = 600
max_allowed_packet      = 16M
thread_cache_size       = 128
sort_buffer_size        = 4M
bulk_insert_buffer_size = 16M
tmp_table_size          = 32M
max_heap_table_size     = 32M
#
# * MyISAM
#
# This replaces the startup script and checks MyISAM tables if needed
# the first time they are touched. On error, make copy and try a repair.
myisam_recover_options = BACKUP
key_buffer_size         = 128M
#open-files-limit       = 2000
table_open_cache        = 400
myisam_sort_buffer_size = 512M
concurrent_insert       = 2
read_buffer_size        = 2M
read_rnd_buffer_size    = 1M
#
# * Query Cache Configuration
#
# Cache only tiny result sets, so we can fit more in the query cache.
query_cache_limit               = 128K
query_cache_size                = 64M
# for more write intensive setups, set to DEMAND or OFF
#query_cache_type               = DEMAND
#
# * Logging and Replication
#
# Both location gets rotated by the cronjob.
# Be aware that this log type is a performance killer.
# As of 5.1 you can enable the log at runtime!
#general_log_file        = /var/log/mysql/mysql.log
#general_log             = 1
#
# Error logging goes to syslog due to /etc/mysql/conf.d/mysqld_safe_syslog.cnf.
#
# we do want to know about network errors and such
log_warnings            = 2
#
# Enable the slow query log to see queries with especially long duration
#slow_query_log[={0|1}]
slow_query_log_file     = /var/log/mysql/mariadb-slow.log
long_query_time = 10
#log_slow_rate_limit    = 1000
log_slow_verbosity      = query_plan

#log-queries-not-using-indexes
#log_slow_admin_statements
#
# The following can be used as easy to replay backup logs or for replication.
# note: if you are setting up a replication slave, see README.Debian about
#       other settings you may need to change.
#server-id              = 1
#report_host            = master1
#auto_increment_increment = 2
#auto_increment_offset  = 1
log_bin                 = /var/log/mysql/mariadb-bin
log_bin_index           = /var/log/mysql/mariadb-bin.index
# not fab for performance, but safer
#sync_binlog            = 1
expire_logs_days        = 10
max_binlog_size         = 100M
# slaves
#relay_log              = /var/log/mysql/relay-bin
#relay_log_index        = /var/log/mysql/relay-bin.index
#relay_log_info_file    = /var/log/mysql/relay-bin.info
#log_slave_updates
#read_only
#
# If applications support it, this stricter sql_mode prevents some
# mistakes like inserting invalid dates etc.
#sql_mode               = NO_ENGINE_SUBSTITUTION,TRADITIONAL
#
# * InnoDB
#
# InnoDB is enabled by default with a 10MB datafile in /var/lib/mysql/.
# Read the manual for more InnoDB related options. There are many!
default_storage_engine  = InnoDB
# you can't just change log file size, requires special procedure
#innodb_log_file_size   = 50M
innodb_buffer_pool_size = 256M
innodb_log_buffer_size  = 8M
innodb_file_per_table   = 1
innodb_open_files       = 400
innodb_io_capacity      = 400
innodb_flush_method     = O_DIRECT
#
# * Security Features
#
# Read the manual, too, if you want chroot!
# chroot = /var/lib/mysql/
#
# For generating SSL certificates I recommend the OpenSSL GUI "tinyca".
#
# ssl-ca=/etc/mysql/cacert.pem
# ssl-cert=/etc/mysql/server-cert.pem
# ssl-key=/etc/mysql/server-key.pem

#
# * Galera-related settings
#
[galera]
# Mandatory settings
#wsrep_on=ON
#wsrep_provider=
#wsrep_cluster_address=
#binlog_format=row
#default_storage_engine=InnoDB
#innodb_autoinc_lock_mode=2
#
# Allow server to accept connections on all interfaces.
#
#bind-address=0.0.0.0
#
# Optional setting
#wsrep_slave_threads=1
#innodb_flush_log_at_trx_commit=0

[mysqldump]
quick
quote-names
max_allowed_packet      = 16M

[mysql]
#no-auto-rehash # faster start of mysql but no tab completion

[isamchk]
key_buffer              = 16M

#
# * IMPORTANT: Additional settings that can override those from this file!
#   The files must end with '.cnf', otherwise they'll be ignored.
#
!include /etc/mysql/mariadb.cnf
!includedir /etc/mysql/conf.d/

[server]
skip-name-resolve
innodb_buffer_pool_instances = 1
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 32M
innodb_max_dirty_pages_pct = 90
query_cache_type = 1
query_cache_min_res_unit = 2k
max_heap_table_size = 64M
slow-query-log = 1
slow-query-log-file = /var/log/mysql/slow.log

[client]
default-character-set = utf8mb4

[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
transaction_isolation = READ-COMMITTED
binlog_format = ROW
EOF
    sudo sed -i "s/##bind-address/bind-address                              = $MARIADB_BIND_IP/g" /etc/mysql/my.cnf

    echo -e "${GREEN}[$TAG] Running through 'mysql_secure_installation'"
    SECURE_MYSQL=$(expect -c "
    set timeout 3
    spawn mysql_secure_installation
    expect \"Enter current password for root (enter for none):\"
    send \"$CURRENT_MYSQL_PASSWORD\r\"
    expect \"root password?\"
    send \"y\r\"
    expect \"New password:\"
    send \"$MARIADB_ROOT_PASSWORD\r\"
    expect \"Re-enter new password:\"
    send \"$MARIADB_ROOT_PASSWORD\r\"
    expect \"Remove anonymous users?\"
    send \"y\r\"
    expect \"Disallow root login remotely?\"
    send \"y\r\"
    expect \"Remove test database and access to it?\"
    send \"y\r\"
    expect \"Reload privilege tables now?\"
    send \"y\r\"
    expect eof
    ")
    echo "${SECURE_MYSQL}" &> /dev/null

    echo -e "${GREEN}[$TAG] Reloading & Restarting MariaDB"
    sudo systemctl restart mariadb.service &> /dev/null

    STATUS=$(sudo systemctl show -p ActiveState mariadb.service | sed 's/ActiveState=//g')
    if [ "$STATUS" == "failed" ]; then
      echo -e "${REDBLINK}[$TAG] Configuration of $pkg failed!${NOCOLOR}"
      sudo systemctl status ${TAG}.service
    elif [ "$STATUS" == "active" ]; then
      echo -e "${GREENBLINK}[$TAG] Successfully installed $pkg ${NOCOLOR}"
    fi
    sudo reboot
    fi
  done
}

clear
prerequisites
top
intro
mariadb
