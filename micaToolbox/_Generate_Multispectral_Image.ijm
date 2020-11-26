/*
_______________________________________________________________________

	Title: Generate Multispectral Image
	Author: Jolyon Troscianko
	Date: 16/10/2014
	update: 26/9/18 - lots of updates: e.g. converting to reflectance
		numbers (0-100%) in normalisation, cone-catch
		on 0-1 scale. Various bug fixes in other parts of
		the toolbox. The settings options have been simplified
		slightly. Support for non-linear images has been 
		improved (sRGB and linear image support).
	update:20/10/20 - major overhaul of mspec system, with more flexble
		metadata-based information sharing between scripts
		and support for affine transform alignment 
.................................................................................................................

Description:
''''''''''''''''''''''''''''''''
This code generates multispectral images that are linear, normalised and aligned from
any combination of photos and filters. These images can be used for analysis directly,
or used for converting to animal cone-catch quanta.

As long as none of the photos are over-exposed, the processing will not result in data
loss when measuring reflectances above 100% relative to the standard (which is
common with shiny objects, or when the standard isn't as well lit as other parts of the
image). This is because all images are opened and processed as 32-bit floating point
straight from the RAW files, so no (very)large intermediate TIFF images ever need to be
saved.

Using two or more standards (or one standard with black point estimates) overcomes
the problem of the unknown black point of the camera sensor, making the method
robust in the field with various factors reducing contrast.

Photographing through reflective surfaces, or through slightly opaque media is also
made possible by using two or more grey standards. This allows photography through
water from the air (as long as the reflected sky/background is uniform), underwater, or
though uniformly foggy/misty atmospheric conditions.

Multi/hyperspectral cameras with almost any number of bands are supported by the
code and can be used for greater colour measurement confidence.

These tools will be published soon, but in the meantime they can only be used and
distributed with our permission.

Please let me know if you need any specific camera cone mapping combinations and
report bugs/suggestions to me (jt@jolyon.co.uk)

Instructions:
''''''''''''''''''''''''''''''''''''''''
See the included user guide for a full overview. There are loads of supported options.

A .mspec file is generated alongside the RAW files. These files need to be kept together
in the same folder for the .mspec configuration file to link to the RAW files correctly.

_________________________________________________________________________
*/

requires("1.52");

// DCRAW import linear:
//run("DCRaw Reader...", "open=[/media/jolyon/NIKON D70001/2 grey temp/IMG_3146.CR2] use_temporary_directory white_balance=None do_not_automatically_brighten output_colorspace=raw read_as=[16-bit linear] interpolation=[High-speed, low-quality bilinear]");


// LOAD PREVIOUSLY USED VALUES

settingsFilePath = getDirectory("plugins") + "micaToolbox/importSettings.txt";
if(File.exists(settingsFilePath) == 1){
	settingsString=File.openAsString(settingsFilePath);	// open txt data file
	defaultSettings=split(settingsString, "\n");
} else defaultSettings = newArray(
"Visible",	// settings choice
"Same photo",	// grey loaction
"0",	// estimate black
"20,80", 	// grey levels
"0", 	// customise RGB levels
"0", 	// standards move
"1",	// images sequential
"None",	// align
"16",	// offset
"4",	// loops
"0.005",	// scale step size
"1",	// custom zone
"RAW Photo",	// use non-linear function
"Linear Normalised Reflectance Stack", // image output
"",	// default name
"0");	// rename RAW files
//"use_temporary_directory white_balance=None do_not_automatically_brighten output_colorspace=raw read_as=[16-bit linear] interpolation=[High-speed, low-quality bilinear] do_not_rotate"); // dcraw string

//dcrawOptions = defaultSettings[16];

//  USER OPTIONS

	infoPath = getDirectory("plugins")+"micaToolbox/cameras";
	infoList=getFileList(infoPath);
	infoNames = newArray(infoList.length);

		for(a=0; a<infoList.length; a++)
			infoNames[a] = replace(infoList[a], ".txt","");

	inImType = newArray("RAW Photo", "Linear Image", "Custom Non-linear", "sRGB");


	greyChoice = newArray("Same photo", "Separate photos");
	offsetOptions = newArray("4","8","16","32","64","128","256","512","1024");
	outputOptions = newArray(
		"Linear Normalised Reflectance Stack",
		"Linear Stack",
		"Linear Colour Image",
		"Non-linear Colour Image",
		"Non-linear Colour VIS-UV Image");

	//lineariseOptions = newArray("Linearise Only", "Linearise & Normalise");
	alignOptions = newArray("None", "Auto-Align", "Manual Align", "Affine Align");

	helpPage = "http://www.empiricalimaging.com/knowledge-base/creating-a-calibrated-image/";

	Dialog.create("Multispectral Image Generation");
		Dialog.addChoice("Camera type", infoNames, defaultSettings[0]); // change the last value here to change the default
		Dialog.addChoice("Image type", inImType, defaultSettings[12]); // change the last value here to change the default
				
		Dialog.addMessage("_________________Grey Standards_________________");
		Dialog.addChoice("Grey standards in:", greyChoice, defaultSettings[1]);
		Dialog.addCheckbox("Estimate black point (useful with one standard)", defaultSettings[2]);
		Dialog.addString("Standard reflectance(s)", defaultSettings[3], 20);
		Dialog.addCheckbox("Customise standard levels", defaultSettings[4]);
		Dialog.addCheckbox("Standards move between photos", defaultSettings[5]);

		Dialog.addMessage("________________Alignment & Scaling______________ ");
		Dialog.addChoice("Alignment", alignOptions, defaultSettings[7]);

		Dialog.addMessage("___________________Output_________________ ");
		Dialog.addChoice("Image output", outputOptions, defaultSettings[13]);
		Dialog.addString("Image Name", defaultSettings[14], 20);
		Dialog.addCheckbox("Rename Image files", defaultSettings[15]);
 		Dialog.addHelp(helpPage);

	Dialog.show();

	settingsChoice = Dialog.getChoice();
	nonLin = Dialog.getChoice();
	greyLocation = Dialog.getChoice();
	estimateBlack = Dialog.getCheckbox();
	standardString = Dialog.getString();
	customiseLevels = Dialog.getCheckbox();
	customiseLocation = Dialog.getCheckbox();
	//imagesSequential = Dialog.getCheckbox();

	autoAlignOption = Dialog.getChoice();

	imageOutput = Dialog.getChoice();
	imageName = Dialog.getString();
	renameRAWs = Dialog.getCheckbox();

	if(greyLocation == "Separate photos")
		imagesSequential = 0; // this would make life more complicated...

	imageName = replace(imageName," ", "_"); // remove spaces as DCRAW doens't like them

