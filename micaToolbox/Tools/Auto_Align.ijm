// AUTOMATIC IMAGE ALIGNMENT


//....................................................................................................................................................................................................





offsetOptions = newArray("4","8","16","32","64","128","256","512","1024");

Dialog.create("Alignment & Scaling Options");
	Dialog.addMessage("_____________________Alignment___________________________");
	Dialog.addChoice("Offset:", offsetOptions, "16");
	Dialog.addMessage("16 works well for a 100mm lens on a tripod, allowing\nfor up to 31 pixels misalignment in the x or y axes\n");
	Dialog.addMessage("_______________________Scaling___________________________");
	Dialog.addNumber("Loops", 8);
	Dialog.addMessage("More scaling loops will allow the code to home in on a\nmore precise scale, but will take longer. 8 is plenty\n \nSet to 1 to turn off scaling."); 
	Dialog.addMessage("---------------------------------Window---------------------------------------");
	Dialog.addNumber("Scale_step_size", 0.005);
	Dialog.addMessage("A larger window will allow for greater scale differences,\nbut won't home in on the correct scale as quickly");
	Dialog.addMessage("-----------------------------Image Region----------------------------------");
	Dialog.addSlider("Proportion", 0, 0.99, 0.95);
	Dialog.addMessage("Specify the region of the image to use for alignment.\nSmaller regions will be much faster to process, but\nwon't be as accurate for the outer regions of the image");

Dialog.show();

maxOff = parseInt(Dialog.getChoice());
nScales = Dialog.getNumber();
scaleWindow = Dialog.getNumber();
windowSize = 1/Dialog.getNumber();

// SET UP IMAGES

	//setBatchMode(true);

	selectImage("align1");
	run("Select None");
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	visAlignID = getImageID();

	selectImage("align2");
	run("Select None");
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	uvAlignID = getImageID();


print("\\Clear");
print("______________________________________________");
print("------------Starting alignment & scaling------------");
print(" ");
print(" ");
print(" ");


// show log window:
logScript =
    "lw = WindowManager.getFrame('Log');\n"+
    "if (lw!=null) {\n"+
    "   lw.setLocation("+ (screenWidth - 390) +",20);\n"+
    "   lw.setSize(380, 600)\n"+
    "}\n";
eval("script", logScript); 


//selectImage(2);
//visAlignID = getImageID();

//selectImage(1);
//uvAlignID = getImageID();

selectImage(uvAlignID);
w = getWidth;
h = getHeight;

//maxOff = 16;
//windowSize = 1.05; // e.g. 5 will create a central window 1/5th of the image width

winW = round(w/windowSize); // window height
winH = round(h/windowSize); // window width
initialX = round((w/2)-(winW/2));
initialY = round((h/2)-(winH/2));
//bestScale = 0.98;
//scaleWindow = 0.01;
//nScales = 8;
bestScale = 1-scaleWindow;
//firstFlag = 0;
smallBig = newArray(0,0);
prevBestFit = 2 * pow(2,bitDepth());
xOff = newArray(2);
yOff = newArray(2);


setBatchMode(true);


