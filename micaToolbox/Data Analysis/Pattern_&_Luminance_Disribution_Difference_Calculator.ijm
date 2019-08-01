/*
labels = newArray(nResults);
zoneNames = newArray(1);
zoneNames[0] = getResultLabel(0);
zoneLocs = newArray(1); // array holding rows of each group level
zoneLocs[0] = "0";

for(i=0; i<nResults; i++)
	labels[i] = getResultLabel(i);


for(i=1; i<nResults; i++){
	match = 0;
	for(j=0; j<zoneNames.length; j++)
		if(labels[i] == zoneNames[j]){
			match = 1;
			tempString = zoneLocs[j] + "," + d2s(i,0);
			zoneLocs[j] = tempString;
		}
	if(match==0){
		zoneNames = Array.concat(zoneNames, labels[i]);
		zoneLocs = Array.concat(zoneLocs,d2s(i,0));
	}
}
*/


headings = String.getResultsHeadings;
headings = replace(headings, "Label\t", "");
headings = replace(headings, " \t", "");
headings = split(headings, "\t");
if(headings.length == 1)
	exit("Exiting - there's no data\nOpen the data so that they are in the results window (e.g. open a .csv file)");



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
nBins = 0;

for(i=1; i<nResults; i++){
	if(photoIDs[i] == photoIDs[0] && zoneIDs[i] == zoneIDs[0])
		nBins = i+1;
	else	i = nResults;	
}

if(nResults/nBins != round(nResults/nBins))
	exit("The number of results must be a multiple of the bin size of " + nBins);


// OPTIONS

comparisonOptions = newArray("Within Photo", "Between Photos");

Dialog.create("Calculate pattern or luminance distribution differences");
	Dialog.addChoice("Data", headings, headings[headings.length-1]);
	Dialog.addChoice("Compare this region:", zoneNames, zoneNames[0]);
	Dialog.addChoice("to this region:", zoneNames, zoneNames[0]);
	Dialog.addChoice("Region comparison:", comparisonOptions, comparisonOptions[0]);
Dialog.show();

	dataHeading = Dialog.getChoice();
	zoneA = Dialog.getChoice();
	zoneB = Dialog.getChoice();
	interPhoto = Dialog.getChoice();

// RESULTS TABLE

if(interPhoto == "Within Photo"){
	run("New... ", "name=[Comparison Results] type=Table");
	print("[Comparison Results]", "\\Headings:Photo\tZone A\tZone B\t" + dataHeading + "_diff");
}// within photo

if(interPhoto == "Between Photos"){
	run("New... ", "name=[Comparison Results] type=Table");
	print("[Comparison Results]", "\\Headings:Photo A\tPhoto B\tZone A\tZone B\t" + dataHeading + "_diff");
}// within photo


// EXTRACT DATA

data = newArray(nResults);
for(i=0; i<nResults; i++)
	data[i] = getResult(dataHeading, i);



// COMPARE SELECTED ZONES & IMAGES

aVals = newArray(nBins);
bVals = newArray(nBins);

nMeasurements = nResults/nBins;

for(i=0; i<nMeasurements; i++){
	if(zoneIDs[i*nBins] == zoneA){ // find zoneA values
		for(j=0; j<nBins; j++)
			aVals[j] = data[(i*nBins) + j];

		if(interPhoto == "Within Photo"){
			for(j=0; j<nMeasurements; j++){
				if(zoneIDs[j*nBins] == zoneB && i!=j && photoIDs[i*nBins] == photoIDs[j*nBins]){ // find zoneB values, and don't compare against itself
					for(k=0; k<nBins; k++)
						bVals[k] = data[(j*nBins) + k];
	
					// COMPARE A & B SAMPLES

					diffSum = 0;
					for(k=0; k<nBins; k++)
						diffSum = diffSum + abs(aVals[k] - bVals[k]);
					print("[Comparison Results]", photoIDs[i*nBins] + "\t" + zoneIDs[i*nBins] + "\t"+ zoneIDs[j*nBins] + "\t" + d2s(diffSum,9));
				}//if
			}//j
		}// within photo

		if(interPhoto == "Between Photos"){
			for(j=0; j<nMeasurements; j++){
				if(zoneIDs[j*nBins] == zoneB && i!=j){ // find zoneB values, and don't compare against itself
					for(k=0; k<nBins; k++)
						bVals[k] = data[(j*nBins) + k];
	
					// COMPARE A & B SAMPLES

					diffSum = 0;
					for(k=0; k<nBins; k++)
						diffSum = diffSum + abs(aVals[k] - bVals[k]);
					print("[Comparison Results]", photoIDs[i*nBins] + "\t" + photoIDs[j*nBins] + "\t" + zoneIDs[i*nBins] + "\t"+ zoneIDs[j*nBins] + "\t" + d2s(diffSum,9));

				}//if
			}//j
		}// between photo


	}// zone a match
}













