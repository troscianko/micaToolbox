
dataString = getMetadata("Info");

dataString = split(dataString, "\n");

row = split(dataString[0], ",");
fileDir = row[0];
settingsChoice = row[1];

row = split(dataString[1], ",");

filterNames = newArray(dataString.length-1);
imageNames =  newArray(dataString.length-1);
imagePaths = newArray(dataString.length-1);
standardLevels = newArray(row.length -1);
standardMeasurements = newArray(filterNames.length * standardLevels.length);

for(i=1; i<dataString.length; i++){
	row = split(dataString[i], ",");
	tempVal = split(row[0], ":");
	filterNames[i-1] = tempVal[0];
	imageNames[i-1] = tempVal[1];
	imagePaths[i-1] = fileDir + tempVal[1];

	for(j=1; j<row.length; j++){
		tempVal = split(row[j], ":");
		standardLevels[j-1] = parseFloat(tempVal[0]);
		standardMeasurements[ ((i-1)* standardLevels.length) + j-1] = tempVal[1];
	}
}



//Array.print(imagePaths);
//Array.print(standardLevels);
//Array.print(standardMeasurements);

// LOAD PREVIOUSLY USED VALUES

settingsFilePath = getDirectory("plugins") + "micaToolbox/importSettings.txt";
if(File.exists(settingsFilePath) == 1){
	settingsString=File.openAsString(settingsFilePath);	// open txt data file
	defaultSettings=split(settingsString, "\n");
} else defaultSettings = newArray(
"Visible & UV",	// settings choice
"Same photo",	// grey loaction
"0",	// estimate black
"20,80", 	// grey levels
"0", 	// customise RGB levels
"0", 	// standards move
"1",	// images sequential
"Auto-Align",	// align
"16",	// offset
"4",	// loops
"0.005",	// scale step size
"1",	// custom zone
"1",	// save config file
"Aligned Normalised 32-bit", // image output
"",	// default name
"0");	// rename RAW files
//"use_temporary_directory white_balance=None do_not_automatically_brighten output_colorspace=raw read_as=[16-bit linear] interpolation=[High-speed, low-quality bilinear] do_not_rotate"); // dcraw string

//dcrawOptions = defaultSettings[16];


//  USER OPTIONS

	infoPath = getDirectory("plugins")+"micaToolbox/cameras";

	offsetOptions = newArray("4","8","16","32","64","128","256","512","1024");
	//outputOptions = newArray( "Aligned Normalised 32-bit", "Visual 32-bit", "Pseudo UV 32-bit", "Config file only");
	outputOptions = newArray(
		"Linear Normalised Reflectance Stack",
		"Linear Stack",
		"Linear Colour Image",
		"Non-linear Colour Image",
		"Non-linear Colour VIS-UV Image");

	alignOptions = newArray("None", "Auto-Align", "Manual Align");


	Dialog.create("Multispectral Image Compositioning");

		if(imageNames.length > 1){

		Dialog.addMessage("________________Alignment & Scaling______________ ");
		Dialog.addChoice("Alignment", alignOptions, defaultSettings[7]);
		Dialog.addChoice("Offset", offsetOptions, defaultSettings[8]);
		Dialog.addNumber("Scaling loops (1=off)", defaultSettings[9]);
		Dialog.addNumber("Scale_step_size",defaultSettings[10]);
		Dialog.addCheckbox("Custom alignment zone", defaultSettings[11]);
		}

		Dialog.addMessage("___________________Output_________________ ");
		//Dialog.addCheckbox("Save configuration file", defaultSettings[12]);
		Dialog.addChoice("Image output", outputOptions, defaultSettings[13]);
		Dialog.addString("Image Name", defaultSettings[14], 20);
		Dialog.addCheckbox("Rename RAW files", defaultSettings[15]);

	Dialog.show();

