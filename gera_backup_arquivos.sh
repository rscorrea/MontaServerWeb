#!/bin/bash

DATA=`date +%F`
INICIO=`date '+%d-%m-%Y %T'`
NOME=$(echo $1 | awk -F/ '{print $NF}')
echo "---Backup ARQUIVOS "$NOME". "$INICIO >> /var/log/backup/arquivos.log
tar -jc -T $1 -f ~/backup/bkp-$NOME-$DATA.tar.bz2