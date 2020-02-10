/*
_______________________________________________________________________

	Title: Make Presentation Image
	Author: Jolyon Troscianko
	Date: 30/06/15
	update: 24/9/18 - Adjustable non-linear image output
.................................................................................................................

Description:

Multispectral images are displayed as a greyscale stack by default so that any
number of channels can be added. For display purposes it is often desirable
to show colour images for human viewing on monitors and in print.

This tool makes it easy to select how a multispectral image or cone-catch image
should be converted to an RGB colour image.

_________________________________________________________________________
*/

origImage = getImageID();
title = getTitle();
w=getWidth();
h=getHeight();

//setBatchMode(true);
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
outSuggestions = newArray("Red", "Green", "Blue", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore", "Ignore");

if(maxVal < 10)
	maxRec = 1;
else maxRec = 100;


Dialog.create("Colour and False-Colour Image Creator");
	Dialog.addMessage("Select which input channels to use for each colour output. For best results\nonly use red, green and blue once each, or yellow and blue for dichromats.");
	for(i=0; i<nSlices; i++){
		Dialog.addChoice(replace(sliceNames[i], ":", "_"), outColours, outSuggestions[i]);
	}

	Dialog.addMessage(" __________Image Brightness__________");
	tempString = "Brightest measured pixel value: " + maxVal + " reflectance images would normally be\n100, cone-catch images 1. If the images are too dark select a lower maxium\nand/or a lower non-linear transform";
	Dialog.addMessage(tempString);
	Dialog.addNumber("Presentation image maximum:", maxRec);

	Dialog.addMessage(" __________Non-linear Transform__________");
	Dialog.addNumber("Power", 0.5);
	Dialog.addMessage("1=linear image (often looks too dark), 0.5=square-root transform (very non-linear).\nWhere presentation images will be directly compared to each-other make sure\nthe same maximum and transform values are used. Remember this image is for\npresentation only, not for measurements");
	Dialog.addCheckbox("Convert to 24-bit RGB colour", false);
	Dialog.addCheckbox("CIEXYZ to sRGB conversion", false);
	Dialog.addMessage("This conversion restores 'normal' colour saturation from XYZ images");
	

Dialog.show();

for(i=0; i<nSlices; i++)
	outColours[i] = Dialog.getChoice();

maxVal = Dialog.getNumber();
tPower = Dialog.getNumber();
rgbColour = Dialog.getCheckbox();
srgbColour = Dialog.getCheckbox();

maxVal = pow(maxVal, tPower);

outCount = 0;
for(i=0; i<sliceNames.length; i++)
	if(outColours[i] != "Ignore")
		outCount++;

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
if(srgbColour ==  false)
	run("Make Composite", "display=Composite");

outImage = getImageID();

setPasteMode("Copy");


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
		if(srgbColour ==  false)
			run(outColours[i]);
		//if(tPower != 1)
		//	run("Macro...", tempString);
		//setMinAndMax(min, max);
		outSlice++;
	}//fi

if(srgbColour ==  true){
	run("CIEXYZ to Linear sRGB");
	run("Make Composite", "display=Composite");

	outSRGB = getImageID();
	selectImage(outImage);
	close();
	selectImage(outSRGB);
	rename(title);
}

tempString = "code=v=pow(v," + tPower + ") slice";

if(tPower != 1)
for(i=0; i<nSlices; i++){
	setSlice(i+1);
	run("Macro...", tempString);
}

ts = "min=0 max=" + maxVal;
run("Set Min And Max", ts);

if(rgbColour==true)
	run("RGB Color");

setBatchMode("show");


