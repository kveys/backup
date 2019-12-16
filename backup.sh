#!/bin/bash
#
# create a backup to Amazon S3
#
# Author: Koen Veys
# script is maintained in https://github.com/kveys/linux/backup.sh
# documenation is at: https://dwkoen.ddns.net/doku.php?id/linux:backup.sh

#
# Setting variables 

#program
gzip=/bin/gzip
rm=/bin/rm
tar=/bin/tar
aws=/usr/local/bin/aws

#global
bindir=/usr/local/bin/backup
appsdir=$bindir/apps
logdir=$bindir/log
logfile=$logdir/backup.log
dir2bu2=/tmp
servername=`hostname`

# S3 specific 
s3bucket="bckp151219"

#functions

#timestamp
now(){
date +"%d%m%Y_%H%M"
}


######################
# script preparation #
######################

if ! [ -d $logdir ];then
        mkdir $logdir
fi

if ! [ -f $logfile ];then
        touch $logfile
fi

###################
# start of script #
###################

echo -e "`now`;script start" | tee -a $logfile
echo $servername

#reading dirs to backup
apps2backup=$(find $appsdir -type f -printf %f\ )

#create timestamp	
timestamp=`now`

for apps in $apps2backup; do
	echo processing $apps| tee -a $logfile

	#creating TAR file
	$tar -cf $dir2bu2/`echo $apps`_$timestamp.tar --files-from /dev/null
	for dir in `cat $appsdir/$apps`; do
		$tar -rf $dir2bu2/`echo $apps`_$timestamp.tar $dir 
		tarresult=$?
		if [ "$tarresult" == 0 ];then
			echo -e "`now` TAR: added $dir successfully" | tee -a $logfile
		else
			echo -e "`now` TAR: added $dir NOT! successfully" | tee -a $logfile
		fi
	done

	#zipping TAR file
	$gzip $dir2bu2/`echo $apps`_$timestamp.tar
	gzipresult=$?
	if [ "$gzipresult" == 0 ];then
		echo -e "`now` GZIP: gzipped TARfile successfully" | tee -a $logfile
	else
		echo -e "`now` GZIP: gzipped TARfile NOT! successfully" | tee -a $logfile
	fi

	#uploading TAR.GZ file
	$aws s3 cp $dir2bu2/`echo $apps`_$timestamp.tar.gz s3://$s3bucket/$servername/
	s3result=$?
	if [ "$s3result" == 0 ];then
		echo -e "`now` S3: uploaded TAR.GZfile successfully" | tee -a $logfile
		#$rm -f $dir2bu2/`echo $apps`_$timestamp.tar.gz
		rmresult=$?
			if [ "$rmresult" == 0 ];then
				echo -e "`now` RM: TAR.GZfile successfully removed from $dir2bu2" | tee -a $logfile
			else
				echo -e "`now` RM: TAR.GZfile NOT! successfully removed from $dir2bu2" | tee -a $logfile
				echo -e "`now` RM: TAR.GZfile is still in $dir2bu2" | tee -a $logfile
			fi
	else
		echo -e "`now` S3: uploaded TAR.GZfile NOT! successfully" | tee -a $logfile
		echo -e "`now` S3: TAR.GZfile is still in $dir2bu2" | tee -a $logfile
	fi

done

echo -e "`now`;script end" | tee -a $logfile
echo -e "==================================================================="  | tee -a $logfile
