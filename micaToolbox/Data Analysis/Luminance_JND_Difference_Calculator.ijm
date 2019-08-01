


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

nBins = 1;


// OPTIONS

comparisonOptions = newArray("Within Photo", "Between Photos");

Dialog.create("Calculate luminance JND differences");
	Dialog.addNumber("Weber Fraction", 0.05);
	Dialog.addMessage("Select the column containing the luminance data (e.g. lumMean)");
	Dialog.addChoice("Luminance Data:", headings, "lumMean");
	Dialog.addMessage(" \n_______________Regions to compare_______________");
	Dialog.addChoice("Compare this region:", zoneNames, zoneNames[0]);
	Dialog.addChoice("to this region:", zoneNames, zoneNames[0]);
	Dialog.addChoice("Region comparison:", comparisonOptions, comparisonOptions[0]);
	Dialog.addMessage(" \nCopy data from additional columns:");
	Dialog.addCheckbox("Specify columns:", false);
Dialog.show();


	weberFraction = Dialog.getNumber();
	channelName = Dialog.getChoice();
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
	print("[Comparison Results]", "\\Headings:Photo\tZone A\tZone B\t" + "lumJND_diff" + extraColumns);
}// within photo

if(interPhoto == "Between Photos"){
	run("New... ", "name=[Comparison Results] type=Table");
	print("[Comparison Results]", "\\Headings:Photo A\tPhoto B\tZone A\tZone B\t" + "lumJND_diff" + extraColumns);
}// within photo


// EXTRACT DATA


// COMPARE SELECTED ZONES & IMAGES

aVals = 0;
bVals = 0;
extraColumnsA = "";
extraColumnsB = "";

for(i=0; i<nResults; i++){
	if(zoneIDs[i] == zoneA){ // find zoneA values
		aVals = getResult(channelName, i);

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

	
					bVals = getResult(channelName, j);
	
					// COMPARE A & B SAMPLES - LUMINANCE - following Siddiqi et al 2004
					JND = abs(   log(aVals/bVals)/weberFraction );


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


					bVals = getResult(channelName, j);
	
					// COMPARE A & B SAMPLES - LUMINANCE - following Siddiqi et al 2004
					JND = abs(   log(aVals/bVals)/weberFraction );

					print("[Comparison Results]", photoIDs[i] + "\t" + photoIDs[j] + "\t" + zoneIDs[i] + "\t"+ zoneIDs[j] + "\t" + d2s(JND,9) + extraColumnsA + extraColumnsB);

				}//if
			}//j
		}// between photo


	}// zone a match
}













