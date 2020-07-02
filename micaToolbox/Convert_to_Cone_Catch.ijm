/*
_______________________________________________________________________

	Title: Convert to Cone Catch
	Author: Jolyon Troscianko
	Date: 16/10/2014
	update: 20/12/2018
		addition of negative number removal
.................................................................................................................

Description:
''''''''''''''''''''''''''''''''
This code converts a multispectral image file into cone-catch quanta.

Instructions:
''''''''''''''''''''''''''''''''''''''''
Load a multispectral image file (must be 32-bit, normalised and aligned), run
the code and select the camera and visual system combinaiton you want.
_________________________________________________________________________
*/


title = getTitle();

if(bitDepth() != 32)
	exit("Requires a 32-bit normalised image");

// LISTING CONE CATCH MODELS

	modelPath = getDirectory("plugins")+"Cone Models";

	modelList=getFileList(modelPath);

	modelNames = newArray();

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
		Dialog.addChoice("Model", modelNames);
		Dialog.addMessage("Dark noise from the camera sensor can cause erroneously high\nsaturation levels. These can be reduced by setting any pixel to\ngrey (i.e. average of all channels) below a dark threshold");
		Dialog.addCheckbox("Desaturate dark values", true);
		Dialog.addNumber("Desaturation threshold (cone catch)", 0.01);
		Dialog.addMessage("Negative values can occur due to normalisaiton problems (e.g.\ndifferent lighting on subject and standard), or because the\ncolour is out-of-gamut of the camera or animal. Negative\nvalues in very dark areas of an image are not a concern.");
		Dialog.addCheckbox("Remove negative values", true);
		Dialog.addNumber("Replace negative values with", 0.001);

	Dialog.show();

	visualSystem = Dialog.getChoice();
	//visualSystem = replace(visualSystem, "_", " ");

	desaturate = Dialog.getCheckbox();
	desaturateVal = Dialog.getNumber();

	remove = Dialog.getCheckbox();
	replaceVal = Dialog.getNumber();

setBatchMode(true);
run(visualSystem);
setMinAndMax(0, 1);
rename(title + " " + visualSystem);

if(desaturate == true){

	w = getWidth();
	h = getHeight();

	run("Overlay Options...", "stroke=none width=0 fill=blue set show");
	oID = getImageID();

	run("Average Stack");
	setThreshold(-10E10, desaturateVal);
	
	run("Create Selection");

	print("Coverage of pixels below desaturation threshold (blue overlay):");

	if(selectionType() != -1){
		run("Copy");
		roiManager("Add");
		getStatistics(area, mean, min, max, sd);
		print( (area/(w*h))*100 + "%");
		close();

		selectImage(oID);
		roiManager("select", roiManager("Count")-1);

		for(i=1; i<=nSlices; i++){
			setSlice(i);
			run("Add Selection...");
			run("Paste");
			setBatchMode("show");
		}//i

		roiManager("Delete");
		run("Select None");

	} else {
		print("0%");
		close();
	}

}

setBatchMode("show");

if(remove == true){
	
	roiLocs = newArray(0);
	negValsFound = 0;
	run("Overlay Options...", "stroke=none width=0 fill=red set show");
	print("Coverage of pixels with negative cone-catch values (red overlay):");
	w = getWidth();
	h = getHeight();

	for(i=1; i<=nSlices; i++){
		setSlice(i);
		setThreshold(-10E10, 0.00);
		run("Create Selection");
		if(selectionType() != -1){
			getStatistics(area, mean, min, max, sd);
			print(getInfo("slice.label") + ": " + (area/(w*h))*100 + "%");
			negValsFound += area;
			ts = "value=" + replaceVal + " slice";
			run("Set...", ts);
			run("Add Selection...");

		} else print(getInfo("slice.label") + ": 0%");
	}//i

	run("Select None");
	resetThreshold();
	setSlice(1);
}



setBatchMode(false);
