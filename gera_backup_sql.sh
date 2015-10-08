#!/bin/bash

DATA=`date +%F`
INICIO=`date '+%d-%m-%Y %T'`
SENHA='*******'
mysqldump -h localhost -u peduser -p$SENHA $1 > ~/backup/bkp-mysql-$1-$DATA.sql
tar -jc ~/backup/bkp-mysql-$1-$DATA.sql --remove-files -f ~/backup/bkp-mysql-$1-$DATA.tar.bz2
echo "---Backup MYSQL "$1". "`date '+%d-%m-%Y %T'` >> /var/log/backup/mysql.log