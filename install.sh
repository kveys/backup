#!/bin/bash
#
# install backup script
#
# Author: Koen Veys
# script is maintained in https://github.com/kveys/backup.git

#
# Setting variables 

#program
gzip=/bin/gzip
rm=/bin/rm
tar=/bin/tar
aws=/usr/local/bin/aws

#global
tmpdir=/tmp
bindir=/opt/backup
appsdir=$bindir/apps
logdir=$bindir/log
servername=`hostname`

###################
# start of script #
###################

echo "installing backup script on $servername"

mkdir $bindir

mv $tmpdir/backup/backup.sh $bindir
mv $tmpdir/backup/apps $bindir
mv $tmpdir/backup/backup.cron /etc/cron.d/backup

chmod -R 700 $bindir
chown -R root $bindir
