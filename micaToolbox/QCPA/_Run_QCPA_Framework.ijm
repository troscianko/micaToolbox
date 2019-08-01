/*__________________________________________________________________

	Title: QCPA Framework Script
	''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	Authors: Jolyon Troscianko & Cedric van den Berg
	Date: 18/3/2018
............................................................................................................

This script applies the QCPA framework to a cone-catch image


............................................................................................................

Requirements:

A di, tri, or tetrachromatic cone-catch image. There must be an additional
final slice which is the "luminance" channel.

____________________________________________________________________
*/




oTitle = getTitle();

// LIST VISUAL SYSTEM WEBER FRACTIONS

	vsPath = getDirectory("plugins")+"micaToolbox/weberFractions";
	vsList=getFileList(vsPath);
	vsNames = newArray();
	vsNames = Array.concat("Custom", vsNames);

	for(i=0; i<vsList.length; i++){
		if(endsWith(vsList[i], ".txt")==1)
			vsNames = Array.concat(vsNames,replace(vsList[i],".txt",""));
		if(endsWith(vsList[i], ".TXT")==1)
			vsNames = Array.concat(vsNames,replace(vsList[i],".TXT",""));
	}

	headings = String.getResultsHeadings;
	headings = replace(headings, "Label\t", "");
	headings = replace(headings, " \t", "");
	headings = split(headings, "\t");
	if(headings.length == 1)
		exit("Exiting - there are no data\nOpen the data so that they are in the results window (e.g. open a .csv file)");

	acuityMethod = newArray("None", "AcuityView", "Gaussian");
	clusterMethod = newArray("None", "RNL Cluster", "Naive Bayes");

//------------------LOAD PREVIOUSLY USED VALUES---------------------

settingsFilePath = getDirectory("plugins") + "micaToolbox/QCPA/frameworkSettings.txt";
if(File.exists(settingsFilePath) == 1){
	settingsString=File.openAsString(settingsFilePath);	// open txt data file
	defaultSettings=split(settingsString, "\n");
} else defaultSettings = newArray(
"AcuityView",
"1",
"RNL Cluster",
"Custom",
"0.1",
"0",
"0");

Dialog.create("QCPA Framework Options");
	Dialog.addMessage("Ensure the current image has a luminance channel as the last slice");
	Dialog.addMessage("Select which aspects of processing to apply:");
	Dialog.addChoice("Acuity Correction", acuityMethod, defaultSettings[0]);
	Dialog.addMessage("AcuityView is fast and uses FFT, but requires use on whole-images.\nThe Gaussian method is slower, but can measure ROIs independently\nof their surroundings");
	Dialog.addCheckbox("RNL_Ranked_Filter", defaultSettings[1]);
	Dialog.addChoice("Clustering", clusterMethod, defaultSettings[2]);
	Dialog.addChoice("Visual system Weber fractions", vsNames, defaultSettings[3]);
	Dialog.addNumber("Luminance Weber fraction", defaultSettings[4]);
	Dialog.addCheckbox("Particle Analysis", defaultSettings[5]);
	Dialog.addCheckbox("Local Edge Intensity Analysis", defaultSettings[6]);
	Dialog.addMessage("When using this Beta version of the framework cite: van den Berg &\nTroscianko et al. (2019) Quantitative Colour Pattern Analysis (QCPA):\nA Comprehensive Framework for the Analysis of Colour Patterns in\nNature, BIORXIV/2019/592261");
	Dialog.addHelp("http://www.empiricalimaging.com/knowledge-base/running-the-qcpa-framework/");
Dialog.show();


acChoice = Dialog.getChoice();
runWRF = Dialog.getCheckbox();
clChoice = Dialog.getChoice();
vsChoice = Dialog.getChoice();
lumWeber = Dialog.getNumber();
plAnalysis = Dialog.getCheckbox();
leiAnalysis = Dialog.getCheckbox();

// -----------------------SAVE PREVIOUSLY USED SETTINGS----------------------------
dataFile = File.open(settingsFilePath);
	print(dataFile, acChoice);
	print(dataFile, runWRF);
	print(dataFile, clChoice);
	print(dataFile, vsChoice);
	print(dataFile, lumWeber);
	print(dataFile, plAnalysis);
	print(dataFile, leiAnalysis);
File.close(dataFile);


// GET SELECTED WEBER FRACTIONS

