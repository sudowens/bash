#!/bin/bash

#Function for displaying usage
	function fn_Usage {
	 echo
	 echo "     //LTV3 Playlist Pre-Release Tool//"
	 echo
	 echo "     This script is designed to update the packages.cssc file"
	 echo "     and create the .packages.cssc.md5sum required for reconciling"
	 echo "     It requires two arguments, a .zip filename and a description."
	 echo "     Q4 2019 Dave Owens "
	 echo
	 echo "     Arguments missing, see example usage below:"
	 echo
	 echo "     bash prerelease.sh <filename.zip> \"United Test Campaign\""
	 echo
}

#If no filename was supplied then display usage
	if [ $# -eq 0 ]; then
			fn_Usage
		exit 0
	fi

#Take the supplied inputs 1=.zip name, 2=Description 
	playlistzip=$1
	description=$2

#Grab the file size for the zip file
	playlistzipsize=$(wc -c $playlistzip |awk '{print $1}')

#Remove the .zip from the filename for use creating a folder and adding to the packages file
	playlistbasename="$(basename $1 .zip)"

#Grab the md5sum of the zip file
	playlistzipmd5=$(md5sum $playlistzip |awk '{print $1}')

#Run the magic php script which calculates whole, unpackaged folder md5s
	playlistfoldermd5=$(php md5_calc.php -p $PWD/$playlistbasename |grep result: | awk '{print $4}')

#Unzip the playlist .zip
	for d in *.zip
	do
	  dir=$PWD/${d%%.zip}
	  unzip -q -o -d "$dir" "$playlistzip"
	done

#Grab the unzipped directory size and push it to a string
	playlistdirsize=$(du -sb $playlistbasename |awk '{print $1}')

#Add the end flag back in
	sed -i 's/End://'g $PWD/packages.cssc

#Remove pesky double space at the end of the file
	sed -i -e :n -e 'N;s/\n$//;tn' $PWD/packages.cssc

#Write packages entry to match formatting EXACTLY!
	echo File: $playlistbasename >> $PWD/packages.cssc
	echo Size: $playlistdirsize >> $PWD/packages.cssc
	echo MD5: $playlistfoldermd5 >> $PWD/packages.cssc
	echo CryptType: vsuplzip >> $PWD/packages.cssc
	echo CryptFile: $playlistzip >> $PWD/packages.cssc
	echo CryptSize: $playlistzipsize >> $PWD/packages.cssc
	echo CryptMD5: $playlistzipmd5 >> $PWD/packages.cssc
	echo URLBase: content/dist/continental >> $PWD/packages.cssc
	echo Description: $description >> $PWD/packages.cssc
	echo >> $PWD/packages.cssc	

	echo End: >> packages.cssc

#Create md5 file for packages.cssc
	packagesdotmd5=$(md5sum $PWD/packages.cssc | awk '{print $1}')
	#Rearrange output to match the current .md5sum file EXACTLY
		echo -e $packagesdotmd5$'\t''/content/dist/continental/packages.cssc' >.packages.cssc.md5sum
		