//while(scaleWindow > 0.0001){
for(k=0; k<nScales; k++){ // Scaling loop

print("\\Update3:Aligning scale level " + (k+1) + " of " + nScales);

for(i=0; i<2; i++){

if(nScales == 1)
	i = 1; // if only one scaling loop is specified then ditch the first scan & get on with second

offset = maxOff;
bestFit = 2 * pow(2,bitDepth());

if(i == 0) //smaller
	scaleVal = bestScale - scaleWindow;
if(i == 1) // bigger
	scaleVal = bestScale + scaleWindow;


// SCALING

winX = initialX;
winY = initialY;

selectImage(uvAlignID);

if(nScales > 1){ // normal scaling behaviour
	showStatus("Aligning - Scaling level " + (k+1) + " of " + nScales);
	run("Scale...", "x=&scaleVal y=&scaleVal interpolation=Bilinear average create title=scaleUV.tif");
}
if(nScales ==1){ // if scaling is turned off, just copy the image instead
	run("Select All");
	run("Copy");
	run("Internal Clipboard");
}

showProgress(k/nScales);
showStatus("Aligning - Scaling level " + (k+1) + " of " + nScales);

makeRectangle(winX*scaleVal, winY*scaleVal, winW, winH); // select central region of image
run("Crop");
croppedUV = getImageID();



//setPasteMode("Difference");



//__________________________ALIGNMENT LOOP________________________________




bestX = winX;
bestY = winY;
endFlag =0;

//print("best x: " +bestX);
//print("best y: " +bestY)

bars = 0;

while(offset > 0 && endFlag < 2){
//print(offset);

//CENTRE
	selectImage(visAlignID);
	makeRectangle(winX, winY, winW, winH);
	run("Copy");
	run("Internal Clipboard");
	tempVis = getImageID();
	imageCalculator("difference create", croppedUV, tempVis);

	getStatistics(area, mean, min, max);
		if(mean<bestFit){
			bestFit = mean;
			bestX = winX;
			bestY = winY;
		}
	close();
	selectImage(tempVis);
	close();
//print(mean);
//TOP LEFT
	selectImage(visAlignID);
	makeRectangle(winX-offset, winY-offset, winW, winH);
	run("Copy");
	run("Internal Clipboard");
	tempVis = getImageID();
	imageCalculator("difference create", croppedUV, tempVis);

	getStatistics(area, mean, min, max);
		if(mean<bestFit){
			bestFit = mean;
			bestX = winX-offset;
			bestY = winY-offset;
		}
	close();
	selectImage(tempVis);
	close();
//print(mean);
//TOP
	selectImage(visAlignID);
	makeRectangle(winX, winY-offset, winW, winH);
	run("Copy");
	run("Internal Clipboard");
	tempVis = getImageID();
	imageCalculator("difference create", croppedUV, tempVis);

	getStatistics(area, mean, min, max);
		if(mean<bestFit){
			bestFit = mean;
			bestX = winX;
			bestY = winY-offset;
		}
	close();
	selectImage(tempVis);
	close();
//print(mean);
//TOP RIGHT
	selectImage(visAlignID);
	makeRectangle(winX+offset, winY-offset, winW, winH);
	run("Copy");
	run("Internal Clipboard");
	tempVis = getImageID();
	imageCalculator("difference create", croppedUV, tempVis);

	getStatistics(area, mean, min, max);
		if(mean<bestFit){
			bestFit = mean;
			bestX = winX+offset;
			bestY = winY-offset;
		}
	close();
	selectImage(tempVis);
	close();
//print(mean);
//RIGHT
	selectImage(visAlignID);
	makeRectangle(winX+offset, winY, winW, winH);
	run("Copy");
	run("Internal Clipboard");
	tempVis = getImageID();
	imageCalculator("difference create", croppedUV, tempVis);

	getStatistics(area, mean, min, max);
		if(mean<bestFit){
			bestFit = mean;
			bestX = winX+offset;
			bestY = winY;
		}
	close();
	selectImage(tempVis);
	close();
//print(mean);
//BOTTOM RIGHT
	selectImage(visAlignID);
	makeRectangle(winX+offset, winY+offset, winW, winH);
	run("Copy");
	run("Internal Clipboard");
	tempVis = getImageID();
	imageCalculator("difference create", croppedUV, tempVis);

	getStatistics(area, mean, min, max);
		if(mean<bestFit){
			bestFit = mean;
			bestX = winX+offset;
			bestY = winY+offset;
		}
	close();
	selectImage(tempVis);
	close();
//print(mean);
//BOTTOM
	selectImage(visAlignID);
	makeRectangle(winX, winY+offset, winW, winH);
	run("Copy");
	run("Internal Clipboard");
	tempVis = getImageID();
	imageCalculator("difference create", croppedUV, tempVis);

	getStatistics(area, mean, min, max);
		if(mean<bestFit){
			bestFit = mean;
			bestX = winX;
			bestY = winY+offset;
		}
	close();
	selectImage(tempVis);
	close();
//print(mean);
//BOTTOM LEFT
	selectImage(visAlignID);
	makeRectangle(winX-offset, winY+offset, winW, winH);
	run("Copy");
	run("Internal Clipboard");
	tempVis = getImageID();
	imageCalculator("difference create", croppedUV, tempVis);

	getStatistics(area, mean, min, max);
		if(mean<bestFit){
			bestFit = mean;
			bestX = winX-offset;
			bestY = winY+offset;
		}
	close();
	selectImage(tempVis);
	close();
//print(mean);
//LEFT
	selectImage(visAlignID);
	makeRectangle(winX-offset, winY, winW, winH);
	run("Copy");
	run("Internal Clipboard");
	tempVis = getImageID();
	imageCalculator("difference create", croppedUV, tempVis);

	getStatistics(area, mean, min, max);
		if(mean<bestFit){
			bestFit = mean;
			bestX = winX-offset;
			bestY = winY;
		}
	close();
	selectImage(tempVis);
	close();

bars ++;
nBars = " ";
for(l=0; l<bars; l++)
	nBars = nBars + "-";
print("\\Update:Aligning " + nBars);

//print(mean);
//print("best x: " +bestX);
//print("best y: " +bestY);

offset = round(offset/2); // halve the offset value

if(offset == 1)
	endFlag ++;


winX = bestX;
winY = bestY;

}// while alignment loop

selectImage(croppedUV);
close();


// imageCalculator("difference create selection", uvAlignID, visAlignID);


xOff[i] = initialX - bestX;
yOff[i] = initialY - bestY;

print("\\Update:Scale: " + scaleVal + "\t Fit: " + bestFit + "\t Offsets - x: " + xOff[i] + "\t y: " + yOff[i]);
print(" "); // new line for next row

smallBig[i] = bestFit;


}// bigger & smaller scaling loop

/*
if(scaleVal == 1){ // resets the maximum offset based on the initial (zero scaling) alignment
	if(abs(xOff) > abs(yOff))
		maxOff = 2*abs(xOff);
	else
		maxOff = 2*abs(yOff);
	print("New max offset: " + maxOff);
}
*/

if(nScales == 1)
	smallBig[0] = pow(2, bitDepth());

if(smallBig[0] < smallBig[1] && smallBig[0] < prevBestFit){
	bestScale = bestScale - scaleWindow;
	prevBestFit = smallBig[0];
	bestXOff = xOff[0];
	bestYOff = yOff[0];
}

if(smallBig[1] < smallBig[0] && smallBig[1] < prevBestFit){
	bestScale = bestScale + scaleWindow;
	prevBestFit = smallBig[1];
	bestXOff = xOff[1];
	bestYOff = yOff[1];
}

// if niether smaller or bigger are better then stay put at the current scale


scaleWindow = scaleWindow/2;

} // while scaling loop

