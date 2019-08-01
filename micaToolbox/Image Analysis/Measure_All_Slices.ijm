// Measure all channels
run("Set Measurements...", "area mean min redirect=None decimal=9");

plugins = getDirectory("plugins");

installString = "install=[" + plugins + "micaToolbox/Image Analysis/Measure_All_Slices.ijm]";

run("Install...", installString);// Measure all channels

macro "Measure all channels [m]" {

setBatchMode(true);

row = nResults;

if(bitDepth!=24){ // image stack

if(getMetadata("Label") == ""){
	for(i=1; i<nSlices+1; i++){
		setSlice(i);
		getStatistics(area, mean);
		setResult(i + "_mean", row, mean);
	}
} else {

	for(i=1; i<nSlices+1; i++){
		setSlice(i);
		getStatistics(area, mean);
		setResult(getMetadata("Label")+"_mean", row, mean);
	}
}

	setSlice(1);

}// stack

if(bitDepth==24){ // RGB image

setRGBWeights(1,0,0); //red
	getStatistics(area, mean);
	setResult("Red_mean", row, mean);

setRGBWeights(0,1,0); //green
	getStatistics(area, mean);
	setResult("Green_mean", row, mean);

setRGBWeights(0,0,1); //blue
	getStatistics(area, mean);
	setResult("Blue_mean", row, mean);


}// RGB image


setBatchMode(false);
updateResults();

} // macro ends
