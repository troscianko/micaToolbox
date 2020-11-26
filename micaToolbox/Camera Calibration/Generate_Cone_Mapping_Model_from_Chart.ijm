/*
________________________________________________________________________________

	Title: Generate cone mapping models
	Author: Jolyon Troscianko
	Date: 12/02/2019
		10/2/2020 - bug fix, now opens .CSV files with manual parse
....................................................................................................................................................................................

	Description:

________________________________________________________________________________
*/

requires("1.52a");

// GET LINEAR NORMALISED CHART VALUES
// to be replaced with chart measurement tool

//open("/home/jolyon/ImageJ/plugins/Jolyon/Colour Chart Calibration/7DpastelRawPxVals.csv");

//updateResults();

run("Input/Output...", "jpeg=95 gif=-1 file=.csv use_file copy_column save_column");

if(nResults==0){
	path=File.openDialog("Select Measurement Results CSV File");
	//open(path);

	ts = File.openAsString(path);
	ts = replace(ts, "\t", ","); // works with tab-deliniated files too
	ta = split(ts, "\n");
	sensorNames = split(ta[0], ",");
	//nColumns = sensorNames.length;
	//sensorNames = newArray(nColumns);

	nRes = ta.length-1;
	if(nRes<20)
		waitForUser("There aren't many measurements - the models might be poor quality!");

	chartVals = newArray(nRes*sensorNames.length);


	for(j=1; j<ta.length; j++)
	for(i=0; i<sensorNames.length; i++){
		
		taa = split(ta[j], ",");
		chartVals[(i*nRes)+(j-1)] = parseFloat( taa[i]);
	}




} else{  // load from results window

	columns = String.getResultsHeadings;
	// remove first empty column if present
	columns = replace(columns, " \t", "");
	columns = replace(columns, "Label\t", "");

	columns = split(columns, "\t"); //array of column names (must not have any repeats)



	nColumns = columns.length;


	chartVals = newArray(nResults*nColumns);


	for(j=0; j<nColumns; j++)
		for(i=0; i<nResults; i++)
			chartVals[(j*nResults)+i] = getResult(columns[j],i);

	sensorNames = newArray(nColumns);
	for(j=0; j<nColumns; j++)
		sensorNames[j] = columns[j];

	if(nResults<20)
		waitForUser("There aren't many measurements - the models might be poor quality!");

}






// LIST ILLUMINANTS

	illumPath = getDirectory("plugins")+"Cone Mapping/Illuminants";

	illumList=getFileList(illumPath);

	illumNames = newArray(0);

	for(i=0; i<illumList.length; i++){
		if(endsWith(illumList[i], ".csv")==1)
			illumNames = Array.concat(illumNames,replace(illumList[i],".csv",""));
		if(endsWith(illumList[i], ".CSV")==1)
			illumNames = Array.concat(illumNames,replace(illumList[i],".CSV",""));
	}

// LIST RECEPTORS

	receptorPath = getDirectory("plugins")+"Cone Mapping/Receptors";

	receptorList=getFileList(receptorPath);

	receptorNames = newArray(0);

	for(i=0; i<receptorList.length; i++){
		if(endsWith(receptorList[i], ".csv")==1)
			receptorNames = Array.concat(receptorNames,replace(receptorList[i],".csv",""));
		if(endsWith(receptorList[i], ".CSV")==1)
			receptorNames = Array.concat(receptorNames,replace(receptorList[i],".CSV",""));
	}

// LIST CHART SPECTRA

	chartPath = getDirectory("plugins")+"Cone Mapping/Charts";

	chartList=getFileList(chartPath);

	chartNames = newArray(0);

	for(i=0; i<chartList.length; i++){
		if(endsWith(chartList[i], ".csv")==1)
			chartNames = Array.concat(chartNames,replace(chartList[i],".csv",""));
		if(endsWith(chartList[i], ".CSV")==1)
			chartNames = Array.concat(chartNames,replace(chartList[i],".CSV",""));
	}