rgbFlag = 0;

if(autoAlignOption != "None"){

	Dialog.create("Alignment Options");

		Dialog.addMessage("___________________Image Location________________ ");
		Dialog.addCheckbox("Images sequential (alphabetically) in directory", defaultSettings[6]);

		if(autoAlignOption == "Auto-Align"){
			Dialog.addMessage("________________Alignment & Scaling______________ ");
			Dialog.addChoice("Offset", offsetOptions, defaultSettings[8]);
			Dialog.addNumber("Scaling loops (1=off)", defaultSettings[9]);
			Dialog.addNumber("Scale_step_size",defaultSettings[10]);
		}


		if(autoAlignOption != "Affine Align")
			Dialog.addCheckbox("Custom alignment zone", defaultSettings[11]);

	Dialog.show();

	imagesSequential = Dialog.getCheckbox();
	if(autoAlignOption == "Auto-Align"){
		autoAlignOffset = Dialog.getChoice();
		autoAlignLoops = Dialog.getNumber();
		autoAlignScaleStepSize = Dialog.getNumber();
		autoAlignProportion = 1-(2*autoAlignScaleStepSize);
	} else {
		autoAlignOffset = defaultSettings[8];
		autoAlignLoops = defaultSettings[9];
		autoAlignScaleStepSize = defaultSettings[10];
		autoAlignProportion = 1-(2*autoAlignScaleStepSize);
	}
	if(autoAlignOption != "Affine Align")
		autoAlignCustomZone = Dialog.getCheckbox();
	else autoAlignCustomZone = 0;

} else {

	imagesSequential = defaultSettings[6];
	autoAlignOffset = defaultSettings[8];
	autoAlignLoops = defaultSettings[9];
	autoAlignScaleStepSize = defaultSettings[10];
	autoAlignProportion = 1-(2*autoAlignScaleStepSize);
	autoAlignCustomZone = defaultSettings[11];


}

// SAVE PREVIOUSLY USED SETTINGS
dataFile = File.open(settingsFilePath);

	print(dataFile, settingsChoice);
	print(dataFile, greyLocation);
	print(dataFile, estimateBlack);
	print(dataFile, standardString);
	print(dataFile, customiseLevels);
	print(dataFile, customiseLocation);
	print(dataFile, imagesSequential);
	print(dataFile, autoAlignOption);
	print(dataFile, autoAlignOffset);
	print(dataFile, autoAlignLoops);
	print(dataFile, autoAlignScaleStepSize);
	//print(dataFile, autoAlignProportion);
	print(dataFile, autoAlignCustomZone);
	//print(dataFile, saveConfig);
	print(dataFile, nonLin);
	print(dataFile, imageOutput);
	print(dataFile, imageName);
	print(dataFile, renameRAWs);
	//print(dataFile, dcrawOptions);

File.close(dataFile);

// LOAD CAMERA CONFIGURATION SETTINGS

	settingsPath = infoPath+"/"+settingsChoice+".txt";

	settingsString=File.openAsString(settingsPath);
	settingsString=split(settingsString, "\n"); // split settings into rows

	// Calculate number of slices required
	stackSize = 0;

	slideNumberString = "";

	for(i=1; i<(settingsString.length); i++){
		settingsTemp = split(settingsString[i], "\t");
		for(j=1; j<=3; j++){
			if(parseInt(settingsTemp[j]) > stackSize)
				stackSize = parseInt(settingsTemp[j]);
			if(slideNumberString == "")
				slideNumberString = settingsTemp[j];
			else slideNumberString = slideNumberString + "," +settingsTemp[j];
		}
	}

	nPhotos = settingsString.length-1;
	saveSliceLabels = newArray(stackSize);
	photoNames = newArray(nPhotos);


// NON-LINEAR IMAGE SETTINGS

	linCameraChoice = newArray(nPhotos);
	linCameraSettings = newArray(nPhotos);

	nonLinSettingsPath = getDirectory("plugins")+"micaToolbox/Linearisation Models";
	nonLinList=getFileList(nonLinSettingsPath);
	nonLinNames = newArray(nonLinList.length);

		for(a=0; a<nonLinList.length; a++)
			nonLinNames[a] = replace(nonLinList[a], ".txt","");



// Standard reflectance values

	standardString = replace(standardString, " ", ""); // remove any spaces
	standardString = split(standardString, ",");

	standardLevels = newArray(standardString.length);
	for(i=0; i<standardString.length; i++)
		standardLevels[i] = parseFloat(standardString[i]);

// Create Array of slices to check for alignment

	alignCheckSlices = newArray();



// CLEAR ROI MANAGER
while(roiManager("count")>0){
	roiManager("select", 0);
	roiManager("Delete");
}


// work out directory of firstPath & subsequent image numbers (if sequential)


// OPEN FIRST IMAGE IF ALPHABETICALLY ORDERED