if(imageNames.length > 1){

	autoAlignOption = Dialog.getChoice();
	autoAlignOffset = Dialog.getChoice();
	autoAlignLoops = Dialog.getNumber();
	autoAlignScaleStepSize = Dialog.getNumber();
	autoAlignProportion = 1-(2*autoAlignScaleStepSize);
	autoAlignCustomZone = Dialog.getCheckbox();
	if(autoAlignOption == "None")
		autoAlignCustomZone = 0;
}



	//saveConfig = Dialog.getCheckbox();
	saveConfig = 1;
	imageOutput = Dialog.getChoice();
	imageName = Dialog.getString();
	renameRAWs = Dialog.getCheckbox();

	imageName = replace(imageName," ", "_"); // remove spaces as DCRAW doens't like them


// SAVE PREVIOUSLY USED SETTINGS
dataFile = File.open(settingsFilePath);

	print(dataFile, defaultSettings[0]);
	print(dataFile, defaultSettings[1]);
	print(dataFile, defaultSettings[2]);
	print(dataFile, defaultSettings[3]);
	print(dataFile, defaultSettings[4]);
	print(dataFile, defaultSettings[5]);
	print(dataFile, defaultSettings[6]);
	if(imageNames.length > 1){
		print(dataFile, autoAlignOption);
		print(dataFile, autoAlignOffset);
		print(dataFile, autoAlignLoops);
		print(dataFile, autoAlignScaleStepSize);
		print(dataFile, autoAlignCustomZone);
	} else {
		print(dataFile, defaultSettings[7]);
		print(dataFile, defaultSettings[8]);
		print(dataFile, defaultSettings[9]);
		print(dataFile, defaultSettings[10]);
		print(dataFile, defaultSettings[11]);
	}
	print(dataFile, saveConfig);
	print(dataFile, imageOutput);
	print(dataFile, imageName);
	print(dataFile, renameRAWs);
	//print(dataFile, dcrawOptions);

File.close(dataFile);

// If no alignment is required the mspec can be created straight away...

//    ----------if(autoAlignOption == "None" || 

// LOAD CAMERA CONFIGURATION SETTINGS

	settingsPath = infoPath+"/"+settingsChoice+".txt";

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
	saveSliceLabels = newArray(stackSize);
	photoNames = newArray(nPhotos);

// Save settings for first image

alignInfo = newArray("0", "0", "1"); // x off, y off, scale
channelNames = newArray("R","G","B");
photoSettings = split(settingsString[1], "\t"); // settings for first photo
alignCheckSlices = newArray();

for(i=0; i<3; i++)
if(parseInt(photoSettings[i+1]) > 0){ // channel is to be added

	// create label that stores all the relevant linearisation, normalisation, alignment & scale data

	labelString = "label=" + photoSettings[0] + ":" + channelNames[i] + ":" + alignInfo[0] + ":" + alignInfo[1] + ":" + alignInfo[2];

	for(k=0; k<standardLevels.length; k++){
		tempMeasures = standardMeasurements[k];
		tempMeasures = split(tempMeasures, " ");
		labelString = labelString + ","+ standardLevels[k] + ":" + tempMeasures[i];
	}//k

	saveSliceLabels[parseInt( photoSettings[i+1])-1] = labelString; // save slice data for config file

	
}//i