if(vsChoice == "Custom"){ //----------------custom Weber fractions------------

	channelNames = newArray(nSlices-1);

	for(i=0; i<nSlices-1; i++){
		setSlice(i+1);
		if(getMetadata("Label") == "")
			setMetadata("Label", i+1);
		channelNames[i] = getMetadata("Label");
	}

	Dialog.create("Specify Weber fractions");
		Dialog.addMessage("Specify the Weber fraction associated with each\nchannel. Note that the last channel should be the\nluminance channel, and is not listed here.");
		for(i=0; i<nSlices-1; i++)
			Dialog.addNumber(channelNames[i], 0.05);
		
	Dialog.show();
	

	weberFractions = newArray(nSlices-1);
	for(i=0; i<nSlices-1; i++)
		weberFractions[i] = Dialog.getNumber();		
	

}else {

	tempString = File.openAsString(vsPath + "/" + vsChoice + ".txt");
	tempString = split(tempString, "\n");

	channelNames = newArray(tempString.length-1);
	weberFractions = newArray(tempString.length-1);

	for(i=1; i<tempString.length; i++){
		row = split(tempString[i], "\t");
		channelNames[i-1] = row[0];
		weberFractions[i-1] = parseFloat(row[1]);
	}

	if(weberFractions.length > 4) //  make sure there aren't too many channels
		exit("Error - more than 4 channels\n \nThis code only calculates JNDs with 2, 3 or 4 channels.\nMake sure your Weber fractions file has the correct format.");

	if(weberFractions.length < 2) //  make sure there aren't too many channels
		exit("Error - fewer than 2 channels\n \nThis code only calculates JNDs with 2, 3 or 4 channels.\nMake sure your Weber fractions file has the correct format.");

	//-------check image slice names match channels-------------

	sliceNames = newArray(nSlices);

	for(i=0; i<nSlices; i++){
		setSlice(i+1);
		sliceNames[i] = getMetadata("Label");
	}

	matchCount = 0;
	
	tChannelNames = Array.copy(channelNames);
	tWeberFractions = Array.copy(weberFractions);

	for(j=0; j<sliceNames.length; j++)
		for(i=0; i<channelNames.length; i++)
			if(tChannelNames[i] == sliceNames[j]){
				matchCount++;
				weberFractions[j] = tWeberFractions[i];
				channelNames[j] = tChannelNames[i];
			}


	if(matchCount < channelNames.length){
		Array.show(channelNames, sliceNames);
		exit("Error - The current image channel names do not match the specified Weber fractions.\nThis script will stop and show the Weber fraction names and slice names for checking.\nNote that the order does not need to match, only the names.");
	}


}


//Array.show(channelNames, weberFractions);

gausROI = "whole image";

if(acChoice == "AcuityView")
	run("Acuity View");
if(acChoice == "Gaussian"){
	run("Gaussian Acuity Control");

	// if using Gaussian, does the user select a specific ROI?
	gausROI = getInfo("log");

	gausROI = split(gausROI, "\n");
	gausROI = replace(gausROI[gausROI.length-2], "Image Region = ", "");

}
leiaID = getImageID();


if(runWRF == true){

	oTitle = getTitle();


	//------------------LOAD PREVIOUSLY USED VALUES---------------------

	settingsFilePath = getDirectory("plugins") + "micaToolbox/QCPA/wrfSettings.txt";
	if(File.exists(settingsFilePath) == 1){
		settingsString=File.openAsString(settingsFilePath);	// open txt data file
		defaultSettings=split(settingsString, "\n");
	} else defaultSettings = newArray(
	//"0.10",
	"5",
	"5",
	"3");

	Dialog.create("RNL Ranked Filter Settings");
		//Dialog.addNumber("Luminance Weber fraction:", defaultSettings[0]);
		Dialog.addNumber("Iterations:", defaultSettings[0]);
		Dialog.addNumber("Radius:", defaultSettings[1]);
		Dialog.addMessage("If you specified a pixels-per-MRA, you should\nuse the same number as the radius here.");
		
		Dialog.addNumber("Falloff:", defaultSettings[2]);
		Dialog.addMessage("Higher falloff values create a steeper falloff\nin the influence of neighbouring pixels,\npreserving more fine detail");
		Dialog.addHelp("http://www.empiricalimaging.com/knowledge-base/rnl-ranked-filter/");	
	Dialog.show();

	//lumWeber = Dialog.getNumber();
	iterations = parseInt(Dialog.getNumber());
	radius = parseInt(Dialog.getNumber());
	falloff = Dialog.getNumber();

	// -----------------------SAVE PREVIOUSLY USED SETTINGS----------------------------
	dataFile = File.open(settingsFilePath);
		//print(dataFile, lumWeber);
		print(dataFile, iterations);
		print(dataFile, radius);
		print(dataFile, falloff);
	File.close(dataFile);


	tStr = "";

	for(i=0; i<weberFractions.length; i++)
		tStr = tStr + " weber_" + channelNames[i] + "=" + weberFractions[i];
	tStr = tStr + " lum=" + lumWeber + " iterations=" + iterations + " radius=" + radius + " falloff=" + falloff;
	run("RNL Ranked Filter", tStr);
	//run("Weber Ranked Filter", "weber_1=0.050 weber_2=0.071 weber_3=0.166 lum=0.0500 iterations=1 radius=1 falloff=2.0000");

	rename(oTitle+"_WeberFiltered_itr" + iterations + "_rad"+ radius + "_fall" + falloff);
	tStr = replace(tStr, " ", "\n");
	print("________________________________");
	print("--------------RNL-Filter--------------");
	print(tStr);
	print("________________________________");

	leiaID = getImageID();
}


