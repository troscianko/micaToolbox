tmp = roiManager("count");

function addArea(letter, selColour){

setBatchMode(true);

nSelections = roiManager("count");

roiManager("Add");

selNames = newArray(nSelections);
//run("Labels...", "color=white font=12 show use draw");

letterCount = 0;
letterLoc = newArray(0);

for(i=0; i<nSelections; i++){
	roiManager("select", i);
	selNames[i] = getInfo("selection.name");

	if(startsWith(selNames[i] , letter) == 1){ // record target selection areas
		letterCount ++;
		letterLoc = Array.concat(letterLoc, i);
	}
}
setBatchMode(false);

//print(selectionType());

// EGG SELECTION
if(letter == "e"){ // letter E

	roiManager("select", nSelections);
	getSelectionCoordinates(xPre, yPre);
	roiManager("Delete");
	eggString = "egg_number=" + (letterCount+1);

	makeSelection("point", xPre, yPre);

	run("Egg Measurement PreScaled", eggString);

	getSelectionCoordinates(xPost, yPost);
	if(xPre.length == xPost.length){
		makeSelection("Multipoint", xPre, yPre);
		exit(); // exit if the adjust button was selected
	}
	roiManager("Add");
	letter = "egg";

}// egg selection

nSelections = roiManager("count");
roiManager("select", nSelections-1);
//run("From ROI Manager");
if(startsWith(letter, "Scale") == 1 ) // increment unless it's the scale bar
	roiManager("Rename", letter);
else roiManager("Rename", letter + (letterCount + 1));

showStatus(letterCount);

roiManager("Set Color", selColour);
roiManager("Show All");
run("Labels...", "color=white font=12 show use draw");


// Select all ROIS as this seems to speed things up
selArray = newArray(nSelections);

for(i=0; i<nSelections; i++)
	selArray[i] = i;

roiManager("select", selArray);

}//add area function

// SELF-INSTALL THE MACRO ON FIRST RUN


plugins = getDirectory("plugins");

installString = "install=[" + plugins + "micaToolbox/Tools/Save_ROIs.ijm]";

run("Install...", installString);

exit();

// ADD AREAS WITH AUTO LABELS


macro "Add Area A [a]"{
letter = "a";
selColour = "yellow";
addArea(letter, selColour);
}

macro "Add Area B [b]"{
letter = "b";
selColour = "blue";
addArea(letter, selColour);
}

macro "Add Area C [c]"{
letter = "c";
selColour = "cyan";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area D [d]"{
letter = "d";
selColour = "yellow";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area E [e]"{
letter = "e";
selColour = "blue";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area F [f]"{
letter = "f";
selColour = "blue";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area G [g]"{
letter = "g";
selColour = "green";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area H [h]"{
letter = "h";
selColour = "red";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area I [i]"{
letter = "i";
selColour = "green";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area J [j]"{
letter = "j";
selColour = "blue";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area K [k]"{
letter = "k";
selColour = "yellow";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area L [l]"{
letter = "l";
selColour = "magenta";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area M [m]"{

	row = nResults;

	if(getMetadata("Label") == ""){
		for(i=1; i<nSlices+1; i++){
			setSlice(i);
			getStatistics(area, mean);
			setResult(i + "_mean", row, mean);
		}
	} else {

		for(i=1; i<nSlices+1; i++){
			setSlice(i);
			getStatistics(area, mean);
			setResult(getMetadata("Label")+"_mean", row, mean);
		}
	}

	setSlice(1);

}

macro "Add Area N [n]"{
letter = "n";
selColour = "red";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area O [o]"{
letter = "o";
selColour = "orange";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area P [p]"{
letter = "p";
selColour = "blue";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area Q [q]"{
letter = "q";
selColour = "cyan";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area R [r]"{
//letter = "r";
//selColour = "red";
//addArea(letter, selColour);
//run("Labels...", "color=white font=12 show use draw");
run("Measure ROIs");

}

macro "Add Scale Bar S [s]"{

if(selectionType() == 5 || selectionType() == 6){ // straight line - calculate pythagorean distance
	getSelectionCoordinates(xCoords, yCoords);
	scaleLength = pow(pow(xCoords[0]-xCoords[1],2) + pow(yCoords[0]-yCoords[1],2), 0.5);
} else { // other shape (hopefully square or circle for ball bearing etc..) so take average bounds
	waitForUser("The selection isn't a line, so the tool will take the average bounds (w+h)/2");
	getSelectionBounds(x, y, selWidth, selHeight);
	scaleLength = (selWidth + selHeight)/2;
}

Dialog.create("Scale Bar");
	Dialog.addMessage("How long is the scale bar?");
	Dialog.addNumber("Length, diameter or bounding box dimensions (e.g. in mm)", 0);
Dialog.show();

	rulerLength = Dialog.getNumber();

if(rulerLength >= 0 || rulerLength <= 0){
	letter = "Scale Bar:" + scaleLength + ":" + rulerLength;
	selColour = "red";
	addArea(letter, selColour);
	run("Labels...", "color=white font=12 show use draw");
}else waitForUser("Error","Please only enter numbers in the scale bar length");

	



}

macro "Add Area T [t]"{
letter = "t";
selColour = "cyan";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area U [u]"{
letter = "u";
selColour = "red";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area V [v]"{
letter = "v";
selColour = "green";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area W [w]"{
letter = "w";
selColour = "blue";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area X [x]"{
letter = "x";
selColour = "cyan";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area Y [y]"{
letter = "y";
selColour = "yellow";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Add Area Z [z]"{
letter = "z";
selColour = "magenta";
addArea(letter, selColour);
run("Labels...", "color=white font=12 show use draw");
}

macro "Save ROIs [0]" {

	//savePath = getInfo("log");
	//savePath = split(savePath, "\n");
	savePath = getMetadata("Info");
	//saveFlag = 0;

	if(endsWith(savePath, ".mspec") == false)
		savePath = File.openDialog("Select image config file");

	fileType = ".zip"; // seems to only want zips even with one selection
	savePath = replace(savePath, ".mspec", fileType); // replace .txt with either .roi or .zip as required

	selectionArray = newArray(roiManager("count"));

	for(i=0; i<roiManager("count"); i++)
		selectionArray[i] = i;

	roiManager("Select", selectionArray);

	roiManager("Save", savePath);

	showStatus("Done saving ROIs with multispectral image");
	
	print(" \nROIs saved to: " + savePath);

} // macro ends