if(imagesSequential == 1){

	firstPath=File.openDialog("Select first photo"); // get file locations
	firstPhotoString = split(firstPath, "/");
	if(firstPhotoString.length == 1) // windows
		firstPhotoString = split(firstPath, "\\");

	seqDirectory = replace(firstPath, firstPhotoString[firstPhotoString.length-1], "");
	seqDirectoryFullList = getFileList(seqDirectory);
	seqDirectoryList = newArray();

for(i=0; i<seqDirectoryFullList.length; i++)
	if( endsWith(seqDirectoryFullList[i], ".pp3") == 0) // filter out the RAWTherapee .pp3 files
		seqDirectoryList = Array.concat(seqDirectoryList, seqDirectoryFullList[i]);

for(i=0; i<seqDirectoryList.length; i++)
	if(seqDirectoryList[i] == firstPhotoString[firstPhotoString.length-1])
		firstIndex = i;

for(i=0; i<nPhotos; i++)
	photoNames[i] = seqDirectoryList[firstIndex+i];


} // images sequential




// OPEN IMAGES & MEASURE STANDARD(s)

alignSaveString  = "";
labelSaveString = "";
greySaveString = "";

channelNames = newArray("R","G","B");
firstFlag = 1;

for(j=0; j<nPhotos; j++){

	photoSettings = split(settingsString[j+1], "\t"); // settings for current photo

	if(imagesSequential == 1){
		nonLinString = seqDirectory + photoNames[j];
		//dcrawString = "open=[" + seqDirectory + photoNames[j] + "] " + dcrawOptions;
		dcrawString = "select=[" + seqDirectory + photoNames[j] + "] camera auto-level";
	} else {
		imagePath=File.openDialog("Select " + photoSettings[0] +  " photo containing standard" ); // get file locations
		imagePathTemp = split(imagePath, "/");
		if(imagePathTemp.length == 1) // windows
			imagePathTemp = split(imagePath, "\\");

		photoNames[j] = imagePathTemp[imagePathTemp.length-1];
		seqDirectory = replace(imagePath, imagePathTemp[imagePathTemp.length-1], ""); // used later for config file
		//dcrawString = "open=[" + imagePath + "] " + dcrawOptions;
		dcrawString = "select=[" + imagePath + "] camera auto-level";
		nonLinString = seqDirectory + photoNames[j];
	}
	
	//-------------------OPEN RAW OR NON-LINEAR IMAGE-----------------
	if(nonLin == "RAW Photo"){
		//run("DCRaw Reader...", dcrawString);
		setBatchMode(true);
		run("DCRAW import", dcrawString);
		photoID = getImageID();

		//---------------exposure check-----------------
		//setBatchMode(true);
		run("Select All");
		run("Duplicate...", "duplicate");
		eID=getImageID();
		run("Set Min And Max", "min=65534 max=65535");
		run("RGB Color");
		rgbID=getImageID();
		rename("Exposure Test");
		run("Divide...", "value=3");
		selectImage(photoID);
		run("Add Image...", "image=[Exposure Test] x=0 y=0 opacity=100 zero");
		selectImage(eID);
		close();
		selectImage(rgbID);
		close();
		selectImage(photoID);

		run("Square Root", "stack");
		setMinAndMax(0, 10);
		run("Make Composite", "display=Composite");
		setSlice(3);
		setMinAndMax(0, 255);
		setSlice(2);
		setMinAndMax(0, 255);
		setSlice(1);
		setMinAndMax(0, 255);
		setBatchMode(false);

	} else {
		setBatchMode(true);
		open(nonLinString);
		photoID = getImageID();
		if(bitDepth == 24){
			rgbFlag = 1;

			//------------exposure check----------
			run("Select All");
			run("Duplicate...", "duplicate");
			eID=getImageID();
			//setMinAndMax(254, 255);
			//run("Apply LUT");
			run("RGB Exposure Overlay");
			rename("Exposure Test");
			//run("Divide...", "value=3");
			selectImage(photoID);


			run("RGB Stack");
			//run("32-bit");
			//run("Make Composite", "display=Composite");
		} else rgbFlag = 0;
		if(bitDepth != 32)
			run("32-bit");

		if(nonLin == "Custom Non-linear"){
		
			Dialog.create("Linearity Model");
				Dialog.addChoice("Linearity model for " + photoSettings[0], nonLinNames);
			Dialog.show();

			linCameraChoice[j] = Dialog.getChoice();
		} else if(nonLin == "Linear Image")
			linCameraChoice[j] = "Linear TIF";
		else if(nonLin == "sRGB")
			linCameraChoice[j] = "sRGB";
			
		nonLinSettingsString=File.openAsString(nonLinSettingsPath + "/" + linCameraChoice[j] + ".txt");
		linCameraSettings[j] = nonLinSettingsString;
		nonLinSettingsString=split(nonLinSettingsString, ","); // split settings

		selectImage(photoID);
		if(nonLinSettingsString.length != nSlices)
			exit("The chosen linearity model has a different number of channels than the selected image");

		for(a=0; a<nSlices; a++) // linearise image
			run("Linearisation Function", nonLinSettingsString[a]);

		//setBatchMode("show");

		if(rgbFlag == 0)
			run("Enhance Contrast", "saturated=0.35");
		else {
			selectImage(photoID);
			run("Make Composite", "display=Composite");
			photoID = getImageID();
			run("Add Image...", "image=[Exposure Test] x=0 y=0 opacity=100 zero");
			selectImage(eID);
			close();
			selectImage(photoID);

			run("Square Root", "stack");
			setMinAndMax(0, 10);
			run("Make Composite", "display=Composite");
			setSlice(3);
			setMinAndMax(0, 16);
			setSlice(2);
			setMinAndMax(0, 16);
			setSlice(1);
			setMinAndMax(0, 16);
		}
		setBatchMode(false);
		
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

	alignInfo = newArray("0", "0", "1"); // x off, y off, scale

	// IMAGE ALIGNMENT
	// Align all subsequent images to the first
	// alignment x,y and scale are saved after slice name, e.g. visible:R:3:5:0.9876,grey values...

	if(autoAlignOption != "None" && autoAlignCustomZone == 1 && j ==0 && greyLocation == "Same photo" && customiseLocation == 0){
		//setTool("rectangle");
		run("Rounded Rect Tool...", "stroke=1 corner=2 color=blue fill=none");
		run("Rounded Rect Tool...", "stroke=1 corner=1 color=blue fill=none");
		setTool("roundrect");
		//setBatchMode("show");
		run("Select None");
		waitForUser("Custom Alignment Zone", "Draw a box over the area to use for alignment");
		getSelectionBounds(xAlign, yAlign, wAlign, hAlign);
	}


	setBatchMode(true);

	if(j > 0 && autoAlignOption != "None" && greyLocation == "Same photo" && customiseLocation == 0){
		selectImage(newStack);
		setSlice(photoSettings[4]); // the reference slice
		alignCheckSlices = Array.concat(alignCheckSlices, parseInt(photoSettings[4]));
		alignCheckSlices = Array.concat(alignCheckSlices, parseInt(photoSettings[parseInt(photoSettings[5])])); // work out what position this slice will have

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
		if(autoAlignOption != "Affine Align"){
			run("Internal Clipboard");
			rename("align2");
		}
	
		if(autoAlignOption == "Auto-Align"){
			alignString =  "offset=" + autoAlignOffset + " loops=" + autoAlignLoops +" scale_step_size=" + autoAlignScaleStepSize + " proportion=" + autoAlignProportion;
			run("Auto Align", alignString);
		}
		if(autoAlignOption == "Manual Align"){
			selectImage(newStack);
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
			//setBatchMode(true);
			selectImage("ManualAlign");
			close();
		}

		if(autoAlignOption == "Affine Align"){
			selectImage("align1");
			run("Add Slice");
			run("Paste");
			run("Select None");
			run("Enhance Contrast", "saturated=0.35");
	

			selectImage(newStack);
			setBatchMode("show");
			selectImage(photoID);
			setBatchMode("show");
			selectImage("align1");
			setBatchMode("show");
			setBatchMode(false);

//-------------Affine align start---------------

flag=0;

msg = "Select three or more points of alignment in each image, using the multipoint tool \n \nTip: if you have lots of photos with the same offset, you can save and reload the point\nROI in the ROI manager";

setTool("Multipoint");

while(flag==0){

	waitForUser(msg);

	getSelectionCoordinates(xs, ys);

	if(selectionType == 10 && xs.length>=6 && xs.length/2 == round(xs.length/2))
		flag=1;
	else msg = "You need to use the multi-point tool, and ensure there are three or more corresponding points in each slice";


	run("Clear Results");
	run("Set Measurements...", "area mean min redirect=None decimal=9");
	run("Measure");

	zs = newArray(xs.length);

	n1s = 0;
	n2s = 0;
	for(i=0; i<xs.length; i++){
		zs[i] = getResult("Slice", i);
		if(zs[i] == 1)
			n1s++;
		if(zs[i] == 2)
			n2s++;
	}
	if(n1s != n2s){
		flag = 0;
		msg = "There aren't an equal number of anchor points in each slice";
	}

}// waiting for user to select the right type of points

x1 = newArray(n1s);
y1 = newArray(n1s);

x2 = newArray(n1s);
y2 = newArray(n1s);

t1 = 0;
t2 = 0;

for(i=0; i<xs.length; i++){
	if(zs[i] == 1){
		x1[t1] = xs[i];
		y1[t1] = ys[i];
		t1++;
	}

	if(zs[i] == 2){
		x2[t2] = xs[i];
		y2[t2] = ys[i];
		t2++;
	}
		
}



run("Clear Results");

for(i=0; i<x1.length; i++){
	setResult("x", i, x2[i]);
	setResult("x2", i, x1[i]);
	setResult("y2", i, y1[i]);
}

print("\\Clear");
run("multiple regression");
logString = getInfo("log");
logString = split(logString, "\n");
logString = logString[2];
logString = replace(logString, "\\(x2\\*", "");
logString = replace(logString, "\\(y2\\*", "");
logString = replace(logString, "\\)", "");
logString = replace(logString, " ", "");
logString = split(logString, "+");


if(logString.length != 3)
	exit("Error parsing the matrix");

xAffine = newArray(3);
for(i=0; i<3; i++)
	xAffine[i] = logString[i];
	//xAffine[i] = parseFloat(logString[i]);

//Array.show(logString);



run("Clear Results");

for(i=0; i<x1.length; i++){
	setResult("y", i, y2[i]);
	setResult("x2", i, x1[i]);
	setResult("y2", i, y1[i]);
}

print("\\Clear");
run("multiple regression");
logString = getInfo("log");
logString = split(logString, "\n");
logString = logString[2];
logString = replace(logString, "\\(x2\\*", "");
logString = replace(logString, "\\(y2\\*", "");
logString = replace(logString, "\\)", "");
logString = replace(logString, " ", "");
logString = split(logString, "+");


if(logString.length != 3)
	exit("Error parsing the matrix");

yAffine = newArray(3);
for(i=0; i<3; i++)
	yAffine[i] = logString[i];
	//yAffine[i] = parseFloat(logString[i]);

//Array.show(xAffine, yAffine);
print("\\Clear");





//--------------Affine align end--------------------
		}



		selectImage("align1");
		close();
		if(autoAlignOption != "Affine Align"){
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
			}

		}

	}


	rPxs = newArray(standardLevels.length);
	gPxs = newArray(standardLevels.length);
	bPxs = newArray(standardLevels.length);

	rGreys = newArray(standardLevels.length);
	gGreys = newArray(standardLevels.length);
	bGreys = newArray(standardLevels.length);


for(i=0; i<standardLevels.length; i++){

	if(j != 0) // not the first image, so select pre-drawn area
		roiManager("select", i);

	if(j == 0) // first image only
		run("Select None");

	if( customiseLocation == 1 || j == 0 || greyLocation == "Separate photos"){ // first image, or custom location
		//setBatchMode(false);

		if(toolID == 0){
			run("Rounded Rect Tool...", "stroke=1 corner=2 color=blue fill=none");
			run("Rounded Rect Tool...", "stroke=1 corner=1 color=blue fill=none");
			setTool("roundrect");
		}

		setBatchMode("show");
		waitForUser("Select " + standardLevels[i] + "% standard");
		setBatchMode("hide");
		//setBatchMode(true);
	}

	if(j == 0){ // first image only
		roiManager("Add");
		roiManager("select", roiManager("count")-1);
		roiManager("Rename", standardString[i] );
	}
	

	if(customiseLevels == 1){
		Dialog.create("Customise " + standardLevels[i] + "% Standard Levels");
			Dialog.addNumber("Red reflectance %", standardLevels[i]);
			Dialog.addNumber("Green reflectance %", standardLevels[i]);
			Dialog.addNumber("Blue reflectance %", standardLevels[i]);
		Dialog.show();

		rGreys[i] = Dialog.getNumber();
		gGreys[i] = Dialog.getNumber();
		bGreys[i]= Dialog.getNumber();

	} else{
		rGreys[i] = standardLevels[i];
		gGreys[i]  = standardLevels[i];
		bGreys[i]  = standardLevels[i];
	}

	// MEASURE GREY STANDARDS - only from channels that are to be used


	if(j > 0 && autoAlignOption != "None" && greyLocation == "Same photo" && customiseLocation == 0 && autoAlignOption != "Affine Align"){ // control for alignment of grey standard selection
		getSelectionCoordinates(xCoords, yCoords);
		for(k = 0; k<xCoords.length; k++){
			xCoords[k] = xCoords[k] + parseInt(alignInfo[0]);
			yCoords[k] = yCoords[k] + parseInt(alignInfo[1]);
		}//k

		makeSelection("Polygon", xCoords, yCoords); // make aligned grey standard selection
		//waitForUser("waiting");
	}


	for(k=1; k<=3; k++){
		if(parseInt(photoSettings[k]) > 0){ // channel is to be added
			setSlice(k);

			if(j>0 && autoAlignOption == "Affine Align" && customiseLocation == 0){
				ts = "xc=" + xAffine[0] +" xx=" + xAffine[1]  +" xy=" + xAffine[2] + " yc=" + yAffine[0] + " yx=" + yAffine[1] + " yy=" + yAffine[2] + " slice=" + k;
				//print(ts);
				run("Affine align slice", ts);
			}

			getStatistics(area, mean, min, max, std);
			if(rgbFlag == 1 || nonLin == "RAW Photo"){
				mean = mean*mean;
				max = max*max;
			}

			//if(mean + (std*3) > 65000 || max > 65530)
			if(nonLin == "RAW Photo" && max >= 65535){
				warningText = "This standard could be over-exposed in the " + channelNames[k-1] + " channel";
				waitForUser("Exposure Warning", warningText);
			}

			if(k == 1) // red
				rPxs[i] = mean;
			if(k == 2) // green
				gPxs[i] = mean;
			if(k == 3) // blue
				bPxs[i] = mean;
		}
	}//k



} // i


// GREY STANDARD IN SEPARATE PHOTO:

if(greyLocation == "Separate photos"){
	selectImage(photoID);
	close(); // close measured photo & open photo to process
	imagePath=File.openDialog("Select " + photoSettings[0] +  " photo without standard" ); // get file locations

		imagePathTemp2 = split(imagePath, "/");
		if(imagePathTemp2.length == 1) // windows
			imagePathTemp2 = split(imagePath, "\\");

	seqDirectory = replace(imagePath, imagePathTemp2[imagePathTemp2.length-1], ""); // used later for config file
	//dcrawString = "open=[" + imagePath + "] " + dcrawOptions;
	dcrawString = "select=[" + imagePath + "] camera auto-level";


	//-------------------OPEN RAW OR NON-LINEAR IMAGE-----------------
	if(nonLin == "RAW Photo"){
		//run("DCRaw Reader...", dcrawString);
		setBatchMode(true);
		run("DCRAW import", dcrawString);
		photoID = getImageID();

		//---------------exposure check-----------------
		//setBatchMode(true);
		run("Select All");
		run("Duplicate...", "duplicate");
		eID=getImageID();
		run("Set Min And Max", "min=65534 max=65535");
		run("RGB Color");
		rgbID=getImageID();
		rename("Exposure Test");
		run("Divide...", "value=3");
		selectImage(photoID);
		run("Add Image...", "image=[Exposure Test] x=0 y=0 opacity=100 zero");
		selectImage(eID);
		close();
		selectImage(rgbID);
		close();
		selectImage(photoID);

		run("Square Root", "stack");
		setMinAndMax(0, 10);
		run("Make Composite", "display=Composite");
		setSlice(3);
		setMinAndMax(0, 255);
		setSlice(2);
		setMinAndMax(0, 255);
		setSlice(1);
		setMinAndMax(0, 255);
		setBatchMode(false);

	} else {
		setBatchMode(true);
		open(imagePath);
		photoID = getImageID();
		if(bitDepth == 24){
			rgbFlag = 1;

			//------------exposure check----------
			run("Select All");
			run("Duplicate...", "duplicate");
			eID=getImageID();
			setMinAndMax(254, 255);
			run("Apply LUT");
			rename("Exposure Test");
			run("Divide...", "value=3");
			selectImage(photoID);


			run("RGB Stack");
			//run("32-bit");
			//run("Make Composite", "display=Composite");
		} else rgbFlag = 0;
		if(bitDepth != 32)
			run("32-bit");

		if(nonLinSettingsString.length != nSlices)
			exit("The chosen linearity model has a different number of channels than the selected image");

		for(a=0; a<nSlices; a++) // linearise image
			run("Linearisation Function", nonLinSettingsString[a]);

				if(rgbFlag == 0)
			run("Enhance Contrast", "saturated=0.35");
		else {
			selectImage(photoID);
			run("Make Composite", "display=Composite");
			photoID = getImageID();
			run("Add Image...", "image=[Exposure Test] x=0 y=0 opacity=100 zero");
			selectImage(eID);
			close();
			selectImage(photoID);

			run("Square Root", "stack");
			setMinAndMax(0, 10);
			run("Make Composite", "display=Composite");
			setSlice(3);
			setMinAndMax(0, 16);
			setSlice(2);
			setMinAndMax(0, 16);
			setSlice(1);
			setMinAndMax(0, 16);
		}
		setBatchMode(false);
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

	imagePathTemp = split(imagePath, "/");
	if(imagePathTemp.length == 1) // windows
		imagePathTemp = split(imagePath, "\\");
	photoNames[j] = imagePathTemp[imagePathTemp.length-1];
}

if(greyLocation == "Separate photos" || customiseLocation == 1){

	if(autoAlignOption != "None" && autoAlignCustomZone == 1 && j ==0){
		//setBatchMode("show");
		//setTool("rectangle");
		run("Rounded Rect Tool...", "stroke=1 corner=2 color=blue fill=none");
		run("Rounded Rect Tool...", "stroke=1 corner=1 color=blue fill=none");
		setTool("roundrect");
		run("Select None");
		waitForUser("Custom Alignment Zone", "Draw a box over the area to use for alignment");
		getSelectionBounds(xAlign, yAlign, wAlign, hAlign);
		//setBatchMode("hide");
	}



	if(j > 0 && autoAlignOption != "None"){
		selectImage(newStack);
		setSlice(photoSettings[4]); // the reference slice

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
		if(autoAlignOption != "Affine Align"){
			run("Internal Clipboard");
			rename("align2");
		}

	
		if(autoAlignOption == "Auto-Align"){
			alignString =  "offset=" + autoAlignOffset + " loops=" + autoAlignLoops +" scale_step_size=" + autoAlignScaleStepSize + " proportion=" + autoAlignProportion;
			run("Auto Align", alignString);
		}
		if(autoAlignOption == "Manual Align"){
			selectImage(newStack);
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
			//setBatchMode(true);
			selectImage("ManualAlign");
			close();
		}



		if(autoAlignOption == "Affine Align"){
			selectImage("align1");
			run("Add Slice");
			run("Paste");
			run("Select None");
			run("Enhance Contrast", "saturated=0.35");
	

			selectImage(newStack);
			setBatchMode("show");
			selectImage(photoID);
			setBatchMode("show");
			selectImage("align1");
			setBatchMode("show");
			setBatchMode(false);

//-------------Affine align start---------------

flag=0;

msg = "Select three or more points of alignment in each image, using the multipoint tool \n \nTip: if you have lots of photos with the same offset, you can save and reload the point\nROI in the ROI manager";

setTool("Multipoint");

while(flag==0){

	waitForUser(msg);

	getSelectionCoordinates(xs, ys);

	if(selectionType == 10 && xs.length>=6 && xs.length/2 == round(xs.length/2))
		flag=1;
	else msg = "You need to use the multi-point tool, and ensure there are three or more corresponding points in each slice";


	run("Clear Results");
	run("Set Measurements...", "area mean min redirect=None decimal=9");
	run("Measure");

	zs = newArray(xs.length);

	n1s = 0;
	n2s = 0;
	for(i=0; i<xs.length; i++){
		zs[i] = getResult("Slice", i);
		if(zs[i] == 1)
			n1s++;
		if(zs[i] == 2)
			n2s++;
	}
	if(n1s != n2s){
		flag = 0;
		msg = "There aren't an equal number of anchor points in each slice";
	}

}// waiting for user to select the right type of points

x1 = newArray(n1s);
y1 = newArray(n1s);

x2 = newArray(n1s);
y2 = newArray(n1s);

t1 = 0;
t2 = 0;

for(i=0; i<xs.length; i++){
	if(zs[i] == 1){
		x1[t1] = xs[i];
		y1[t1] = ys[i];
		t1++;
	}

	if(zs[i] == 2){
		x2[t2] = xs[i];
		y2[t2] = ys[i];
		t2++;
	}
		
}



run("Clear Results");

for(i=0; i<x1.length; i++){
	setResult("x", i, x2[i]);
	setResult("x2", i, x1[i]);
	setResult("y2", i, y1[i]);
}

print("\\Clear");
run("multiple regression");
logString = getInfo("log");
logString = split(logString, "\n");
logString = logString[2];
logString = replace(logString, "\\(x2\\*", "");
logString = replace(logString, "\\(y2\\*", "");
logString = replace(logString, "\\)", "");
logString = replace(logString, " ", "");
logString = split(logString, "+");


if(logString.length != 3)
	exit("Error parsing the matrix");

xAffine = newArray(3);
for(i=0; i<3; i++)
	xAffine[i] = logString[i];
	//xAffine[i] = parseFloat(logString[i]);

//Array.show(logString);



run("Clear Results");

for(i=0; i<x1.length; i++){
	setResult("y", i, y2[i]);
	setResult("x2", i, x1[i]);
	setResult("y2", i, y1[i]);
}

print("\\Clear");
run("multiple regression");
logString = getInfo("log");
logString = split(logString, "\n");
logString = logString[2];
logString = replace(logString, "\\(x2\\*", "");
logString = replace(logString, "\\(y2\\*", "");
logString = replace(logString, "\\)", "");
logString = replace(logString, " ", "");
logString = split(logString, "+");


if(logString.length != 3)
	exit("Error parsing the matrix");

yAffine = newArray(3);
for(i=0; i<3; i++)
	yAffine[i] = logString[i];
	//yAffine[i] = parseFloat(logString[i]);

//Array.show(xAffine, yAffine);
print("\\Clear");





//--------------Affine align end--------------------
		}



		selectImage("align1");
		close();

		if(autoAlignOption != "Affine Align"){
			selectImage("align2");
			close();
		
			// extract alignment info
			selectWindow("Alignment Results");
			alignInfo = getInfo("window.contents");
			alignInfo = split(alignInfo, "\n"); // split rows
			alignInfo = split(alignInfo[1], "\t"); // split second rown into data
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
			}
		}

	}
}



// use camera configuration file to assign slices to the right place in the composite image


//Array.print(photoSettings);


for(i=1; i<=3; i++){
	if(parseInt(photoSettings[i]) > 0){ // channel is to be added

		selectImage(photoID);
		setSlice(i);

		if(greyLocation == "Separate photos" || customiseLocation == 1)
		if(j>0 && autoAlignOption == "Affine Align"){
			ts = "xc=" + xAffine[0] +" xx=" + xAffine[1]  +" xy=" + xAffine[2] + " yc=" + yAffine[0] + " yx=" + yAffine[1] + " yy=" + yAffine[2] + " slice=" + i;
			run("Affine align slice", ts);
		}
			
		if(firstFlag == 1){ // first photo - set up new image
			run("Select All");
			run("Copy");
			if(imageName != "")
				newImageName = imageName;
			else newImageName = "Multispectral Composite";
			newImage(newImageName, "32-bit black", getWidth(), getHeight(), stackSize);
			setMinAndMax(0, 65535);
			//run("Internal Clipboard");
			newStack = getImageID();
			setSlice(parseInt( photoSettings[i]) );
			run("Paste");
			setBatchMode("show");
			firstFlag = 0;
	
		} else { // subsequent photo - add new slice
			run("Select All");
			run("Copy");
			selectImage(newStack);
			setSlice(parseInt( photoSettings[i]) );
			run("Select All");
			run("Paste");
		}



		if(estimateBlack == 1){ // add a 0.05% dark point
			run("Select All");
			getStatistics(area, mean, lowObs, max, sd);
			if(rgbFlag == 1 || nonLin == "RAW Photo"){
				lowObs = lowObs*lowObs;
			}

		} // estimate black point





		if(greySaveString != ""){
			greySaveString = greySaveString + ",";
			labelSaveString = labelSaveString + ",";
			alignSaveString = alignSaveString + ",";
		}

		tAlignSaveString = "";

		if(autoAlignOption == "Affine Align" && j>0)
			tAlignSaveString = xAffine[0] + ":" + xAffine[1] + ":"  + xAffine[2] + ":" + yAffine[0] + ":" + yAffine[1] + ":"  + yAffine[2];
		else tAlignSaveString = alignInfo[0] + ":" + alignInfo[1] + ":" + alignInfo[2];

		alignSaveString = alignSaveString + tAlignSaveString;

		tGreySaveString = "";

		for(k=0; k<standardLevels.length; k++){
			if(k>0)
				tGreySaveString = tGreySaveString + "_";
			
			if(i==1)
				tGreySaveString = tGreySaveString + rGreys[k] + ":" + d2s(rPxs[k], -12);
			if(i==2)
				tGreySaveString = tGreySaveString + gGreys[k] + ":" + d2s(gPxs[k], -12);
			if(i==3)
				tGreySaveString = tGreySaveString + bGreys[k] + ":" + d2s(bPxs[k], -12);
		}


		if(estimateBlack == 1) // add a 0.00% dark point
			tGreySaveString = tGreySaveString + "_0:" + d2s(lowObs, -1);

		greySaveString = greySaveString + tGreySaveString;

		tls = photoSettings[0] + ":" + channelNames[i-1];
		labelSaveString = labelSaveString +  tls;

		//saveSliceLabels[parseInt( photoSettings[i])-1] = labelString; // save slice data for config file

		//tls = "label=" + tls;
		//run("Set Label...", tls);

		tls = tls +"\nrefVals=" + tGreySaveString;
		tls = tls +"\nalignMethod="+ autoAlignOption;
		if(autoAlignOption != "None")
			tls = tls + "\nalignData="+ tAlignSaveString;

		setMetadata(tls);

			
	}
}//i

selectImage(photoID);
close();

} // j

