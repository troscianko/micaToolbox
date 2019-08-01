/*__________________________________________________________________

	Title: QCPA on ROIs
	''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	Authors: Jolyon Troscianko & Cedric van den Berg
	Date: 18/3/2018
............................................................................................................

This script applies the QCPA analysis to a clustered cone-catch image


............................................................................................................

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

	lumWeber = 0.10;


Dialog.create("QCPA Options");
	Dialog.addString("Image Label", oTitle, 30);
	Dialog.addChoice("Visual system Weber fractions", vsNames);
	Dialog.addNumber("Luminance Weber fraction", lumWeber);
	Dialog.addCheckbox("Show separate horizontal and vertical adjacency results", false); 
	Dialog.addCheckbox("Output adjacency matrix", false); 

Dialog.show();

imLabel = Dialog.getString();
imLabel = replace(imLabel, " ", "_");

vsChoice = Dialog.getChoice();

lumWeber =  Dialog.getNumber();
hvOutput = Dialog.getCheckbox();
mOutput = Dialog.getCheckbox();



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

/*
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
*/

}


//Array.show(channelNames, weberFractions);



//run("Adjacency Analysis", "image=ImageID weber_1=0.050 weber_2=0.071 weber_3=0.166 luminance_weber_fraction=0.050 horizontal output");

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


if(nROIs == 0){
	print("No ROIs found - measuring whole image");
	run("Select All");

	tStr = "image=[" + imLabel + "]";
	for(i=0; i<weberFractions.length; i++)
		tStr = tStr + " weber_" + (i+1) + "=" + weberFractions[i];
	tStr = tStr + " luminance_weber_fraction=" + lumWeber;
	if(hvOutput == true)
		tStr = tStr + " horizontal";
	if(mOutput == true)
		tStr = tStr + " output";

	run("QCPA Analysis", tStr);

}