print("______________________________________________");
print("------------Finished aligning & scaling------------");
print(" ");
print("Best Scale: " + bestScale + "\t Offsets x: " + bestXOff + "\t y: " + bestYOff);
if(abs(bestXOff) == (2*maxOff-1) || abs(bestYOff) == (2*maxOff-1))
	print(" \nWARNING: The best alignment is at the maximum\noffset value of " + ((2*maxOff)-1) + ".\nRun the script again and select a larger pixel offset.");

print("______________________________________________");

/*

print("\\Clear");
print( bestXOff + "," + bestYOff + "," +bestScale);
print("______________________________________________");
print("Best Scale: " + bestScale + "\t Offsets x: " + bestXOff + "\t y: " + bestYOff);
if(abs(bestXOff) == (2*maxOff-1) || abs(bestYOff) == (2*maxOff-1))
	print(" \nWARNING: The best alignment is at the maximum\noffset value of " + ((2*maxOff)-1) + ".\nRun the script again and select a larger pixel offset.");

*/
	// save results to table
	alignResultsTable = "[Alignment Results]";
	run("New... ", "name="+alignResultsTable+" type=Table");

	print(alignResultsTable, "\\Headings:x offset\ty offset\tscale");
	print(alignResultsTable, bestXOff +"\t" + bestYOff +"\t" + bestScale);



showStatus("Finished finding alignment");

//________________________DONE SCALING & ALIGNING___________________________

