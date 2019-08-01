run("Set Measurements...", "area mean min redirect=None decimal=9");
//setBatchMode(true);

Dialog.create("Measure GabRat Edge Disruption");
	Dialog.addMessage("This applies the 'GabRat' measurement of edge\ndisruption. The edge disruption is measured for\neach ROI specified in the image and each channel");

	Dialog.addMessage("Please cite: Troscianko, J., Skelhorn, J. & Stevens,\nM. Quantifying camouflage: how to predict\ndetectability from appearance. BMC Evolutionary\nBiology 17, 7 (2017)");


	Dialog.addNumber("Number of angles", 4);
	Dialog.addNumber("Sigma", 3.0);
	Dialog.addNumber("Gamma aspect ratio", 1.0);
	Dialog.addNumber("Frequency", 2.0);

	Dialog.addMessage("Sigma is the most important variable to change\nas this controlls the scale of the kernel. Use the\n'GabRat Disruption' tool for assessing kernels\nand additional output information");
	Dialog.addHelp("http://www.empiricalimaging.com/knowledge-base/gabrat/");
Dialog.show();

angles = Dialog.getNumber();
sigma = Dialog.getNumber();
gamma = Dialog.getNumber();
freq = Dialog.getNumber();


for(j=0; j<roiManager("count"); j++){


roiManager("Select", j);

tStr = getInfo("selection.name");

if(startsWith(tStr, "Scale Bar") == false){ // only measure ROIs which aren't scale bars
tStr = getTitle + "_" + tStr;

	for(i=1; i<nSlices+1; i++){
		setSlice(i);
		tStr2 = tStr + "_" + getMetadata("Label");
		run("GabRat Disruption", "number_of_angles=&angles sigma=&sigma gamma=&gamma frequency=&freq label=&tStr2");
	}
}// scale bar
}//j roi