// USER SETTINGS

	Dialog.create("Settings");
		Dialog.addMessage("Select Configuration:");
		Dialog.addString("Camera Name","CameraID", 30);
		Dialog.addChoice("Receptors", receptorNames);
		Dialog.addChoice("Illuminant", illumNames);
		Dialog.addChoice("Chart reflectance spectra", chartNames);
		Dialog.addMessage("Set the maximum number of interaction terms:\ne.g. 3 = Red*Green*Blue");
		Dialog.addNumber("Interaction Levels", 2);
		Dialog.addNumber("Polynomial level", 1);
		Dialog.addHelp("http://www.empiricalimaging.com/knowledge-base/chart-based-cone-catch-model/");
	Dialog.show();


	scriptName = Dialog.getString();
	receptorChoice = Dialog.getChoice();
	illumChoice = Dialog.getChoice();
	chartChoice = Dialog.getChoice();
	nInteractions = Dialog.getNumber();
	polyLevel = Dialog.getNumber();


	osName = getInfo("os.name");


// Make model name from choices

	scriptName = scriptName + "_" + receptorChoice + "_" + illumChoice;

	scriptName = replace(scriptName, " ", "_");
	scriptName = replace(scriptName, "300-700" , "");
	scriptName = replace(scriptName, "400-700" , "");
	scriptName = replace(scriptName, "__" , "_");
	scriptName = replace(scriptName, "." , "_");
	scriptName = replace(scriptName, "-" , "_");
	scriptName = replace(scriptName, "_\t" , ""); // remove tailing underscore

//	bitDepthLevels = 65535;
//	bitDepthCasting = "0xffff";
//		sensorNames[i] = getResultString(columns[1], i);


// IMPORT ILLUMINANT SPECTRA
//---------------Horizontally arranged values-----------------

//open(illumPath + "/" + illumChoice + ".csv");

ts = File.openAsString(illumPath + "/" + illumChoice + ".csv");
ts = replace(ts, "\t", ","); // works with tab-deliniated files too
ta = split(ts, "\n");
ta = split(ta[1], ",");

iBins = ta.length-1;
illumSpec = newArray(iBins);
for(i=0; i<iBins; i++)
	illumSpec[i] = parseFloat(ta[i+1]);



// IMPORT CHART REFLECTANCE VALUES

//open(chartPath + "/" + chartChoice + ".csv");

ts = File.openAsString(chartPath + "/" + chartChoice + ".csv");
ts = replace(ts, "\t", ","); // works with tab-deliniated files too
ta = split(ts, "\n");

wBins = ta.length-1;

if(wBins != iBins)
	exit("Error - the illuminant and chart wavelength units are different");

taa = split(ta[0], ",");
nChartVals = taa.length-1;

chartRs = newArray(wBins*nChartVals);

for(j=0; j<wBins; j++){
	taa = split(ta[j+1], ",");
	for(i=0; i<nChartVals; i++)
		chartRs[(i*wBins)+j] = parseFloat(taa[i+1]);
}//j


// IMPORT RECEPTOR SENSITIVITIES
//---------------Horizontally arranged values-----------------

//open(receptorPath + "/" + receptorChoice + ".csv");
ts = File.openAsString(receptorPath + "/" + receptorChoice + ".csv");
ts = replace(ts, "\t", ","); // works with tab-deliniated files too
ta = split(ts, "\n");

nReceptors =  ta.length-1;
taa = split(ta[0], ",");
rBins = taa.length-1;

if(rBins ! = wBins)
	exit("Error - receptors and illuminant have different wavelength units");

recepSpec = newArray(nReceptors*rBins);
coneNames = newArray(nReceptors);

for(j=0; j<nReceptors; j++){
	taa = split(ta[j+1], ",");
	coneNames[j] = taa[0];
	for(i=0; i<rBins; i++)
		recepSpec[(j*rBins)+i] = parseFloat(taa[i+1]);
}//j



// CONE RESPONSES
//----------------------Horizontally arranged receptors-----------------
vonKreis = newArray(coneNames.length);
for(i=0; i<coneNames.length; i++){
	vonKreis[i] = 0; // set initial to zero
	for(j=0; j<wBins; j++)
		vonKreis[i] = vonKreis[i] + (illumSpec[j]*recepSpec[j+(i*wBins)]);
}//i

