

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


// LISTING CONE CATCH MODELS

	ccModelPath = getDirectory("plugins")+"Cone Models";

	ccModelList=getFileList(ccModelPath);

	ccModelNames = newArray(1);
	ccModelNames[0] = "None";

	for(i=0; i<ccModelList.length; i++){
		if(endsWith(ccModelList[i], ".class")==1)
			ccModelNames = Array.concat(ccModelNames,replace(ccModelList[i],".class",""));
		if(endsWith(ccModelList[i], ".CLASS")==1)
			ccModelNames = Array.concat(ccModelNames,replace(ccModelList[i],".CLASS",""));
	}
	
	for(i=0; i<ccModelNames.length; i++)
		ccModelNames[i] = replace(ccModelNames[i], "_", " ");


// ----------------------------IMAGE PROCESSING SETTINGS-------------------------

//setBatchMode("show");
//setBatchMode(false);

scaleChoice = newArray("Angular width of image (degrees)", "Viewing distance (scale bar unit)", "None");

Dialog.create("SBL Model Choice");
	Dialog.addMessage("Select the visual system to use:");
	Dialog.addChoice("SBL_model_", modelNames);
	Dialog.addChoice("Cone_catch_model_", ccModelNames, "None");	
	//Dialog.addChoice("Luminance_channel", sliceNames);
	Dialog.addNumber("Luminance slice", 2);
	//Dialog.addCheckbox("Output_bandpass stack", true);
	//Dialog.addCheckbox("Output_clipping stack", false);
	Dialog.addChoice("Scaling_method", scaleChoice, "Viewing distance (scale bar unit)");
	Dialog.addString("Scale_unit (degrees or distance)", "20, 40, 80");
	//Dialog.addCheckbox("Salience measure", true);
	Dialog.addMessage("For processing over a range of scales, separate scale units with commas");
	Dialog.addCheckbox("Output_salience images", true);
Dialog.show();

params = Dialog.getChoice();
ccModelChoice = Dialog.getChoice();
lumSlice = Dialog.getNumber();
scaleMethod = Dialog.getChoice();

scaleString = Dialog.getString();
scaleString = replace(scaleString, " ", ""); // remove spaces
scaleVals = split(scaleString, ",");
outputSalIm = Dialog.getCheckbox();



modelFile = "";
for(i=0; i<modelNames.length; i++)
	if(params == modelNames[i])
		modelFile = modelList[modelFileIndex[i]];



//lumSlice = 1;
//for(i=0; i<sliceNames.length; i++)
//	if(lumChannelName == sliceNames[i])
//		lumSlice = i+1;

print("Params: " + modelFile);
print("Lum channel: " + lumSlice);
//setSlice(lumSlice);
		
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



if(L_Model == "Gabor")
	kernelPxPerCycle = 4.7; // based on default Gabor parameters of  sigma 2, gamma 1, frequency 3
else
	kernelPxPerCycle = 5.8; // this value is based on the default DoG parameters of sigma = 1 and 1.6

SFarray = split(SFs, ",");
peakSF = 0;
for(i=0; i<SFarray.length; i++)
	if(parseFloat(SFarray[i]) > peakSF)
		peakSF = parseFloat(SFarray[i]);
print("Max SF: " + peakSF);

L_CS_array = split(L_CS, ",");
maxCS = 0;
maxSF = 0;
for(i=0; i<SFarray.length; i++)
	if(parseFloat(L_CS_array[i]) > maxCS){
		maxCS = parseFloat(L_CS_array[i]);
		maxSF = parseFloat(SFarray[i]);
	}
print("Max CS: " + maxCS + " at: " + maxSF + "cpd");


octaveSeparation = 3; // Number of octave above current to analyse saliency
sigma1 = 1.0;
sigma2 = 3.0;
//scaleLow = SFarray[0];
//scaleHigh = SFarray[SFarray.length-1];
scaleLow = maxSF;
scaleHigh = peakSF;

Dialog.create("Saliency Settings");
	Dialog.addMessage("Select the spatial scales over which to apply saliency (cpd)");
	Dialog.addNumber("From (low SF):", scaleLow);
	Dialog.addNumber("To (high SF)", scaleHigh);
	Dialog.addMessage("The number of octaves lower SF than the selected to calculate saliency");
	Dialog.addNumber("Octave separation", octaveSeparation);
	Dialog.addNumber("Centre sigma:", sigma1);
	Dialog.addNumber("Surround sigma", sigma2);
	Dialog.addCheckbox("Max pooling", true);
	Dialog.addString("Target ROI name", "t1");

