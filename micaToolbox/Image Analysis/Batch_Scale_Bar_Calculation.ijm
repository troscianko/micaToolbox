/*
_______________________________________________________________________

	Title: Batch Calculate Scale-Bar Metrics
	Author: Jolyon Troscianko
	Date: 16/10/2014
.................................................................................................................

Description:
''''''''''''''''''''''''''''''''
This tool calculates the pixels per millimetre (or other scale unit) in a whole folder
of .mspec multispectral images. It provides statistics on the scale bars at so that
the user can work out the optimal scaling that uniformly sclaes all images down,
ensuring no images are enlarged (which will create false data).

It also warns the user if the minimum value (which is the value that should not be
exceeded) is an outlier (defined as >2.5 standard deviations from the mean).

The image with the smallest (minimum) scale bar is shown in case this is anomalous
and needs checking.

Instructions:
''''''''''''''''''''''''''''''''''''''''
Select a folder full of the .mspec files and their associalted .zip files containing ROI
informtion and scale bars. The scale bars must be added using the Save ROIs tool,
or directly following gneration of a multispectral image

_________________________________________________________________________
*/











fileDir = getDirectory("Select DIR");

fileList = getFileList(fileDir);



ROIlist = newArray();

for(i=0; i<fileList.length; i++) // list ROI files
	if(endsWith(fileList[i], ".zip") == 1 || endsWith(fileList[i], ".ZIP") == 1 || endsWith(fileList[i], ".roi") == 1 || endsWith(fileList[i], ".ROI") == 1)
		ROIlist = Array.concat(ROIlist, fileList[i]);


setBatchMode(true);
newImage("Untitled", "32-bit black", 10, 10, 1);
roiArray = newArray();

minVal = 10E32;
minName = "";

for(i=0; i<ROIlist.length; i++){
	roiPath = fileDir + ROIlist[i];
	roiManager("Open", roiPath);
	
	nSelections = roiManager("count");

	scaleFlag = 0;

	for(j=0; j<nSelections; j++){
		roiManager("select", j);
		selName = getInfo("selection.name");

		if( startsWith(selName, "Scale") == 1){ // found the scale bar - extract the info
			scaleLoc = j;
			scaleFlag = 1;
			scaleInfo = split(selName, ":");
			pixLength = scaleInfo[1];
			scaleMm = scaleInfo[2];
		}	
	}//j


	if(scaleFlag ==1){
		scaleVal = parseFloat(pixLength)/parseFloat(scaleMm);
		roiArray = Array.concat(roiArray,scaleVal);
		if(scaleVal < minVal){
			minVal = scaleVal;
			minName = ROIlist[i];
		}

	}

	for(j=0; j<nSelections; j++){ // clear ROI
		roiManager("select", 0);
		roiManager("Delete");
	}
	

}//i

close();
setBatchMode(false);

//Array.print(roiArray);
Array.getStatistics(roiArray, min, max, mean, stDev);
print("\\Clear");
//minLoc = -1;
//for(i=0; i<roiArray.length; i++)
//	if(roiArray[i] == min)
//		minLoc = i;

print("___________Scale Bar Statistics:___________\n ");

print("Path: " + fileDir);
print("Scale bar count: " + roiArray.length );
print("Minimum px/mm: " + min);
print("Maximum px/mm: " + max);
print("Mean px/mm: " + mean);
print("SD px/mm: " + stDev);

print("---------------------------------------------------------\n ");

if(min < (mean-(2.5*stDev)))
	print("The minimum is an outlier, less than 2.5\nstandard deviations lower than the mean.\nUsing a scaling value equal to or lower than\nthe minimum will mean no images are scaled\nup \(which creates false data\), but the\nminimum might be anomalous here");
else print("The minimum is not an outlier \(it is <2.5\nstandard deviations from the mean\).\nUsing a scaling value equal to or lower than\nthe minimum will mean no images are scaled\nup \(which creates false data\).");

minName = replace(minName, ".zip", "");
print(" \nThe smallest scale bar is in photo: " + minName);

print("_________________________________________\n ");