if(clChoice == "RNL Cluster"){

	oTitle = getTitle();

	//------------------LOAD PREVIOUSLY USED VALUES---------------------

	settingsFilePath = getDirectory("plugins") + "micaToolbox/QCPA/RNLclusterSettings.txt";
	if(File.exists(settingsFilePath) == 1){
		settingsString=File.openAsString(settingsFilePath);	// open txt data file
		defaultSettings=split(settingsString, "\n");
	} else defaultSettings = newArray(
	"2",
	"5",
	"20",
	"2",
	"10",
	"6",
	"1",
	"20",
	oTitle,
	//"0.10",
	"0",
	"0");

	Dialog.create("RNL Clustering Settings");
		Dialog.addNumber("Colour JND Threshold", defaultSettings[0]);
		Dialog.addNumber("Luminance JND Threshold", defaultSettings[1]);
		Dialog.addNumber("Loops", defaultSettings[2]);
		Dialog.addNumber("Radius multiplier", defaultSettings[3]);
		Dialog.addNumber("Minimum cluster size", defaultSettings[4]);
		Dialog.addNumber("Compare all clusters from pass:", defaultSettings[5]);
		Dialog.addNumber("Stop clustering if number of clusters is below", defaultSettings[6]);
		Dialog.addNumber("Record output from pass", defaultSettings[7]);
		Dialog.addString("Image Label", oTitle, defaultSettings[8]);
		//Dialog.addNumber("Luminance Weber fraction", defaultSettings[9]);
		Dialog.addCheckbox("Show separate horizontal and vertical adjacency results", defaultSettings[9]); 
		Dialog.addCheckbox("Output adjacency matrix", defaultSettings[10]); 
		Dialog.addHelp("http://www.empiricalimaging.com/knowledge-base/rnl-clustering/");	
	Dialog.show();


	colJND = Dialog.getNumber();
	lumJND = Dialog.getNumber();
	loops = parseInt(Dialog.getNumber());
	rMultiplier = Dialog.getNumber();
	minSize = parseInt(Dialog.getNumber());
	compareFrom = parseInt(Dialog.getNumber());
	stopN = parseInt(Dialog.getNumber());
	recordFrom = parseInt(Dialog.getNumber());
	imLabel = Dialog.getString();
	imLabel = replace(imLabel, " ", "_");

	//lumWeber =  Dialog.getNumber();
	hvOutput = Dialog.getCheckbox();
	mOutput = Dialog.getCheckbox();

	// -----------------------SAVE PREVIOUSLY USED SETTINGS----------------------------
	dataFile = File.open(settingsFilePath);
		print(dataFile, colJND);
		print(dataFile, lumJND);
		print(dataFile, loops);
		print(dataFile, rMultiplier);
		print(dataFile, minSize);
		print(dataFile, compareFrom);
		print(dataFile, stopN);
		print(dataFile, recordFrom);
		print(dataFile, imLabel);
		//print(dataFile, lumWeber);
		print(dataFile, hvOutput);
		print(dataFile, mOutput);
	File.close(dataFile);

	tStr = "colour_jnd_threshold=" + colJND + " luminance_jnd_threshold=" + lumJND + " loops=" + loops + " minimum=" + minSize + " compare=" + compareFrom + " stop=" + stopN + " record=" + recordFrom + " image=[" + imLabel + "]";
	for(i=0; i<weberFractions.length; i++)
		tStr = tStr + " weber_" + (i+1) + "=" + weberFractions[i];
		//tStr = tStr + " weber_" + channelNames[i] + "=" + weberFractions[i];
	tStr = tStr + " luminance_weber_fraction=" + lumWeber;
	//if(hvOutput == true)
	//	tStr = tStr + " horizontal";
	//if(mOutput == true)
	//	tStr = tStr + " output_adjacency_matrix";

	run("RNL Clustering", tStr);

	selectImage(imLabel + "_Cluster_IDs");
	//waitForUser("waiting");

	// ----- Run QCPA on whole image-----------

	if(gausROI == "whole image"){

		run("Select All");

		tStr = "image=[" + imLabel + "_whole-image]";
		for(i=0; i<weberFractions.length; i++)
			tStr = tStr + " weber_" + (i+1) + "=" + weberFractions[i];
		tStr = tStr + " luminance_weber_fraction=" + lumWeber;
		if(hvOutput == true)
			tStr = tStr + " horizontal";
		if(mOutput == true)
			tStr = tStr + " output";

		run("QCPA Analysis", tStr);
	} // run QCPA analysis on whole image (means there isn't redundancy when selecting a single ROI in the Gaussian acuity method)


	// ----- Run QCPA on ROIs-----------

	nROIs = roiManager("count");


	for(r=0; r<nROIs; r++){

		roiManager("Select", r);
		roiName = Roi.getName;
		if(startsWith(roiName, "Scale") == false){ // ignore scale bars
		
			tStr = "image=[" + imLabel + "_" + roiName + "]";
			for(i=0; i<weberFractions.length; i++)
			tStr = tStr + " weber_" + (i+1) + "=" + weberFractions[i];
			tStr = tStr + " luminance_weber_fraction=" + lumWeber;
			if(hvOutput == true)
				tStr = tStr + " horizontal";
			if(mOutput == true)
				tStr = tStr + " output";

			run("QCPA Analysis", tStr);

		}//ignore scale bar
	}




	//run("RNL Clustering", "colour_jnd_threshold=3.000 luminance_jnd_threshold=3.000 loops=20 radius=2.000 minimum=10 compare=6 stop=1 record=20 image=ImageID weber_1=0.050 weber_2=0.050 weber_3=0.050 weber_4=0.050 luminance_weber_fraction=0.050 horizontal output_adjacency_matrix");
} // RNL cluster

