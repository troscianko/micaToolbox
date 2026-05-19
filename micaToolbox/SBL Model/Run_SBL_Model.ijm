/*
_______________________________________________________________________

	Title: SBL Model
	Author: Jolyon Troscianko
		Based on the SBL model developed by Troscianko & Osorio
	Date: 5/10/2024

.................................................................................................................

Description:
''''''''''''''''''''''''''''''''
Processes image using the SBL model, which is a colour appearance model
parametrised by contrast sensitivity functions (CSFs)

Instructions:
''''''''''''''''''''''''''''''''''''''''
Load and image and run... if it's a colour 24-bit (8-bits-per channel) image, it will
be converted to linear sRGB. If the image is 32-bit, it is assumed ot be linear
cone-catch.
_________________________________________________________________________
*/

setBatchMode(true);

//print(selectionType);
selFlag = 0;
if(selectionType >= 0){
	selFlag = 1;
	getSelectionCoordinates(xs, ys);
}

poolW = 1;
postSigma = 0.95;


imTitle = getTitle();
inID = getImageID();
//-----------------------prepare input image----------------------
if(bitDepth() == 8)
	run("RGB Color");

if(bitDepth() == 24){
	run("sRGB to linRGB");
	tID = getImageID();
	run("Add...", "value=0.01 stack"); // ensure no zeros
	run("Michelson opponent B");
	rmID = getImageID(); // relative modulation ID
	selectImage(tID);
	close();
	selectImage(rmID);
	if(selFlag == 1)
		makeSelection("freehand", xs, ys);
} else {
	rmID = getImageID(); // relative modulation ID
}

sliceNames = newArray(nSlices);
setSlice(1);
for(i=0; i<nSlices; i++){
	setSlice(i+1);
	sliceNames[i] = getInfo("slice.label");
}
setSlice(1);




//---------------- LISTING AVAILABLE SBL MODEL PARAMS-------------

modelPath = getDirectory("plugins")+"micaToolbox/SBL Model/SBL Params/";

modelList=getFileList(modelPath);

modelNames = newArray();
modelFileIndex = newArray();

for(i=0; i<modelList.length; i++){
	if(endsWith(modelList[i], ".txt")==1){
		modelNames = Array.concat(modelNames,replace(modelList[i],".txt",""));
		modelFileIndex = Array.concat(modelFileIndex, i);
	}
	if(endsWith(modelList[i], ".TXT")==1){
		modelNames = Array.concat(modelNames,replace(modelList[i],".TXT",""));
		modelFileIndex = Array.concat(modelFileIndex, i);
	}
}
	
for(i=0; i<modelNames.length; i++)
	modelNames[i] = replace(modelNames[i], "_", " ");


// ----------------------------IMAGE PROCESSING SETTINGS-------------------------

setBatchMode("show");
setBatchMode(false);

scaleChoice = newArray("Angular width of image (degrees)", "Viewing distance (scale bar unit)", "None");

Dialog.create("SBL Model Choice");
	Dialog.addMessage("Select the visual system to use:");
	Dialog.addChoice("Model_", modelNames);
	Dialog.addChoice("Luminance_channel", sliceNames);
	Dialog.addCheckbox("Output_bandpass stack", true);
	Dialog.addCheckbox("Output_clipping stack", false);
	Dialog.addChoice("Scaling_method", scaleChoice);
	Dialog.addNumber("Scale_unit (degrees or distance)", 20);
	Dialog.addCheckbox("Salience measure", true);
Dialog.show();

params = Dialog.getChoice();
lumChannelName = Dialog.getChoice();
showBandpass = Dialog.getCheckbox();
showClipping = Dialog.getCheckbox();
scaleMethod = Dialog.getChoice();
scaleUnit = Dialog.getNumber();
salMeasure = Dialog.getCheckbox();



setBatchMode(true);

modelFile = "";
for(i=0; i<modelNames.length; i++)
	if(params == modelNames[i])
		modelFile = modelList[modelFileIndex[i]];



lumSlice = 1;

for(i=0; i<sliceNames.length; i++)
	if(lumChannelName == sliceNames[i])
		lumSlice = i+1;

