#!/bin/bash

#Function for displaying usage
	function fn_Usage {
	 echo
	 echo "     //LTV3 Playlist Pre-Release Tool//"
	 echo
	 echo "     This script is designed to create a valid test zip by updating the packages.cssc"
	 echo "     and catalog.cssc file and creating the .packages.cssc.md5sum and" 
	 echo "     .catalog.cssc.md5sum files required for reconciling."
	 echo "     It requires three (3) arguments, a .zip filename a campaign number and"
	 echo "     a description."
	 echo "                                                                   Q4 2019 Dave Owens"
	 echo
	 echo "     usage:"
	 echo "     bash prerelease.sh <filename.zip> \"Test Campaign Number\" \"Description\""
	 echo
	 echo "     example:"
	 echo "     bash prelease.sh U3Dec19_TestPlaylists.zip \"LV3-WUAL-0000\" \"United Test Campaign\""
}

	function fn_RequiredFilesInfo {
	 echo
	 echo "     Required files are missing:"
	 echo	 	
			#Check catalog.cssc file exists
				if [ "$CatalogExists" = False ]; then
		 echo "     - catalog.cssc           missing" 
				fi
			#Check packages.cssc file exists
				if [ "$PackagesExists" = False ]; then
		 echo "     - packages.cssc          missing"  
				fi

			#Check md5_calc.php file exists
				if [ "$md5phpExists" = False ]; then
		 echo "     - md5_calc.php           missing" 
				fi
			
			#Check campaign.content.temp file exists
				if [ "$CampaignContentExists" = False ]; then
		 echo "     - campaign.content.temp  missing" 
				fi
 	 
}

#Do some simple validation
	#If not enough arguments supplied then display usage
		if [ $# -lt 3 ]; then
				fn_Usage
			exit 0
		fi

	#Check the required files are present
		#Check catalog.cssc file exists
			if [ ! -f $PWD/catalog.cssc ]; then
				CatalogExists=False 
			fi
		#Check packages.cssc file exists
			if [ ! -f $PWD/packages.cssc ]; then
				PackagesExists=False 
			fi

		#Check md5_calc file exists
			if [ ! -f $PWD/md5_calc.php ]; then
				md5phpExists=False 
			fi
		
		#Check campaign.content.temp file exists
			if [ ! -f $PWD/campaign.content.temp ]; then
				CampaignContentExists=False 
			fi		
		
#Check all of the above passed validation, if not show the required files info		
		if [ "$CatalogExists" = False ] || [ "$PackagesExists" = False ] || [ "$md5phpExists" = False ] || [ "$CampaignContentExists" = False ]; then
				fn_RequiredFilesInfo
				exit 0
		fi	

	#Take the supplied inputs 
		playlistzip=$1	
		campaignnumber=$2
		description=$3

echo
echo "Unzipping original package.."

	#Unzip the playlist .zip
		for d in $playlistzip
		do
		  dir=$PWD/${d%%.zip}
		  unzip -q -o -d "$dir" "$playlistzip"
		done

	#Remove the .zip from the filename for use creating a folder and adding to the packages file
		playlistbasename="$(basename $playlistzip .zip)"

	#Make the reserved folder as created by Content Central
		mkdir $PWD/$playlistbasename/"reserved"

echo "Updating content.campaign file.."

	#Update the content.campaign.new file
		cp $PWD/campaign.content.temp $PWD/campaign.content.new
		sed -i 's/CAMPAIGNNUMBER/'$campaignnumber'/'g $PWD/campaign.content.new
		sed -i 's/CAMPAIGNDESCRIPTION/'"$description"'/'g $PWD/campaign.content.new #Double quotes around the variable becuase it expands with spaces e.g. "United campaign"

	#Move the campaign.content file into reserved	
		mv $PWD/campaign.content.new $PWD/$playlistbasename/reserved/

	#Rename folder to match expected naming structure
		mv $PWD/$playlistbasename $PWD/playlist-cssc-$campaignnumber
		
	#Grab the final folder name and create variables
		playlistfinalfolder=playlist-cssc-$campaignnumber
		playlistfinalzip=playlist-cssc-$campaignnumber.zip

echo "Zipping playlist package.."

	#Re Zip everythign into a valid playlist zip; enter the directory, zip it, leave the directory
		cd $playlistfinalfolder; zip -r -q $playlistfinalzip *

	#Move the zip back to the higher directory	
		mv $playlistfinalzip ../; cd ..
		

	#Grab the file size for the zip file
		playlistzipsize=$(wc -c $playlistfinalzip |awk '{print $1}')

	#Remove the .zip from the filename for use creating a folder and adding to the packages file
		playlistbasename="$(basename $playlistfinalzip .zip)"

	#Grab the md5sum of the zip file
		playlistzipmd5=$(md5sum $playlistfinalzip |awk '{print $1}')

	#Run the magic php script which calculates whole, unpackaged folder md5s
		playlistfoldermd5=$(php md5_calc.php -p $PWD/$playlistfinalfolder |grep result: | awk '{print $4}')

	#Grab the unzipped directory size and push it to a string
		playlistdirsize=$(du -sb $playlistfinalfolder |awk '{print $1}')

echo "Removing temp paths.."

	#Remove the expanded playlist folder
		rm -rf $playlistfinalfolder

	#Add the end flag back in
		sed -i 's/End://'g $PWD/packages.cssc

	#Remove pesky double space at the end of the file
		sed -i -e :n -e 'N;s/\n$//;tn' $PWD/packages.cssc

echo "Updating pacakges.cssc file.."

	#Write packages entry to match formatting EXACTLY!
		echo File: $playlistfinalfolder >> $PWD/packages.cssc
		echo Size: $playlistdirsize >> $PWD/packages.cssc
		echo MD5: $playlistfoldermd5 >> $PWD/packages.cssc
		echo CryptType: vsuplzip >> $PWD/packages.cssc
		echo CryptFile: $playlistfinalzip >> $PWD/packages.cssc
		echo CryptSize: $playlistzipsize >> $PWD/packages.cssc
		echo CryptMD5: $playlistzipmd5 >> $PWD/packages.cssc
		echo URLBase: content/dist/continental >> $PWD/packages.cssc
		echo Description: $description >> $PWD/packages.cssc
		echo >> $PWD/packages.cssc	

		echo End: >> packages.cssc

echo "Creating pacakges.cssc md5sum file.."

	#Create md5 file for packages.cssc
		packagesdotmd5=$(md5sum $PWD/packages.cssc | awk '{print $1}')
		#Rearrange output to match the current .md5sum file EXACTLY
			echo -e $packagesdotmd5$'\t''/content/dist/continental/packages.cssc' >.packages.cssc.md5sum

echo "Updating catalog.cssc file.."

	#Add a new entry to the bottom of the catalog.cssc file
		sed -i 's/9999/'$(date '+%Y.%d.%m')':\n\n'$playlistfinalfolder'\n\n9999/' $PWD/catalog.cssc

echo "Creating pacakges.cssc md5sum file.."

	#Create md5 file for packages.cssc
		catalogdotmd5=$(md5sum $PWD/catalog.cssc | awk '{print $1}')
		#Rearrange output to match the current .md5sum file EXACTLY
			echo -e $catalogdotmd5$'\t''/content/dist/continental/catalog.cssc' >.catalog.cssc.md5sum

#sed -i "s/9999/$(date '+%Y.%d.%m'):\n\nplaylistzip\n\n9999/" catalog.cssc

echo
echo "Complete."
