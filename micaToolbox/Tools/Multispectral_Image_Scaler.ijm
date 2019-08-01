

// USER SETTINGS

	Dialog.create("Settings");
		Dialog.addNumber("Pixels per unit length:", 10); 
	Dialog.show();

	pixelsMm = Dialog.getNumber();



// GET SCALE FROM ROI

nSelections = roiManager("count");

scaleFlag = 0;

for(j=0; j<nSelections; j++){
	roiManager("select", j);
	selName = getInfo("selection.name");

	if( startsWith(selName, "Scale") == 1){ // found the scale bar - extract the info
		scaleLoc = j;
		scaleFlag = scaleFlag+1;
		scaleInfo = split(selName, ":");
		pixLength = scaleInfo[1];
		scaleMm = scaleInfo[2];
	}
		
}

if(scaleFlag == 0)
	exit("No scale bar found\n \nUse the 'Save ROIs' script to add\none by selecting it and pressing 'S',\nthen press '0' to save the ROIs");
if(scaleFlag > 1)
	showMessageWithCancel("Multiple Scale Bars", "There's more than one scale bar\n \nThis script will only use the last one");


scaleFactor = (pixelsMm * scaleMm)/pixLength;	// target length / observed length

// DELETE THE SCALE BAR NOW IT'S NOT NEEDED
roiManager("Deselect");
roiManager("select", scaleLoc);
roiManager("Delete");



// scale selections

scaleString = "x=" + scaleFactor + " y=" + scaleFactor;

for(j=0; j<nSelections-1; j++){
	roiManager("Deselect");
	roiManager("select", 0);
	selName = getInfo("selection.name");

	run("Scale... ", scaleString);
	roiManager("Add"); // add scaled ROI

	roiManager("Deselect");
	roiManager("select", 0);
	roiManager("Delete"); // delete original

	newSelection = roiManager("count") -1;
	roiManager("select", newSelection);
	roiManager("Rename", selName); // rename new one

	roiManager("Deselect");

}


	imWidth = round(getWidth()*scaleFactor);
	imHeight = round(getHeight()*scaleFactor);
	imName = getTitle() + "_Resized";
	imDepth = nSlices;
	originalID = getImageID();

// RESIZE

	run("Select None");

	run("Scale...", "x=&scaleFactor y=&scaleFactor z=1.0 width=&imWidth height=&imHeight depth=&imDepth interpolation=Bilinear average process create title=&imName");	// bilinear is used because bicubic can introduce artefacts
	run("Set Scale...", "pixel=1 unit=pixel");

	roiManager("Show All with labels");

	selectImage(originalID);
	close();



	