// SAVE CONFIGURATION FILE



configFilePath =  seqDirectory + imageName + ".mspec";
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
		configFilePath =  seqDirectory + imageName + ".mspec";
	}//rename
}

//if(saveConfig == 1){

if(renameRAWs ==1){

	if(startsWith(photoNames[0], imageName) == 0)
		photoNamesString = "files=" + imageName + photoNames[0];
	else
		photoNamesString = "files=" + photoNames[0];

	for(i=1; i<photoNames.length; i++)
		if(startsWith(photoNames[i], imageName) == 0)
			photoNamesString = photoNamesString + "," + imageName + photoNames[i];
		else
			photoNamesString = photoNamesString + "," + photoNames[i];
} else {
	photoNamesString = "files=" + photoNames[0];

	for(i=1; i<photoNames.length; i++)
		photoNamesString = photoNamesString + "," + photoNames[i];
}


saveSlicelabelsString = saveSliceLabels[0];
for(i=1; i<stackSize; i++)
	saveSlicelabelsString = saveSlicelabelsString + "\t" + saveSliceLabels[i];

if(nonLin != "RAW Photo"){
	linString = linCameraSettings[0];
	for(i=1; i<linCameraSettings.length; i++)
		linString = linString + "\t" + linCameraSettings[i];

	linString = replace(linString, "\n", ""); // ensure there are no line breaks
}


