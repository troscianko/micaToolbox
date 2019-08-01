// Create Colour-Map figure

/*

calculate areas & volume

*/

//colOptions = newArray("Colours from map location","Unify colours within maps");
colOptions = newArray("Colour based on map location","Lock colours between slices", "Use colour palette");
roiManager("Show None");

Dialog.create("Colour Map Plotting Settings");

	Dialog.addString("Figure title", "", 20);
	Dialog.addNumber("Scale", 8);
	Dialog.addMessage("The colour-map resolution is multiplied by this, higher\nvalues produces higher-resolution figures.");
	Dialog.addNumber("Z-Axis_resolution (JNDs)", 2);
	//Dialog.addMessage("For tetrachromatic images sets the number of slices\nthrough the z-axis (normally UV) channel. Set to '1'\nto collapse the z-axis into one layer.");
	Dialog.addChoice("Colour options", colOptions, "Use colour palette");
	Dialog.addCheckbox("Unify colours within maps", true);
	//Dialog.addCheckbox("Crop figure", true);
	//Dialog.addNumber("Boundary threshold", 0.005);
	Dialog.addNumber("Boundary threshold x10^6", 1.0);
	Dialog.addNumber("JND Perimeter Size", 1);
	Dialog.addNumber("Figure border size", 20);
	Dialog.addNumber("Tick length", 2);
	Dialog.addNumber("Line width", 2);
	Dialog.addNumber("Axis_font size", 4);
	Dialog.addCheckbox("Add colour map labels", true);	
	Dialog.addNumber("Label font size", 3);
	
Dialog.show();

figTitle = Dialog.getString();
scaleFactor = Dialog.getNumber();
zRes = Dialog.getNumber();
colSel = Dialog.getChoice();

if(colSel == "Colour based on map location") lockCols = 0;
if(colSel == "Lock colours between slices") lockCols = 1;
if(colSel == "Use colour palette") lockCols = 2;

mapColours = Dialog.getCheckbox;
//cropFig = Dialog.getCheckbox;
minThreshold = Dialog.getNumber() /1000000;
jndBoundary = Dialog.getNumber();
border = Dialog.getNumber(); //px (will be multiplied by scale factor)
tick = Dialog.getNumber(); // tick size in final plot
lineWidth = Dialog.getNumber();
axesFont = Dialog.getNumber(); // 5 reccommended for uncropped figures
addLabels = Dialog.getCheckbox; // add labels to colour maps
labelFont = Dialog.getNumber(); // 4 reccommended for uncropped figures

setBatchMode(true);


//----------Find map images------------

alreadyOpen = 0;
imList = getList("image.titles");

mapList = newArray();

for(i=0; i<imList.length; i++){
	selectImage(imList[i]);
	mapInfo = getMetadata("Info");
	if(startsWith(mapInfo, "label=") == true)
		mapList = Array.concat(mapList, getImageID());
}

if(mapList.length > 0)
	alreadyOpen = 1;
else {
	path = getDirectory("Choose directory containing colour maps");
	list = getFileList(path);

	print("________________________________");
	print("Colour map files:");

	for(i=0; i<list.length; i++)
	if(endsWith(list[i], ".tif") == 1){
		print(list[i]);
		open(path + list[i]);
		mapInfo = getMetadata("Info");
		if(startsWith(mapInfo, "label=") == true)
			mapList = Array.concat(mapList, getImageID());
		else close();
	}
	print("________________________________");
}


if(mapList.length == 0)
	exit("There are no compatible maps; open all colour maps you wish to plot and compare and re-run");


//------arrays to hold info--------
label = newArray(mapList.length);
nPx = newArray(mapList.length);
res = newArray(mapList.length);
channelString = newArray(mapList.length);
label = newArray(mapList.length);
xMins = newArray(mapList.length);
yMins = newArray(mapList.length);
zMins = newArray(mapList.length);
xMaxs = newArray(mapList.length);
yMaxs = newArray(mapList.length);
zMaxs = newArray(mapList.length);
crop = newArray(mapList.length);
tetra = newArray(mapList.length); // flag for tetrachromatic images
tetra[0] = 0;
weber = newArray(mapList.length);