/*
//----------------------Vertically arranged receptors-----------------
vonKreis = newArray(coneNames.length);
for(i=0; i<coneNames.length; i++){
	vonKreis[i] = 0; // set initial to zero
	for(j=0; j<nResults; j++)
		vonKreis[i] = vonKreis[i] + (illumSpec[j]*recepSpec[j+(i*nResults)]);
}//i
*/

if(nResults!=0){
	selectWindow("Results");
	run("Close");
}


//open("/home/jolyon/ImageJ/plugins/Jolyon/Colour Chart Calibration/7DpastelRawPxVals.csv");

setResult("y", 0, 0.0);
for(i=0; i<sensorNames.length; i++)
for(j=0; j<nChartVals; j++)
	setResult(sensorNames[i], j, chartVals[(i*nChartVals)+j]);




//----------------CALCULATE POLYNOMIAL MODEL TERMS----------------


mSensorNames = Array.copy(sensorNames);
for(i=0; i<sensorNames.length; i++){
	tempName = sensorNames[i];
	for(j=1; j<polyLevel; j++){
		prevName = tempName;
		tempName = tempName+"*" +sensorNames[i];
		for(k=0; k<nChartVals; k++)
			setResult(tempName, k, getResult(prevName,k)*getResult(sensorNames[i],k));
		mSensorNames = Array.concat(mSensorNames, tempName);
	}
}

//----------------CALCULATE INTERACTION MODEL TERMS----------------

if(nInteractions > 1)
for(i=0; i<mSensorNames.length; i++)
for(k=i+1; k<mSensorNames.length; k++)
for(j=0; j<nChartVals; j++)
	setResult(mSensorNames[i] + "*" + mSensorNames[k], j, getResult(mSensorNames[i],j)*getResult(mSensorNames[k],j) );

if(nInteractions > 2)
for(i=0; i<mSensorNames.length; i++)
for(k=i+1; k<mSensorNames.length; k++)
for(l=k+1; l<mSensorNames.length; l++)
for(j=0; j<nChartVals; j++)
	setResult(mSensorNames[i] + "*" + mSensorNames[k] + "*" + mSensorNames[l], j, getResult(mSensorNames[i],j)*getResult(mSensorNames[k],j)*getResult(mSensorNames[l],j) );

if(nInteractions > 3)
	waitForUser("Currently the script only supports three-way interactions");



//----------------CALCULATE RECEPTOR CONE CATCH QUANTA TO CHART REFLECTANCE----------------


coneEstimates = newArray(coneNames.length * nChartVals);
modelR2s = newArray(coneNames.length);
models = newArray(coneNames.length);

showStatus("Calculating receptor responses to chart spectra");
for(k=0; k<coneNames.length; k++){
	for(i=0; i<nChartVals; i++){
		tempVal = 0;
		for(j=0; j<wBins; j++)
			tempVal = tempVal + chartRs[(i*wBins)+j]*illumSpec[j]*recepSpec[j+(k*wBins)];
		tempVal = tempVal/vonKreis[k];
		setResult("y",i, tempVal);
		coneEstimates[(k*nChartVals)+i] = tempVal;
		showProgress((k/sensorNames.length) + ((i/nChartVals)/coneNames.length) );
	}

	updateResults();
	print("\\Clear"); // clear log window
	run("multiple regression");

	logString = getInfo("log");
	logString = split(logString, "\n");

	modelR2s[k] = coneNames[k] + " " + replace(logString[1], "R2: ", "");

	for(i=0; i<sensorNames.length; i++)
		logString[2] = replace(logString[2], sensorNames[i], sensorNames[i] + "[i]");

	models[k] = logString[2];
	//waitForUser("waiting");

}
showProgress(1);

showStatus("Done Modelling");

print("\\Clear"); // clear log window


for(i=0; i<sensorNames.length; i++){
	sensorNames[i] = replace(sensorNames[i], ":", "");
	sensorNames[i] = replace(sensorNames[i], "Normalised", "");
}

for(i=0; i<models.length; i++){
	models[i] = replace(models[i], ":", "");
	models[i] = replace(models[i], "Normalised", "");
}


