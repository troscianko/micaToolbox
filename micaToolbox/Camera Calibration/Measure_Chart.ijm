
if(nImages == 0)
	exit("Open the mspec image of the colour chart\nand convert to animal cone-catch if required\nbefore running this tool.");

Dialog.create("Measure Printer Calibration Page");

	Dialog.addMessage("Specify the number of rows & columns to match\nthe colour chart");
	Dialog.addNumber("Columns:", 6);
	Dialog.addNumber("Rows:", 4);
	Dialog.addMessage(" \nSelect a margin size (0 to 1)");
	Dialog.addSlider("Margin scale:", 0, 1, 0.5);
	Dialog.addMessage("Select a lower margin scale if the measuremnt\nboxes overlap their neighbours");

Dialog.show();

rows = Dialog.getNumber();
columns = Dialog.getNumber();
scale = Dialog.getNumber();

setTool("multipoint");
waitForUser("Place a point on each of the corners, moving clockwise from the top left)");

Overlay.clear;

setBatchMode(true);

getSelectionCoordinates(xCoords, yCoords);


if(xCoords.length != 4)
	exit("Error - select only 4 points, one in each corner");



// LEFT LINE INTERSECTIONS (1-2)

m = (yCoords[0] - yCoords[1]) / (xCoords[0] - xCoords[1]);
c = yCoords[0] - (xCoords[0]*m);

leftXCoords = newArray(rows+1);
leftYCoords = newArray(rows+1);

for(i=0; i<rows+1; i++){
	leftXCoords[i] = xCoords[0] - (((xCoords[0] - xCoords[1])/(rows)) * i);
	leftYCoords[i] = leftXCoords[i] * m + c;
}

makeSelection("multipoint", leftXCoords, leftYCoords);

// BOTTOM LINE INTERSECTIONS (2-3)

m = (xCoords[1] - xCoords[2]) / (yCoords[1] - yCoords[2]);
c = xCoords[1] - (yCoords[1]*m);

bottomXCoords = newArray(columns+1);
bottomYCoords = newArray(columns+1);

for(i=0; i<columns+1; i++){
	bottomYCoords[i] = yCoords[1] - (((yCoords[1] - yCoords[2])/(columns)) * i);
	bottomXCoords[i] = bottomYCoords[i] * m + c;
}

makeSelection("multipoint", bottomXCoords, bottomYCoords);


// RIGHT LINE INTERSECTIONS (1-2)

m = (yCoords[2] - yCoords[3]) / (xCoords[2] - xCoords[3]);
c = yCoords[2] - (xCoords[2]*m);

rightXCoords = newArray(rows+1);
rightYCoords = newArray(rows+1);

for(i=0; i<rows+1; i++){
	//rightXCoords[i] = xCoords[2] - (((xCoords[2] - xCoords[3])/(rows)) * i);
	rightXCoords[i] = xCoords[3] - (((xCoords[3] - xCoords[2])/(rows)) * i);
	rightYCoords[i] = rightXCoords[i] * m + c;
}

makeSelection("multipoint", rightXCoords, rightYCoords);


// TOP LINE INTERSECTIONS (2-3)

m = (xCoords[0] - xCoords[3]) / (yCoords[0] - yCoords[3]);
c = xCoords[0] - (yCoords[0]*m);

topXCoords = newArray(columns+1);
topYCoords = newArray(columns+1);

for(i=0; i<columns+1; i++){
	topYCoords[i] = yCoords[0] - (((yCoords[0] - yCoords[3])/(columns)) * i);
	topXCoords[i] = topYCoords[i] * m + c;
}

makeSelection("multipoint", topXCoords, topYCoords);

boxX = newArray(4);
boxY = newArray(4);

results = newArray(rows*columns*nSlices);



//i = 20;
//j = 36;
//Overlay.drawLine(topXCoords[i], topYCoords[i], bottomXCoords[i], bottomYCoords[i]);
//Overlay.drawLine(leftXCoords[j], leftYCoords[j], rightXCoords[j], rightYCoords[j]);

for(k=0; k<nSlices; k++){
	setSlice(k+1);

for(i=0; i<columns; i++)
for(j=0; j<rows; j++){


// BOX TOP LEFT

a = (topYCoords[i] - bottomYCoords[i]) / (topXCoords[i] - bottomXCoords[i]);
b = topYCoords[i] - (topXCoords[i] * a);

c = (leftYCoords[j] - rightYCoords[j]) / (leftXCoords[j] - rightXCoords[j]);
d = leftYCoords[j] - (leftXCoords[j] * c);

boxX[0] = (d-b)/(a-c);
boxY[0] = a * boxX[0] + b;

// BOX BOTTOM LEFT

a = (topYCoords[i] - bottomYCoords[i]) / (topXCoords[i] - bottomXCoords[i]);
b = topYCoords[i] - (topXCoords[i] * a);

c = (leftYCoords[j+1] - rightYCoords[j+1]) / (leftXCoords[j+1] - rightXCoords[j+1]);
d = leftYCoords[j+1] - (leftXCoords[j+1] * c);

boxX[1] = (d-b)/(a-c);
boxY[1] = a * boxX[1] + b;

// BOX BOTTOM RIGHT

a = (topYCoords[i+1] - bottomYCoords[i+1]) / (topXCoords[i+1] - bottomXCoords[i+1]);
b = topYCoords[i+1] - (topXCoords[i+1] * a);

c = (leftYCoords[j+1] - rightYCoords[j+1]) / (leftXCoords[j+1] - rightXCoords[j+1]);
d = leftYCoords[j+1] - (leftXCoords[j+1] * c);

boxX[2] = (d-b)/(a-c);
boxY[2] = a * boxX[2] + b;

// BOX TOP RIGHT

a = (topYCoords[i+1] - bottomYCoords[i+1]) / (topXCoords[i+1] - bottomXCoords[i+1]);
b = topYCoords[i+1] - (topXCoords[i+1] * a);

c = (leftYCoords[j] - rightYCoords[j]) / (leftXCoords[j] - rightXCoords[j]);
d = leftYCoords[j] - (leftXCoords[j] * c);

boxX[3] = (d-b)/(a-c);
boxY[3] = a * boxX[3] + b;


makeSelection("polygon", boxX, boxY);

run("Scale... ", "x=&scale y=&scale centered");

//for(k=0; k<nSlices; k++){
	//setZCoordinate(k);
	//setSlice(k+1);
	getStatistics(area, mean, min, max);
	results[(k*rows*columns)+(i*rows)+j] = mean;


if(k==0)
	Overlay.addSelection("red", 1);
	//run("Add Selection...");

}//ij
}//k

Overlay.show;

// OUTPUT RESULTS

labels = newArray(nSlices);
for(k=1; k<nSlices+1; k++){
	setSlice(k);
	labels[k-1] = getMetadata("Label");
}

row = 0;

for(i=0; i<columns; i++)
for(j=0; j<rows; j++){
	for(k=0; k<nSlices; k++)
		setResult(labels[k], row, results[(k*rows*columns)+(i*rows)+j]);
	row ++;
}

setSlice(1);

makeSelection("multipoint", xCoords, yCoords);
updateResults();
waitForUser("Check Measurement Zones", "Check that there is no overlap between the measured squares\nand the colour chart squares. If there is overlap select a smaller\nmargin scale and repeat.");