for(j=0; j<mapList.length; j++){

selectImage(mapList[j]);
mapInfo = getMetadata("Info");
mapInfo = split(mapInfo, ",");

for(i=0; i<mapInfo.length; i++){
	row = split(mapInfo[i], "=");
	
	if(row[0] == "label") label[j] = row[1];
	if(row[0] == "nPx") nPx[j] = parseInt(row[1]);
	if(row[0] == "res") res[j] = parseInt(row[1]);
	if(row[0] == "channels") channelString[j] = row[1];
	if(row[0] == "weber") weber[j] = row[1];
	if(row[0] == "x_limits"){
		xLims = split(row[1], ":");
		xMins[j] = parseInt(xLims[0]);
		xMaxs[j] = parseInt(xLims[1]);
	}
	if(row[0] == "y_limits"){
		yLims = split(row[1], ":");
		yMins[j] = parseInt(yLims[0]);
		yMaxs[j] = parseInt(yLims[1]);
	}
	if(row[0] == "z_limits"){
		zLims = split(row[1], ":");
		zMins[j] = parseInt(zLims[0]);
		zMaxs[j] = parseInt(zLims[1]);
		tetra[j] = 1;
	}	 
	//if(row[0] == "crop") crop[j] = row[1];
}

}//j


//-----------Work out final figure bounds---------------------

	cxMin = 10E10;
	cxMax = -10E10;
	cyMin = 10E10;
	cyMax = -10E10;
	for(j=0; j<mapList.length; j++){
		if(xMins[j] < cxMin) cxMin = xMins[j];
		if(yMins[j] < cyMin) cyMin = yMins[j];
		if(xMaxs[j] > cxMax) cxMax = xMaxs[j];
		if(yMaxs[j] > cyMax) cyMax = yMaxs[j];
	}


//--------------Crop z-axis-------------------
if(tetra[0] == 1){
	czMin = 10E10;
	czMax = -10E10;
	for(j=0; j<mapList.length; j++){
		if(zMins[j] < czMin) czMin = zMins[j];
		if(zMaxs[j] > czMax) czMax = zMaxs[j];
	}
}


//---------------Check all maps are compatible-------------

for(j=0; j<mapList.length; j++)
for(k=j+1; k<mapList.length; k++){
		if(res[j] != res[k]){
			print("Stopping - these maps are not compatible:");
			print(label[j] " map resolution = " + res[j]);
			print(label[k] " map resolution = " + res[k]);
			exit("Error - the resolutions of the colour maps do not match");
		}
		if(channelString[j] != channelString[k]){
			print("Stopping - these maps are not compatible:");
			print(label[j] " channel names = " + channelString[j]);
			print(label[k] " channel names = " + channelString[k]);
			exit("Error - the maps have different channel names");
		}
		if(weber[j] != weber[k]){
			print("Stopping - these maps are not compatible:");
			print(label[j] + " Weber fractions = " + weber[j]);
			print(label[k] + " Weber fractions = " + weber[k]);
			exit("Error - the maps have different weber fractions");
		}
		if(label[j] == label[k]){
			print("Warning, two colour maps share the same label.\nThey will be renamed:");
			print("Label 1: " + label[j] + "_1");
			print("Label 2: " + label[k] + "_2");
			label[j] = label[j]+"_1";
			label[k] = label[k]+"_2";
		}

}//j k