print("Params: " + modelFile);
print("Lum channel: " + lumSlice);
setSlice(lumSlice);
		
ts = modelPath + modelFile;
paramString = File.openAsString(ts);
paramString = split(paramString, "\n");

//----------------------------------------------------IMPORT PARAMS-------------------------------------------
importCheck = 0;
for(i=0; i<paramString.length; i++){

	if(startsWith(paramString[i], "Name:") == true){
		modelName = replace(paramString[i], "Name:", "");
		importCheck++;
	}
	if(startsWith(paramString[i], "L_Model:") == true){
		L_Model = replace(paramString[i], "L_Model:", "");
		importCheck++;
	}
	if(startsWith(paramString[i], "Scene:") == true){
		Scene = replace(paramString[i], "Scene:", "");
		importCheck++;
	}
	if(startsWith(paramString[i], "SFs:") == true){
		SFs = replace(paramString[i], "SFs:", "");
		//SFs = split(SFs, ",");
		importCheck++;
	}
	if(startsWith(paramString[i], "L_CS:") == true){
		L_CS = replace(paramString[i], "L_CS:", "");
		//L_CS = split(L_CS, ",");
		importCheck++;
	}
	if(startsWith(paramString[i], "L_BW:") == true){
		L_BW = replace(paramString[i], "L_BW:", "");
		importCheck++;
	}
	if(startsWith(paramString[i], "L_Weights:") == true){
		L_Weights = replace(paramString[i], "L_Weights:", "");
		//L_Weights = split(L_Weights, ",");
		importCheck++;
	}

}// i param string

if( importCheck < 6){
	ts = "Error opening the parameter file - check it contains all the required parameters\nParam path: " + modelPath + modelFile;
	exit(ts);
}

//--------------------------------IMAGE SCALING-----------------------

if(L_Model == "Gabor")
	kernelPxPerCycle = 4.7; // based on default Gabor parameters of  sigma 2, gamma 1, frequency 3
else
	kernelPxPerCycle = 5.8; // this value is based on the default DoG parameters of sigma = 1 and 1.6

SFarray = split(SFs, ",");
peakSF = 0;
for(i=0; i<SFarray.length; i++)
	if(parseFloat(SFarray[i]) > peakSF)
		peakSF = parseFloat(SFarray[i]);
print("Peak SF: " + peakSF);

run("Select None");
w = getWidth();
h = getHeight();
if(scaleMethod == "Angular width of image (degrees)"){
	scaledWidth = scaleUnit * kernelPxPerCycle * peakSF;
	rescale = scaledWidth/w;
	scaledHeight = round(rescale*h);
	scaledWidth = round(scaledWidth);
	print("Image angular width: " + scaleUnit + " degrees");
	print("Rescale: " + rescale);
	print("Scaled width: " + scaledWidth);
	print("Scaled height: " + scaledHeight);

	run("Duplicate...", " ");
	ts = "scaling=" + rescale;
	run("Multispectral Image Scaler No Scale Bar", ts);
	//run("Scale...", "width=&scaledWidth height=&scaledHeight depth=3 interpolation=Bilinear average process create");

}else if (scaleMethod == "Viewing distance (scale bar unit)"){ //--------------------------calculate angular width based on distance and image scale-----------------------
	// get scale bar px/mms

	nSelections = roiManager("count");
	scaleFlag = 0;

	for(j=0; j<nSelections; j++){
		roiManager("select", j);
		selName = getInfo("selection.name");

		if( startsWith(selName, "Scale") == 1){ // found the scale bar - extract the info
			scaleLoc = j;
			scaleFlag = scaleFlag+1;
			scaleInfo = split(selName, ":");
			pxMm = parseFloat(scaleInfo[1])/parseFloat(scaleInfo[2]);
		}
		
	}

	if(scaleFlag == 0)
		exit("No scale bar found\n \nUse the 'Save ROIs' script to add\none by selecting it and pressing 'S',\nthen press '0' to save the ROIs");
	if(scaleFlag > 1)
		showMessageWithCancel("Multiple Scale Bars", "There's more than one scale bar\n \nThis script will only use the last one");

	imageWidthMM = w/pxMm;
	imageAngle = atan((imageWidthMM/2)/scaleUnit)*2; // image angle in radians
	alpha = 180 * imageAngle/PI; // image angular width in degrees

	scaledWidth = alpha * kernelPxPerCycle * peakSF;

	rescale = scaledWidth/w;
	scaledHeight = round(rescale*h);
	scaledWidth = round(scaledWidth);
	print("Distance: " + scaleUnit);
	print("Rescale: " + rescale);
	print("Scaled width: " + scaledWidth);
	print("Scaled height: " + scaledHeight);

	run("Select None");
	run("Duplicate...", " ");
	ts = "scaling=" + rescale;
	run("Multispectral Image Scaler No Scale Bar", ts);
	
	//run("Scale...", "width=&scaledWidth height=&scaledHeight depth=3 interpolation=Bilinear average process create");

}




