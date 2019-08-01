/*
_______________________________________________________________________

	Title: Gaussian Acuity Control for Image
	Author: Jolyon Troscianko
	Date: 26/9/18
.................................................................................................................

Description:
''''''''''''''''''''''''''''''''
This tool is essentially an alternative to AcuityView, which uses a Gaussian pass filter instead
of FFT using a specific MTF. The Gaussian distribution fits the MTF pretty well, but the main
advantage is that this can easily be applied to ROIs of any shape and size. FFTs are a pig
to use with anything which isn't rectangular.

The sigma of the Gaussian blur has been specifically modelled against the pixels-per-MRA chosen,
specifically in the range from 4 px/MRA to 16 px/MRA. This testing ensured the blurring results in contrasts
which are 2% of the original. As such the safest range of px/MRAs to use is between 4 and 16.

This script requires a linear 32-bit image or image stack (ideally created with the micaToolbox).
If viewing distance is used to work out the angular width of the image, then the image must contain
a scle bar (as created through the mspec image generation workflow).

_________________________________________________________________________
*/

imTitle  = getTitle();
//setBatchMode(true);
getMinAndMax(oMin, oMax);

//run("Duplicate...", "duplicate");

oID = getImageID();


w = getWidth();
h = getHeight();


if(w>h)
	D = w;
else D = h;

//-----------------------------LIST ROIs-----------------------

roiList = newArray("whole image");
roiFullList = newArray();
nROIs = roiManager("count");

for(j=0; j<nROIs; j++){
	roiManager("Select", j);
	tStr = getInfo("selection.name");
	roiFullList = Array.concat(roiFullList, tStr);
	if(startsWith(tStr, "Scale Bar") == false) // only measure ROIs which aren't scale bars
		roiList = Array.concat(roiList, tStr);
}


//------------------LOAD PREVIOUSLY USED VALUES---------------------

settingsFilePath = getDirectory("plugins") + "micaToolbox/QCPA/acuitySettings.txt";
if(File.exists(settingsFilePath) == 1){
	settingsString=File.openAsString(settingsFilePath);	// open txt data file
	defaultSettings=split(settingsString, "\n");
} else defaultSettings = newArray(
"Minimum resolvable angle",
"0.05",
"Angular width of image",
"20",
"5");

//------------------USER OPTIONS---------------------

acChoice = newArray("Minimum resolvable angle", "Cycles per degree");
calcChoice = newArray("Angular width of image", "Viewing distance");

Dialog.create("Gaussian Acuity Control");

	Dialog.addMessage("_________________________________________Acuity Settings_________________________________________");
	Dialog.addChoice("Acuity units:", acChoice, defaultSettings[0]);
	Dialog.addNumber("Acuity value", defaultSettings[1]);

	Dialog.addMessage("____________________________________Distance/Angle Settings____________________________________");
	Dialog.addChoice("Method:", calcChoice, defaultSettings[2]);
	Dialog.addNumber("Distance or angle value", defaultSettings[3]);
	Dialog.addMessage("If using 'Viewing distance' the image must contain a scale-bar, and the units entered above\nmust match the scale bar units (e.g. mm). All angles are in degrees");

	Dialog.addNumber("Rescale to px per MRA", defaultSettings[4]);
	Dialog.addMessage("Automatically re-scale the image to a set number of pixels per MRA");

	Dialog.addMessage("______________________________________Specify ROI______________________________________");
	Dialog.addChoice("ROI:", roiList,  "whole image");
	Dialog.addMessage("When using this Beta version of the framework cite: van den Berg &\nTroscianko et al. (2019) Quantitative Colour Pattern Analysis (QCPA):\nA Comprehensive Framework for the Analysis of Colour Patterns in\nNature, BIORXIV/2019/592261");
	
Dialog.show();

aMethod = Dialog.getChoice();
aVal = Dialog.getNumber();
bMethod = Dialog.getChoice();
bVal = Dialog.getNumber();
pxMRA = Dialog.getNumber(); // pixels per minimum resolvable angle
if(pxMRA == 0)
	exit("Unlike AcuityView (which uses FFT) the modelling used here assumes the image has been\nscaled to a specified pixels-per-minimum-resolvable-angle, so you cannot set it to zero here");

roiChoice = Dialog.getChoice();
roiSel = 0;
for(j=0; j<roiFullList.length; j++)
	if(roiChoice == roiFullList[j])
		roiSel = j;



