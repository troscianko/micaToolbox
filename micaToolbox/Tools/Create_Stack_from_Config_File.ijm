// load global DCRAW import settings

configFilePath=File.openDialog("Select Config File"); // get file location
tempString = "select=["+ configFilePath+"]";


//  LOAD INFO

	//configFilePath=File.openDialog("Select Config File"); // get file location
	if(endsWith(configFilePath, ".mspec") == 0)
		exit("Error - Please select a .mspec multispectral image file");
	infoPath = getDirectory("plugins")+"micaToolbox/cameras";

	configFileDir = split(configFilePath, "/"); // unix
	if(configFileDir.length == 1) // windows
		configFileDir = split(configFilePath, "\\");

	imageName = configFileDir[ configFileDir.length-1 ];
	imageDir = replace(configFilePath, imageName, "");
	imageName = replace(imageName, ".mspec", "");

	configString = File.openAsString(configFilePath);
	configString = split(configString, "\n");

	photoNames = split(configString[1], "\t");
	sliceLabels = split(configString[2], "\t");

	nonLin = 0;
	cwb = 0; // use camera white balance (legacy support)
	if(configString.length>3){
		if(startsWith(configString[3], "equation=") == true){
			nonLin = 1;
			nonLinSettings = split(configString[3],"\t");
		}
	
		if(startsWith(configString[3], "RAW Photo") == true)
			cwb = 1;
	}



// LOAD CAMERA CONFIGURATION SETTINGS

	settingsPath = infoPath+"/"+configString[0]+".txt";
	//print(settingsPath);

	settingsString=File.openAsString(settingsPath);
	settingsString=split(settingsString, "\n"); // split settings into rows

	// Calculate number of slices required
	stackSize = 0;
	for(i=1; i<(settingsString.length); i++){
		settingsTemp = split(settingsString[i], "\t");
		for(j=1; j<=3; j++)
			if(parseInt(settingsTemp[j]) > stackSize)
				stackSize = parseInt(settingsTemp[j]);
	}

	nPhotos = settingsString.length-1;

// CLEAR ROI MANAGER
while(roiManager("count")>0){
	roiManager("select", 0);
	roiManager("Delete");
}


// OPEN IMAGES & MEASURE STANDARD(s)

setBatchMode(true);

firstFlag = 1;

for(j=0; j<nPhotos; j++){

	photoSettings = split(settingsString[j+1], "\t"); // settings for current photo

	imagePath= imageDir + photoNames[j];
	if(File.exists(imagePath) == 0)
		exit("Exiting - can't find image files\n \nThe image file(s) linked to the .mspec configuration\nfile must be in the same folder.");

	//dcrawString = "open=[" + imagePath + "] " + dcrawOptions;
	if(cwb == 0)
		dcrawString = "select=[" + imagePath + "]";
	else	dcrawString = "select=[" + imagePath + "] camera";

	//-------------------OPEN RAW OR NON-LINEAR IMAGE-----------------
	if(nonLin == 0)
		//run("DCRaw Reader...", dcrawString);
		run("DCRAW import", dcrawString);
	else {
		open(imagePath);
		if(bitDepth == 24)
			run("RGB Stack");
		if(bitDepth != 32)
			run("32-bit");

		nonLinSettingsString = split(nonLinSettings[j], ",");

		if(nonLinSettingsString.length != nSlices)
			exit("The chosen linearity model has a different number of channels than the selected image");

		for(a=0; a<nSlices; a++) // linearise image
			run("Linearisation Function", nonLinSettingsString[a]);

	}

	photoID = getImageID();

	if(j==0){
		iw = getWidth();
		ih = getHeight();
	} else {
		w = getWidth();
		h = getHeight();

		if(h!=ih){ // Ensure all images are landscape, as canon pics are auto-rotated
			run("Rotate 90 Degrees Right");
		}

	}


for(i=1; i<=3; i++){
	if(parseInt(photoSettings[i]) > 0){ // channel is to be added

		selectImage(photoID);
		setSlice(i);
			
		if(firstFlag == 1){ // first photo - set up new image
			run("Select All");
			run("Copy");
			newImage(imageName, "32-bit black", getWidth(), getHeight(), stackSize);
			//run("Internal Clipboard");
			newStack = getImageID();
			setSlice(parseInt( photoSettings[i]) );
			run("Paste");

			firstFlag = 0;
	
		} else { // subsequent photo - add new slice
			run("Select All");
			run("Copy");
			selectImage(newStack);
			setSlice(parseInt( photoSettings[i]) );
			run("Paste");
		}
			
	}
}//i

selectImage(photoID);
close();

selectImage(newStack);

} // j

// RENAME SLICES

for(i=1; i<=sliceLabels.length; i++){
	setSlice(i);
	run("Set Label...", sliceLabels[i-1]);
}// i labels

setBatchMode(false);
showStatus("Finished loading slices");


// LOAD ROIs IF PRESENT - mush have the same name as the config file, with ".zip" extension

roiPath = replace(configFilePath, ".mspec", ".zip");

if(File.exists(roiPath) == 1){
	open(roiPath);
	roiManager("Show All with labels");
	run("Labels...", "color=white font=12 show use draw");
	roiManager("Select", 0);
	roiManager("Deselect");
}
setSlice(1);














