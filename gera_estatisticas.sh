#!/bin/bash

PASTABASE=/home/gogs/gogs-repositories/
DIRESTATIC=/usr/share/nginx/estatisticas/
GITSTATS=/opt/gitstats/gitstats

find $PASTABASE -iwholename *.git -print | while read linha
do
	if [ -d "$linha" ];then
		DIR=`echo $linha | awk 'BEGIN { FS="/"; } { print $(NF-1),"-",$NF; }' | sed 's/ //g'`
		if [ -d $DIRESTATIC$DIR ];then
			rm -rf $DIRESTATIC$DIR
		fi
		cd "$linha"
		git rev-list --all --quiet &> /dev/null
		if [ $? -eq 0 ];then
			mkdir -p $DIRESTATIC$DIR
			cd $DIRESTATIC$DIR
			$GITSTATS "$linha" $DIRESTATIC$DIR &> log.err
		fi
	fi
done