// -----------------------SAVE PREVIOUSLY USED SETTINGS----------------------------
dataFile = File.open(settingsFilePath);
	print(dataFile, aMethod);
	print(dataFile, aVal);
	print(dataFile, bMethod);
	print(dataFile, bVal);
	print(dataFile, pxMRA);
File.close(dataFile);

//------------------CALCULATE VARIABLES---------------------

print("________________________________");
print("------Gaussian Acuity Control------");

if(aMethod == "Minimum resolvable angle"){
	MRA = aVal;
	imTitle = imTitle + "_MRA" + aVal;
} else{
	MRA = 1/aVal;
	imTitle = imTitle + "_Acuity" + aVal;
	print("Acuity = " + aVal);
}

if(bMethod == "Angular width of image"){
	alpha = bVal; // angular width of image
	imTitle = imTitle + "_AW" + bVal;
}else{ //--------------------------calculate angular width based on distance and image scale-----------------------
	imTitle = imTitle + "_Dist" + bVal;
	print("Distance = " + bVal);

// get scale bar px/mms

	nSelections = roiManager("count");

	scaleFlag = 0;

	for(j=0; j<nSelections; j++){
		roiManager("select", j);
		selName = getInfo("selection.name");

		if( startsWith(selName, "Scale") == 1){ // found the scale bar - extract the info
			scaleLoc = j;
			scaleFlag = scaleFlag+1;
			scaleInfo = split(selName, ":");
			pxMm = parseFloat(scaleInfo[1])/parseFloat(scaleInfo[2]);
			//pixLength = scaleInfo[1];
			//scaleMm = scaleInfo[2];
		}
		
	}

	if(scaleFlag == 0)
		exit("No scale bar found\n \nUse the 'Save ROIs' script to add\none by selecting it and pressing 'S',\nthen press '0' to save the ROIs");
	if(scaleFlag > 1)
		showMessageWithCancel("Multiple Scale Bars", "There's more than one scale bar\n \nThis script will only use the last one");

	imageWidth = D/pxMm;
	imageAngle = atan((imageWidth/2)/bVal)*2; // image angle in radians
	alpha = 180 * imageAngle/PI; // image angle in degrees
}


print("MRA = " + MRA);
if(w>h)
	print("Image angular width = " + alpha);
else 
	print("Image angular height = " + alpha);

print("Image Region = " + roiChoice);

print("________________________________");



//------------------Image Scaling-----------------

// scale to a given number of px per MRA

sR= (pxMRA*alpha/MRA)/D; // scaled angular width ratio

if(sR > 1)
	waitForUser("These settings will increase the image dimensions beyond their original size, which invalidates the smoothing");

if(roiChoice != "whole image"){
	roiManager("select", roiSel);
	
	run("Duplicate...", "duplicate");

	roiManager("Add");
	roiManager("deselect");

	for(i=0; i<nROIs; i++){ // delete all other ROIs
		roiManager("select", 0);
		roiManager("delete");
	}
} else {
	run("Select None");
	run("Duplicate...", "duplicate");
}


tStr = "scaling=" + d2s(sR,12);
	run("Multispectral Image Scaler No Scale Bar", tStr);

if(roiChoice != "whole image"){
	roiManager("select", 0); // select new ROI
	run("Make Inverse");
	run("Set...", "value=0 stack");
	run("Make Inverse");
	//----make inverse can select regions outside the image boundary, so the code here cleans up the ROI
	roiManager("Add");
	run("Select All");
	roiManager("Add");
	roiManager("Select", 1);
	roiManager("Select", newArray(1,2));
	roiManager("AND");
	roiManager("Add");

	roiManager("Select", newArray(0,1,2));
	roiManager("delete");

	roiManager("Select", 0);

	roiManager("rename", roiChoice);

	//roiManager("select", 0); // select new ROI
}


oID = getImageID();
D = round(D*sR);



//-----------Gaussian blur modelling based on testing:------------
M = 0.45045736;
C = -0.09008928;

sigma = M*pxMRA+C;
if(roiChoice == "whole image"){
	run("Gaussian Blur...", "sigma=&sigma stack");
	imTitle = imTitle + "_WholeImage";
	rename(imTitle);
} else {
	tStr = "sigma="+sigma;
	for(i=1; i<=nSlices; i++){
		setSlice(i);
		run("Gaussian Blur ROI", tStr);
	}
	setSlice(1);
	imTitle = imTitle + "_" + roiChoice;
	rename(imTitle);
}

setMinAndMax(oMin, oMax);
setBatchMode("show");

