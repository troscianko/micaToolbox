/*
_______________________________________________________________________________________________

	Title: Pattern & Luminance Measurements

	Author: Jolyon Troscianko
	Date: 15/092014

-------------------------------------------------------------------------------------------------------------------------------
Description:

This script runs fast-Fourier-transform bandpass filtering of the image at different spatial scales.
This basically means splitting the image in multiple spatial scales, and measuring the amount of "energy"
(i.e. variance) at each spatial scale. The energy spectra generated are used for pattern comparisons.

This code measures energy as standard deviaiton rather than: [variance/number of pixels] as some
others have done. This is because standard deviation maintains a linear scale with the original data,
whereas variance squares the values, making large energy values non-linearly larger than smaller
values (and I can't find any reason in the literature to use a non-linear energy scale).

The code deals with non-square selection areas by extracting the area and measuring it's energy
against a zero (black) background, then doing the same with a "null" image, that has the same shape
as the selection area, but is filled with the mean pixel level (i.e. the same shape with all pattern data
removed)

The code offers the option of scaling the image before processing. This is handy with large images that
would otherwise be very slow to process.

The code ask whether you'd like to combine any selection areas (regions of interest - ROIs) using a
specific prefix. E.g. if you've got ROIs labelled egg1 and egg2, adding "egg" to the option box will combine
the two eggs and analyse them as one. Otherwise it will measure them separately.

-------------------------------------------------------------------------------------------------------------------------------

Requirements:

- REQUIRES A 32-BIT IMAGE
- Images that you want to compare for pattern MUST all have the same scale (pixels/mm).
- Should ideally be run on luminance cone catch images, or at least linear reflectance values - if the
  latter then the green channel is probably best to approximate bird double cone sensitivities.
- Areas to measure should be in the ROI manager (use the Multiple Area Selection plugin). If no
  areas are selected the whole image will be used. The code should be able to deal with any selection
  shape.

_______________________________________________________________________________________________
*/




nSelections = roiManager("count");
roiManager("Show All with labels");

//setBatchMode(true);
sliceNames = newArray(nSlices);
setSlice(1);
for(i=0; i<nSlices; i++){
	setSlice(i+1);
	sliceNames[i] = getInfo("slice.label");
}


imagePath = getInfo("image.directory"); // for saving energy map


// LOAD PREVIOUSLY USED VALUES

settingsFilePath = getDirectory("plugins") + "micaToolbox/analysisSettings.txt";
if(File.exists(settingsFilePath) == 1){
	settingsString=File.openAsString(settingsFilePath);	// open txt data file
	defaultSettings=split(settingsString, "\n");
} else defaultSettings = newArray(
"",	//0 rowLabel
"dbl",	//1 lumChoice
"2",	//2 startSize 
"512",	//3 endSize 
d2s(pow(2,0.5),9),	//4 stepSize 
"Multiply",	//5 multiplierChoice 
"1",	// 6 pattern spectrum
"0",	// 7 energyMapOutput
"32",	//8 lumBands
"0",	//9 histMin 
"100",	//10 histMax 
"Linear",	//11 transChoice 
"",	//12 combi
"FFT");	//13 bandpass method



bMethods = newArray("FFT", "DoG");

Dialog.create("Pattern & Luminance Measurement");
	Dialog.addString("Image_Label", " ");
	Dialog.addChoice("Luminance_Channel", sliceNames, defaultSettings[1]);
	Dialog.addMessage("Image Scaling (all images must be scaled uniformly):");
	Dialog.addMessage("Pattern Analysis Options:");
	Dialog.addChoice("Bandpass_Method", bMethods, defaultSettings[13]);
	Dialog.addNumber("Start_Size (px, 0 = off)", defaultSettings[2]);
	Dialog.addNumber("End_Size (px)", defaultSettings[3]);
	Dialog.addNumber("Step_Size", defaultSettings[4], 8, 10, "");
	Dialog.addChoice("Step_Multiplier", newArray("Add", "Multiply"), defaultSettings[5]);
	Dialog.addCheckbox("Output_Pattern_Spectrum",  defaultSettings[6]);
	Dialog.addCheckbox("Output_Energy_Maps", defaultSettings[7]);
	Dialog.addMessage("Visual display of the energy maps - saved alongside\nthe original image. Useful for checking, but remember\nthese are auto-scaled, so adjsut the brightness settings\non different images before comparing them directly");
	Dialog.addMessage("Luminance Options:");
	Dialog.addNumber("Luminance_Bands (0 = off)", defaultSettings[8]);
	Dialog.addNumber("Lowest_Luminance", defaultSettings[9]);
	Dialog.addNumber("Highest_Luminance", defaultSettings[10]);
	Dialog.addChoice("Transform_Luminance", newArray("Linear", "Square Root", "Log"), defaultSettings[11]);
	Dialog.addMessage("Combine ROIs:");
	Dialog.addString("Prefix (separate with a comma)", defaultSettings[12]);
	
