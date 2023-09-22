<?php

function dirMD5( $path, $skipExt = "" )
{
	if(!is_dir($path)) return md5_file( $path );
	$dir = opendir($path);
	while($file = readdir($dir))
	{
		// pathinfo will allow us to determine the extension of each file
		$path_ext = pathinfo($file, PATHINFO_EXTENSION);  
		// if an extension has been given to skip, then skip those files; still need to process files that have no ext
		if( $skipExt == "" || $path_ext != $skipExt) {
			$fileArray[] = $file;
		}
	}

	sort( $fileArray );

	$fileMD5 = "";
	$TotalMD5 = "";
	foreach( $fileArray as $file )
	{
		if( is_file($path."/".$file) ) $fileMD5 = md5_file($path."/".$file);
		if( is_dir($path."/".$file) && $file!= "." && $file !="..") $fileMD5 = dirMD5( $path."/".$file );

		$TotalMD5 = $TotalMD5.$fileMD5;
		echo "File: $file MD5: $fileMD5\n";
	}
	echo "TotalMD5 concatenated string: $TotalMD5\n";
	return ( md5($TotalMD5) );
}



#FILEPATH
$filepath = getopt('p:');
echo "Calculating md5 for filepath:  " . $filepath['p'];
$result = dirMD5( $filepath['p'] );
echo "\nMD5 Output result: $result\n";
?>