Dialog.show();

scaleLow = Dialog.getNumber();
scaleHigh = Dialog.getNumber();
octaveSeparation = Dialog.getNumber();
sigma1 = Dialog.getNumber();
sigma2 = Dialog.getNumber();
maxPool = Dialog.getCheckbox();
targetROI = Dialog.getString();


//L_Model = "Gabor"; // Ganor or DoG
//Human 150cdm2 GaborIso 4 woodland --- LIMITED TO 16 CPD
postSigma = 0.95;
poolW = 1;
//SFs = "0.125,0.25,0.5,1,2,4,8,16";
//L_CS ="15.5477,52.6182,125.7582,212.2589,253.0024,212.9671,126.5988,53.1466";
//L_BW = 4;
//L_Weights = "0.04364,0.02959,0.0146,0.009007,0.007728,0.009355,0.01536,0.0305";

// Salience settings:
//scaleLow = 4;
//scaleHigh = 16;
//octaveSeparation = 3;
//sigma1 = 1; // centre
//sigma2 = 3; //surround
nAngles = 4;
//maxPool = 1;

//scaleUnit = 10; // in this case, I've used animal body-lengths as the scale
//scaleMethod = "Viewing distance (scale bar unit)";

//targetROI = "t1";
//lumChannel = 2;

while( roiManager("count") > 0){
	roiManager("select", 0);
	roiManager("delete");
}


setBatchMode(true);


//imDir = "/home/jolyon/Documents/Work/Light Environment Fellowship/SBL Animal Vision/Figures/batch example/";

imDir = getDir("Select directory containing mspec images");
fileList = getFileList(imDir);
mspecList = newArray();

for(i=0; i<fileList.length; i++)
	if(endsWith(fileList[i], ".mspec") == 1)
		mspecList = Array.concat(mspecList, fileList[i]);

Array.show(mspecList);