Dialog.show();

rowLabel = Dialog.getString();
lumChoice = Dialog.getChoice();
bandChoice = Dialog.getChoice();
startSize = Dialog.getNumber();
endSize = Dialog.getNumber();
stepSize = Dialog.getNumber();
multiplierChoice = Dialog.getChoice();
outputPatternSpectrum = Dialog.getCheckbox();
energyMapOutput = Dialog.getCheckbox();
lumBands = Dialog.getNumber();
histMin = Dialog.getNumber();
histMax = Dialog.getNumber();
transChoice = Dialog.getChoice();
combi = Dialog.getString();

if(startSize ==0 || endSize == 0){
	energyMapOutput = 0; // make sure energy map output is switched off if pattern isn't being measured
	startSize = 0;
	endSize = 0;
}

// SAVE PREVIOUSLY USED SETTINGS
dataFile = File.open(settingsFilePath);

	print(dataFile, rowLabel);
	print(dataFile, lumChoice);
	print(dataFile, startSize);
	print(dataFile, endSize);
	print(dataFile, d2s(stepSize,9));
	print(dataFile, multiplierChoice);
	print(dataFile, outputPatternSpectrum);
	print(dataFile, energyMapOutput);
	print(dataFile, lumBands);
	print(dataFile, histMin);
	print(dataFile, histMax);
	print(dataFile, transChoice);
	print(dataFile, combi);
	print(dataFile, bandChoice);

File.close(dataFile);

if(imagePath == "" && energyMapOutput == 1)
	imagePath = getDirectory("Select output directory for energy maps");

if(transChoice == "Square Root"){
	histMin = pow(histMin, 0.5);
	histMax = pow(histMax, 0.5);
}

if(transChoice == "Log"){
	histMin = log(histMin);
	histMax = log(histMax);
}

// SET UP TABLES

windowList = getList("window.titles");

patternTableExists = 0;
luminanceTableExists = 0;

for(i=0; i<windowList.length; i++){
	if(windowList[i] == "Pattern Results")
		patternTableExists = 1;
	if(windowList[i] == "Luminance Results")
		luminanceTableExists = 1;
}

if(patternTableExists == 0){
	run("New... ", "name=[Pattern Results] type=Table");
	print("[Pattern Results]", "\\Headings:Label\tpattern_size\tpattern_energy");
}
if(luminanceTableExists == 0){
	run("New... ", "name=[Luminance Results] type=Table");
	print("[Luminance Results]", "\\Headings:Label\tluminance\tcoverage");
}


//setBatchMode(true);

if(bitDepth() != 32)
	run("32-bit");

// LUMINANCE SLICE
imageSlices = nSlices;

	for(i=0; i<nSlices; i++)
		if(lumChoice == sliceNames[i])
			lumSlice = i+1;
	
	setSlice(lumSlice);

setBackgroundColor(0,0,0);


// COMBINE ROIs

selNames = newArray(nSelections);
run("Labels...", "color=white font=12 show use draw");
for(i=0; i<nSelections; i++){ // get names
	roiManager("select", i);
	selNames[i] = getInfo("selection.name");

}

