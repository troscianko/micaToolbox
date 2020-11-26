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
		Dialog.addCheckbox("Normalise", true);
		Dialog.addChoice("Curve", fitOptions, "Straight Line");
		//Dialog.addChoice("Normalisation", lineariseOptions, "Linearise & Normalise");
		Dialog.addCheckbox("Log linearisation fit results", false);
		Dialog.addCheckbox("Align", true);

	Dialog.show();

	normaliseChoice = Dialog.getCheckbox();
	equation = Dialog.getChoice();
	//lineariseOnly = Dialog.getChoice();
	logResults = Dialog.getCheckbox();
	alignChoice = Dialog.getCheckbox();


setBatchMode(true);



for(j=0; j<nSlices; j++){

	setSlice(j+1);


	// EXTRACT DATA FROM METADATA

	metaString = getMetadata();
	metaString = split(metaString, "\n");

	refFlag = 0;
	alignFlag = 0;

	for(i=0; i<metaString.length; i++){

		if(startsWith(metaString[i], "refVals=") == true){
			refVals = replace(metaString[i], "refVals=", "");
			refFlag = 1;
		}

		if(startsWith(metaString[i], "alignMethod=") == true){
			alignMethod = replace(metaString[i], "alignMethod=", "");
			alignFlag ++;
		}
		

		if(startsWith(metaString[i], "alignData=") == true){
			alignData = replace(metaString[i], "alignData=", "");
			alignFlag ++;
		}
			

	}

	if(normaliseChoice == true && refFlag == 0)
		waitForUser("The reflectance metadata are not present - has this image already been processed?");

	//if(alignChoice == true && alignFlag < 2)
	if(alignMethod != "None" && alignFlag <2)
		exit("The alignment metadata are not present - has this image already been processed?");

	//imageLabel = getMetadata("Label");

	if(alignMethod == "None")
		alignChoice = 0;
	// ALIGN
	if(alignChoice == true){

	if(alignData != "0:0:1"){

	sliceAlignData = split(alignData, ":");
	
	if(alignMethod == "Manual Align" || alignMethod == "Auto-Align"){

	if(sliceAlignData[2] == "1"){ // no rescaling required
		if(sliceAlignData[0] !="0" || sliceAlignData[1] !="0"){ // needs shifting
			run("Select All");
			run("Copy");
			makeRectangle( -1*parseInt(sliceAlignData[0]), -1*parseInt(sliceAlignData[1]), getWidth(), getHeight());
			run("Paste");

			// At this point the image could either be cropped to the smallest common area, or just colour the outside black
			setBackgroundColor(0, 0, 0);
			run("Clear Outside", "slice");

			//run("Crop");
		}
	} else{

	// ALIGN & SCALE

		multiSpecID = getImageID();
		run("Select All");

		run("Scale...", "x=" + sliceAlignData[2] +" y=" + sliceAlignData[2] +" interpolation=Bilinear create title=scaled.tif");
		scaledImageID = getImageID();
		scaledWidth = getWidth();
		scaledHeight = getHeight();
		run("Select All");
		run("Copy");

		selectImage(multiSpecID);
		makeRectangle( -1*parseInt(sliceAlignData[0]), -1*parseInt(sliceAlignData[1]), scaledWidth, scaledHeight);
		run("Paste");
		setBackgroundColor(0, 0, 0);
		run("Clear Outside", "slice");

		selectImage(scaledImageID);
		close();

	}// else align & scale
	} // align method = manual or auto


	if(alignMethod == "Affine Align"){

		ts = "xc=" + sliceAlignData[0] +" xx=" + sliceAlignData[1]  +" xy=" + sliceAlignData[2] + " yc=" + sliceAlignData[3] + " yx=" + sliceAlignData[4] + " yy=" + sliceAlignData[5] + " slice=" + (j+1);
		run("Affine align slice", ts);

	} // align method = affine


	} // align data equals 0:0:1, so don't do anything
	} // align choice ==true

	// LINEARISE & NORMALISE

	if(normaliseChoice == true){


		sliceRefVals = split(refVals, "_");

		nStandards = sliceRefVals.length;

		if(nStandards>0){// only normalise image if there's a grey standard

			greyVals = newArray(nStandards);
			pxVals = newArray(nStandards);

			for(i=0; i<nStandards; i++){
				tempVals = split(sliceRefVals[i], ":");
				greyVals[i] = parseFloat(tempVals[0]);
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
				if(fitR2 < 0.98)
				print("WARNING - linearisation fit is not perfect, R^2 = " + fitR2 + "\n \n This normally occurs when standards are not perfectly measured\n or when there are subtle light intensity differences" );
			}// multiple standards

			if(nStandards == 1){ // ONLY ONE STANDARD
				x2 = 0;
				x1 = greyVals[0]/pxVals[0];
				x0 = 0;
			}


			// LINEARISE & NORMALISE

			lineariseString = "x^2=" + x2 +" x=" + x1 + " constant=" + x0 + " slice=" + (j+1);


			run("Polynomial Slice Transform 32Bit", lineariseString);
			newLabel = metaString[0] + ":Normalised";
			setMetadata(newLabel);

		}// >0 stadnards


	}// linearise and normalise


}//j

setMinAndMax(0, 100);