//---------------------------------------------------APPLY SBL MODEL---------------------------------------------------

if(L_Model == "Gabor"){
	print("Running Gabor Model");
	if(showClipping == 0){
		run("Gabor ScC Model Michelson", "number_of_angles=4 sigma=2 gamma=1 frequency=3 michelson clipping dynamic=&L_BW postsigma=&postSigma spatial_frequency=[&SFs] csf=[&L_CS] gain=[&L_Weights] pooling=&poolW interpolation label=[]");
	} else {
		ts = "number_of_angles=4 sigma=2 gamma=1 frequency=3 michelson clipping ";
		ts = ts + "clipping_mask ";
		ts = ts + "dynamic="+L_BW+" postsigma="+postSigma+" spatial_frequency=["+SFs+"] csf=["+L_CS+"] gain=["+L_Weights+"] pooling="+poolW+" interpolation label=[]";
		run("Gabor ScC Model Michelson clipping", ts);
	}
}

if(L_Model == "DoG"){
	print("Running DoG Model");
	run("DoG ScC Model Michelson", "sigma1=1 sigma2=1.60 michelson clipping dynamic=&L_BW post=&postSigma spatial_frequency=[&SFs] csf=[&L_CS] gain=[&L_Weights] pooling=&poolW interpolation label=[]");
}


setBatchMode("show");
if(showClipping == 1 && L_Model == "Gabor"){
	selectImage("Pooled Image");
	setBatchMode("show");
	selectImage("Clipping Masks");
	setBatchMode("show");
}

if(salMeasure == 1){
	selectImage("Gabor output");

octaveSeparation = 3; // Number of octave above current to analyse saliency
sigma1 = 1.0;
sigma2 = 3.0;
scaleLow = SFarray[0];
scaleHigh = SFarray[SFarray.length-1];

Dialog.create("Saliency Settings");
	Dialog.addMessage("Select the spatial scales over which to apply saliency (cpd)");
	Dialog.addNumber("From (low SF):", scaleLow);
	Dialog.addNumber("To (high SF)", scaleHigh);
	Dialog.addMessage("The number of octaves lower SF than the selected to calculate saliency");
	Dialog.addNumber("Octave separation", octaveSeparation);
	Dialog.addNumber("Centre sigma:", sigma1);
	Dialog.addNumber("Surround sigma", sigma2);
	Dialog.addCheckbox("Max pooling", true);

Dialog.show();

scaleLow = Dialog.getNumber();
scaleHigh = Dialog.getNumber();
octaveSeparation = Dialog.getNumber();
sigma1 = Dialog.getNumber();
sigma2 = Dialog.getNumber();
maxPool = Dialog.getCheckbox();



salString = "from=" + scaleLow + " to=" + scaleHigh + " octave=" + octaveSeparation + " centre=" + sigma1 + " surround=" + sigma2;
if(maxPool == 1)
	salString = salString + " max";

run("Saliency Process", salString);

selectImage("Salience");
setBatchMode("show");

} // sal measure


if(showBandpass == 1 && L_Model == "Gabor"){
	selectImage("Gabor output");
	setBatchMode("show");
}

if(showBandpass == 1 && L_Model == "DoG"){
	selectImage("DoG output");
	setBatchMode("show");
}














