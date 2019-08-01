nROIs = roiManager("Count");

setBatchMode(true);

run("Select All");
getStatistics(area, mean, min, max);
for(i=1; i<=max; i++){
	setThreshold(i, i);
	run("Create Selection");
	roiManager("Add");
	roiManager("Select", nROIs+i-1);
	roiManager("Rename", i);
}


resetThreshold();


//----------------------Particle Analysis----------------------

windowTitles = getList("window.titles");
for(i=0; i<windowTitles.length; i++)
	if(windowTitles[i] == "Results")
		IJ.renameResults("Results", "Original ROI Resutls");



run("Set Measurements...", "centroid center perimeter fit shape feret's redirect=None decimal=9");

oID = getImageID();
w = getWidth();
h = getHeight();

newImage("Masks", "8-bit white", w, h, 1);
ID = getImageID();

clusterCounts = newArray(max);

for(i=1; i<=max; i++){
	rename(i);
	run("Select All");
	run("Set...", "value=255");
	roiManager("Select", nROIs+i-1);
	run("Set...", "value=0");
	run("Select None");
	run("Analyze Particles...", "summarize in_situ");
	clusterCounts[i-1] = Table.get("Count", i-1);
}

close();



Table.renameColumn("Slice", "Cluster ID");
updateResults();

IJ.renameResults("Summary", "Cluster Particle Analysis Summary Results");

//updateResults();

selectImage(oID);
run("Select None");

setBatchMode(false);

tArea = 0;

row=0;
for(i=0; i<max; i++)
for(j=0; j<clusterCounts[i]; j++){
	tArea = getResult("Area", row);
	setResult("Area", row, "" + (i+1) + "_" + (j+1));
	setResult("Area (px)", row, tArea);
	row++;
}

updateResults();

selectWindow("Results");
Table.renameColumn("Area", "ClusterID_Particle#");
IJ.renameResults("Results", "Individual Particle Results");