metaString = "mspec calibrated image";
metaString = metaString + "\n" + photoNamesString;
metaString = metaString + "\nimageType=" + nonLin;
if(nonLin != "RAW Photo")
	metaString = metaString + "\n" + "linearisationModel=" + linString;

metaString = metaString + "\nslices="+slideNumberString;
metaString = metaString + "\nlabels="+labelSaveString;
metaString = metaString + "\nrefVals="+greySaveString;
metaString = metaString + "\nalignMethod="+ autoAlignOption;
if(autoAlignOption != "None")
	metaString = metaString + "\nalignData="+ alignSaveString;

//setMetadata(metaString);


configFile = File.open(configFilePath);

	print(configFile, metaString);

/*
	print(configFile, "mspec calibrated image");
	print(configFile, photoNamesString);
	print(configFile, "imageType=" + nonLin);
	if(nonLin != "RAW Photo")
		print(configFile, "linearisationModel=" + linString);
	print(configFile, "slices="+slideNumberString);
	print(configFile, "labels="+labelSaveString);
	print(configFile, "refVals="+greySaveString);
	print(configFile, "alignMethod="+ autoAlignOption);
	if(autoAlignOption != "None")
		print(configFile, "alignData="+ alignSaveString);
*/	

File.close(configFile);

// RENAME FILES

