// Create Colour-Map figure

/*

calculate areas & volume

*/

//colOptions = newArray("Colours from map location","Unify colours within maps");
comOptions = newArray("measurement", "pixel");


Dialog.create("Colour Map Plotting Settings");

	Dialog.addString("Combined map title(s)", "Combined Map", 20);
	Dialog.addString("Group maps containing label(s):", "", 20);
	Dialog.addChoice("Equal weighting per:", comOptions, "measurement");
	Dialog.addMessage("If combining with equal weighting per measurement,\nthis step must be performed in one go. You must not\nadd more measuremetns to the combined map later.");

	
Dialog.show();

mapTitle = Dialog.getString();
mapGroup = Dialog.getString();
comSel = Dialog.getChoice();


mapTitle = replace(mapTitle, ", ", ",");
mapTitles = split(mapTitle, ",");

mapGroup = replace(mapGroup, ", ", ",");
mapGroups = split(mapGroup, ",");

if(mapGroups.length > 1)
if(mapGroups.length != mapTitles.length)
	exit("When combining multiple groups there must be the same number of map titles and map groups");


setBatchMode(true);


//----------Find map images------------

imList = getList("image.titles");

mapList = newArray();

for(i=0; i<imList.length; i++){
	selectImage(imList[i]);
	mapInfo = getMetadata("Info");
	if(startsWith(mapInfo, "label=") == true)
		mapList = Array.concat(mapList, getImageID());
}

if(mapList.length == 0){
	path = getDirectory("Choose directory containing colour maps");
	list = getFileList(path);

	for(i=0; i<list.length; i++)
	if(endsWith(list[i], ".tif") == 1){
		//print(list[i]);
		open(path + list[i]);
		mapInfo = getMetadata("Info");
		if(startsWith(mapInfo, "label=") == true)
			mapList = Array.concat(mapList, getImageID());
		else close();
	}

}

print("________________________________");
print("-------Combine Colour Maps-------");
print(" ");
print("Found colour maps:");
for(j=0; j<mapList.length; j++){
	selectImage(mapList[j]);
	print(getTitle());
}
print("---------------------------------------------");
print("-----------Combining Maps-----------");
print("Equal weighting per " + comSel);

if(mapList.length == 0)
	exit("There are no compatible maps; open all colour maps you wish to combine and re-run");

if(mapGroups.length > 1)
	nGroups = mapGroups.length;
else{
	nGroups = 1;
	if(mapGroup == "")
		mapGroups = newArray(1);
}



//-----------------------------Go through maps and combine them--------------------