if(combi != ""){

	combi = split(combi, ",");
	toDelete = newArray(); // index of ROIs that have been combined and need deleting
	
	for(i=0; i<combi.length; i++){
		combineIndex = newArray();

		for(j=0; j<nSelections; j++)
			if(startsWith(selNames[j], combi[i]) == 1)
				combineIndex = Array.concat(combineIndex, j);
		
		if(combineIndex.length > 1){ // only combine if there's more than one
			roiManager("Deselect");
			roiManager("select", combineIndex);
			roiManager("Combine");
			roiManager("Add");
			roiManager("select", roiManager("Count")-1);
			roiManager("Rename", combi[i]);

			toDelete = Array.concat(toDelete, combineIndex);
		} else if(combineIndex.length == 1){ // remove anything after the prefix
			roiManager("Deselect");
			roiManager("select", combineIndex[0]);
			roiManager("Rename", combi[i]);
		}

	}// i

	// Delete combined ROIs and reset names etc...
	if(combineIndex.length > 1){
		roiManager("Deselect");
		roiManager("select", toDelete);
		roiManager("Delete");
	}

	nSelections = roiManager("count");
	selNames = newArray(nSelections);
	for(i=0; i<nSelections; i++){ // get new names
		roiManager("Deselect");
		roiManager("select", i);
		selNames[i] = getInfo("selection.name");
	}


}// combine ROIs


// COLOUR MEASUREMENTS

nLoops = nSelections;
if(nSelections == 0)
	nLoops = 1;

setBatchMode(true);

nColours = imageSlices;


colourSaveMeans = newArray(nLoops*nColours);
colourSaveSD = newArray(nLoops*nColours);


for(j=0; j<nLoops; j++){ // ROI loop

	wholeImage = 0;
	if(nSelections == 0){ // if there's no ROI, use the whole image
		wholeImage = 1;
		run("Select All");
		roiManager("Add");
		selNames = newArray(1);
		selNames[0] = "whole_image";
	}

	roiManager("select", j);
	setSlice(1);
	for(i=0; i<nColours; i++){
		setSlice(i+1);
		getStatistics(colArea, colMean, colMin, colMax, colSD);
	//print(colMean);
		//setResult(selNames[j] + "_" + sliceNames[i] +"Mean", resultsRow, colMean);
		//setResult(selNames[j] + "_" + sliceNames[i] +"SD", resultsRow, colSD);
		colourSaveMeans[(nColours*j) + i] = colMean; // saving the values for later means all the columns can be kept organised as more are added
		colourSaveSD[(nColours*j) + i] = colSD;
	}
	

} // j nLoops Colour Measure


origID = getImageID();
w = getWidth();
h = getHeight();


//____________________________________________________________________________________________________

// MEASURE PATTERN & LUMINANCE

// LOOP FOR MULTIPLE ROIs

nLoops = nSelections;
if(nSelections == 0){
	nLoops = 1;
	//print("nSelections = 0");
}



