/*
_______________________________________________________________________

	Title: Photo Screening
	Author: Jolyon Troscianko
	Date: 31/7/2017
.................................................................................................................

Description:
''''''''''''''''''''''''''''''''
Loads RAW image previews from a folder of RAW images, showing histograms and highlighting
any regions with over-exposed pixel values. This makes it easy to judge which images will
have the best exposures to use for measurement.

The previews can also be used ot generate mspec images from the RAW images by selecting
which images to use, measuring the standards, and clicking "Create MSPEC".

Instructions:
''''''''''''''''''''''''''''''''''''''''
Select a folder with RAW files and select the grey standard values.

Wait for the iamges to finish loading. Loading large numbers of images will take time.

If the buttons aren't functional, simply re-run the script.

Use the checkboxes on the right to specify which images to use for generating an mspec
image. Highlight the standard in the relevant image and clcik the relevant checkbox. Note
that if you use a differnet image for measuring the standard it must have exactly the same
settings. The camera settings used are currently only shown if there are no spaces in the
folder paths of the selected image folder.

Once everything is selected click "Create MSPEC", and this will lead to alignment options (if any)
and output options.
_________________________________________________________________________
*/

requires("1.52");

// -----------------------Restart buttons if the screening image is open----------------------------

imageNames = getList("image.titles");

for(i=0; i<imageNames.length; i++)
	if(imageNames[i] == "Photo Screening"){
		selectImage("Photo Screening");
		run("Rounded Rect Tool...", "stroke=1 corner=2 color=blue fill=none");
		run("Rounded Rect Tool...", "stroke=1 corner=1 color=blue fill=none");
		setTool("roundrect");
		run("Photo Screening Buttons");
		exit();
	}



//----------------------- Get Info ----------------------------------

/*
// LOAD PREVIOUSLY USED VALUES

settingsFilePath = getDirectory("plugins") + "micaToolbox/importSettings.txt";
if(File.exists(settingsFilePath) == 1){
	settingsString=File.openAsString(settingsFilePath);	// open txt data file
	defaultSettings=split(settingsString, "\n");
	dcrawOptions = defaultSettings[16];
} else dcrawOptions = "use_temporary_directory white_balance=None do_not_automatically_brighten output_colorspace=raw read_as=[16-bit linear] interpolation=[High-speed, low-quality bilinear] do_not_rotate"; // dcraw string
*/

// LOAD PREVIOUSLY USED VALUES

settingsFilePath = getDirectory("plugins") + "micaToolbox/screeningSettings.txt";
if(File.exists(settingsFilePath) == 1){
	settingsString=File.openAsString(settingsFilePath);	// open txt data file
	defaultSettings=split(settingsString, "\n");
} else defaultSettings = newArray(
"Visible & UV",	// settings choice
"NEF,CR2,SRW", // RAW extensions
"0",	// estimate black
"20,80", 	// grey levels
"1000");	// preview size


infoPath = getDirectory("plugins")+"micaToolbox/cameras";
infoList=getFileList(infoPath);
infoNames = newArray(infoList.length);

		for(a=0; a<infoList.length; a++)
			infoNames[a] = replace(infoList[a], ".txt","");

Dialog.create("Photo Screening Options");
	Dialog.addMessage("___________Camera and filter combination___________");
	Dialog.addChoice("Settings", infoNames, defaultSettings[0]);
	Dialog.addString("RAW_file extensions", defaultSettings[1], 20);
	Dialog.addMessage("Select the RAW file extensions to load, separate\nthem with a comma");
	Dialog.addMessage("_______________Grey Standard Options_______________");
	Dialog.addCheckbox("Estimate black point", defaultSettings[2]);
	Dialog.addMessage("Black point estimation is useful to reduce loss of\ncontrast when one standard is used");
	Dialog.addString("Standard reflectance(s)", defaultSettings[3], 20);
	Dialog.addMessage("Separate standard values with a comma");
	Dialog.addMessage("__________________Preview Options__________________");
	Dialog.addNumber("Preview size (px width)", defaultSettings[4]);
	Dialog.addMessage("Choose a size that fits your monitor");

Dialog.show();

settingsChoice = Dialog.getChoice();
rawExtensions = Dialog.getString();
zeroEst = Dialog.getCheckbox();
standardString = Dialog.getString();
thumbWidth = Dialog.getNumber();

// SAVE PREVIOUSLY USED SETTINGS
dataFile = File.open(settingsFilePath);

	print(dataFile, settingsChoice);
	print(dataFile, rawExtensions);
	print(dataFile, zeroEst);
	print(dataFile, standardString);
	print(dataFile, thumbWidth);

