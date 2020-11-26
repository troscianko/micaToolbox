/*
_______________________________________________________________________

	Title: Batch Measure Multispectral Image Analysis
	Author: Jolyon Troscianko
	Date: 16/10/2014
.................................................................................................................

Description:
''''''''''''''''''''''''''''''''
This tool measures a whole host of patter, colour and luminance metrics from a
folder full of .mspec multispectral images.

Instructions:
''''''''''''''''''''''''''''''''''''''''
See the included user guide for a full overview. There are laods of supported options.

Select a folder containing the .mspec images and their respective RAW files and
select the options you want to measure.

_________________________________________________________________________
*/



imageDIR = getDirectory("Select folder containing multispectral images");


fileList=getFileList(imageDIR);

mspecList=newArray();

for(i=0; i<fileList.length; i++) // list only mspec files
	if(endsWith(fileList[i], ".mspec")==1)
		mspecList = Array.concat(mspecList, fileList[i]);


// LISTING CONE CATCH MODELS

	modelPath = getDirectory("plugins")+"Cone Models";

	modelList=getFileList(modelPath);

	modelNames = newArray("None");

	for(i=0; i<modelList.length; i++){
		if(endsWith(modelList[i], ".class")==1 && modelList[i] != "Human_Luminance_32bit.class")
			modelNames = Array.concat(modelNames,replace(modelList[i],".class",""));
		if(endsWith(modelList[i], ".CLASS")==1 && modelList[i] != "Human_Luminance_32bit.class")
			modelNames = Array.concat(modelNames,replace(modelList[i],".CLASS",""));
	}

	for(i=0; i<modelNames.length; i++)
		modelNames[i] = replace(modelNames[i], "_", " ");

// IMAGE PROCESSING SETTINGS

	Dialog.create("Image Processing Settings");
		Dialog.addMessage("Select the visual system to use:");
		Dialog.addChoice("Model", modelNames);
		Dialog.addCheckbox("Add human luminance channel", 0);
		Dialog.addMessage("_______________________________________");
		Dialog.addMessage("Image Scaling");
		Dialog.addMessage("For pattern analysis all images must have the\nsame scale - scale bars must already be added\nto the image ROIs");
		Dialog.addNumber("Scale (px/mm)", 0);
		Dialog.addCheckbox("Ignore scale bars and use scale factor", 0);
		Dialog.addMessage("Set to zero to turn off scaling. If you're not sure\nwhat scale to use, run the \"Batch Scale Bar\nCalculation\" tool on this folder first.");
		Dialog.addNumber("Start processing at file number:", 1);
	Dialog.show();

	visualSystem = Dialog.getChoice();
	humanLum = Dialog.getCheckbox();
	scaleVal = Dialog.getNumber();
	ignoreScaleBar = Dialog.getCheckbox();
	//visualSystem = replace(visualSystem, "_", " ");
	startNumber = Dialog.getNumber()-1;

if(startNumber == 0){
	dataFilePath = imageDIR +"Image Analysis Results "+ visualSystem + ".csv";
	patternFilePath = imageDIR +"Pattern Analysis Results "+ visualSystem + ".csv";
	luminanceFilePath = imageDIR +"Luminance Analysis Results "+ visualSystem + ".csv";
}else {
	dataFilePath = imageDIR +"Image Analysis Results "+ visualSystem + "_restarting_from_" + mspecList[startNumber] + ".csv";
	patternFilePath = imageDIR +"Pattern Analysis Results "+ visualSystem + "_restarting_from_" + mspecList[startNumber] + ".csv";
	luminanceFilePath = imageDIR +"Luminance Analysis Results "+ visualSystem + "_restarting_from_" + mspecList[startNumber] + ".csv";
}

// BATCH PROCESSING LOOP


print("\\Clear");
print("_________________________________________________");
print("---Colour, Luminance & Pattern Measurements---");
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