for(j=0; j<nLoops; j++){ // ROI loop

	resultsRow = nResults;

	// OUTPUT PATTERN SCALE SIZES

	nSteps = 0;
	bandpassScales = newArray(1);
	bandpassScales[0] = startSize;

	i=startSize;
	if(startSize !=0 && endSize != 0){
		while(i <=endSize+0.001){
			nSteps++;
			if(multiplierChoice == "Add")
				i = i + stepSize;
			if(multiplierChoice == "Multiply")
				i = i * stepSize;
			bandpassScales = Array.concat(bandpassScales, i);
		} //
	} // if bandpass on

	setResult("Label", resultsRow, rowLabel + "_" + selNames[j]);
	
	selectImage(origID);
	row=0;

	wholeImage = 0;
	if(nSelections == 0){ // if there's no ROI, use the whole image
		wholeImage = 1;
		run("Select All");
		roiManager("Add");
		selNames = newArray(1);
		selNames[0] = "whole_image";
	}

	roiManager("select", j);
	getBoundingRect(selectionX, selectionY, selectionW, selectionH);
	setSlice(lumSlice);

	getStatistics(wholeArea, wholeMean, wholeMin, wholeMax, wholeSD);

	// MEASURE LUMINACE VALUES

	if(transChoice == "Square Root")
		run("Square Root", "slice");

	if(transChoice == "Log")
		run("Log", "slice");


	getHistogram(histVals, histCounts, lumBands, histMin, histMax);
	getStatistics(transArea, transMean, transMin, transMax, transSD);

	if(transChoice != "Linear")
		run("Undo");

	for(l=0; l<lumBands; l++){
		//setResult("lumHist", l + resultsRow, histCounts[l]/transArea);
		print("[Luminance Results]", rowLabel + "_" + selNames[j] + "\t" + ((l+1)/lumBands) + "\t" + d2s((histCounts[l]/transArea),9));
	}
	setResult("lumMean", resultsRow, transMean);
	setResult("lumSD", resultsRow, transSD);
	setResult("area", resultsRow, transArea);

	updateResults();



	if(energyMapOutput ==1){
		mapRange = histMax;

		if(transChoice == "Square Root")
			mapRange = transMax*transMax;

		if(transChoice == "Log")
			mapRange = exp(transMax);

		newImage(rowLabel+"_" +selNames[j] +"_energy_map" , "32-bit black", selectionW, selectionH, nSteps);
		outputEnergyMapID = getImageID();
		setMinAndMax(-1*mapRange/25, mapRange/25);
		//print(mapRange);
		run("Fire");
	}

	selectImage(origID);

	if(bandChoice == "FFT"){
	// GENREATE NULL IMAGE - an image with no pattern data, filled with the mean value - an alternative would be a larger blending, e.g. Gaussian

	i = startSize;
	if(startSize != 0 && endSize != 0){

	if(wholeImage == 0){
		run("Copy");
		run("Internal Clipboard");
		for(y=0; y<h; y++)
			for(x=0; x<w; x++)
				if(getPixel(x,y) != 0)
					setPixel(x, y, wholeMean);
		//updateDisplay();
		nullID = getImageID(); // image to use for null
	} // whole image

	powerArray = newArray(0);
	maxPower = 0;
	powerSum = 0;
	maxFreq = startSize;

	while(i <=endSize+0.001){
	//for(i=startSize; i<endSize+0.001; i = i *stepSize ){ // bandpass scale loop

		// RUN BANDPASS ON RAW IMAGE

		selectImage(origID);
		roiManager("select", j);
		setSelectionLocation(selectionX, selectionY);
		//if(scaleValue == 1)
			setSlice(lumSlice);
		run("Copy");
		run("Internal Clipboard");
		bandpassString = "filter_large=" + i + " filter_small=" + i + " suppress=None tolerance=5";
		run("Bandpass Filter...", bandpassString);
		energyTempID = getImageID();


		// RUN BANDPASS ON NULL IMAGE
		if(wholeImage == 0){
			selectImage(nullID);
			roiManager("select", j);
			setSelectionLocation(0, 0);
			run("Copy");
			run("Internal Clipboard");
			run("Bandpass Filter...", bandpassString);
			nullTempID = getImageID();

			// COMBINE RAW AND NULL IMAGE

			roiManager("select", j);
			setSelectionLocation(0, 0);
			run("Copy");
			selectImage(energyTempID);
			setPasteMode("Subtract");
			//roiManager("select", j);
			//setSelectionLocation(0, 0);
			run("Paste");
			setPasteMode("Normal");

			roiManager("select", j);
			setSelectionLocation(0, 0);
		} // whole image

		getStatistics(bandArea, bandMean, bandMin, bandMax, bandSD);
		if(outputPatternSpectrum ==1){
			//setResult("patternHist", row + resultsRow, bandSD);
			print("[Pattern Results]", rowLabel + "_" + selNames[j] + "\t" + i + "\t" + d2s(bandSD,9));
		}
		powerArray = Array.concat(powerArray, bandSD);
		powerSum = powerSum + bandSD;
		if(bandSD > maxPower){
			maxPower = bandSD;
			maxFreq = i;
		}


		updateResults();

		if(energyMapOutput ==1){
			run("Copy");
			selectImage(outputEnergyMapID);
			roiManager("select", j);
			setSelectionLocation(0, 0);
			setSlice(row+1);
			run("Paste");
			run("Enhance Contrast", "saturated=0.35");
			labelString = "label=" + d2s(i,3) + "px";
			run("Set Label...", labelString);
			setBatchMode("show");
		}
		row++;

		//waitForUser("Waiting");
		selectImage(energyTempID);
		if(wholeImage == 0)
			setSelectionLocation(selectionX, selectionY); // put the selection back - just so it doesn't look offset during processing 
		close();

		if(wholeImage == 0){
			selectImage(nullTempID);
			close();
		} // whole image

		if(multiplierChoice == "Add")
			i = i + stepSize;
		if(multiplierChoice == "Multiply")
			i = i * stepSize;

	}// i bandpass loop


	if(wholeImage == 0){
		selectImage(nullID);
		close();
	} // whole image
	}// zero = off

	} else if(bandChoice == "DoG"){// FFT method

	if(startSize != 0 && endSize != 0){

	powerArray = newArray(bandpassScales.length-1);
	maxPower = 0;
	powerSum = 0;
	maxFreq = startSize;

	selectImage(origID);
	roiManager("select", j);
	run("Duplicate...", " ");
	rename("A");
	bandpassString = "sigma=" + bandpassScales[0];
	run("Gaussian Blur...", bandpassString);

	for(i=0; i<bandpassScales.length-1; i++){

		// RUN BANDPASS ON RAW IMAGE
		selectImage(origID);
		roiManager("Deselect");
		roiManager("select", j);
		run("Duplicate...", " ");
		//roiManager("select", j);
		//setSelectionLocation(0, 0);
		rename("B");
		bandpassString = "sigma=" + bandpassScales[i+1];
		run("Gaussian Blur...", bandpassString);

		imageCalculator("Subtract", "A","B");
		selectImage("A");

		//setBatchMode("show");
		//waitForUser("waiting");


		getStatistics(bandArea, bandMean, bandMin, bandMax, bandSD);
		if(outputPatternSpectrum ==1){
			//setResult("patternHist", row + resultsRow, bandSD);
			print("[Pattern Results]", rowLabel + "_" + selNames[j] + "\t" + bandpassScales[i] + "\t" + d2s(bandSD,9));
		}
		powerArray[i] = bandSD;
		powerSum = powerSum + bandSD;
		if(bandSD > maxPower){
			maxPower = bandSD;
			maxFreq = bandpassScales[i];
		}


		//updateResults();

		if(energyMapOutput ==1){
			run("Copy");
			selectImage(outputEnergyMapID);
			setSlice(row+1);
			run("Select None");
			run("Paste");
			run("Enhance Contrast", "saturated=0.35");
			labelString = "label=" + d2s(bandpassScales[i],3) + "px";
			run("Set Label...", labelString);
			setBatchMode("show");
		}
		row++;

		//waitForUser("Waiting");
		//selectImage(energyTempID);
		if(wholeImage == 0)
			setSelectionLocation(selectionX, selectionY); // put the selection back - just so it doesn't look offset during processing 

		selectImage("A");
		close();
		selectImage("B");
		rename("A");

	}// i bandpass loop

	selectImage("A");
	close();

	}// zero = off


	}// method = DoG

	if(energyMapOutput ==1){
		selectImage(outputEnergyMapID);
		setSlice(1);
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		run("Add Selection...");
		saveAs("Tiff", imagePath + rowLabel+"_" +selNames[j] +"_energy_map.tif");
		close();
		//print(imagePath);
	}

	// SAVE DESCRIPTIVE STATS

	if(startSize !=0 && endSize != 0){
		Array.getStatistics(powerArray, powerMin, powerMax, powerMean, powerSD);

		setResult("maxPower", resultsRow, powerMax);
		setResult("maxFreq", resultsRow, maxFreq);
		setResult("propPower", resultsRow, powerMax/powerSum);
		setResult("sumPower", resultsRow, powerSum);
		setResult("meanPower", resultsRow, powerMean);
		setResult("powerSD", resultsRow, powerSD);
	}
	
	// OUTPUT SAVED COLOUR RESULTS - this is to keep all the columns in the same order
	for(i=0; i<nColours; i++){
		setResult(sliceNames[i] +"Mean", resultsRow, colourSaveMeans[(nColours*j) + i]);
		setResult(sliceNames[i] +"SD", resultsRow, colourSaveSD[(nColours*j) + i]);
	}

}// j ROIs

/*
if(scaleValue != 1){
	selectImage(origID); // scaled image
	close();
}
*/