//--------------------------Expand maps to same size---------------------------
for(j=0; j<mapList.length; j++){

	selectImage(mapList[j]);

	mw = (xMaxs[j]-xMins[j])*res[0];
	mh = (yMaxs[j]-yMins[j])*res[0];

	selectImage(mapList[j]);
	run("Select All");
	run("Copy");
	ts = label[j] + "_Colour_Map";
	if(tetra[j] == 0){
		newImage(ts, "32-bit black", (cxMax-cxMin)*res[0], (cyMax-cyMin)*res[0], 1);
		makeRectangle((xMins[j]-cxMin)*res[0], (yMins[j]-cyMin)*res[0], mw, mh);
		run("Paste");
		nID = getImageID();
	} else {

		newImage(ts, "32-bit black", (cxMax-cxMin)*res[0], (cyMax-cyMin)*res[0], (czMax-czMin)*res[0]);
		nID = getImageID();
		//waitForUser("THIS BIT NEEDS SORTING");
		for(i=0; i<(zMaxs[j]-zMins[j])*res[0]; i++){
			selectImage(mapList[j]);
			//setSlice(i-(zMins[j]*res[0])+1);
			setSlice(i+1);
			run("Select All");
			run("Copy");
			selectImage(nID);
			setSlice((zMins[j]-czMin)*res[0]+i+1);
			//makeRectangle(xMins[j], yMins[j], mw, mh);
			makeRectangle((xMins[j]-cxMin)*res[0], (yMins[j]-cyMin)*res[0], mw, mh);
			run("Paste");
		}
		nID = getImageID();
	}

	selectImage(mapList[j]);
	close();

	selectImage(nID);
	mapList[j]=getImageID();

//---------Reset the image pixel count to reflect normalisation----------------

selectImage(mapList[j]);

	if(tetra[j] == 0){
		ts = "label=" + label[j] + ",nPx=1,res=" + res[j] +
			",channels=" + channelString[j] + ",x_limits=" + cxMin + ":" + cxMax +
			",y_limits=" + cyMin + ":" + cyMax;
	} else {
		ts = "label=" + label[j] + ",nPx=1,res=" + res[j] +
			",channels=" + channelString[j] + ",x_limits=" + cxMin + ":" + cxMax +
			",y_limits=" + cyMin + ":" + cyMax +
			",z_limits=" + czMin + ":" + czMax;
	}

setMetadata("Info", ts);


//-----------Normalise pixel counts---------------
selectImage(mapList[j]);
if(nPx[j] != 1){
	ts = "value=" + nPx[j];
	if(tetra[j] == 1)
		ts = ts + " stack";
	run("Divide...", ts);
}

if(alreadyOpen == 1)
	setBatchMode("show");
}//j


//-----------------------------------Colour Overlap Measurement-------------------------
if(mapList.length > 1){

if(isOpen("Colour Distribution Overlap Measurements") == true)
	IJ.renameResults("Colour Distribution Overlap Measurements", "Results");

run("Clear Results");
row = nResults;

overlaps = newArray(mapList.length*mapList.length);

for(j=0; j<mapList.length-1; j++){
	for(k=j+1; k<mapList.length; k++){
		if(tetra[j]==0){
			imageCalculator("Difference create 32-bit", mapList[j], mapList[k]);
			run("Select All");
			getStatistics(area, mean);
			close();
			overlaps[k+j*mapList.length] = (area*mean)/2;
			overlaps[j+k*mapList.length] = (area*mean)/2;
		} else {
			imageCalculator("Difference create 32-bit stack", mapList[j], mapList[k]);
			run("Select All");
			for(i=0; i<nSlices; i++){
				setSlice(i+1);
				getStatistics(area, mean);
				overlaps[k+j*mapList.length] += (area*mean)/2;
				overlaps[j+k*mapList.length] += (area*mean)/2;
			}
			close();
		}

		// due to 32-bit rounding error, when there is no overlap this can be slightly above 1
		if(overlaps[k+j*mapList.length] > 1) overlaps[k+j*mapList.length] = 1.0;
		if(overlaps[j+k*mapList.length] > 1) overlaps[j+k*mapList.length] = 1.0;
	}//k
}//j

for(j=0; j<mapList.length; j++){
	setResult("Label", row, label[j]);
	for(k=0; k<mapList.length; k++){
		if(k==j)
			overlaps[k+j*mapList.length] = 0;
		setResult(label[k], row, 1-overlaps[j+k*mapList.length]);
	}
	row++;
}//j

updateResults();
IJ.renameResults("Results","Colour Distribution Overlap Measurements");

}// if more than one map measure overlaps



cxRes = (cxMax-cxMin)*res[0];
cyRes = (cyMax-cyMin)*res[0];


