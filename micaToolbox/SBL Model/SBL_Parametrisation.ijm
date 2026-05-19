/*
_______________________________________________________________________

	Title: SBL Model parametrisation script
	Author: Jolyon Troscianko
		Based on the SBL model developed by Troscianko & Osorio
	Date: 5/10/2024

.................................................................................................................

Description:
''''''''''''''''''''''''''''''''
The SBL model requires constrast sensitivity functions, and neural bandwidth
The model output is then re-weighted across spatial frequencies so that there is
equal contrast in each spatial frequency (whitening) for typical natural scene statistics

This script allows you to specify the CSF model and bandwidth, and select a bank of images
to use for use in calculating this weighting function.

Instructions:
''''''''''''''''''''''''''''''''''''''''

_________________________________________________________________________
*/

nAngles = 4;
postSigma = 0.95; // specifies the level of smoothing to be applied post-SF downsampling (generaly leave it here).
poolW = 1.0; // pooling weight - 1 means the whitenning weight values are applied in full, zero would mean the are ignored (no whitening).
minHeight = 8; // the height in pixels of the natural scene images at the lowest SF (assuming landscape image orientations). This should ideally not be lower than the diameter of the Gabor or DoG kernel (typcially about 11), however in practice that would demand very high resolution images for visual systems with a wide spatial range


//---------------- LISTING AVAILABLE CSFs-------------

modelPath = getDirectory("plugins")+"micaToolbox/SBL Model/CSFs/";

modelList=getFileList(modelPath);

modelNames = newArray();
modelFileIndex = newArray();

for(i=0; i<modelList.length; i++){
	if(endsWith(modelList[i], ".csv")==1){
		modelNames = Array.concat(modelNames,replace(modelList[i],".csv",""));
		modelFileIndex = Array.concat(modelFileIndex, i);
	}
	if(endsWith(modelList[i], ".CSV")==1){
		modelNames = Array.concat(modelNames,replace(modelList[i],".CSV",""));
		modelFileIndex = Array.concat(modelFileIndex, i);
	}
}
	
for(i=0; i<modelNames.length; i++)
	modelNames[i] = replace(modelNames[i], "_", " ");




scenePath = getDirectory("plugins")+"micaToolbox/SBL Model/Natural Scenes/";
sceneList=getFileList(scenePath);
for(i=0; i<sceneList.length; i++){
	sceneList[i] = replace(sceneList[i] , "/", "");
	sceneList[i] = replace(sceneList[i] , "\\\\", "");
}

modelType = newArray("Gabor isotropic", "Gabor anisotropic", "DoG");

Dialog.create("SBL Model Parametrisation");
	Dialog.addMessage("Specify the contrast sensitivity function.\nCS must be in Michelson contrast values");
	Dialog.addChoice("Visual system CSF", modelNames);
	Dialog.addChoice("Model type", modelType);
	Dialog.addChoice("Scene library", sceneList);
	Dialog.addNumber("Neural bandwidth", 4);
	Dialog.addNumber("CS_cutoff", 1.5);
	Dialog.addMessage("CS values below this cutoff will be ignored.\nValues lower than 1.5 can cause weighting\nissues.");
Dialog.show();


csfChoice = Dialog.getChoice();
modelChoice = Dialog.getChoice();
sceneChoice = Dialog.getChoice();
L_BW = Dialog.getNumber();
csCutoff = Dialog.getNumber();

//------------------ check whether CSFs are on an octave scale, and rescale if necessary------------------

modelFile = "";
for(i=0; i<modelNames.length; i++)
	if(csfChoice == modelNames[i])
		modelFile = modelList[modelFileIndex[i]];

ts = modelPath + modelFile;
csfString = File.openAsString(ts);
csfString = split(csfString, "\n");

SFs = newArray(); // spatial frequency
CSs = newArray(); // contrast sensitivity

for(i=1; i<csfString.length; i++){
	row = split(csfString[i], ",");
	SFs = Array.concat(SFs, parseFloat(row[0]));
	CSs = Array.concat(CSs, parseFloat(row[1]));
}

Array.show(SFs, CSs);

//------check octave separation of SFs-------


devSum = 0;
roundingError = 0.0001;
for(i=0; i<SFs.length-1; i++){
	dev = SFs[i+1]-SFs[i]*2;
	if(dev > roundingError || dev < -roundingError)
		devSum ++;
}

if(devSum > 0){
	print("The CSF is not on an octave scale, so a function will be fitted");
	print("Note that this will fit a polynomial with log-log axis transforms");
	print("because this fits typical CSF functions. To use your own function,");
	print("ensure the SFs are on an onctave scale that passes through 1");
	for(i=0; i<SFs.length; i++){
		SFs[i] = log(SFs[i]);
		CSs[i] = log(CSs[i]);
	}//i

	Fit.doFit("2nd Degree Polynomial", SFs, CSs);
	Fit.plot;


	// find lowest values where CS>=1

	SFpeak = exp(-Fit.p(1) / (2 * Fit.p(2))); // SF with peak CS
	//SFpeak = -Fit.p(1) / (2 * Fit.p(2)); // SF with peak CS
	print("SF peak (cpd): " + SFpeak);

	sf = 1;
	cs = exp(Fit.f(log(sf)));

	octCSs = newArray();
	octSFs = newArray();

	for(i=0; i<10; i++)
		sf = sf/2;

	while(sf < 200){
		sf *= 2;
		cs = exp(Fit.f(log(sf)));
		if(cs > csCutoff){
			octCSs = Array.concat(octCSs, cs);
			octSFs = Array.concat(octSFs, sf);
		}

	}
	//print("SFs: " + octSFs);
	//print("CSs: " + octCSs);

} else {
	octSFs = Array.copy(SFs);
	octCSs = Array.copy(CSs);
}

