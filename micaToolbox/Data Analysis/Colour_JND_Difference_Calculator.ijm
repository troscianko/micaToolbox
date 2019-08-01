
// LIST VISUAL SYSTEM WEBER FRACTIONS


//if(getInfo("os.name") == "Windows")// i think windows can deal with forward slashes
//	vsPath = getDirectory("plugins")+"Multispectral Imaging\\weberFractions";
//else
	vsPath = getDirectory("plugins")+"micaToolbox/weberFractions";

	vsList=getFileList(vsPath);

	vsNames = newArray();

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



// LIST PHOTOS & ZONES

zoneNames = newArray(1);
zoneNames[0] = getResultLabel(0);
tempArray = split(zoneNames[0], "_");
zoneNames[0] = tempArray[tempArray.length-1];

photoIDs = newArray(nResults);
zoneIDs = newArray(nResults);

for(i=0; i<nResults; i++){
	tempString = getResultLabel(i);
	tempArray = split(tempString, "_");
	photoIDs[i] = replace(tempString, "_" + tempArray[tempArray.length-1], ""); // select whole string excluding last underscore
	zoneIDs[i] = tempArray[tempArray.length-1];
}


for(i=1; i<nResults; i++){
	match = 0;
	for(j=0; j<zoneNames.length; j++)
		if(zoneIDs[i] == zoneNames[j])
			match = 1;
	if(match==0)
		zoneNames = Array.concat(zoneNames, zoneIDs[i]);	
}

// CALCULATE BIN SIZE
nBins = 1;

/*
for(i=1; i<nResults; i++){
	if(photoIDs[i] == photoIDs[0] && zoneIDs[i] == zoneIDs[0])
		nBins = i+1;
	else	i = nResults;	
}

if(nResults/nBins != round(nResults/nBins))
	exit("The number of results must be a multiple of the bin size of " + nBins);
*/

// OPTIONS

comparisonOptions = newArray("Within Photo", "Between Photos");

Dialog.create("Calculate colour JND differences");
	Dialog.addChoice("Visual system Weber fractions", vsNames);
	Dialog.addChoice("Compare this region:", zoneNames, zoneNames[0]);
	Dialog.addChoice("to this region:", zoneNames, zoneNames[0]);
	Dialog.addChoice("Region comparison:", comparisonOptions, comparisonOptions[0]);
	Dialog.addMessage(" \nCopy data from additional columns:");
	Dialog.addCheckbox("Specify columns:", false);
Dialog.show();

	vsChoice = Dialog.getChoice();
	zoneA = Dialog.getChoice();
	zoneB = Dialog.getChoice();
	interPhoto = Dialog.getChoice();
	outputColumns = Dialog.getCheckbox();

if(outputColumns == 1){
	Dialog.create("Calculate colour JND differences");
		Dialog.addMessage("Select additional columns to output:");
		Dialog.addCheckboxGroup(headings.length, 1, headings, newArray(headings.length));
	Dialog.show();

	columnsToOutput = newArray(0);
	for(i=0; i<headings.length; i++){
		tempVal = Dialog.getCheckbox();
		if(tempVal == 1)
			columnsToOutput = Array.concat(columnsToOutput, i);

	}

}




// GET SELECTED WEBER FRACTIONS

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



// RESULTS TABLE

extraColumns = "";

if(outputColumns == 1){

	for(i=0; i<columnsToOutput.length; i++)
		extraColumns = extraColumns + "\t"+ headings[columnsToOutput[i]] + " A";
	for(i=0; i<columnsToOutput.length; i++)
		extraColumns = extraColumns + "\t"+ headings[columnsToOutput[i]] + " B";

}


if(interPhoto == "Within Photo"){
	run("New... ", "name=[Comparison Results] type=Table");
	print("[Comparison Results]", "\\Headings:Photo\tZone A\tZone B\t" + "JND_diff" + extraColumns);
}// within photo

if(interPhoto == "Between Photos"){
	run("New... ", "name=[Comparison Results] type=Table");
	print("[Comparison Results]", "\\Headings:Photo A\tPhoto B\tZone A\tZone B\t" + "JND_diff" + extraColumns);
}// within photo


// EXTRACT DATA

//data = newArray(nResults);
//for(i=0; i<nResults; i++)
//	data[i] = getResult(dataHeading, i);



// COMPARE SELECTED ZONES & IMAGES

aVals = newArray(weberFractions.length);
bVals = newArray(weberFractions.length);
extraColumnsA = "";
extraColumnsB = "";