if(clChoice == "Naive Bayes"){
	updateResults();

	oTitle = getTitle();


	if(nResults > 1){
		if(nResults >256)
			exit("This method only supports 256 different clusters, but in practice works best with a handful");
	}else if(roiManager("Count") > 1){
		run("Measure ROIs");
		if(nResults >256)
			exit("This method only supports 256 different clusters, but in practice works best with a handful");

	} else exit("There are no results or ROIs - either open some suitable measurements or specify some ROIs");

	updateResults();
	run("Naive Bayes Classify");


	Dialog.create("Naive Bayes Cluster Analysis Settings");
		Dialog.addString("Image Label", oTitle, 30);
		//Dialog.addNumber("Luminance Weber fraction", lumWeber);
		Dialog.addCheckbox("Show separate horizontal and vertical adjacency results", false); 
		Dialog.addCheckbox("Output adjacency matrix", false); 
		Dialog.addHelp("http://www.empiricalimaging.com/knowledge-base/naive-bayes-clustering/");
	Dialog.show();


	imLabel = Dialog.getString();
	imLabel = replace(imLabel, " ", "_");

	//lumWeber =  Dialog.getNumber();
	hvOutput = Dialog.getCheckbox();
	mOutput = Dialog.getCheckbox();

	tStr = "image=[" + imLabel + "]";
	for(i=0; i<weberFractions.length; i++)
		tStr = tStr + " weber_" + (i+1) + "=" + weberFractions[i];
	tStr = tStr + " luminance_weber_fraction=" + lumWeber;
	if(hvOutput == true)
		tStr = tStr + " horizontal";
	if(mOutput == true)
		tStr = tStr + " output";

	print(tStr);
	run("QCPA Analysis", tStr);

	//run("Adjacency Analysis", "image=ImageID weber_1=0.050 weber_2=0.050 weber_3=0.050 weber_4=0.050 luminance_weber_fraction=0.050 horizontal output");

} // Naive bayes cluster




if(plAnalysis == true){
	run("Cluster Particle Analysis");

}



