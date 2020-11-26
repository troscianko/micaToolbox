osName = getInfo("os.name");

if( startsWith(osName, "Windows") ==1){
	dcPath = getDirectory("plugins")+"dcraw/dcrawWin.exe";

} else if( startsWith(osName, "Linux") ==1){
	dcPath = getDirectory("plugins")+"dcraw/dcrawLin";

} else if( startsWith(osName, "Mac") ==1){
	dcPath = getDirectory("plugins")+"dcraw/dcrawMac";

} else {
	exit("Operating system could not be identified - supports windows, mac and linux");
}

//settingsString = "-w -o 0 -q 0 -4 -T";
 

rawPath = File.openDialog("Select RAW file");	
//tifPath = split(rawPath,".");
//tifPath = replace(rawPath, tifPath[tifPath.length-1], "tiff");

tifPath = rawPath + ".tiff";

//THIS WORKS (tested on windows, mac and linux)
//exec("/home/jolyon/Desktop/ImageJ/plugins/dcraw/dcraw", "-w", "-o", "0", "-q", "0", "-4", "-T", "/home/jolyon/Desktop/ImageJ/plugins/dcraw/temp folder/test.SRW");

Dialog.create("Import RAW image settings");
	Dialog.addCheckbox("Camera white balance", true);
	Dialog.addMessage("Using the camera's white-balance can produce a slightly higher dynamic range");
	Dialog.addCheckbox("Auto-level brightness", true);
	Dialog.addMessage("This only affects the viewing brightness, not actual pixel values");
Dialog.show();

cwb = Dialog.getCheckbox();
ab = Dialog.getCheckbox();


if(cwb == true)
	exec(dcPath, "-w", "-o", "0", "-q", "0", "-4", "-T", rawPath);
else exec(dcPath, "-o", "0", "-q", "0", "-4", "-T", rawPath);

cDelay = 50; // check delay
maxWait = 20000; // only wait for a max of 20 seconds
flag = 0;
for(i=0; i<maxWait; i=i+cDelay){
	if(File.exists(tifPath)){
		i = maxWait;
		flag = 1;	
	}
	wait(cDelay);
}

if(flag == 1){
	open(tifPath);
	if(File.delete(tifPath) != true){
		print("Temporary file could not be deleted");
		print("Location: " + tifPath);
	}
}
else waitForUser("Timeout - DCRAW doesn't seem to have processed this file");

run("32-bit");

if(ab == true){
	for(k=1; k<=nSlices; k++){
		setSlice(k);
		run("Enhance Contrast", "saturated=0.35");
	}
} else {
	for(k=1; k<=nSlices; k++){
		setSlice(k);
		setMinAndMax(0, 65535);
	}
}