for(m=0; m<nGroups; m++){

groupMapList = newArray(0);
groupLkp = newArray(0); //group lookup values

print("---------------------------------------------");
if(mapGroup != "")
	print("\"" + mapGroups[m] + "\" group contains:");

for(j=0; j<mapList.length; j++){

selectImage(mapList[j]);
mapInfo = getMetadata("Info");
mapInfo = split(mapInfo, ",");

	for(i=0; i<mapInfo.length; i++){
		row = split(mapInfo[i], "=");
	
		if(row[0] == "label"){
			ts = row[1];

			if(  indexOf(ts, mapGroups[m]) > -1 || mapGroup == ""){
				groupMapList = Array.concat(groupMapList, mapList[j]);
				groupLkp = Array.concat(groupLkp, j);
				print(ts);
			}
		}
	}//i
}//j

//------arrays to hold info--------
label = newArray(groupMapList.length);
nPx = newArray(groupMapList.length);
res = newArray(groupMapList.length);
channelString = newArray(groupMapList.length);
label = newArray(groupMapList.length);
xMins = newArray(groupMapList.length);
yMins = newArray(groupMapList.length);
zMins = newArray(groupMapList.length);
xMaxs = newArray(groupMapList.length);
yMaxs = newArray(groupMapList.length);
zMaxs = newArray(groupMapList.length);
crop = newArray(groupMapList.length);
tetra = newArray(groupMapList.length); // flag for tetrachromatic images
tetra[0] = 0;
weber = newArray(groupMapList.length);


for(j=0; j<groupMapList.length; j++){
selectImage(groupMapList[j]);
mapInfo = getMetadata("Info");
mapInfo = split(mapInfo, ",");

for(i=0; i<mapInfo.length; i++){
	row = split(mapInfo[i], "=");
	
	if(row[0] == "label") label[j] = row[1];
	if(row[0] == "nPx") nPx[j] = parseInt(row[1]);
	if(row[0] == "res") res[j] = parseInt(row[1]);
	if(row[0] == "channels") channelString[j] = row[1];
	if(row[0] == "weber") weber[j] = row[1];
	if(row[0] == "x_limits"){
		xLims = split(row[1], ":");
		xMins[j] = parseInt(xLims[0]);
		xMaxs[j] = parseInt(xLims[1]);
	}
	if(row[0] == "y_limits"){
		yLims = split(row[1], ":");
		yMins[j] = parseInt(yLims[0]);
		yMaxs[j] = parseInt(yLims[1]);
	}
	if(row[0] == "z_limits"){
		zLims = split(row[1], ":");
		zMins[j] = parseInt(zLims[0]);
		zMaxs[j] = parseInt(zLims[1]);
		tetra[j] = 1;
	}	 

}//i
}//j


//-----------Work out final figure bounds---------------------

	cxMin = 10E10;
	cxMax = -10E10;
	cyMin = 10E10;
	cyMax = -10E10;
	for(j=0; j<groupMapList.length; j++){
		if(xMins[j] < cxMin) cxMin = xMins[j];
		if(yMins[j] < cyMin) cyMin = yMins[j];
		if(xMaxs[j] > cxMax) cxMax = xMaxs[j];
		if(yMaxs[j] > cyMax) cyMax = yMaxs[j];
	}


//--------------Crop z-axis-------------------
if(tetra[0] == 1){
	czMin = 10E10;
	czMax = -10E10;
	for(j=0; j<groupMapList.length; j++){
		if(zMins[j] < czMin) czMin = zMins[j];
		if(zMaxs[j] > czMax) czMax = zMaxs[j];
	}
}


//---------------Check all maps are compatible-------------

for(j=0; j<groupMapList.length; j++)
for(k=j+1; k<groupMapList.length; k++){
		if(res[j] != res[k]){
			print("Stopping - these maps are not compatible:");
			print(label[j] " map resolution = " + res[j]);
			print(label[k] " map resolution = " + res[k]);
			exit("Error - the resolutions of the colour maps do not match");
		}
		if(channelString[j] != channelString[k]){
			print("Stopping - these maps are not compatible:");
			print(label[j] " channel names = " + channelString[j]);
			print(label[k] " channel names = " + channelString[k]);
			exit("Error - the maps have different channel names");
		}
		if(weber[j] != weber[k]){
			print("Stopping - these maps are not compatible:");
			print(label[j] + " Weber fractions = " + weber[j]);
			print(label[k] + " Weber fractions = " + weber[k]);
			exit("Error - the maps have different weber fractions");
		}
		if(label[j] == label[k]){
			print("Warning, two colour maps share the same label.\nThey will be renamed:");
			print("Label 1: " + label[j] + "_1");
			print("Label 2: " + label[k] + "_2");
			label[j] = label[j]+"_1";
			label[k] = label[k]+"_2";
		}

}//j k


//--------------------------Expand maps to same size---------------------------
for(j=0; j<groupMapList.length; j++){

	selectImage(groupMapList[j]);

	mw = (xMaxs[j]-xMins[j])*res[0];
	mh = (yMaxs[j]-yMins[j])*res[0];

	selectImage(groupMapList[j]);
	run("Select All");
	run("Copy");
	ts = label[j] + "_Colour_Map";
	if(tetra[j] == 0){
		newImage(ts, "32-bit black", (cxMax-cxMin)*res[0], (cyMax-cyMin)*res[0], 1);
		makeRectangle((xMins[j]-cxMin)*res[0], (yMins[j]-cyMin)*res[0], mw, mh);
		run("Paste");
		nID = getImageID();
	} else {

		newImage(ts, "32-bit black", (cxMax-cxMin)*res[0], (cyMax-cyMin)*res[0], (czMax-czMin)*res[0]);
		nID = getImageID();
		for(i=0; i<(zMaxs[j]-zMins[j])*res[0]; i++){
			selectImage(groupMapList[j]);
			//setSlice(i-(zMins[j]*res[0])+1);
			setSlice(i+1);
			run("Select All");
			run("Copy");
			selectImage(nID);
			setSlice((zMins[j]-czMin)*res[0]+i+1);
			//makeRectangle(xMins[j], yMins[j], mw, mh);
			makeRectangle((xMins[j]-cxMin)*res[0], (yMins[j]-cyMin)*res[0], mw, mh);
			run("Paste");
		}
		nID = getImageID();
	}

	run("Select None");

	//selectImage(groupMapList[j]);
	//close();

	selectImage(nID);
	groupMapList[j]=getImageID();
	//mapList[groupLkp[j]] = getImageID();


//-----------Normalise pixel counts---------------
if(comSel == "measurement"){
	selectImage(groupMapList[j]);
	if(nPx[j] != 1){
		ts = "value=" + nPx[j];
		if(tetra[j] == 1)
			ts = ts + " stack";
		run("Divide...", ts);
	}
}

//setBatchMode("show");

}//j

pxSum = nPx[0];

for(j=1; j<groupMapList.length; j++){

	pxSum += nPx[j];

	if(tetra[0] == 0)
		imageCalculator("Add 32-bit", groupMapList[0], groupMapList[j]);
	else 
		imageCalculator("Add 32-bit stack", groupMapList[0], groupMapList[j]);

	selectImage(groupMapList[j]);
	close();

}//j


if(comSel == "measurement")
	pxSum = groupMapList.length;


//---------Reset the image pixel count to reflect normalisation----------------

selectImage(groupMapList[0]);

	if(tetra[0] == 0){
		ts = "label=" + mapTitles[m] + ",nPx=" + pxSum + ",res=" + res[0] +
			",channels=" + channelString[0] + ",weber=" + weber[0] +
			",x_limits=" + cxMin + ":" + cxMax +
			",y_limits=" + cyMin + ":" + cyMax;
	} else {
		ts = "label=" + mapTitles[m] + ",nPx=" + pxSum + ",res=" + res[0] +
			",channels=" + channelString[0] + ",weber=" + weber[0] +
			",x_limits=" + cxMin + ":" + cxMax +
			",y_limits=" + cyMin + ":" + cyMax +
			",z_limits=" + czMin + ":" + czMax;
	}

setMetadata("Info", ts);
rename(mapTitles[m]);
setBatchMode("show");

}//m


print("________________________________");

setBatchMode(false);