if(tetra[0] == 1)
	for(j=0; j<mapList.length; j++){
		selectImage(mapList[j]);
		run("Select None");
		run("Duplicate...", "duplicate"); // don't mess with the original image
		mapList[j] = getImageID(); // reset imageID
		// apply a median z-axis filter at the z-resolution
		if(zRes != 0){
			zS = res[0]*zRes;
			ts = "x=0 y=0 z=" + round(zS/2);			
		} else { // collapse z-axis
			zS = res[0]*zRes;
			ts = "x=0 y=0 z=" + nSlices();
		}
		run("Mean 3D...", ts);
	}



if(tetra[0] == 1 && zRes != 0){
	//startZ = floor(czMin/zS)*zS;
	//stopZ = (floor((czMax-1)/zS)+1)*zS;
	//startZ = 1;
	stopZ = (czMax-czMin)*res[0];
} else {
	startZ = 0;
	stopZ = 1;
	zS = 1;
}

//------------------------------------------------CREATE OUTPUT FIGURE---------------------------------------------

selR = newArray(mapList.length);
selG = newArray(mapList.length);
selB = newArray(mapList.length);

arrowX = newArray(mapList.length);
arrowY = newArray(mapList.length);

tick = tick*scaleFactor;
sb = scaleFactor * border;
w = scaleFactor * (cxRes +border+border);
h = scaleFactor * (cyRes +border+border);
setLineWidth(lineWidth);

roiExists = newArray(mapList.length);
figExists = 0;

// -----------------------get maxima for normalisation--------------------------------
maxima = newArray(mapList.length);
modalX = newArray(mapList.length);
modalY = newArray(mapList.length);

for(j=0; j<mapList.length; j++){
	selectImage(mapList[j]);
	run("Select All");
	if(tetra[0] == 1 && zRes !=0){
		for(z=1; z<=nSlices; z=z+res[0]*zRes ){
			setSlice(z);
			run("Select All");
			getStatistics(area, mean, min, max, sd);
			if(max > maxima[j]){
				maxima[j] = max;
				run("Find Maxima...", "noise=10 output=[Point Selection]");
				getSelectionCoordinates(xC,yC);
				modalX[j] = xC[0];
				modalY[j] = yC[0];
			}
		} //z
	} else {
		run("Select All");
		getStatistics(area, mean, min, max, sd);
		if(max > maxima[j]){
			maxima[j] = max;
			run("Find Maxima...", "noise=10 output=[Point Selection]");
			getSelectionCoordinates(xC,yC);
			modalX[j] = xC[0];
			modalY[j] = yC[0];
		}
	}

}//j

//Array.show(maxima);

if(zRes == 0)
incZ = 1;
else incZ = res[0]*zRes;