File.close(dataFile);

// LOAD CAMERA CONFIGURATION SETTINGS

	settingsPath = infoPath+"/"+settingsChoice+".txt";

	settingsString=File.openAsString(settingsPath);
	settingsString=split(settingsString, "\n"); // split settings into rows

	filterNames = newArray(settingsString.length-1);
	for(i=1; i<settingsString.length; i++){
		rowString = split(settingsString[i], "\t");
		filterNames[i-1] = rowString[0];
	}


// Standard reflectance values

	standardString = replace(standardString, " ", ""); // remove any spaces
	standardString = split(standardString, ",");

	standardLevels = newArray(standardString.length);
	for(i=0; i<standardString.length; i++)
		standardLevels[i] = parseFloat(standardString[i]);

	if(zeroEst == 1)
		standardLevels = Array.concat(0, standardLevels);

rawExtensions = replace(rawExtensions, " ", ""); //remove spaces
rawExtensions = split(rawExtensions, ",");

fileDir = getDirectory("Select DIR");

fileList = getFileList(fileDir);

pathSplit = split(fileDir, " ");
verbose = 0;
//if(pathSplit.length == 1)
//	verbose=1;


rawList = newArray();



//--------------------------------- Open RAW images-----------------------------------

for(i=0; i<fileList.length; i++) // list raw files
	for(j=0; j<rawExtensions.length; j++)
		if(endsWith(fileList[i], rawExtensions[j]) == 1)
			rawList = Array.concat(rawList, fileList[i]);

//Array.show(rawList);





setBatchMode(true);

overExposed = newArray(3);