if(imageNames.length > 1){ // Multiple photos
if(autoAlignOption != "None"){
// Open first image

	//dcrawString = "open=[" +imagePaths[0] + "] use_temporary_directory white_balance=None do_not_automatically_brighten output_colorspace=raw read_as=[16-bit linear] interpolation=[High-speed, low-quality bilinear]" ;
	//run("DCRaw Reader...", dcrawString);
	dcrawString = "select=[" + imagePaths[0] + "] camera";
	run("DCRAW import", dcrawString);

	firstPhotoID = getImageID();

	// IMAGE ALIGNMENT
	// Align all subsequent images to the first
	// alignment x,y and scale are saved after slice name, e.g. visible:R:3:5:0.9876,grey values...

	if(autoAlignCustomZone == 1){
		selectImage(firstPhotoID);
		setBatchMode("show");
		setTool("rectangle");
		waitForUser("Custom Alignment Zone", "Draw a box over the area to use for alignment");
		getSelectionBounds(xAlign, yAlign, wAlign, hAlign);
	}
}// alignment required

	for(j=1; j<nPhotos; j++){
		photoSettings = split(settingsString[j+1], "\t"); // settings for current photo
		alignCheckSlices = Array.concat(alignCheckSlices, parseInt(photoSettings[4]));
		alignCheckSlices = Array.concat(alignCheckSlices, parseInt(photoSettings[parseInt(photoSettings[5])])); // work out what position this slice will have

		if(autoAlignOption != "None"){
		//dcrawString = "open=[" +imagePaths[j] + "] use_temporary_directory white_balance=None do_not_automatically_brighten output_colorspace=raw read_as=[16-bit linear] interpolation=[High-speed, low-quality bilinear]" ;
		//run("DCRaw Reader...", dcrawString);
		dcrawString = "select=[" + imagePaths[j] + "] camera";
		run("DCRAW import", dcrawString);
		photoID = getImageID();


		selectImage(firstPhotoID);
		setSlice(photoSettings[4]);

		if(autoAlignCustomZone == 1)
			makeRectangle(xAlign, yAlign, wAlign, hAlign);
		else
			run("Select All");

		run("Copy");
		run("Internal Clipboard");
		rename("align1");

		selectImage(photoID);
		setSlice(parseInt(photoSettings[5])); // the slice to be aligned to the reference, specified in the script

		if(autoAlignCustomZone == 1)
			makeRectangle(xAlign, yAlign, wAlign, hAlign);
		else
			run("Select All");

		run("Copy");
		run("Internal Clipboard");
		rename("align2");

		if(autoAlignOption == "Auto-Align"){
			alignString =  "offset=" + autoAlignOffset + " loops=" + autoAlignLoops +" scale_step_size=" + autoAlignScaleStepSize + " proportion=" + autoAlignProportion;
			run("Auto Align", alignString);
		}
		if(autoAlignOption == "Manual Align"){
			selectImage(firstPhotoID);
			setBatchMode("show");
			selectImage(photoID);
			setBatchMode("show");
			selectImage("align1");
			setBatchMode("show");
			selectImage("align2");
			setBatchMode("show");
			setBatchMode(false);
			run("Manual Align");
			//waitForUser("Select the \"Manual Align\" image, then use\nW, A, S, Z, keys to shift and align the image");
			setBatchMode(true);
			selectImage("ManualAlign");
			close();
		}



		selectImage("align1");
		close();
		selectImage("align2");
		close();

		// extract alignment info
		selectWindow("Alignment Results");
		alignInfo = getInfo("window.contents");
		alignInfo = split(alignInfo, "\n"); // split rows
		alignInfo = split(alignInfo[1], "\t"); // split second row into data
		run("Close");
		
		scaleShift = parseFloat(alignInfo[2]);

		if(autoAlignCustomZone == 1 && scaleShift != 1){ // coords need updating if a custom zone was used and the scale was changed
			w = getWidth();
			h = getHeight();
			xImageShift = (w-(w*scaleShift))/2;
			yImageShift = (h-(h*scaleShift))/2;
			xZoneShift = (wAlign-(wAlign*scaleShift))/2;
			yZoneShift = (hAlign-(hAlign*scaleShift))/2;
			xShiftDiff = xZoneShift - xImageShift;
			yShiftDiff = yZoneShift - yImageShift;
		
			alignInfo[0] = round(parseFloat(alignInfo[0])+xShiftDiff);
			alignInfo[1] =round( parseFloat(alignInfo[1])+yShiftDiff);
		}// custom zone
		}// alignment required

		if(autoAlignOption != "None"){
			selectImage(photoID);
			close();
		}


		// Save information

		for(i=0; i<3; i++)
		if(parseInt(photoSettings[i+1]) > 0){ // channel is to be added

			// create label that stores all the relevant linearisation, normalisation, alignment & scale data

			labelString = "label=" + photoSettings[j-1] + ":" + channelNames[i] + ":" + alignInfo[0] + ":" + alignInfo[1] + ":" + alignInfo[2];

			for(k=0; k<standardLevels.length; k++){
				tempMeasures = standardMeasurements[(standardLevels.length*j)+k];
				tempMeasures = split(tempMeasures, " ");
				labelString = labelString + ","+ standardLevels[k] + ":" + tempMeasures[i];
			}//k

			saveSliceLabels[parseInt( photoSettings[i+1])-1] = labelString; // save slice data for config file

	
		}//i

	}//j

	if(autoAlignOption != "None"){
		selectImage(firstPhotoID);
		close();
	}

}// multiple photos