for(i=0; i<nResults; i++){
	if(zoneIDs[i] == zoneA){ // find zoneA values
		for(j=0; j<weberFractions.length; j++)
			aVals[j] = getResult(channelNames[j] + "Mean", i);

		if(outputColumns == 1){
			extraColumnsA = "";
			for(j=0; j<columnsToOutput.length; j++)
				extraColumnsA = extraColumnsA +"\t" + d2s(getResult(headings[columnsToOutput[j]], i),9);
		}

		if(interPhoto == "Within Photo"){
			for(j=0; j<nResults; j++){
				if(zoneIDs[j] == zoneB && i!=j && photoIDs[i] == photoIDs[j]){ // find zoneB values, and don't compare against itself


					if(outputColumns == 1){
						extraColumnsB = "";
						for(k=0; k<columnsToOutput.length; k++)
							extraColumnsB = extraColumnsB +"\t" + d2s(getResult(headings[columnsToOutput[k]], j),9);
					}

					for(k=0; k<weberFractions.length; k++)
						bVals[k] = getResult(channelNames[k] + "Mean", j);


					// DICHROMATIC - V&O model using log differences
					if(weberFractions.length == 2){
						Dfi1 = log(aVals[0]/bVals[0]);
						Dfi2 = log(aVals[1]/bVals[1]);
						JND = pow(pow(Dfi1-Dfi2,2)/(pow(weberFractions[0],2)+pow(weberFractions[1],2)),0.5);
					}//di

					// TRICHROMATIC
					if(weberFractions.length == 3){
						Dfi1 = log(aVals[0]/bVals[0]);
						Dfi2 = log(aVals[1]/bVals[1]);
						Dfi3 = log(aVals[2]/bVals[2]);
						JND = pow((pow(weberFractions[0],2)*pow(Dfi3-Dfi2,2)+pow(weberFractions[1],2)*pow(Dfi3-Dfi1,2)+pow(weberFractions[2],2)*pow(Dfi1-Dfi2,2))/(pow(weberFractions[0]*weberFractions[1],2)+pow(weberFractions[0]*weberFractions[2],2)+pow(weberFractions[1]*weberFractions[2],2)),0.5);
			
					}//tri

					// TETRACHROMATIC
					if(weberFractions.length == 4){
						Dfi0 = log(aVals[0]/bVals[0]);
						Dfi1 = log(aVals[1]/bVals[1]);
						Dfi2 = log(aVals[2]/bVals[2]);
						Dfi3 = log(aVals[3]/bVals[3]);
						JND = pow((pow(weberFractions[0]*weberFractions[1],2)*pow(Dfi3-Dfi2,2)+pow(weberFractions[0]*weberFractions[2],2)*pow(Dfi3-Dfi1,2)+pow(weberFractions[0]*weberFractions[3],2)*pow(Dfi2-Dfi1,2)+pow(weberFractions[1]*weberFractions[2],2)*pow(Dfi3-Dfi0,2)+pow(weberFractions[1]*weberFractions[3],2)*pow(Dfi2-Dfi0,2)+pow(weberFractions[2]*weberFractions[3],2)*pow(Dfi1-Dfi0,2))/(pow(weberFractions[0]*weberFractions[1]*weberFractions[2],2)+pow(weberFractions[0]*weberFractions[1]*weberFractions[3],2)+pow(weberFractions[0]*weberFractions[2]*weberFractions[3],2)+pow(weberFractions[1]*weberFractions[2]*weberFractions[3],2)),0.5);
					}//tet


					print("[Comparison Results]", photoIDs[i] + "\t" + zoneIDs[i] + "\t"+ zoneIDs[j] + "\t" + d2s(JND,9) + extraColumnsA + extraColumnsB);

				}//if
			}//j
		}// within photo

		if(interPhoto == "Between Photos"){
			for(j=0; j<nResults; j++){
				if(zoneIDs[j] == zoneB && i!=j){ // find zoneB values, and don't compare against itself

					if(outputColumns == 1){
						extraColumnsB = "";
						for(k=0; k<columnsToOutput.length; k++)
							extraColumnsB = extraColumnsB +"\t" + d2s(getResult(headings[columnsToOutput[k]], j),9);
					}


					for(k=0; k<weberFractions.length; k++)
						bVals[k] = getResult(channelNames[k] + "Mean", j);
	

					// DICHROMATIC - V&O model using log differences
					if(weberFractions.length == 2){
						Dfi1 = log(aVals[0]/bVals[0]);
						Dfi2 = log(aVals[1]/bVals[1]);
						JND = pow(pow(Dfi1-Dfi2,2)/(pow(weberFractions[0],2)+pow(weberFractions[1],2)),0.5);
					}//di

					// TRICHROMATIC
					if(weberFractions.length == 3){
						Dfi1 = log(aVals[0]/bVals[0]);
						Dfi2 = log(aVals[1]/bVals[1]);
						Dfi3 = log(aVals[2]/bVals[2]);
						JND = pow((pow(weberFractions[0],2)*pow(Dfi3-Dfi2,2)+pow(weberFractions[1],2)*pow(Dfi3-Dfi1,2)+pow(weberFractions[2],2)*pow(Dfi1-Dfi2,2))/(pow(weberFractions[0]*weberFractions[1],2)+pow(weberFractions[0]*weberFractions[2],2)+pow(weberFractions[1]*weberFractions[2],2)),0.5);
			
					}//tri

					// TETRACHROMATIC
					if(weberFractions.length == 4){
						Dfi0 = log(aVals[0]/bVals[0]);
						Dfi1 = log(aVals[1]/bVals[1]);
						Dfi2 = log(aVals[2]/bVals[2]);
						Dfi3 = log(aVals[3]/bVals[3]);
						JND = pow((pow(weberFractions[0]*weberFractions[1],2)*pow(Dfi3-Dfi2,2)+pow(weberFractions[0]*weberFractions[2],2)*pow(Dfi3-Dfi1,2)+pow(weberFractions[0]*weberFractions[3],2)*pow(Dfi2-Dfi1,2)+pow(weberFractions[1]*weberFractions[2],2)*pow(Dfi3-Dfi0,2)+pow(weberFractions[1]*weberFractions[3],2)*pow(Dfi2-Dfi0,2)+pow(weberFractions[2]*weberFractions[3],2)*pow(Dfi1-Dfi0,2))/(pow(weberFractions[0]*weberFractions[1]*weberFractions[2],2)+pow(weberFractions[0]*weberFractions[1]*weberFractions[3],2)+pow(weberFractions[0]*weberFractions[2]*weberFractions[3],2)+pow(weberFractions[1]*weberFractions[2]*weberFractions[3],2)),0.5);
					}//tet


					print("[Comparison Results]", photoIDs[i] + "\t" + photoIDs[j] + "\t" + zoneIDs[i] + "\t"+ zoneIDs[j] + "\t" + d2s(JND,9) + extraColumnsA + extraColumnsB);

				}//if
			}//j
		}// between photo


	}// zone a match
}













