

//refs = "99,80,60,40,20,10,5,2";
//refs = "99,79.5882352941,58.6882352941,40.1823529412,19.9294117647,9.7058823529,5.3123529412,1.4170588235";

// these pre-loaded values are measurements of my XRite passport grey levels from 420-680nm
refs = "91.5736394356503,59.4147769174464,38.3956994557667,19.3768145989381,10.1723971251945,3.21941237074612";




equNames = newArray("Straight Line", "JT Linearisation", "sRGB", "2nd Degree Polynomial",  "3rd Degree Polynomial", "Rodbard", "Power", "Exponential", "Exponential with Offset", "Exponential Recovery", "Gaussian", "Gamma Variate", "Chapman-Richards");
equFormulae = newArray("Straight Line", "y =x*x*c +x*d + exp((x-a)/b)", "sRGB", "2nd Degree Polynomial",  "3rd Degree Polynomial", "Rodbard", "Power", "Exponential", "Exponential with Offset", "Exponential Recovery", "Gaussian", "Gamma Variate", "Chapman-Richards");

Dialog.create("Model Linearisation");

	Dialog.addMessage("Specify the grey standard reflectance values\nseparated by commas.");

	Dialog.addString("Standard reflectances", refs, 20);

	Dialog.addMessage(" " );
	Dialog.addString("Camera Name", "Test", 20);
	Dialog.addHelp("http://www.empiricalimaging.com/knowledge-base/linearisation-modelling/");
	
Dialog.show();


refs = Dialog.getString();
camName = Dialog.getString();

refs = split(refs, ",");
nRefs = refs.length;

imagePath=File.openDialog("Select Photo Containing Standards"); // get file locations
open(imagePath);
photoID = getImageID();

bd = bitDepth;

if(bitDepth==24){
	sliceN = 3;
	sliceNames = newArray("Red", "Green", "Blue");


	//------------exposure check----------

	setBatchMode(true);
	run("Select All");
	run("Duplicate...", "duplicate");
	eID=getImageID();
	run("RGB Exposure Overlay");
	rename("Exposure Test");
	selectImage(photoID);

	run("Add Image...", "image=[Exposure Test] x=0 y=0 opacity=100 zero");
	selectImage(eID);
	close();
	selectImage(photoID);
	setBatchMode(false);


}else{
	sliceN = nSlices;
	sliceNames = newArray(sliceN);
}
pxs = newArray(nRefs*sliceN);

run("Select None");

for(j=0; j<nRefs; j++){


	waitForUser("Select " + refs[j] + "% standard");

	if(bitDepth!=24){ // image stack

		for(i=0; i<nSlices; i++){
			setSlice(i+1);
			getStatistics(area, mean);
			pxs[(i*nRefs) + j] = mean;
			if(j==0)
				if(getInfo("slice.label") != "")
					sliceNames[i] = getInfo("slice.label");
			else sliceNames[i] = i+1;
		}

		setSlice(1);
	}// stack

	if(bitDepth==24){ // RGB image

		setRGBWeights(1,0,0); //red
			getStatistics(area, mean);
			pxs[j] = mean;

		setRGBWeights(0,1,0); //green
			getStatistics(area, mean);
			pxs[nRefs + j] = mean;

		setRGBWeights(0,0,1); //blue
			getStatistics(area, mean);
			pxs[(2*nRefs) + j] = mean;

	}// RGB image

} //j

r2s = newArray(equNames.length*sliceN);
r2eqs = newArray(equNames.length*sliceN);
r2sliceNames = newArray(equNames.length*sliceN);

print("\\Clear");
print("---------------Linearisation Modelling---------------");
print("_____________________________________________");


