#!/bin/bash
#
# create a backup to Amazon S3 or an NFS host
#
# Author: Koen Veys
# script is maintained in https://github.com/kveys/backup.git
# documenation is at: https://dwkoen.ddns.net/doku.php?id/linux:backup.sh

#
# Setting variables 

#program
gzip=/bin/gzip
rm=/bin/rm
tar=/bin/tar
aws=/usr/local/bin/aws
mount=/bin/mount
umount=/bin/umount

#global
bindir=/opt/backup
appsdir=$bindir/apps
logdir=$bindir/log
logfile=$logdir/backup.log
dir2bu2=/tmp
hostn=`hostname | cut -d. -f1`
upload=AWS #other values: NFS

# S3 specific 
s3bucket="bckp151219"

# NFS specific
NFSHOST=<nfsHost>
NFSDIR=<nfsDirBackup>
NFSMNT=<localMountPoint>


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
	if [ "$upload" == "AWS" ];then
		$aws s3 cp $dir2bu2/`echo $apps`_$timestamp.tar.gz s3://$s3bucket/$servername/
	elif [ "$upload" == "NFS" ];then
		$mount -t nfs $NFSHOST:/$NFSDIR $NFSMNT 
		cp $dir2bu2/`echo $apps`_$timestamp.tar.gz $NFSMNT/$hostn 
	fi

	uplresult=$?
	if [ "$uplresult" == 0 ];then
		echo -e "`now` $upload: uploaded TAR.GZfile successfully" | tee -a $logfile
		$rm -f $dir2bu2/`echo $apps`_$timestamp.tar.gz
		rmresult=$?
		if [ "$rmresult" == 0 ];then
			echo -e "`now` RM: TAR.GZfile successfully removed from $dir2bu2" | tee -a $logfile
		else
			echo -e "`now` RM: TAR.GZfile NOT! successfully removed from $dir2bu2" | tee -a $logfile
			echo -e "`now` RM: TAR.GZfile is still in $dir2bu2" | tee -a $logfile
		fi
	else
		echo -e "`now` $upload: uploaded TAR.GZfile NOT! successfully" | tee -a $logfile
		echo -e "`now` $upload: TAR.GZfile is still in $dir2bu2" | tee -a $logfile
	fi

done

#unmounting NFS
if [ "$upload" == "NFS" ];then
	$umount $NFSMNT 
fi

echo -e "`now`;script end" | tee -a $logfile
echo -e "==================================================================="  | tee -a $logfile