for(k=0; k<scaleVals.length; k++){
scaleUnit = parseFloat(scaleVals[k]);

for(i=0; i<mspecList.length; i++){

	ts = "select=[" + imDir  + mspecList[i] + "]";
	run("Create Stack from Config File", ts);

	imName = replace(mspecList[i], ".mspec", "");
	print("Processing: " + imName + " at dist/scale: " + scaleUnit);

	run("Select None");
	w = getWidth();
	h = getHeight();
	if(scaleMethod == "Angular width of image (degrees)"){
		scaledWidth = scaleUnit * kernelPxPerCycle * peakSF;
		rescale = scaledWidth/w;
		//print("rescale: " + rescale);
		scaledHeight = round(h*rescale);
		scaledWidth = round(scaledWidth);
		print("Scaled width: " + scaledWidth + " px");
		print("Image angular width: " + scaleUnit + " degrees");

	} else if (scaleMethod == "Viewing distance (scale bar unit)"){ //--------------------------calculate angular width based on distance and image scale-----------------------
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
		print("Scaled width: " + scaledWidth + " px");
		rescale = scaledWidth/w;
		scaledHeight = round(h*rescale);
		scaledWidth = round(scaledWidth);
		print("Image angular width: " + alpha + " degrees");
	}

	// only proceed if image is large enough
	if(scaledHeight < 10 || scaledWidth < 10){
		ws = "Image too small to process at dist " + scaleUnit;
		print(ws);
	} else {

	ts = "scaling=" + rescale;
	run("Multispectral Image Scaler No Scale Bar", ts);

	//--------------- Add cone-catch model here if desired------------
	if(ccModelChoice != "None"){
		run(ccModelChoice);
	} 

	scaledIm = getImageID();

	nSelections = roiManager("count");

	targetROIIndex = -1;

	for(j=0; j<nSelections; j++){
		roiManager("select", j);
		selName = getInfo("selection.name");

		if( selName == targetROI){ // found the target ROI
			targetROIIndex = j;
			
			getBoundingRect(roiX, roiY, roiW, roiH);
			roiMaxDim = getValue("Major"); // get the major ellipse length as the measurement of body-length
			run("From ROI Manager");
			
			makeRectangle(roiX - roiMaxDim - roiMaxDim, roiY - roiMaxDim - roiMaxDim, 5*roiMaxDim, 5*roiMaxDim); // create cropped area of 2 body lengths
			run("Crop");
			run("To ROI Manager");
	
			//----------create surround of 1 body-length-------------
			roiManager("Deselect");
			roiManager("select", targetROIIndex);
			enlargeRemaining = roiMaxDim;
			while(enlargeRemaining > 250){
				run("Enlarge...", "enlarge=250");
				enlargeRemaining = enlargeRemaining - 250;
			}
			run("Enlarge...", "enlarge=&enlargeRemaining");
			roiManager("add");
			nSelections = roiManager("count");
			roiManager("Deselect");
			roiManager("select", newArray(targetROIIndex, nSelections-1));
			roiManager("XOR");
			roiManager("add");
			surrROIIndex = nSelections;

			//-------edge-------
			roiManager("Deselect");
			roiManager("select", targetROIIndex);
			getStatistics(areaBefore, mean, min, max, sd);

			run("Enlarge...", "enlarge=-1");
			getStatistics(areaAfter, mean, min, max, sd);
			if(areaAfter < areaBefore){
				roiManager("add");
				roiManager("Deselect");
				roiManager("select", newArray(targetROIIndex, nSelections+1));		
				roiManager("XOR");
				roiManager("add");
				edgeROIIndex = nSelections +2;
			} else {
				edgeROIIndex = targetROIIndex; // the ROI is too small to smallerise further
			}

			setSlice(lumSlice);
			sliceLabel = getInfo("slice.label");
			run("Select None");


			//---------------------------------------------------APPLY SBL MODEL---------------------------------------------------

			if(L_Model == "Gabor"){
				print("Running Gabor Model");
				run("Gabor ScC Model Michelson", "number_of_angles=4 sigma=2 gamma=1 frequency=3 michelson clipping dynamic=&L_BW postsigma=&postSigma spatial_frequency=[&SFs] csf=[&L_CS] gain=[&L_Weights] pooling=&poolW interpolation label=[]");
				selectImage("Gabor output");
			}

			if(L_Model == "DoG"){
				print("Running DoG Model");
				run("DoG ScC Model Michelson", "sigma1=1 sigma2=1.60 michelson clipping dynamic=&L_BW post=&postSigma spatial_frequency=[&SFs] csf=[&L_CS] gain=[&L_Weights] pooling=&poolW interpolation label=[]");
				selectImage("DoG output");
			}
	
			salString = "from=" + scaleLow + " to=" + scaleHigh + " octave=" + octaveSeparation + " centre=" + sigma1 + " surround=" + sigma2;
			if(maxPool == 1)
				salString = salString + " max";

			run("Saliency Process", salString);
			selectImage("Salience");
			roiManager("Deselect");
			roiManager("select", targetROIIndex);
			getStatistics(area, targetMean, min, targetMax, targetSD);
			run("Add Selection...");

			roiManager("Deselect");
			roiManager("select", surrROIIndex);
			getStatistics(area, surrMean, min, surrMax, surrSD);
			run("Add Selection...");

			roiManager("Deselect");
			roiManager("select", edgeROIIndex);
			getStatistics(area, edgeMean, min, edgeMax, edgeSD);
			run("Add Selection...");

			row = nResults();

			
			setResult("Image", row, imName);
			setResult("SBL Model", row, modelName);
			if(ccModelChoice != "None"){
				ccString = ccModelChoice + "_" + sliceLabel;
			} else {
				ccString = sliceLabel;
			}
			setResult("Channel", row, ccString);
			if(scaleMethod == "Angular width of image (degrees)"){
				setResult("Angular width (degs)", row, scaleUnit);
			} else {
				setResult("Distance", row, scaleUnit);
			}
			setResult("Target mean salience", row, targetMean);
			setResult("Target max salience", row, targetMax);
			setResult("Surround mean salience", row, surrMean);
			setResult("Surround max salience", row, surrMax);
			setResult("Edge salience", row, edgeMean);
			setResult("Salience contrast", row, (targetMean-surrMean)/(targetMean+surrMean));

			roiManager("select", newArray(targetROIIndex, surrROIIndex, edgeROIIndex));

			if (outputSalIm == true){
				savePath = imDir + imName + "_sal_" + modelName + "_" + sliceLabel + "_" + scaleUnit + ".tif";
				saveAs("Tiff", savePath);
			}
			j = nSelections; // stop j loop
		} // ROI == target

	}//j
	}  // image size check
updateResults();
run("Close All");

} // i (mspec files)
} // k (scale)

print("-------Finished batch processing-------");

resultsPath = imDir + "Salience_Results_" + modelName + "_" + ccString + ".csv";
saveAs("Results", resultsPath);