for(k=0; k<equNames.length; k++){

print(" ");
print("------------Fitting: " + equNames[k] +"------------");

//Array.show(refs);

for(i=0; i<sliceN; i++){

	print(" ");
	print(sliceNames[i] + " fit with " + equNames[k]);
	Fit.logResults;
	tPxs = newArray(nRefs);
	for(j=0; j<nRefs; j++)
		tPxs[j] = pxs[(i*nRefs) + j];

	eqn = equFormulae[k];
	if(eqn == "sRGB"){ 	// Apply sRGB conversion, then fit to a straight line
		for(j=0; j<nRefs; j++){
			if(tPxs[j] <=10)
				tPxs[j]  = (tPxs[j] /255)/12.92;
			else tPxs[j] = pow(((tPxs[j] /255)+0.055)/(1+0.055),2.4);
		}
		eqn = "Straight Line";
	}//sRGB

	Fit.doFit(eqn, tPxs, refs);
	r2s[(k*sliceN)+i] = Fit.rSquared;
	r2eqs[(k*sliceN)+i] = equNames[k];
	r2sliceNames[(k*sliceN)+i] = sliceNames[i];

	//Array.show(tPxs);
}


}//k


for(i=0; i<sliceN; i++){

//Array.show(r2s);

r2Ranks = Array.rankPositions(r2s);

run("New... ", "name=[Model Fitting Results] type=Table");
	print("[Model Fitting Results]", "\\Headings:Model\tChannel\tR^2 Fit");

for(i=equNames.length*sliceN-1; i>=0; i--)
	print("[Model Fitting Results]", r2eqs[r2Ranks[i]]+ "\t" + r2sliceNames[r2Ranks[i]] + "\t" + d2s(r2s[r2Ranks[i]],8));

endFlag = 0;
coefs = newArray("a","b","c","d");

while(endFlag == 0){

	Dialog.create("Select Best Model");

		Dialog.addMessage("Select which model to view");
		Dialog.addChoice("Model:", equNames, r2eqs[r2Ranks[equNames.length*sliceN-1]]);
		Dialog.addCheckbox("Save Results and Finish", false);

	Dialog.show();

	// close any open graphs
	close("Fitting of*");
			
	selEq = Dialog.getChoice();
	endFlag = Dialog.getCheckbox();

	for(i=0; i<equNames.length; i++)
		if(equNames[i] == selEq)
			eqn = equFormulae[i];
	
	for(i=0; i<sliceN; i++){

		tPxs = newArray(nRefs);
		for(j=0; j<nRefs; j++)
			tPxs[j] = pxs[(i*nRefs) + j];

		if(eqn == "sRGB"){ 	// Apply sRGB conversion	
			for(j=0; j<nRefs; j++){
				if(tPxs[j] <=10)
					tPxs[j]  = (tPxs[j] /255)/12.92;
				else tPxs[j] = pow(((tPxs[j] /255)+0.055)/(1+0.055),2.4);
			}
			eqn = "Straight Line";
		}//sRGB


		Fit.doFit(eqn, tPxs, refs);
		if(bitDepth==bd)
			setColor(sliceNames[i]);
		Fit.plot;
		fittingLabel = "Fitting of " + sliceNames[i] + " with " + selEq;
		Overlay.drawString(fittingLabel, 2, 15);
		Overlay.show();
		rename(fittingLabel);

		if(i==0)
			linFunction = "equation=[" + selEq + "]";
		else linFunction = linFunction + ",equation=[" + selEq + "]";

		for(j=0; j<Fit.nParams; j++)
			linFunction = linFunction + " " + coefs[j] + "=" + d2s(Fit.p(j),12);

		linFunction = linFunction + " slice=" + (i+1);

	}
	
	
}//while


//print(linFunction);

//--------------------SAVE OUTPUT---------------------

settingsFilePath = getDirectory("plugins") + "micaToolbox/Linearisation Models/" + camName + ".txt";
//if(File.exists(settingsFilePath)==true)
//	File.delete(settingsFilePath);


dataFile = File.open(settingsFilePath);
print(dataFile, linFunction);
File.close(dataFile);







