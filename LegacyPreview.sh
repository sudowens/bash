#!/bin/bash
#Dave Owens Q4 2022
#Legacy Preview

#v1.0 - Initial release

echo


function Update_DB () {
  thedate=$(date '+%F %T')
  mysql -e "INSERT INTO LegacyPreview (Date, Filename, Size, Hash, Modified_Time, Status_Time) VALUES ('$thedate','$1', '$2', '$3', '$4', '$5')"
  echo $1 added to DB.
}

function Send_to_DG () {
	printname=$(echo $1 |xargs basename)
	echo Sending $printname to Digital Gateway..
	cp $1 /opt/digitalgateway
}


#allfiles=$(find /opt/contentcentral/Continental/U3Nov22_Schwab_30.mpg -type f -iname "*.mpg" |egrep -iv "/enc/")
allfiles=$(find /opt/contentcentral/ -type f -iname "*.mpg" |egrep -iv "/enc/")

#Special flag to repopulate the DB without moving files
if [[ "$1" = "-updatedb" ]]
then
	echo Updating DB only..
	for file in $allfiles
		do
		filestats=$(stat --format="%n %s %Y %Z" $file)
					filename=$(echo $filestats |awk '{print $1}' |xargs basename)		
					size=$(echo $filestats |awk '{print $2}')
					modified=$(echo $filestats |awk '{print $3}')
					status=$(echo $filestats |awk '{print $4}')
					hash=$(md5sum $file |awk '{print $1}')
		Update_DB $filename $size $hash $modified $status
		done
exit
fi

for file in $allfiles
	#do echo $file
	
	#LookupCount=0
	
	do 
		 
		filestats=$(stat --format="%n %s %Y %Z" $file)
			filename=$(echo $filestats |awk '{print $1}' |xargs basename)		
			size=$(echo $filestats |awk '{print $2}')
			modified=$(echo $filestats |awk '{print $3}')
			status=$(echo $filestats |awk '{print $4}')
			hash=$(md5sum $file |awk '{print $1}')
				
	
	#Check if it already exists in the table at all
	LookupCount=`mysql -N -B -e "SELECT COUNT(Filename) FROM LegacyPreview WHERE Filename = '$filename'"`
	
	#If we have not seen this file before, skip the comparison, add it to the DB and send it to DG
	if [ $LookupCount -gt 0 ]
	then
		echo We already have $filename, comparing attributes.. 
		
		#Check against the size in the db
		from_db_size=`mysql -N -B -e "SELECT Size FROM LegacyPreview WHERE Filename = '$filename' ORDER BY Event DESC LIMIT 1"`		
		echo -ne Comparing size............
		if [[ $size != $from_db_size ]]; then 
			echo Size doesn\'t match: File size: $size DB size: $from_db_size
			Update_DB $filename $size $hash $modified $status
			Send_to_DG $file
			continue
		else
			echo match
		fi
			
			#Check against the modified time in the db
			from_db_modified=`mysql -N -B -e "SELECT Modified_Time FROM LegacyPreview WHERE Filename = '$filename' ORDER BY Event DESC LIMIT 1"`		
			echo -ne Comparing modified time...
			if [[ $modified != $from_db_modified ]]; then 
				echo Modified time doesn\'t match: File modified: $modified DB modified: $from_db_modified
				Update_DB $filename $size $hash $modified $status
				Send_to_DG $file
				continue			
			else 
				echo match
			fi		
			
				#Check against the status time in the db
				from_db_status=`mysql -N -B -e "SELECT Status_Time FROM LegacyPreview WHERE Filename = '$filename' ORDER BY Event DESC LIMIT 1"`
				echo -ne Comparing status time.....
				if [[ $status != $from_db_status ]]; then 
					echo Status time doesn\'t match: File status: $status DB status: $from_db_status
					Update_DB $filename $size $hash $modified $status
					Send_to_DG $file
					continue
				else
					echo match
				fi
				
					#Check against the hash in the db
					echo -ne Comparing hashes..........
					from_db_hash=`mysql -N -B -e "SELECT Hash FROM LegacyPreview WHERE Filename = '$filename' ORDER BY Event DESC LIMIT 1"`					
					if [[ $hash != $from_db_hash ]]; then
						echo Attributes are different: File hash: $hash DB hash: $from_db_hash
						Send_to_DG $file							
					else												
						echo match
						echo $filename ignored.
						continue
					fi						
	else
		echo New file: $filename to the DB and sending to Digital Gateway.
		Update_DB $filename $size $hash $modified $status
		Send_to_DG $file

	fi
done