Array.show(octSFs, octCSs);


CSsStr = "" + octCSs[0];
SFsStr = "" + octSFs[0];
for(i=1; i<octSFs.length; i++){
	CSsStr = CSsStr + "," + octCSs[i];
	SFsStr = SFsStr + "," + octSFs[i];
}

print("SFs: " + SFsStr);
print("CSs: " + CSsStr);


//----------------------------------- Natural scene stats & whitining------------------------------

setBatchMode(true);

gains = "1";
for(i=1; i<octSFs.length; i++)
	gains = gains + ",1"; // array of 1s to match length of CSF

sceneDir = getDirectory("plugins")+"micaToolbox/SBL Model/Natural Scenes/" + sceneChoice + "/";
//print(sceneDir);
fileList=getFileList(sceneDir);

imList=newArray();

for(i=0; i<fileList.length; i++) // list only jpg files
	if(endsWith(fileList[i], ".jpg")==1 || endsWith(fileList[i], ".JPG")==1 || endsWith(fileList[i], ".tif")==1 || endsWith(fileList[i], ".png")==1)
		imList = Array.concat(imList, fileList[i]);

nOctaves = octSFs.length;

targetH = minHeight * pow(2,nOctaves);
scaleFlag = 0;
SDs = newArray();

for(k=0; k<imList.length; k++){

	open(sceneDir + imList[k]);

	//-----------------------prepare input image----------------------
	if(bitDepth() == 8)
		run("RGB Color");

	if(bitDepth() == 24){
		run("sRGB to linRGB");
		run("Add...", "value=0.01 stack"); // ensure no zeros
		run("Michelson opponent B");
		//run("Michelson opponent");
	}

	setSlice(1);

	w = getWidth();
	h = getHeight();

	scale = targetH/h;
	if(scale > 1 && scaleFlag == 0){
		print("WARNING - The natural scene images are being up-scaled,\nwhich means the high SFs will be smoothed (and invalidated).\nEither supply higher resolution images, or use a visual system\nwith a smaller spatial frequency range, or adjust the code's\nminHeight value");
		scaleFlag = 1;
	}
	targetW = w*scale;
	run("Scale...", "xx=- y=- width=&targetW height=&targetH interpolation=None average process create");

	if(modelChoice == "DoG")
		run("DoG ScC Model Michelson", "sigma1=1 sigma2=1.60 michelson clipping dynamic=&L_BW post=&postSigma spatial_frequency=[&SFsStr] csf=[&CSsStr] gain=[&gains] pooling=&poolW interpolation label=[ ]");
	else
		run("Gabor ScC Model Michelson", "number_of_angles=&nAngles sigma=2 gamma=1 frequency=3 michelson clipping dynamic=&L_BW postsigma=&postSigma spatial_frequency=[&SFsStr] csf=[&CSsStr] gain=[&gains] pooling=&poolW interpolation label=[]");

	close(); // pooled image
	row=nResults();
	setResult("Label", row, imList[k]);
	for(i=1; i<=nSlices; i++){
		setSlice(i);
		sliceLabel = getInfo("slice.label");
		getStatistics(area, mean, min, max, sd);
		setResult(sliceLabel, row, sd);
		SDs = Array.concat(SDs, sd);
	}
	updateResults();
	close();
	close();
	close();
	close();
	close();
}//k

//-----------------If Gabor isotropic, average across angles-----------------------

modelTitle = csfChoice;

if(modelChoice == "DoG"){ // no orientation, average across images
	modelTitle = modelTitle + "_DoG_";
	weights = newArray(octSFs.length);
	for(i=0; i<octSFs.length; i++){
		for(j=0; j<imList.length; j++)
			weights[i] += SDs[i+octSFs.length*j];
		weights[i] /= imList.length;
	}//i
}else if(modelChoice == "Gabor isotropic"){ // average across images and orientations


	modelTitle = modelTitle + "_GaborIso_";
	weights = newArray(octSFs.length);
	for(i=0; i<octSFs.length; i++){
		for(j=0; j<imList.length; j++){
			for(k=0; k<nAngles; k++)
				weights[i] += SDs[k+i*nAngles+octSFs.length*j*nAngles];
		}//j
		weights[i] /= (imList.length*nAngles);
	}//i

}else if(modelChoice == "Gabor anisotropic"){ // average across images and retain orientations
	modelTitle = modelTitle + "_GaborAniso_";
	weights = newArray(octSFs.length*nAngles);
	for(i=0; i<octSFs.length*nAngles; i++){
		for(j=0; j<imList.length; j++)
			weights[i] += SDs[i+octSFs.length*j*nAngles];
		weights[i] /= imList.length;
	}//i
}


weightsStr = "" + weights[0];
for(i=1; i<weights.length; i++)
	weightsStr = weightsStr + "," + weights[i];

Array.show(octSFs, octCSs, weights);


modelTitle = modelTitle + L_BW + "_" + sceneChoice + ".txt";

modelPath = getDirectory("plugins")+"micaToolbox/SBL Model/SBL Params/" + modelTitle;

modelChoiceSimple = "Gabor";
if(modelChoice == "DoG")
	modelChoiceSimple = "DoG";


paramFile = File.open(modelPath);
	print(paramFile, "Name:" + csfChoice);
	print(paramFile, "L_Model:" + modelChoiceSimple);
	print(paramFile, "Scene:" + sceneChoice);
	print(paramFile, "SFs:" + SFsStr);
	print(paramFile, "L_CS:" + CSsStr);
	print(paramFile, "L_BW:" + L_BW);
	print(paramFile, "L_Weights:" + weightsStr);
File.close(paramFile);