for(i=startNumber; i<mspecList.length; i++){

	print("\\Update3:Processing Image " + (i+1) + " of " + mspecList.length);

	while(roiManager("count") > 0){ // clear ROIs
		roiManager("select", 0);
		roiManager("Delete");
	}


	// LOAD MULTISPECTRAL IMAGE
	imageString = "select=[" + imageDIR + mspecList[i] + "]";
	run("Create Stack from Config File", imageString);
	run("Normalise & Align Multispectral Stack", "normalise curve=[Straight Line] align");
	setSlice(1);

	// SCALE IMAGE
	if(scaleVal != 0 && ignoreScaleBar == 0){
		imageString= "pixels=" + scaleVal;
		run("Multispectral Image Scaler", imageString);
	}

	if(ignoreScaleBar == 1){
		if(i == startNumber){
			Dialog.create("Image Processing Settings");
				Dialog.addNumber("Scale value", 0.5);
				Dialog.addMessage("All images will be scaled using this value\ne.g. 0.5 will halve the image lengths & widths");
			Dialog.show();

			scaleVal = Dialog.getNumber();
		}

		imageString= "scaling=" + scaleVal;
		run("Multispectral Image Scaler No Scale Bar", imageString);
	}

	// CONVERT TO CONE CATCH
	origImage = getImageID();
	if(visualSystem != "None"){
		run(visualSystem);
		coneImage = getImageID();
		selectImage(origImage);
		close(); // close original image
	} else coneImage = getImageID; // if cone catch isn't being used

	if(humanLum == 1)
		run("Human Luminance 32bit");


if(i == startNumber){ // GET ANALYSIS SETTINGS IN FIRST IMAGE

// IMAGE ANALYSIS SETTINGS

luminanceChoiceArray = newArray(nSlices);
setSlice(1);
for(j=0; j<nSlices; j++){
	setSlice(j+1);
	luminanceChoiceArray[j] = getInfo("slice.label");
}

//luminanceChoiceArray = Array.concat(luminanceChoiceArray, "Calculate Human Luminance");


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
	Dialog.addChoice("Luminance_Channel", luminanceChoiceArray, defaultSettings[1]);
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

} // 


	// Remove scale bar if there's no pattern analysis

	deleteArray = newArray(); // list locations of scale bar(s)
	if(scaleVal == 0 || startSize == 0 || endSize == 0){
		nSelections = roiManager("count");
		for(j=0; j<nSelections; j++){
			roiManager("select", j);
			selName = getInfo("selection.name");	

			if( startsWith(selName, "Scale") == 1) // found the scale bar - delete
				deleteArray = Array.concat(deleteArray, j);
		}
		for(j=0; j<deleteArray.length; j++){
			roiManager("select", deleteArray[j]);
			roiManager("Delete");
		}

	}// endSize ==0



	//run("Pattern & Luminance Measurements", "image_label=test luminance_channel=dbl recale=1 start_size=2 end_size=512 step_size=1.41421356 step_multiplier=Multiply luminance_bands=32 lowest_luminance=0 highest_luminance=65535 transform_luminance=Linear prefix=[] output_energy_maps select=[/media/jolyon/NIKON D7000/2 grey temp/]");

	imageLabel = replace(mspecList[i], ".mspec", "");
	analysisString = "image_label=" + imageLabel +
		" luminance_channel=" + lumChoice +
		"  bandpass_method=" + bandChoice +
		" start_size=" + startSize +
		" end_size=" + endSize +
		" stepSize=" + stepSize +
		" step_Multiplier=" + multiplierChoice;
	if(outputPatternSpectrum == 1)
		analysisString = analysisString + " output_pattern_spectrum";
	if(energyMapOutput == 1)
		analysisString = analysisString +" output_energy_maps";

	analysisString = analysisString +
		" luminance_bands=" + lumBands +
		" lowest_luminance=" + histMin +
		" highest_luminance=" + histMax +
		" transform_luminance=" + transChoice +
		" prefix=[" + combi + "]";

	
	analysisString = analysisString +
		" select=[" + imageDIR + "]";

	run("Pattern Colour & Luminance Measurements", analysisString);
	close();

	selectWindow("Results");
	saveAs("Results", dataFilePath);
	selectWindow("Pattern Results");
	saveAs("Results", patternFilePath);
	selectWindow("Luminance Results");
	saveAs("Results", luminanceFilePath);



}// i batch loop


while(roiManager("count") > 0){ // clear ROIs
	roiManager("select", 0);
	roiManager("Delete");
}

print("\\Update3:Finished Processing " + mspecList.length + " images.");