if(renameRAWs ==1)
	for(i=0; i<photoNames.length; i++)
		if(startsWith(photoNames[i], imageName) == 0)
			if(File.rename(seqDirectory + photoNames[i], seqDirectory + imageName + photoNames[i]) == 1);
			else print("Error renaming file");


transformInfo = "";

if(rgbFlag == 1 || nonLin == "RAW Photo")
	run("Square", "stack");


//setBatchMode("show");
//waitForUser("waiting");

if(autoAlignOption == "Affine Align" && greyLocation == "Same Photo"){
	run("Normalise & Align Multispectral Stack", "normalise curve=[Straight Line]");
}else if(imageOutput == "Linear Stack"){
	run("Normalise & Align Multispectral Stack", "curve=[Straight Line] align");  // align only
}else{
	run("Normalise & Align Multispectral Stack", "normalise curve=[Straight Line] align");
}


if(imageOutput == "Linear Stack")
	setMinAndMax(0, 65535);
else setMinAndMax(0, 100);

setSlice(1);

if(imageOutput == "Linear Colour Image"){

	if(nSlices>3){
		waitForUser("This image has more than 3 channels, only the first 3 will be shown as RGB");
		while(nSlices>3){
			setSlice(4);
			run("Delete Slice");
		}
	}

	setMinAndMax(0, 100);
	run("Make Composite", "display=Composite");
	setSlice(3);
	setMinAndMax(0, 100);
	setSlice(2);
	setMinAndMax(0, 100);
	setSlice(1);
	setMinAndMax(0, 100);
	setBatchMode(false);
}