//for(z=startZ; z<=stopZ; z=z+zS){
for(z=1; z<=stopZ; z=z+incZ ){

//print("z: " + z);

// arrays to hold image values
R = newArray(cxRes*cyRes);
G = newArray(cxRes*cyRes);
B = newArray(cxRes*cyRes);

nROIs = roiManager("count");

for(j=0; j<mapList.length; j++){

selectImage(mapList[j]);
if(tetra[0] == 1){
	setSlice(z);
}

//---------Get Colour of region based on modal colour-------------
run("Select None");
getStatistics(area, mean, min, max, sd);
roiExists[j] = 0;
if(max>0){
roiExists[j] = 1;
run("Find Maxima...", "noise=10 output=[Point Selection]");
getSelectionCoordinates(xC,yC);
//Array.show(xC, yC);

if(lockCols == 0){
	BY = (((yC[0]/res[0])+cyMin)+50)/100;
	RG = 1-(((xC[0]/res[0])+cxMin)+50)/100;
} else if(lockCols == 1){
	BY = (((modalY[j]/res[0])+cyMin)+50)/100;
	RG = 1-(((modalX[j]/res[0])+cxMin)+50)/100;
} else {
	//print("Separate colours");

	if(j==0){
		BY = 0.3;
		RG = 0.3;
	} else {
		BY = (j/mapList.length)*0.4+0.3;
		// flip red/green axis while incrementing blue-yellow (good for RG colour-blind people)
		if(j/2 == round(j/2)) RG = (j/mapList.length)*0.4+0.3;
		else RG = ((mapList.length-j)/mapList.length)*0.4+0.3;
	}
}


selB[j] = round(255*BY);
selR[j]= round((RG*(2*BY-2)*selB[j]+(2-2*BY)*selB[j])/BY);
selG[j] = round(-1*RG*(2*BY-2)*selB[j]/BY);

if(selR[j]<0) selR[j]=0;
if(selG[j]<0) selG[j]=0;
if(selB[j]<0) selB[j]=0;

if(selR[j]>255) selR[j]=255;
if(selG[j]>255) selG[j]=255;
if(selB[j]>255) selB[j]=255;

//Array.show(selR, selG, selB);

//------------------------------------Calculate bounding region---------------------------
run("Select None");

//-------------Rescale Image------------
ts= "x=- y=- width="+ scaleFactor*cxRes+ " height=" +scaleFactor*cyRes+ " interpolation=None average create";
run("Scale...", ts);

//------------Normalise to max=1--------------------

//ts = "value=" + maxima[j];
//run("Divide...", ts);

//ts = "radius=" + (scaleFactor/2);
ts = "radius=" + scaleFactor;
run("Median...", ts);

//------------Get bounding region--------------
setThreshold(minThreshold, 2);
run("Create Selection");
if(selectionType() == -1)
	makeRectangle(xC[0]*scaleFactor-1,yC[0]*scaleFactor-1,2,2);

arrowY[j] = yC[0]*scaleFactor;
//------------Find position of arrow-----------
if(j/2==round(j/2))
for(x=xC[0]*scaleFactor; x<cxRes*scaleFactor; x++){
	if(selectionContains(x, arrowY[j]) == 0){
		arrowX[j] = x;
		x = cxRes*scaleFactor;
	}
} else for(x=xC[0]*scaleFactor; x>0; x--){
	if(selectionContains(x, arrowY[j]) == 0){
		arrowX[j] = x;
		x = 0;
	}
}


roiManager("Add");
roiManager("select", nROIs+j);
roiManager("rename", label[j]);
close();


//-----------Create Colour Map----------------
selectImage(mapList[j]);
//setMinAndMax(0, 1);

for(y=0; y<cyRes; y++){

	BY = (((y/res[0])+cyMin)+50)/100;
	//BY = (y+cyMin)/res[j];
	if(y==0)
		BY=1E-6;
	for(x=0; x<cxRes; x++){

		pxVal = pow(getPixel(x,y)/maxima[j],1/2);// square-root transform for showing low values more clearly
	
		//RG = (x+cxMin)/res[j];
		//RG = res[j]/x;
		RG = 1-(((x/res[0])+cxMin)+50)/100;

		loc = x+y*cxRes;
		
		if(mapColours == 0){
			Bt = pxVal*255*BY;
			Rt= pxVal*(RG*(2*BY-2)*Bt+(2-2*BY)*Bt)/BY;
			Gt = pxVal*-1*RG*(2*BY-2)*Bt/BY;
		} else {
			Rt = pxVal*selR[j]; 
			Gt = pxVal*selG[j]; 
			Bt = pxVal*selB[j]; 
		}

		B[loc] += Bt;
		G[loc] += Gt;
		R[loc] +=  Rt;
	}//x
}//y

} else {// if max>0
	// add dummy ROI to be deleted later
	run("Select All");
	roiManager("Add");
	roiManager("select", nROIs+j);
	roiManager("rename", label[j]);	
}

}//j



tFlag = 0;
for(j=0; j<mapList.length; j++)
	if(roiExists[j] != 0)
		tFlag++;

if(tFlag > 0){ // only create output image if some regions were found


// Apply colours to new map
for(loc=0; loc<cxRes*cyRes; loc++){

	// flip brightness to white background
	maxVal=0;
	if(R[loc]>maxVal) maxVal=R[loc];
	if(G[loc]>maxVal) maxVal=G[loc];
	if(B[loc]>maxVal) maxVal=B[loc];

	minVal=255;
	if(R[loc]<minVal) minVal=R[loc];
	if(G[loc]<minVal) minVal=G[loc];
	if(B[loc]<minVal) minVal=B[loc];

	R[loc] = 255-maxVal-minVal+R[loc];
	G[loc] = 255-maxVal-minVal+G[loc];
	B[loc] = 255-maxVal-minVal+B[loc];

	if(R[loc]<0) R[loc]=0;
	if(G[loc]<0) G[loc]=0;
	if(B[loc]<0) B[loc]=0;

	if(R[loc]>255) R[loc]=255;
	if(G[loc]>255) G[loc]=255;
	if(B[loc]>255) B[loc]=255;

}


newImage("Temp_Colour_Map", "RGB white", cxRes+border+border, cyRes+border+border, 1);
tID = getImageID();
for(y=0; y<cyRes; y++)
for(x=0; x<cxRes; x++){
	loc = x+y*cxRes;
	val = ((round(R[loc])<< 16) | ((round(G[loc]) << 8) | round(B[loc])));
	setPixel(x+border,y+border, val);
}



//-------------Rescale Image------------
ts= "x=- y=- width="+ scaleFactor*(cxRes+border+border)+ " height=" +scaleFactor*(cyRes+border+border) + " interpolation=None average create";
run("Scale...", ts);

if(tetra[0] == 1)
	rename("Colour Map " + z);
else rename("Colour Map");
cmapID = getImageID();

ts = "radius=" + scaleFactor;
run("Median...", ts);

for(j=0; j<mapList.length; j++)
if(roiExists[j] == 1){


//roiManager("select", nROIs-mapList.length+j);
roiManager("select", nROIs+j);
Roi.getBounds(x, y, width, height);
Roi.move(x+(scaleFactor*border), y+(scaleFactor*border));

hR = toString(toHex(selR[j]));
hG = toString(toHex(selG[j]));
hB = toString(toHex(selB[j]));

if(lengthOf(hR) == 1)
	hR = "0"+hR;
if(lengthOf(hG) == 1)
	hG = "0"+hG;
if(lengthOf(hB) == 1)
	hB = "0"+hB;


oCol = hR + hG + hB;
setColor(selR[j],selG[j],selB[j]);
setLineWidth(lineWidth);

Overlay.addSelection( oCol , 1);

// ---------add 1JND boundary-----------
if(jndBoundary != 0){
	tn = (jndBoundary * scaleFactor * res[0]);
	while(tn > 254){ // roi enlarge can only deal with 245 pixels at a time without freaking out
		ts = "enlarge=" + tn;
		run("Enlarge...", ts);
		tn = tn-254;
	}
	ts = "enlarge=" + tn;
	run("Enlarge...", ts);
	tn = tn-254;

	Overlay.addSelection( oCol , 1);

//	makeRectangle(sb,sb,w-sb, h-sb);
//	setBackgroundColor(255,255,255);
//	run("Clear Outside");
}

run("Select None");

if(addLabels == 1){

	setFont("SansSerif" , labelFont*scaleFactor, "antialiased");

	if(j/2==round(j/2)){
		setJustification("left");
		Overlay.drawLine(arrowX[j]+sb,arrowY[j]+sb,arrowX[j]+sb+(5*tick), arrowY[j]+sb);
		drawString(label[j], arrowX[j]+sb+(5*tick), arrowY[j]+sb+(1*tick));
	} else {
		setJustification("right");
		Overlay.drawLine(arrowX[j]+sb,arrowY[j]+sb,arrowX[j]+sb-(5*tick), arrowY[j]+sb);
		drawString(label[j], arrowX[j]+sb-(5*tick), arrowY[j]+sb+(1*tick));
	}
}
setColor(selR[j],selG[j],selB[j]);
setLineWidth(lineWidth);

Overlay.show();

}//j apply outlines

//------------Flatten overlay if tetrachromatic------------
if(tetra[0] == 1){

	setColor("black");
	setFont("SansSerif", (axesFont-1)*scaleFactor, "antialiased");
	setJustification("center");
	ta = split(channelString[0], ":");

	if(zRes != 0) czLab = "Z ("+ta[0]+ "+" + ta[1] + "+" + ta[2] + "):" + ta[3] + "=" + d2s(  czMin+((z-1)/res[0]), 3);
	else czLab = "Z-axis ("+ta[0]+ "+" + ta[1] + "+" + ta[2] + "):" + ta[3] + " flattened"; 
	drawString(czLab, w/2, sb-(2*tick));
	Overlay.show();

	run("Flatten");
	fID=getImageID();
	selectImage(cmapID);
	close();
	if(figExists == 0){
		stackID = getImageID();
		figExists = 1;
	} else {
		run("Select All");
		run("Copy");
		close();
		selectImage(stackID);
		run("Add Slice");
		run("Paste");
	}
}


selectImage(tID);
close();


}//tFlag


while(roiManager("count")>nROIs){
	roiManager("select", nROIs);
	roiManager("delete");
}



}//z