//------------------------ CREATE JAVA PLUGIN----------------------

pluginPath = getDirectory("plugins")+"Cone Models/" + scriptName + ".java";
if(File.exists(pluginPath)==1)
	File.delete(pluginPath);

scriptFile = File.open(pluginPath);


print(scriptFile, "// Code automatically generated by 'Generate Cone Mapping Model' script by Jolyon Troscianko");
print(scriptFile, "\n//Model fits:");

for(i=0; i<modelR2s.length; i++)
	print(scriptFile, "//" + modelR2s[i]);
print(scriptFile, "\n");
print(scriptFile, "\n");

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

print(scriptFile, "// Generated: " + year + "/" + month + "/" + dayOfMonth + "   " + hour + ":" + minute + ":" + second );
print(scriptFile, "\n");
print(scriptFile, "\n");
print(scriptFile, "import ij.*;");
print(scriptFile, "import ij.plugin.filter.PlugInFilter;");
print(scriptFile, "import ij.process.*;");
print(scriptFile, "\n");
print(scriptFile, "public class "+ scriptName + " implements PlugInFilter {");
print(scriptFile, "\n");
print(scriptFile, "ImageStack stack;");
print(scriptFile, "\tpublic int setup\(String arg, ImagePlus imp\) { \n\tstack = imp.getStack\(\); \n\treturn DOES_32 + STACK_REQUIRED; \n\t}");
print(scriptFile, "public void run\(ImageProcessor ip\) {");
print(scriptFile, "\n");
print(scriptFile, "IJ.showStatus\(\"Cone Mapping\"\);");

for(i=0; i<sensorNames.length; i++)
	print(scriptFile, "float[] " + sensorNames[i] + ";");

print(scriptFile, "int w = stack.getWidth\(\);" );
print(scriptFile, "int h = stack.getHeight\(\);" );
print(scriptFile, "int dimension = w*h;" );
print(scriptFile, "\n");

for(i=0; i<coneNames.length; i++)
	print(scriptFile, "float[] " + coneNames[i] + " = new float[dimension];");

print(scriptFile, "\n");

for(i=0; i<sensorNames.length; i++)
	print(scriptFile, sensorNames[i] + " = \(" + "float[]\) stack.getPixels\("+ (i+1) + "\);");

print(scriptFile, "\n");
print(scriptFile, "for \(int i=0;i<dimension;i++\) {");

for(i=0; i<coneNames.length; i++)
	print(scriptFile, coneNames[i]  + "[i] = \(float\) \(" + models[i] + "\);" );

print(scriptFile, "IJ.showProgress\(\(float\) i/dimension\);");
print(scriptFile, "}");
print(scriptFile, "\n");
print(scriptFile, "ImageStack outStack = new ImageStack\(w, h\);");

for(i=0; i<coneNames.length; i++)
	print(scriptFile, "outStack.addSlice\(\"" + coneNames[i] + "\", " + coneNames[i] + "\);");


print(scriptFile, "new ImagePlus\(\"Output\", outStack\).show\(\);" );
print(scriptFile, "\n");
print(scriptFile, "}");
print(scriptFile, "}");

File.close(scriptFile);


// -------------------------COMPILE PLUGIN SCRIPT-----------------------------------


pluginPath = replace(pluginPath, "\\", "/");

compileString = "compile=["+pluginPath+"]";

run("Compile and Run...", compileString); // compile java script to make .class file

wait(500);

windowList = getList("window.titles");
for(i=0; i<windowList.length; i++)
	if(startsWith(windowList[i], "Exception") == 1){
		selectWindow("Exception"); // exception window comes up & this closes it
		run("Close");
	}
		

print("\\Clear");

print("Cone mapping model completed");

print("____________________________________");
print("Model name:");
print(scriptName);
print("........................................................................");
print("Model R^2 values:");

for(i=0; i<modelR2s.length; i++)
	print(modelR2s[i]);
print("____________________________________");

run("Refresh Menus"); // refresh menus so the new script is visible
updateResults;
selectWindow("Results");
run("Close");