if(imageOutput == "Non-linear Colour Image"){

	if(nSlices>3){
		waitForUser("This image has more than 3 channels, only the first 3 will be shown as RGB");
		while(nSlices>3){
			setSlice(4);
			run("Delete Slice");
		}
	}

	run("Square Root", "stack");
	setMinAndMax(0, 10);
	run("Make Composite", "display=Composite");
	setSlice(3);
	setMinAndMax(0, 10);
	setSlice(2);
	setMinAndMax(0, 10);
	setSlice(1);
	setMinAndMax(0, 10);
	setBatchMode(false);

	setColor(200, 0, 0);
	colourSwitch = colourSwitch * -1;
	setFont("SansSerif", getHeight()*0.04);


	setFont("SansSerif", getHeight()*0.02);
	setColor(200, 0, 0);
	Overlay.drawString("Non-linear image - do not measure pixel values", getWidth()*0.05, getHeight()*0.05);
	Overlay.show;

}

if(imageOutput == "Non-linear Colour VIS-UV Image"){

	if(nSlices<5){
		exit("UV-VIS false colour shows the visible Green and Blue\nand UV Red channels as a composite. This image\ndoes not have enough channels");
		setBatchMode(false);
		setSlice(1);
	}

	while(nSlices>5){
		setSlice(6);
		run("Delete Slice");
	}

	setSlice(4);
	run("Delete Slice"); // delete uvB

	setSlice(1);
	run("Delete Slice"); // delete visR


	run("Square Root", "stack");
	setMinAndMax(0, 10);
	run("Make Composite", "display=Composite");
	setSlice(3);
	setMinAndMax(0, 10);
	setSlice(2);
	setMinAndMax(0, 10);
	setSlice(1);
	setMinAndMax(0, 10);

	setFont("SansSerif", getHeight()*0.02);
	setColor(200, 0, 0);
	Overlay.drawString("Non-linear image - do not measure pixel values", getWidth()*0.05, getHeight()*0.05);
	Overlay.show;


	transformInfo = "________________________________________\nThis is a false-colour image, shifting the\nchannels to show visible green, visible\nblue and uv red. Use this image to judge\nthe alignment and select ROIs, but don't\nmeasure it directly. Once you've selected\nROIs use the batch script"; 

	setBatchMode(false);
}

