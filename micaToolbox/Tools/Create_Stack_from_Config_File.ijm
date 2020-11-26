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

//-------------------- New matadata-based mspec file-------------------------
if(configString[0] == "mspec calibrated image"){
	

	flag=0;

	for(i=0; i<configString.length; i++){

		if(startsWith(configString[i], "files=") == true){
			photoNames = replace(configString[i], "files=", "");
			photoNames = split(photoNames, ",");
			flag ++;
		}

		if(startsWith(configString[i], "imageType=") == true){
			imageType = replace(configString[i], "imageType=", "");
			flag ++;
		}

		if(startsWith(configString[i], "linearisationModel=") == true){
			linModels = replace(configString[i], "linearisationModel=", "");
			linModels = split(linModels, ",");
			flag ++;
		}

		if(startsWith(configString[i], "slices=") == true){
			sliceOrder = replace(configString[i], "slices=", "");
			sliceOrder = split(sliceOrder, ",");
			flag ++;
		}

		if(startsWith(configString[i], "labels=") == true){
			sliceLabels = replace(configString[i], "labels=", "");
			sliceLabels = split(sliceLabels, ",");
			flag ++;
		}

		if(startsWith(configString[i], "refVals=") == true){
			refVals = replace(configString[i], "refVals=", "");
			refVals = split(refVals, ",");
			flag ++;
		}

		if(startsWith(configString[i], "alignMethod=") == true){
			alignMethod = replace(configString[i], "alignMethod=", "");
			flag ++;
		}
		

		if(startsWith(configString[i], "alignData=") == true){
			alignData = replace(configString[i], "alignData=", "");
			alignData = split(alignData, ",");
			flag ++;
		}

	} // i load settings





nPhotos = photoNames.length;


	// Calculate number of slices required
	stackSize = 0;
	for(i=0; i<sliceOrder.length; i++){
		if(parseInt(sliceOrder[i]) > stackSize)
			stackSize = parseInt(sliceOrder[i]);
	}

rgbImage  = 0;
if(stackSize == 3 && sliceOrder[0] == 1 && sliceOrder[1] == 2 && sliceOrder[2] == 3)
	rgbImage = 1;


// CLEAR ROI MANAGER
while(roiManager("count")>0){
	roiManager("select", 0);
	roiManager("Delete");
}


// OPEN IMAGES & MEASURE STANDARD(s)

//setBatchMode(true);


sliceCounter = 0;

for(j=0; j<nPhotos; j++){

	//photoSettings = split(settingsString[j+1], "\t"); // settings for current photo

	imagePath= imageDir + photoNames[j];
	if(File.exists(imagePath) == 0)
		exit("Exiting - can't find image files\n \nThe image file(s) linked to the .mspec configuration\nfile must be in the same folder.");

	//dcrawString = "select=[" + imagePath + "]";
	dcrawString = "select=[" + imagePath + "] camera";

	//-------------------OPEN RAW OR NON-LINEAR IMAGE-----------------
	if(imageType == "RAW Photo")
		run("DCRAW import", dcrawString);
	else {
		open(imagePath);
		if(bitDepth == 24)
			run("RGB Stack");
		if(bitDepth != 32)
			run("32-bit");

	
		if(linModels.length != nSlices)
			exit("The chosen linearity model has a different number of channels than the selected image");

		for(a=0; a<nSlices; a++) // linearise image
			run("Linearisation Function", linModels[a]);

	}

	nPhotoSlices = nSlices();
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


if(rgbImage == 0){
for(i=0; i<nPhotoSlices; i++){
	if(parseInt(sliceOrder[sliceCounter]) > 0){ // channel is to be added

		selectImage(photoID);
		setSlice(i+1);
			
		if(sliceCounter == 0){ // first photo - set up new image
			run("Select All");
			run("Copy");
			newImage(imageName, "32-bit black", getWidth(), getHeight(), stackSize);
			//run("Internal Clipboard");
			newStack = getImageID();
			setSlice(parseInt( sliceOrder[sliceCounter]) );
			run("Paste");
	
		} else { // subsequent photo - add new slice
			run("Select All");
			run("Copy");
			selectImage(newStack);
			setSlice(parseInt( sliceOrder[sliceCounter]) );
			run("Paste");
		}
	}
	sliceCounter++;
}//i


selectImage(photoID);
close();
selectImage(newStack);

} else {
	newStack = getImageID();
	rename(imageName);
}


} // j

// RENAME SLICES

j=1;
for(i=0; i<sliceOrder.length; i++)
if(parseInt(sliceOrder[i]) != 0){
	setSlice(j);
	ti = parseInt(sliceOrder[i]) - 1;
	tsl = sliceLabels[ti];

	if(refVals.length != 0)
		tsl = tsl + "\n" + "refVals=" + refVals[ti];

	if(alignMethod != "None")
		tsl = tsl + "\n" + "alignMethod=" + alignMethod + "\n" + "alignData=" + alignData[ti];
	else tsl = tsl + "\n" + "alignMethod=" + alignMethod;

	setMetadata(tsl);
	j++;
}


setBatchMode(false);
showStatus("Finished loading slices");


// LOAD ROIs IF PRESENT - must have the same name as the config file, with ".zip" extension

roiPath = replace(configFilePath, ".mspec", ".zip");

if(File.exists(roiPath) == 1){
	open(roiPath);
	roiManager("Show All with labels");
	run("Labels...", "color=white font=12 show use draw");
	roiManager("Select", 0);
	roiManager("Deselect");
}
setSlice(1);













} else { //--------------------------------------------Legacy import-------------------------------------------------------------


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

	settingsString=File.openAsString(settingsPath);
	settingsString=split(settingsString, "\n"); // split settings into rows

	// Calculate number of slices required
	stackSize = 0;
	sliceOrder = newArray(0);
	for(i=1; i<(settingsString.length); i++){
		settingsTemp = split(settingsString[i], "\t");
		sliceOrder = Array.concat(sliceOrder, settingsTemp);
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



rgbImage  = 0;
if(stackSize == 3 && sliceOrder[0] == 1 && sliceOrder[1] == 2 && sliceOrder[2] == 3)
	rgbImage = 1;


// OPEN IMAGES & MEASURE STANDARD(s)

//setBatchMode(true);

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

if(rgbImage == 0){
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

} else {
	newStack = getImageID();
	rename(imageName);
}



} // j

// RENAME SLICES

for(i=1; i<=sliceLabels.length; i++){
	setSlice(i);
	tsl = replace(sliceLabels[i-1], "label=", "");
	tsl = split(tsl, ",");
	tsl1 = split(tsl[0], ":");
	tsl2 = "alignData=" + tsl1[2] + ":" + tsl1[3]  + ":" + tsl1[4];

	tsl3 = "refVals=";
	if(tsl.length > 1){
		tsl3 = tsl3 + tsl[1];
		for(j=2; j<tsl.length; j++)
			tsl3 = tsl3 + "_" + tsl[j];
	}
	if(nPhotos > 1)
		tsl4 = "alignMethod=Manual Align";
	else tsl4 = "alignMethod=None";

	tsl = tsl1[0] + ":" + tsl1[1] +"\n" + tsl3 + "\n" + tsl4 + "\n" + tsl2;
	setMetadata(tsl);

	//run("Set Label...", sliceLabels[i-1]);
}// i labels

setBatchMode(false);
showStatus("Finished loading slices");


// LOAD ROIs IF PRESENT - must have the same name as the config file, with ".zip" extension

roiPath = replace(configFilePath, ".mspec", ".zip");

if(File.exists(roiPath) == 1){
	open(roiPath);
	roiManager("Show All with labels");
	run("Labels...", "color=white font=12 show use draw");
	roiManager("Select", 0);
	roiManager("Deselect");
}
setSlice(1);


}///------------legacy---------------