//setBatchMode(false);

//-----------------------Plot axes-------------------

if(tetra[0] == 1){
	selectImage(stackID);
	setSlice(1);
}

setColor("black");
setFont("SansSerif", axesFont*scaleFactor, "antialiased");


Overlay.drawLine(sb-tick,sb,w-sb+tick, sb);
Overlay.drawLine(sb,sb-tick,sb, h-sb+tick);
Overlay.drawLine(sb-tick,h-sb,w-sb+tick, h-sb);
Overlay.drawLine(w-sb,sb-tick,w-sb, h-sb+tick);

// plot grey point if it's contained in the figure:
//Overlay.drawLine( (w/2)-tick, h/2 , (w/2)+tick, h/2 );
//Overlay.drawLine( w/2, (h/2)-tick , w/2, (h/2)+tick );
if(cxMin < 0 && cxMax > 0 && cyMin < 0 && cyMax > 0){

	Overlay.drawLine(	sb+((-cxMin*res[0])*scaleFactor) - tick,
			sb+((-cyMin*res[0])*scaleFactor),
			sb+((-cxMin*res[0])*scaleFactor) + tick,
			sb+((-cyMin*res[0])*scaleFactor) );
	Overlay.drawLine(	sb+((-cxMin*res[0])*scaleFactor),
			sb+((-cyMin*res[0])*scaleFactor)- tick,
			sb+((-cxMin*res[0])*scaleFactor),
			sb+((-cyMin*res[0])*scaleFactor) + tick );
}

