/*
_______________________________________________________________________

	Title: Batch Make Presentation Images
	Author: Jolyon Troscianko
	Date: 30/06/15
		10/2/2020 Added compatibility with CIEXYZ to sRGB space function
.................................................................................................................

Description:

Multispectral images are displayed as a greyscale stack by default so that any
number of channels can be added. For display purposes it is often desirable
to show colour images for human viewing on monitors and in print.

This tool makes it easy to select how a multispectral image or cone-catch image
should be converted to an RGB colour image.

_________________________________________________________________________
*/

setBatchMode(true);
imageDIR = getDirectory("Select folder containing multispectral images");

//-----------------SELECT CONE CATCH----------------------

// LISTING CONE CATCH MODELS

	modelPath = getDirectory("plugins")+"Cone Models";

	modelList=getFileList(modelPath);

	modelNames = newArray(1);
	modelNames[0] = "None";

	for(i=0; i<modelList.length; i++){
		if(endsWith(modelList[i], ".class")==1)
			modelNames = Array.concat(modelNames,replace(modelList[i],".class",""));
		if(endsWith(modelList[i], ".CLASS")==1)
			modelNames = Array.concat(modelNames,replace(modelList[i],".CLASS",""));
	}
	
	for(i=0; i<modelNames.length; i++)
		modelNames[i] = replace(modelNames[i], "_", " ");


// IMAGE PROCESSING SETTINGS

	Dialog.create("Convert Image to Cone Catch");
		Dialog.addMessage("Select the visual system to use:");
		Dialog.addChoice("Model", modelNames, "None");
		Dialog.addNumber("Scale (0=no scaling)", 0);
		Dialog.addMessage("Only use image scaling if all images have a scale-bar ROI");
	Dialog.show();

	visualSystem = Dialog.getChoice();
	scaleVal = Dialog.getNumber;// px/mm

fileList=getFileList(imageDIR);

mspecList=newArray();

for(i=0; i<fileList.length; i++) // list only mspec files
	if(endsWith(fileList[i], ".mspec")==1)
		mspecList = Array.concat(mspecList, fileList[i]);


for(j=0; j<mspecList.length; j++){


	print("\\Update3:Processing Image " + (j+1) + " of " + mspecList.length);

	// LOAD MULTISPECTRAL IMAGE
	imageString = "select=[" + imageDIR + mspecList[j] + "] image=[Linear Normalised Reflectance Stack]";
	run(" Load Multispectral Image", imageString);

	// SCALE IMAGE
	if(scaleVal != 0){
		origImage = getImageID();
		imageString= "pixels=" + scaleVal;
		run("Multispectral Image Scaler", imageString);
	}

	title = getTitle();
	w=getWidth();
	h=getHeight();

	if(visualSystem != "None"){
		origImage = getImageID();
		run(visualSystem);
		coneImage = getImageID();
		setMinAndMax(0, 1);
		rename(title + " " + visualSystem);
		selectImage(origImage);
		close();
		selectImage(coneImage);
	}

	origImage = getImageID();



// FIRST IMAGE - GET SETTINGS	
if(j==0){

sliceNames = newArray(nSlices);
setSlice(1);

maxVal = 0;
run("Select All");
for(i=0; i<nSlices; i++){
	setSlice(i+1);
	sliceNames[i] = getInfo("slice.label");
	getStatistics(area, mean, min, max, sd);
	if(max > maxVal)
		maxVal = max;
}

outColours = newArray("Red", "Green", "Blue", "Yellow", "Ignore");
transform = newArray("None", "Square Root");

if(maxVal < 10)
	maxRec = 1;
else maxRec = 100;


Dialog.create("Colour and False-Colour Image Creator");
	Dialog.addMessage("Select which input channels to use for each colour output. For best results\nonly use red, green and blue once each, or yellow and blue for dichromats.");
	for(i=0; i<nSlices; i++){
		Dialog.addChoice(replace(sliceNames[i], ":", "_"), outColours, outColours[4]);
	}

	Dialog.addMessage(" __________Image Brightness__________");
	tempString = "Brightest measured pixel value: " + maxVal + " reflectance images would normally be\n100, cone-catch images 1. If the images are too dark select a lower maxium\nand/or a lower non-linear transform";
	Dialog.addMessage(tempString);
	Dialog.addNumber("Presentation image maximum:", maxRec);

	Dialog.addMessage(" __________Non-linear Transform__________");
	Dialog.addNumber("Power", 0.8);
	Dialog.addMessage("1=linear image (often looks too dark), 0.5=square-root transform (very non-linear).\nWhere presentation images will be directly compared to each-other make sure\nthe same maximum and transform values are used. Remember this image is for\npresentation only, not for measurements");

Dialog.show();

for(i=0; i<nSlices; i++)
	outColours[i] = Dialog.getChoice();

maxVal = Dialog.getNumber();
tPower = Dialog.getNumber();

maxVal = pow(maxVal, tPower);

outCount = 0;
for(i=0; i<sliceNames.length; i++)
	if(outColours[i] != "Ignore")
		outCount++;


}//first image


title = title + "_FalseColour";
for(i=0; i<sliceNames.length; i++)
	if(outColours[i] == "Yellow")
		title = title + "_"+sliceNames[i];
for(i=0; i<sliceNames.length; i++)
	if(outColours[i] == "Red")
		title = title + "_"+sliceNames[i];
for(i=0; i<sliceNames.length; i++)
	if(outColours[i] == "Green")
		title = title + "_"+sliceNames[i];
for(i=0; i<sliceNames.length; i++)
	if(outColours[i] == "Blue")
		title = title + "_"+sliceNames[i];


title = replace(title, "Normalised", "");
title = replace(title, "visible", "v");
title = replace(title, "uv", "u");
title = replace(title, ":", "");

newImage(title, "32-bit black", w, h, outCount);
run("Make Composite", "display=Composite");
outImage = getImageID();

setPasteMode("Copy");
min = 0;
max=maxVal;


tempString = "code=v=pow(v," + tPower + ") slice";

outSlice = 1;
for(i=0; i<sliceNames.length; i++)
	if(outColours[i] != "Ignore"){
		selectImage(origImage);
		setSlice(i+1);
		run("Select All");
		run("Copy");
		selectImage(outImage);
		setSlice(outSlice);
		run("Paste");
		run(outColours[i]);
		if(tPower != 1)
			run("Macro...", tempString);
		setMinAndMax(min, max);
		outSlice++;
	}//fi



selectImage(outImage);
run("RGB Color");

//setBatchMode("show");


	roiCount = roiManager("count");

	if(roiCount ==0){
		//saveString = imageDIR + mspecList[j] + ".png";
		saveString = imageDIR + title + ".png";
		run("Select All");
		saveAs("PNG", saveString);
		close();
	} else {


	for(k=0; k<roiCount; k++){

		roiManager("Select", k);
		roiName = Roi.getName;

		if(startsWith(roiName, "Scale") != true){ // ignore scale bars
			setBackgroundColor(0, 0, 0);
			run("Duplicate...", "duplicate");
			tempImage = getImageID();
			run("Clear Outside");
			run("RGB Stack");
			selectImage(tempImage);
			setSlice(3);
			run("Add Slice");
			setForegroundColor(255, 255, 255);
			run("Fill", "slice");
			run("Set Label...", "label=Alpha");
			saveString = imageDIR + title + "_" + roiName + ".png";
			saveAs("PNG", saveString);
			close();
		}// ignore scale
	}//k

	close();
	}// roi >0

	close();
	close();

}// j

