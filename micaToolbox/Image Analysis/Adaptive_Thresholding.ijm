

// LOAD PREVIOUSLY USED VALUES

settingsFilePath = getDirectory("plugins") + "micaToolbox/Image Analysis/adSettings.txt";
if(File.exists(settingsFilePath) == 1){
	settingsString=File.openAsString(settingsFilePath);	// open txt data file
	defaultSettings=split(settingsString, "\n");
} else defaultSettings = newArray(
"1",	// 0 high pass
"100",	// 1 low pass
"1.1",	// 2 threshold
"0");	// 3 slice

setBatchMode(true);

if(parseInt(defaultSettings[3]) > nSlices);
	defaultSettings[3] = 1;

sliceNames = newArray(nSlices);

for(i=0; i<nSlices; i++){
	setSlice(i+1);
	if(getMetadata("Label") == "")
		sliceNames[i] = i+1;
	else sliceNames[i] = getMetadata("Label");
	
}

Dialog.create("Adaptive Thresholding");
	Dialog.addNumber("High_Pass", defaultSettings[0]);
	Dialog.addNumber("Low_Pass", defaultSettings[1]);
	Dialog.addNumber("Threshold", defaultSettings[2]);
	//Dialog.addCheckbox("Apply to all ROIs", parseInt(defaultSettings[3]));
	Dialog.addChoice("Image channel", sliceNames, sliceNames[defaultSettings[3]]);
Dialog.show();


highPass = Dialog.getNumber();
lowPass = Dialog.getNumber();
threshold = Dialog.getNumber();
//allROIs = Dialog.getCheckbox();
channelName = Dialog.getChoice();

channel = 1;
for(i=0; i<nSlices; i++)
	if(sliceNames[i] == channelName)
		channel = i+1;
		

// SAVE PREVIOUSLY USED SETTINGS
dataFile = File.open(settingsFilePath);
	print(dataFile, highPass);
	print(dataFile, lowPass);
	print(dataFile, threshold);
	//print(dataFile, allROIs);
	print(dataFile, channel);
File.close(dataFile);

setBackgroundColor(0,0,0);
origImage = getImageID();

nSelections = roiManager("count");
selNames = newArray(nSelections);


eggCount = 0;
eggLoc = newArray(0);

for(i=0; i<nSelections; i++){
	roiManager("select", i);
	selNames[i] = getInfo("selection.name");

	if(startsWith(selNames[i] , "Scale") == 0){ // record target selection areas
		eggCount ++;
		eggLoc = Array.concat(eggLoc, i);
	}
}



for(i=0; i<eggLoc.length; i++){

	roiManager("select", eggLoc[i]);
	run("Make Inverse");
	run("Make Inverse");


	getSelectionBounds(boundsX, boundsY, boundsW, boundsH);

	setSlice(channel);
	run("Duplicate...", " ");
	tempImage = getImageID();
	if(selectionType() > 0)
		run("Clear Outside");
	run("Gaussian Blur...", "sigma=&lowPass");

	selectImage(origImage);
	setSlice(channel);
	run("Duplicate...", " ");
	if(selectionType() > 0)
		run("Clear Outside");
	run("Gaussian Blur...", "sigma=&highPass");
	if(selectionType() > 0)
		run("Select All");
	run("Copy");
	close();

	selectImage(tempImage);
	setPasteMode("Divide");
	run("Paste");

	setThreshold(threshold, 10E10);
	run("Create Selection");
	Roi.move(boundsX, boundsY);
	roiManager("Add");
	close();

	selectImage(origImage);
	roiManager("select", roiManager("count")-1);
	roiManager("rename", selNames[eggLoc[i]] + "-Dark");

	roiManager("select", newArray(eggLoc[i], roiManager("count")-1) );
	roiManager("XOR");
	roiManager("Add");
	roiManager("select", roiManager("count")-1);
	roiManager("rename", selNames[eggLoc[i]] + "-Light");

}//egg

setPasteMode("Copy");
