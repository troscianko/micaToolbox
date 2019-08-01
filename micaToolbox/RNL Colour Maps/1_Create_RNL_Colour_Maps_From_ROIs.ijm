
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


Dialog.create("Create RNL Colour Maps");
	Dialog.addChoice("Visual system Weber fractions", vsNames);
	Dialog.addNumber("Resolution (px per JND):", 4);
	Dialog.addMessage("When using this Beta version of the framework cite: van den Berg &\nTroscianko et al. (2019) Quantitative Colour Pattern Analysis (QCPA):\nA Comprehensive Framework for the Analysis of Colour Patterns in\nNature, BIORXIV/2019/592261");
	
Dialog.show();

vsChoice = Dialog.getChoice();
res = Dialog.getNumber();

dir = getDirectory("Select a directory for saving the colour maps");


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
		Dialog.addMessage("Specify the Weber fraction associated with each\nchannel. Zero values are ignored");
		for(i=0; i<nSlices-1; i++)
			Dialog.addNumber(channelNames[i], 0.05);
		
	Dialog.show();
	

	weberFractions = newArray(0);
	for(i=0; i<nSlices-1; i++){
		tn = Dialog.getNumber();
		if(tn != 0)
			weberFractions = Array.concat(weberFractions, tn);
	}

}else {

	tempString = File.openAsString(vsPath + "/" + vsChoice + ".txt");
	tempString = split(tempString, "\n");

	tChannelNames = newArray(tempString.length-1);
	tWeberFractions = newArray(tempString.length-1);

	for(i=1; i<tempString.length; i++){
		row = split(tempString[i], "\t");
		tChannelNames[i-1] = row[0];
		tWeberFractions[i-1] = parseFloat(row[1]);
	}

	//-------check image slice names match channels-------------

	sliceNames = newArray(nSlices);

	for(i=0; i<nSlices; i++){
		setSlice(i+1);
		sliceNames[i] = getMetadata("Label");
	}

	matchCount = 0;
	//weberFractions = newArray(0);
	//channelNames = newArray(0);
	weberFractions = newArray(sliceNames.length);
	channelNames = newArray(sliceNames.length);

	for(j=0; j<sliceNames.length; j++)
		for(i=0; i<tChannelNames.length; i++)
			if(tChannelNames[i] == sliceNames[j]){
				matchCount++;
				weberFractions[j] = tWeberFractions[i];
				channelNames[j] = tChannelNames[i];
			}


	if(matchCount < tChannelNames.length){
		Array.show(channelNames, sliceNames);
		exit("Error - The current image channel names do not match the specified Weber fractions.\nThis script will stop and show the Weber fraction names and slice names for checking.\nNote that the order does not need to match, only the names.");
	}
}

if(vsChoice != "Custom"){
	if(matchCount > 4) //  make sure there aren't too many channels
		exit("Error - more than 4 channels\n \nThis code only calculates JNDs with 2, 3 or 4 channels.\nMake sure your Weber fractions file has the correct format.");

	if(matchCount < 2) //  make sure there aren't too many channels
		exit("Error - fewer than 2 channels\n \nThis code only calculates JNDs with 2, 3 or 4 channels.\nMake sure your Weber fractions file has the correct format.");
}


//Array.show(channelNames, weberFractions);

oID = getImageID();
imTitle = getTitle();
imTitle = replace(imTitle, ".tif", "");
imTitle = replace(imTitle, ".tiff", "");
imTitle = replace(imTitle, ".TIF", "");
imTitle = replace(imTitle, ".TIFF", "");

setBatchMode(true);


nROIs = 0;


for(i=0; i<roiManager("count"); i++){
		roiManager("deselect");
		roiManager("select", i);
		roiName = Roi.getName;
		if(startsWith(roiName, "Scale") == 0) // ignore scale bars
			nROIs ++;
}


if(nROIs > 0){
	for(i=0; i<roiManager("count"); i++){
		roiManager("deselect");
		roiManager("select", i);
		roiName = Roi.getName;
		if(startsWith(roiName, "Scale") == 0){ // ignore scale bars
		ts = "label=[" + roiName + "]";
		for(j=0; j<weberFractions.length; j++)
			ts = ts + " weber_" + (j+1) +"=" + weberFractions[j];
		ts = ts + " resolution=" + res;
		run("Extract RNL Colour Map", ts);
		savePath = dir + imTitle + "_" + roiName + ".tif";
		saveAs("Tiff", savePath);
		close();
		}
		selectImage(oID);
	}//i
}else {

	Dialog.create("Label");
		Dialog.addMessage("There are no ROIs present, so the entire image will be\nprocessed. What should this measurement label be?");
		Dialog.addString("Label:", "");
		
	Dialog.show();
	
	roiName = Dialog.getString();

	run("Select All");
	ts = "label=[" + roiName + "]";
	for(j=0; j<weberFractions.length; j++)
		ts = ts + " weber_" + (j+1) +"=" + weberFractions[j];
	ts = ts + " resolution=" + res;
	run("Extract RNL Colour Map", ts);
	savePath = dir + imTitle + "_whole_image.tif";
	saveAs("Tiff", savePath);
	close();
	selectImage(oID);
}
setBatchMode(false);


//run("Extract RNL Colour Map", "label=[flower label] weber_1=.05 weber_2=.06 weber_3=.07 weber_4=0.000 weber_5=0.000 resolution=4");