//Array.print(saveSliceLabels);

//--------------------------------------------------------------------------------------------------------------------


// SAVE CONFIGURATION FILE

configFilePath =  fileDir + imageName + ".mspec";
while(File.exists(configFilePath) == 1){
	//showMessageWithCancel("Overwrite?", "A .mspec configuration file with that name\nalready exists, should it be overwritten?");

	overwriteChoice = getBoolean("A .mspec configuration file with that name\nalready exists, should it be overwritten?\n \nSelect \"No\" to rename this file");

	if(overwriteChoice == 1) // overwrite
		File.delete(configFilePath);

	if(overwriteChoice == 0){ // rename
		Dialog.create("Rename Configuration file");
		Dialog.addString("New name", "", 20);
		Dialog.show();

		imageName = Dialog.getString();
		configFilePath =  fileDir + imageName + ".mspec";
	}//rename
}

if(saveConfig == 1){

if(renameRAWs ==1){

	photoNamesString = imageName + imageNames[0];

	for(i=1; i<imageNames.length; i++)
		photoNamesString = photoNamesString + "\t" + imageName + imageNames[i];
} else {
	photoNamesString = imageNames[0];

	for(i=1; i<imageNames.length; i++)
		photoNamesString = photoNamesString + "\t" + imageNames[i];
}


saveSlicelabelsString = saveSliceLabels[0];
for(i=1; i<stackSize; i++)
	saveSlicelabelsString = saveSlicelabelsString + "\t" + saveSliceLabels[i];



configFile = File.open(configFilePath);

	print(configFile, settingsChoice);
	print(configFile, photoNamesString);
	print(configFile, saveSlicelabelsString);
	print(configFile, "RAW Photo");

File.close(configFile);

// RENAME FILES

if(renameRAWs ==1)
	for(i=0; i<photoNames.length; i++)
		File.rename(fileDir + imageNames[i], fileDir + imageName + imageNames[i]);

}// save config


// OUTPUT options: "Config file only", "Unaligned Linear 16-bit", "Aligned Linear 16-bit", "Aligned 32-bit", "Aligned 16-bit", "Aligned 8-bit"

transformInfo = "";

if(imageOutput != "Config file only"){
	loadString = "select=[" + configFilePath + "] image=[" + imageOutput + "]";
	//print(loadString);
	run(" Load Multispectral Image", loadString);
	outImage = getImageID();
	selectImage(outImage);
}


print("\\Clear");

print("__________Config file saved to:__________");
print(configFilePath);


if(imageOutput != "Config file only"){
	print("________________________________________");
	print("Select regions of interest and press any");
	print("key to add them to the ROI manager.\n ");
	print("Draw a line along the scale bar and press");
	print("\"S\" if you're planning to measure pattern.\n ");
	print("To measure eggs and save their coordinates");
	print("press \"E\". Make sure a scale bar is selected\nbeforehand. Place a point on the tip and base\nof the egg, then three more down each side.\n ");
	print("Press \"0\" to save your selections linked");
	print("to the image. Leave this log window open");
	print("while adding selections without needing");
	print("to use the save dialog.");

	print("________________________________________");

	print(transformInfo);

	while(roiManager("count") > 0){
		roiManager("select", 0);
		roiManager("Delete");	
	}
	run("Select None");
	run("Save ROIs");
	setSlice(1);
}

setOption("Changes", false);// reset changes flag so (hopefully) the save image dialog won't come up
showProgress(1); // clear progress bar (it seems to stick)
showStatus("Finished creating multispectral image");

//setBatchMode(false);
setBatchMode(true);

run("Rounded Rect Tool...", "stroke=1 corner=2 color=blue fill=none"); // this seems to make the rectangle visible again!
run("Rounded Rect Tool...", "stroke=1 corner=1 color=blue fill=none");
setTool("roundrect");

run("Photo Screening Buttons");

if(imageOutput != "Config file only"){
	selectImage(outImage);
	setBatchMode("show");
}
setBatchMode(false);