if(leiAnalysis == true){
	selectImage(leiaID);
	oTitle = getTitle();
	tOptions = newArray("none", "log", "sqrt");

	//------------------LOAD PREVIOUSLY USED VALUES---------------------

	settingsFilePath = getDirectory("plugins") + "micaToolbox/QCPA/leiaSettings.txt";
	if(File.exists(settingsFilePath) == 1){
		settingsString=File.openAsString(settingsFilePath);	// open txt data file
		defaultSettings=split(settingsString, "\n");
	} else defaultSettings = newArray(
	oTitle,
	"0.10",
	"none",
	"0",
	"0",
	"0",
	"20");


	Dialog.create("Local Edge Intensity Analysis Settings");
		Dialog.addString("Image Label", oTitle, 30);
		//Dialog.addNumber("Luminance Weber fraction", defaultSettings[1]);
		Dialog.addChoice("Transform delta S values:", tOptions, defaultSettings[2]);
		Dialog.addNumber("Ignnore_chromatic delta S values below:", defaultSettings[3]);
		Dialog.addNumber("Ignnore_luminance delta S values below:", defaultSettings[4]);
		Dialog.addCheckbox("Show horizontal and vertical data", defaultSettings[5]);
		Dialog.addNumber("Maximum display value", defaultSettings[6]);
		Dialog.addHelp("http://www.empiricalimaging.com/knowledge-base/local-edge-intensity-analysis-leia/");
	Dialog.show();

	imLabel = Dialog.getString();
	imLabel = replace(imLabel, " ", "_");

	//lumWeber =  Dialog.getNumber();
	tChoice = Dialog.getChoice();
	ict = Dialog.getNumber();
	ilt = Dialog.getNumber();
	hvOutput = Dialog.getCheckbox();
	maxDisplay = Dialog.getNumber();

	// -----------------------SAVE PREVIOUSLY USED SETTINGS----------------------------
	dataFile = File.open(settingsFilePath);
		print(dataFile, imLabel);
		print(dataFile, lumWeber);
		print(dataFile, tChoice);
		print(dataFile, ict);
		print(dataFile, ilt);
		print(dataFile, hvOutput);
		print(dataFile, maxDisplay);
	File.close(dataFile);


	//run("Local Edge Intensity Analysis", "image=ImageID weber_1=0.050 weber_2=0.071 weber_3=0.166 luminance_weber_fraction=0.100 transform=log ignore_chromatic=1 ignore_luminance=1 horizontal");

	tStr = "image=[" + imLabel + "]";
	for(i=0; i<weberFractions.length; i++)
		tStr = tStr + " weber_" + (i+1) + "=" + weberFractions[i];
	tStr = tStr + " luminance_weber_fraction=" + lumWeber;
	tStr = tStr + " transform=" + tChoice;
	tStr = tStr + " ignore_chromatic=" + ict;
	tStr = tStr + " ignore_luminance=" + ilt;
	if(hvOutput == true)
		tStr = tStr + " horizontal";

	run("Local Edge Intensity Analysis", tStr);
	leiaLumID = getImageID();
	leiaColID = leiaLumID+1;

	//if(tChoice == "none")
		//sdMult = 15;

	minDisplay = 0;

	if(tChoice == "log"){
		//sdMult = log(15);
		maxDisplay = log(maxDisplay);
		minDisplay = -5;
	}
	if(tChoice == "sqrt")
		//sdMult = sqrt(15);
		maxDisplay = pow(maxDisplay, 0.5);

	//-----------check whether LUT exists, if not install---------------
	lutPath = getDirectory("luts") + "BlueRed.lut";

	if(File.exists(lutPath) == false){
		print("LUT required - installing...");
		lutCopyPath = getDirectory("plugins") + "micaToolbox/BlueRed.lut";
		//if(File.copy(lutCopyPath, lutPath) != true){
		//	print("LUT could not be copied across");
		//}
		File.copy(lutCopyPath, lutPath);
		print("LUT installed successfully");
		run("Refresh Menus");
	}

	//selectImage(imLabel + "_Lum_LEIA");
	selectImage(leiaLumID);

	run("Make Composite", "display=Composite");
	setSlice(1);
	run("Red");
	setSlice(2);
	run("Green");
	setSlice(3);
	run("Blue");
	setSlice(4);
	run("BlueRed");
	setSlice(1);

	ts = "min=0 max=" + maxDisplay;
	run("Set Min And Max", ts);


	//selectImage(imLabel + "_Col_LEIA");
	selectImage(leiaColID);

	run("Make Composite", "display=Composite");
	setSlice(1);
	run("Red");
	setSlice(2);
	run("Green");
	setSlice(3);
	run("Blue");
	setSlice(4);
	run("BlueRed");
	setSlice(1);

	run("Set Min And Max", ts);

}