setBatchMode("show");


// LOG THE LOCATION FOR ADDING ROIs

setMetadata("Info", configFilePath);
tempVal = roiManager("count"); // dummy line for opening ROI manager


print("\\Clear");

print("__________Config file saved to:__________");
print(configFilePath);


print("\\Clear");

	print("__________Config File Location:__________");
	print(configFilePath);

	print("________________________________________");
	print("--------------Keyboard Shortcuts:-------------");
	print("A-F, G-L, N-Q, T-Z: create new classes of\nnumbered ROIs\n ");
	print("M: Measure mean values of current selection\n ");
	print("R: Measure mean & SD values of all ROIs\n ");
	print("S: Scale bar (draw a line along an object\nof known length. Use for automatic image\nscaling and pattern analysis)\n ");
	print("E: Egg/ellipsoid selection (use for selecting\neggs and measuring the volume/shape/\nsurface area of ellipsoids). Place a point at\nthe tip and base of the egg, and at least\nthree additional points down each side\n ");
	print("0: (zero) Save selections to .mspec image\n ");	

	print("________________________________________");

	print(transformInfo);

	while(roiManager("count") > 0){
		roiManager("select", 0);
		roiManager("Delete");	
	}
	run("Select None");
	run("Save ROIs");
	setSlice(1);


setOption("Changes", false);// reset changes flag so (hopefully) the save image dialog won't come up
showProgress(1); // clear progress bar (it seems to stick)
showStatus("Finished creating multispectral image");