//Overlay.drawLine( w/2, (h/2)-tick , w/2, (h/2)+tick );

setColor("black");

//---------------work out numbers 

if(round(cxMin) == cxMin) cxMinLab = d2s(cxMin , 0);
else cxMinLab = d2s(cxMin , 3);

if(round(cxMax) == cxMax) cxMaxLab = d2s(cxMax  , 0);
else cxMaxLab = d2s(cxMax  , 3);

if(round(cyMin) == cyMin) cyMinLab = d2s(cyMin , 0);
else cyMinLab = d2s(cyMin , 3);

if(round(cyMax) == cyMax) cyMaxLab = d2s(cyMax , 0);
else cyMaxLab = d2s(cyMax , 3);

// x-axis limits
Overlay.drawString(cxMaxLab, w-sb-(0.5*tick), h-sb+(4*tick));
Overlay.drawString(cxMinLab, sb-(tick), h-sb+(4*tick));

// y-axis limits
Overlay.drawString(cyMinLab, sb-(2*tick), sb+(1.5*tick), 90);
Overlay.drawString(cyMaxLab, sb-(2*tick), h-sb+(2*tick), 90);

// figure title
//Overlay.drawString(figTitle, w/2, sb/2);
setJustification("center");
drawString(figTitle, w/2, sb/2);

ta = split(channelString[0], ":");
opName = "Y ("+ta[0]+ "+" + ta[1] + "):" + ta[2];
Overlay.drawString(opName, sb-tick, (h/2)+(8*tick), 90);

opName = "X " + ta[1]+ ":" + ta[0];
Overlay.drawString(opName, (w/2)-(3*tick), h-sb+(4*tick));


Overlay.show();
run("Select None");
setBatchMode(false);




