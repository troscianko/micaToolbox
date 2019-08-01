

// USER SETTINGS

	Dialog.create("Settings");
		Dialog.addNumber("Scaling factor:", 0.5); 
	Dialog.show();

	scaleFactor = Dialog.getNumber();

nSelections = roiManager("count");



// scale selections

scaleString = "x=" + scaleFactor + " y=" + scaleFactor;

for(j=0; j<nSelections; j++){
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



	


