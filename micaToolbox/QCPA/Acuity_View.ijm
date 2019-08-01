/*
_______________________________________________________________________

	Title: AcuityView for Image
	Author: Jolyon Troscianko (based on AcuityView R package by Caves and Johnsen)
	Date: 26/9/18
.................................................................................................................

Description:
''''''''''''''''''''''''''''''''
AcuityView removes spatial information that isn’t available to a given visual system, but a host
of other processing steps may go into changing what an animal actually perceives.

If you use this tool, please also cite:
Caves, E. M. & Johnsen, S. AcuityView: An r package for portraying the effects of visual
acuity on scenes observed by an animal. Methods in Ecology and Evolution 9, 793–797 (2018).

This script requires a linear 32-bit image or image stack (ideally created with the micaToolbox).
If viewing distance is used to work out the angular width of the image, then the image must contain
a scle bar (as created through the mspec image generation workflow).

_________________________________________________________________________
*/

imTitle  = getTitle();
setBatchMode(true);


run("Duplicate...", "duplicate");

oID = getImageID();


w = getWidth();
h = getHeight();


if(w>h)
	D = w;
else D = h;

// testing shows the dimensions of the "custom FFT filter" should be the maximum image dimensions (not the equivalent FFT sized output, such as 1024x1024)

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

Dialog.create("AcuityView for ImageJ");

	Dialog.addMessage("_________________________________________Acuity Settings_________________________________________");
	Dialog.addChoice("Acuity units:", acChoice, defaultSettings[0]);
	Dialog.addNumber("Acuity value", defaultSettings[1]);

	Dialog.addMessage("____________________________________Distance/Angle Settings____________________________________");
	Dialog.addChoice("Method:", calcChoice, defaultSettings[2]);
	Dialog.addNumber("Distance or angle value", defaultSettings[3]);
	Dialog.addMessage("If using 'Viewing distance' the image must contain a scale-bar, and the units entered above\nmust match the scale bar units (e.g. mm). All angles are in degrees");

	Dialog.addNumber("Rescale to px per MRA", defaultSettings[4]);
	Dialog.addMessage("Automatically re-scale the image to a set number of pixels per MRA, 0=off");


	Dialog.addMessage("________________________________________Background Info________________________________________");
	Dialog.addMessage("AcuityView removes spatial information that isn't available to a given visual system, but a host\nof other processing steps may go into changing what an animal actually perceives.");
	Dialog.addMessage("If you use this tool, please also cite:\nCaves, E. M. & Johnsen, S. AcuityView: An r package for portraying the effects of visual\nacuity on scenes observed by an animal. Methods in Ecology and Evolution 9, 793-797 (2018).");

	Dialog.addHelp("https://eleanorcaves.weebly.com/acuityview-software.html");

Dialog.show();

aMethod = Dialog.getChoice();
aVal = Dialog.getNumber();
bMethod = Dialog.getChoice();
bVal = Dialog.getNumber();
pxMRA = Dialog.getNumber(); // pixels per minimum resolvable angle


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
print("---------------AcuityView---------------");

if(aMethod == "Minimum resolvable angle"){
	MRA = aVal;
	imTitle = imTitle + "_MRA" + aVal + "_WholeImage";
} else{
	MRA = 1/aVal;
	imTitle = imTitle + "_Acuity" + aVal + "_WholeImage";
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
print("________________________________");



//------------------Image Scaling-----------------

// scale to e.g. 5px per MRA


if(pxMRA != 0){
sR= (pxMRA*alpha/MRA)/D; // scaled angular width ratio

if(sR <= 1){
	tStr = "scaling=" + d2s(sR,12);
	run("Multispectral Image Scaler No Scale Bar", tStr);
	oID = getImageID();
	D = round(D*sR);
} else{
	waitForUser("These settings will increase the image dimensions beyond their original size, so no scaling will be performed");
	sR = 1;	
}
}// pxMRA !=0




//------------------CREATE MTF---------------------

// make sure there aren't any old MTFs open to confuse the calculation
imageTitles = getList("image.titles");
for(i=0; i<imageTitles.length; i++)
	if(imageTitles[i] == "MTF"){
		selectImage("MTF");
		exit("There is already an MTF image open - close this image and re-run the script");
	}



d2 = D/2;

newImage("MTF", "32-bit black", D, D, 1);

for(y=0; y<D; y++)
for(x=0; x<D; x++){
	v = pow(pow(x-d2,2) + pow(y-d2,2),0.5)/alpha; // euclidean distance to centre of image / alpha
	setPixel(x,y, exp(-3.56 * pow(v*MRA,2) ) );
}


mtfID = getImageID();


selectImage(oID);
run("Select None");
getMinAndMax(oMin, oMax);
run("Duplicate...", "duplicate");
oID = getImageID();
rename(imTitle);
setSlice(1);
//for(i=1; i<=nSlices; i++)
//	run("Custom Filter...", "filter=MTF");

// this is a really weird get-around, the FFT custom filter often only works with the first slice in a stack
newImage("TEMP", "32-bit black", 10, 10, 3);
run("Custom Filter...", "filter=MTF process");

selectImage(oID);
run("Custom Filter...", "filter=MTF process");
setMinAndMax(oMin, oMax);
setBatchMode("show");


