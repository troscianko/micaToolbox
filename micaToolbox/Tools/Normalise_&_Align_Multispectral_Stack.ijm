/*
________________________________________________________________________________________

_________________________PROCESS MULTISPECTRAL STACK_____________________________
	
	Generates a linearised, normalised & aligned multispectral
	image from previously processed information about the 
	grey standards and alignment.

----------------------------------------------------------------------------------------------------------------------

Author: Jolyon Troscianko

Date: 11/7/2014

________________________________________________________________________________________

------------------------------------Linearisation & normalisation---------------------------------------------

Requirements:
	- DCRAW plugin v1.4.0 for imageJ working with your RAW files.


Installation:

Description:


_______________________________________________________________________________________
*/

fitOptions = newArray("Straight Line", "2nd Degree Polynomial");
//lineariseOptions = newArray("Linearise Only", "Linearise & Normalise");

/* potential curves:
Straight Line,
2nd Degree Polynomial,
3rd Degree Polynomial,
4th Degree Polynomial,
Exponential,
Exponential with Offset,
Exponential Recovery,
Power,
Log,
Rodbard,
Gamma Variate,
*/

	Dialog.create("Linearisation & Normalisation Options");
		Dialog.addChoice("Curve", fitOptions, "Straight Line");
		//Dialog.addChoice("Normalisation", lineariseOptions, "Linearise & Normalise");
		Dialog.addCheckbox("Log linearisation fit results", false);
		Dialog.addCheckbox("Align_Only", false);
	Dialog.show();

	equation = Dialog.getChoice();
	//lineariseOnly = Dialog.getChoice();
	logResults = Dialog.getCheckbox();
	alignOnly = Dialog.getCheckbox();


run("32-bit");
setBatchMode(true);

for(j=0; j<nSlices; j++){

	setSlice(j+1);

	// EXTRACT DATA FROM SLICE LABEL

	//linData = getInfo("slice.label"); // doesn't extract the whole label 
	linData = getMetadata("Label");
	linData = split(linData, ",");
	alignData = split(linData[0], ":");

	imageLabel = split(linData[0], ":");
	imageLabel = imageLabel[0] + ":" + imageLabel[1];

	// ALIGN

	if(alignData[4] == "1"){ // no rescaling required
		if(alignData[2] !="0" || alignData[3] !="0"){ // needs shifting
			run("Select All");
			run("Copy");
			makeRectangle( -1*parseInt(alignData[2]), -1*parseInt(alignData[3]), getWidth(), getHeight());
			//makeRectangle( parseInt(alignData[2]), parseInt(alignData[3]), getWidth(), getHeight());
			run("Paste");

			// At this point the image could either be cropped to the smallest common area, or just colour the outside black
			setBackgroundColor(0, 0, 0);
			run("Clear Outside", "slice");

			//run("Crop");
		}
	} else{

	// ALIGN & SCALE

		multiSpecID = getImageID();
		//run("Scale...", "x=" + alignData[4] +" y=" + alignData[4] +" z=- width=" + round(parseFloat(alignData[4])*getWidth()) + " height=" + round(parseFloat(alignData[4])*getWidth()) + " depth=1 interpolation=Bilinear create title=resized");

		run("Select All");
		//run("Copy");
		//run("Internal Clipboard");
		
		run("Scale...", "x=" + alignData[4] +" y=" + alignData[4] +" interpolation=Bilinear create title=scaled.tif");
		scaledImageID = getImageID();
		scaledWidth = getWidth();
		scaledHeight = getHeight();
		run("Select All");
		run("Copy");

		selectImage(multiSpecID);
		//makeRectangle( -1*parseInt(alignData[2]), -1*parseInt(alignData[3]), getWidth(), getHeight());
		makeRectangle( -1*parseInt(alignData[2]), -1*parseInt(alignData[3]), scaledWidth, scaledHeight);
		run("Paste");
		//run("Crop");
		setBackgroundColor(0, 0, 0);
		run("Clear Outside", "slice");

		selectImage(scaledImageID);
		close();

	}// else align & scale

	// LINEARISE & NORMALISE

	if(alignOnly == 0){

		nStandards = linData.length-1;

		if(nStandards>0){// only normalise image if there's a grey standard

			greyVals = newArray(nStandards);
			pxVals = newArray(nStandards);

			for(i=0; i<nStandards; i++){
				tempVals = split(linData[i+1], ":");
				//greyVals[i] = (parseFloat(tempVals[0])/100)*65535; // convert to 16-bit linear reflectance
				greyVals[i] = parseFloat(tempVals[0]); // convert to 16-bit linear reflectance
				pxVals[i] = parseFloat(tempVals[1]);
			}

			if(nStandards > 1){ // MULTIPLE STANDARDS

				if(logResults == 1){
					print("______________________________________");
					print(imageLabel);
					Fit.logResults;
					print(" ");
				}


				Fit.doFit(equation, pxVals, greyVals);
	

				if(equation == "Straight Line"){
					x2 = 0;
					x1 = Fit.p(1);
					x0 = Fit.p(0);
				}

				if(equation == "2nd Degree Polynomial"){
					x2 = Fit.p(2);
					x1 = Fit.p(1);
					x0 = Fit.p(0);
				}

				if(logResults == 1){
					print("______________________________________");
					print(imageLabel);
					Fit.logResults;
					print(" ");
				}

				fitR2 = Fit.rSquared;
				if(fitR2 < 0.998)
				print("WARNING - linearisation fit is not perfect, R^2 = " + fitR2 );
			}// multiple standards

			if(nStandards == 1){ // ONLY ONE STANDARD
				x2 = 0;
				x1 = greyVals[0]/pxVals[0];
				x0 = 0;
			}


			// LINEARISE & NORMALISE

			lineariseString = "x^2=" + x2 +" x=" + x1 + " constant=" + x0 + " slice=" + (j+1);

			run("Polynomial Slice Transform 32Bit", lineariseString);
			newLabel = "label=" +  imageLabel + ":Normalised";
			run("Set Label...", newLabel);

		}// >0 stadnards

		// Rename Slice label so the linearisation isn't inadvertently repeated

		if(nStandards==0){
			newLabel = "label=" +  imageLabel + ":Linear";
			run("Set Label...", newLabel);
		}

	} else { // align only
		newLabel = "label=" +  imageLabel + ":AlignedLinear";
		run("Set Label...", newLabel);
	}// alignment only

}//j

setMinAndMax(0, 100);
