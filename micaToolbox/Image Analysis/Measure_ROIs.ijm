//run("Set Measurements...", "area mean min redirect=None decimal=9");
run("Set Measurements...", "redirect=None decimal=9");
//setBatchMode(true);

for(j=0; j<roiManager("count"); j++){


row = nResults;
roiManager("Select", j);
tStr = getInfo("selection.name");

if(startsWith(tStr, "Scale Bar") == false){ // only measure ROIs which aren't scale bars
tStr = getTitle + "_" + tStr;
setResult("Label", row, tStr );


if(bitDepth!=24){ // image stack

if(getMetadata("Label") == ""){
	for(i=1; i<nSlices+1; i++){
		setSlice(i);
		getStatistics(area, mean, min, max, sd);
		setResult(i +"_mean", row, mean);
		setResult(i +"_sd", row, sd);
	}
} else {

	for(i=1; i<nSlices+1; i++){
		setSlice(i);
		getStatistics(area, mean, min, max, sd);
		setResult(getMetadata("Label") + "_mean", row, mean);
		setResult(getMetadata("Label") + "_sd", row, sd);
	}
}

	updateResults();
	setSlice(1);

}// stack

if(bitDepth==24){ // RGB image

setRGBWeights(1,0,0); //red
	getStatistics(area, mean, min, max, sd);
	setResult("r_mean", row, mean);
	setResult("r_sd", row, sd);

setRGBWeights(0,1,0); //green
	getStatistics(area, mean, min, max, sd);
	setResult("g_mean", row, mean);
	setResult("g_sd", row, sd);

setRGBWeights(0,0,1); //blue
	getStatistics(area, mean, min, max, sd);
	setResult("b_mean", row, mean);
	setResult("b_sd", row, sd);

}// RGB image

}// ignore scale bar

}//j roi