for(i=0; i< rawList.length; i++){


	//IJ.redirectErrorMessages();
	//if(verbose == 1){
	//	print("\\Clear");
	//	dcrawString = "open=[" + fileDir + rawList[i] + "] " + dcrawOptions + " show_metadata";
	//}else	
	//	dcrawString = "open=[" + fileDir + rawList[i] + "] " + dcrawOptions;
	//run("DCRaw Reader...", dcrawString );
	dcrawString = "select=[" + fileDir + rawList[i] + "] camera";
	run("DCRAW import", dcrawString);

	rawID = getImageID();

	if(verbose == 1){
		metaData = getInfo("log");
		print("\\Clear");
		metaData = split(metaData, "\n");
	}

	w = getWidth();
	h = getHeight();

	if(h>w){ // Ensure all images are landscape, as canon pics are auto-rotated
		run("Rotate 90 Degrees Left");
		w = getWidth();
		h = getHeight();
	}
		


	scaledHeight = round(h*(thumbWidth/w));

	if(i==0){
		newImage("Photo Screening", "RGB black", thumbWidth + 270, scaledHeight + 80, rawList.length+1);
		thumbStack = getImageID();

		//-----------------Save screening options in metadata------------------

		dataString = fileDir + "," + settingsChoice + "," + thumbWidth + "," + scaledHeight + "\n";

		for(j=0; j<filterNames.length; j++){
			dataString = dataString + filterNames[j] + ":not set";
			for(k=0; k<standardLevels.length; k++)
				dataString = dataString + "," + standardLevels[k]  + ":not set";
			if(j<filterNames.length -1)
				dataString = dataString + "\n";
		}

		setMetadata("Info", dataString);

		//---------------------Screening title page----------------------

		titlePath =  getDirectory("plugins") + "micaToolbox/Photo Screening Page.png";
		open(titlePath);
	
		tw = getWidth();
		th = getHeight();
		titleHeight = round(th*(thumbWidth/tw));

		run("Scale...", "x=- y=- z=1.0 width=&thumbWidth height=&titleHeight depth=1 interpolation=None average create title=scaled");
		run("Select All");
		run("Copy");
		close();
		
		selectImage(thumbStack);
		setSlice(1);
		makeRectangle(5, 35, thumbWidth, titleHeight);
		run("Paste");

	}

	newImage("hist", "RGB white", 256, 127, 1);
	run("RGB Stack");
	histID = getImageID();

	setPasteMode("Subtract");

	for(j=1; j<=3; j++){
		selectImage(rawID);
		setSlice(j);

		getHistogram(values, counts, 256, 0, 65535);
		overExposed[j-1] = 100* (counts[255]/ (w*h));

		run("Histogram", "slice");
		makeRectangle(20, 11, 256, 127);
		run("Copy");
		close();

		selectImage(histID);
		setSlice(j);
		run("Paste");
	}//j

	selectImage(histID);
	run("RGB Color");
	run("Select All");
	run("Copy");
	setPasteMode("Copy");
	close();

	selectImage(thumbStack);
	setSlice(i+2);
	makeRectangle(thumbWidth + 10, 35, 256, 127);
	run("Paste");
	
	setColor(128,128,128);
	setLineWidth(1);
	drawRect(thumbWidth + 9, 34, 258, 129);
		

	//-----------Create preview image----------

	satThreshold = 254;

	selectImage(rawID);

	run("Scale...", "x=- y=- z=1.0 width=&thumbWidth height=&scaledHeight depth=3 interpolation=Bilinear average create title=scaled");
	scaledID = getImageID();

	run("Square Root");

	for(j=1; j<=3; j++){
		setSlice(j);
		setMinAndMax(0, 255);
	}//j

	run("RGB Color");
	scaledRGB = getImageID();
	selectImage(scaledID);
	close();

	selectImage(scaledRGB);
	run("RGB Exposure Test");

	run("Select All");
	run("Copy");
	close();
	selectImage(thumbStack);
	setSlice(i+2);
	makeRectangle(5, 35, thumbWidth, scaledHeight);
	run("Paste");
	drawRect(4, 34, thumbWidth+2, scaledHeight+2);

	setColor(255,255,255);
	setFont("SansSerif", 16, "bold");
	drawString(rawList[i], 18, 26);

	
	if(overExposed[0] > 0.05 || overExposed[1] > 0.05 || overExposed[2] > 0.05)
		setColor(255,255,255);
	else setColor(128,128,128);


	setFont("SansSerif", 10);
	drawString("Over exposed pixels (%):", thumbWidth+10, 30);

	setFont("SansSerif", 14);

	if(overExposed[0] < 0.05)
		setColor(128,128,128);
	else setColor(255,0,0);
		drawString(d2s(overExposed[0],2), thumbWidth+138, 30);

	if(overExposed[1] < 0.05)
		setColor(128,128,128);
	else setColor(0,255,0);
		drawString(d2s(overExposed[1],2), thumbWidth+178, 30);

	if(overExposed[2] < 0.05)
		setColor(128,128,128);
	else setColor(0,0,255);
		drawString(d2s(overExposed[2],2), thumbWidth+218, 30);

	if(verbose == 1){
		setColor(255,255,255);
		for(j=0; j<metaData.length; j++){
			if(startsWith(metaData[j], "ISO") == 1)
				drawString(metaData[j], thumbWidth+18, 190);
			if(startsWith(metaData[j], "Shutter") == 1)
				drawString(metaData[j], thumbWidth+18, 210);
			if(startsWith(metaData[j], "Aperture") == 1)
				drawString(metaData[j], thumbWidth+18, 230);
			if(startsWith(metaData[j], "Focal") == 1)
				drawString(metaData[j], thumbWidth+18, 250);
		}
	}
	
	setMetadata("Label", ":" + rawList[i] + ":");
	run("Select None");

	Overlay.remove;
	setColor(200,0,0);
	Overlay.drawString("Loading RAW images", thumbWidth+18, 280);
	Overlay.drawString("Image " + (i+1) + " of " + rawList.length, thumbWidth+18, 300);

	setColor(128,128,128);
	Overlay.drawString("The histogram shows linear values", thumbWidth+18, 340);
	Overlay.drawString("and the preview image is square-", thumbWidth+18, 360);
	Overlay.drawString("root transformed (non-linear).", thumbWidth+18, 380);
	Overlay.drawString("If the buttons stop respoding re- ", thumbWidth+18, 400);
	Overlay.drawString("run this script to re-activate them", thumbWidth+18, 420);
/*
	if(verbose == 0){
		setColor(200,0,0);
		Overlay.drawString("Currently photo setting data are", thumbWidth+18, 440);
		Overlay.drawString("only shown if there are no spaces", thumbWidth+18, 460);
		Overlay.drawString("in the image path (IJ-dcraw bug).", thumbWidth+18, 480);
	}
*/
	Overlay.show;

	setBatchMode("show");

	selectImage(rawID);
	close();

}//i

setSlice(1);
setOption("Changes", false);// reset changes flag so (hopefully) the save image dialog won't come up
showProgress(1); // clear progress bar (it seems to stick)
showStatus("Finished loading images");
// for some reason when this is called like this rectangle regions aren't visible... changing the round rect values fixes this

run("Rounded Rect Tool...", "stroke=1 corner=2 color=blue fill=none");
run("Rounded Rect Tool...", "stroke=1 corner=1 color=blue fill=none");
setTool("roundrect");

run("Photo Screening Buttons");

