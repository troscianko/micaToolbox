// -------------Create overlay from metadata----------------

selectImage("Photo Screening");
photoScreeningID = getImageID();

Overlay.remove;

dataString = getMetadata("Info");

dataString = split(dataString, "\n");

row = split(dataString[0], ",");
fileDir = row[0];
settingsChoice = row[1];
thumbWidth = parseInt(row[2]);
scaledHeight = parseInt(row[3]);

setColor(128,128,128);

Overlay.drawString("Path: " + fileDir, 18, scaledHeight + 65);
Overlay.drawLine(thumbWidth+10, 254, thumbWidth+266, 254);

nButtons = dataString.length -1;
row = split(dataString[1], ",");
nButtons = nButtons * row.length;

buttonXs = newArray(nButtons+2);
buttonYs = newArray(nButtons+2);
buttonWs = newArray(nButtons+2);
buttonHs = newArray(nButtons+2);
buttonTypes = newArray(nButtons+2);

vPos = 280;
buttonCount = 0;
settingValues = newArray(nButtons);
filterNames = newArray(dataString.length-1);
standardLevels = newArray(row.length -1);

imagesSelected = 1;
zeroFlag = 0;
zeroLoc = 0;

for(i=1; i<dataString.length; i++){
	row = split(dataString[i], ",");
	//setColor(255,255,255);
	setColor(128,128,128);
	tempVal = split(row[0], ":");
	Overlay.drawString(tempVal[0] + " photo:", thumbWidth+18, vPos);
	filterNames[i-1] = tempVal[0];
	vPos += 20;

	if(tempVal[1] == "not set"){
		//setColor(128,128,128);
		setColor(255,255,255);
		Overlay.drawString("select image", thumbWidth+38, vPos);
		Overlay.drawRect(thumbWidth+15, vPos-17, 15, 15);
		imagesSelected = 0;
	} else {
		setColor(128,128,128);
		//setColor(255,255,255);
		Overlay.drawString(tempVal[1], thumbWidth+38, vPos);
		Overlay.drawRect(thumbWidth+15, vPos-17, 15, 15);
		Overlay.drawRect(thumbWidth+18, vPos-14, 9, 9);
	}

	//setColor(128,128,128);
	//Overlay.drawString(tempVal[1], thumbWidth+38, vPos);
	//Overlay.drawRect(thumbWidth+15, vPos-17, 15, 15);
	settingValues[buttonCount] = tempVal[1];
	buttonXs[buttonCount] = thumbWidth+15;
	buttonYs[buttonCount] = vPos-11;
	buttonWs[buttonCount] = 15;
	buttonHs[buttonCount] = 15;
	buttonTypes[buttonCount] = "filter";
	buttonCount ++;
	vPos += 20;
	
	for(j=1; j<row.length; j++){
		tempVal = split(row[j], ":");
		setColor(128,128,128);
		Overlay.drawString(tempVal[0] + "%:", thumbWidth+38, vPos);
		standardLevels[j-1] = tempVal[0];
		//vPos += 20;

		if(tempVal[0] == 0){// zero estimate
			if(tempVal[1] == "not set"){
				setColor(255,255,255);		
				Overlay.drawString("estimate black point", thumbWidth+98, vPos);
				Overlay.drawRect(thumbWidth+77, vPos-17, 15, 15);
				imagesSelected = 0;
			} else {
				setColor(128,128,128);			
				Overlay.drawString("measured", thumbWidth+98, vPos);
				Overlay.drawRect(thumbWidth+77, vPos-17, 15, 15);
				Overlay.drawRect(thumbWidth+80, vPos-14, 9, 9);
			}
			buttonTypes[buttonCount] = "zero";
			zeroFlag = 1;
			zeroLoc = buttonCount;
		}else{
			if(tempVal[1] == "not set"){
				setColor(255,255,255);		
				Overlay.drawString("measure standard", thumbWidth+98, vPos);
				Overlay.drawRect(thumbWidth+77, vPos-17, 15, 15);
				imagesSelected = 0;
			} else {
				setColor(128,128,128);			
				Overlay.drawString("measured", thumbWidth+98, vPos);
				Overlay.drawRect(thumbWidth+77, vPos-17, 15, 15);
				Overlay.drawRect(thumbWidth+80, vPos-14, 9, 9);
			}
			buttonTypes[buttonCount] = "grey";
		}

		settingValues[buttonCount] = tempVal[1];
		buttonXs[buttonCount] = thumbWidth+77;
		buttonYs[buttonCount] = vPos-11;
		buttonWs[buttonCount] = 15;
		buttonHs[buttonCount] = 15;

		buttonCount ++;
		vPos += 20;
	}
}

if(imagesSelected == 1)
	setColor(255,255,255);
else
	setColor(128,128,128);

Overlay.drawString("Create MSPEC", thumbWidth-98, scaledHeight + 65);
Overlay.drawRect(thumbWidth-104, scaledHeight + 44, 109, 24);

if(imagesSelected == 1){
	buttonXs[nButtons] = thumbWidth-104;
	buttonYs[nButtons] = scaledHeight + 44;
	buttonWs[nButtons] = 109;
	buttonHs[nButtons] = 24;
	buttonTypes[nButtons] = "create";
}

setColor(255,255,255);
Overlay.drawString("Reset", thumbWidth-158, scaledHeight + 65);
Overlay.drawRect(thumbWidth-164, scaledHeight + 44, 52, 24);
buttonXs[nButtons+1] = thumbWidth-164;
buttonYs[nButtons+1] = scaledHeight + 44;
buttonWs[nButtons+1] = 52;
buttonHs[nButtons+1] = 24;
buttonTypes[nButtons+1] = "reset";

Overlay.show;
//Array.show(buttonXs, buttonYs);
//Array.show(settingValues);

//MOUSE SELECTION

if (getVersion>="1.37r")
	setOption("DisablePopupMenu", true);

	leftButton=16;
	clicked=0;
	tool2=0;
	selectedTool = IJ.getToolName();
	prevButton = -1;

 	getCursorLoc(x, y, z, flags); // this check seems to stop the macro looping create mspec after creating one
	prevX = x;
	prevY = y;

      while (clicked==0) {
 	getCursorLoc(x, y, z, flags);
	if(isActive(photoScreeningID)==1 && prevX != x && prevY != y){

	activeButton = -1;
 	getCursorLoc(x, y, z, flags);

		// switch mouse pointer while over the buttons:
		tool = 0;
		for(i=0; i<nButtons+2; i++)
		if (x>buttonXs[i] &&  y>buttonYs[i]-15 && x<buttonXs[i]+buttonWs[i] && y<buttonYs[i]+buttonHs[i])
			tool=1;

		if(tool != tool2)
			if(tool == 0){
				setTool(selectedTool);
				prevButton = -1;
			}
			if(tool == 1)
				setTool("hand");
		tool2=tool;


	//if mouse clicked:
	if (flags&leftButton!=0){

		for(i=0; i<nButtons+2; i++)
		if (x>buttonXs[i] &&  y>buttonYs[i]-15 && x<buttonXs[i]+buttonWs[i] && y<buttonYs[i]+buttonHs[i])
			activeButton = i;

		if(activeButton != prevButton){
			//print(activeButton);

			if(buttonTypes[activeButton] == "grey"){ // measure grey

				if(selectionType()==-1)
					waitForUser("No selection","Select the grey standard");
				else {
				getSelectionBounds(xBounds, yBounds, wBounds, hBounds);




				if(xBounds < 5 || yBounds < 35 || xBounds + wBounds > thumbWidth +5 || yBounds + hBounds > scaledHeight + 35)
					waitForUser("Selection error", "Selection out of bounds");
				else{
				rSum = 0;
				gSum = 0;
				bSum = 0;
				pxN = 0;
				overFlag = 0;
				
				for(y2= yBounds; y2<yBounds+hBounds; y2++)
				for(x2= xBounds; x2<xBounds+wBounds; x2++)
				if(selectionContains(x2, y2) == 1){
					v = getPixel(x2,y2);
					red = (v>>16)&0xff;
					green = (v>>8)&0xff;
					blue = v&0xff;
					if(red == 255 || green == 255 || blue == 255)
						overFlag = 1;
					
					rSum = rSum + (red * red);
					gSum = gSum + (green * green);
					bSum = bSum +(blue * blue);
					pxN ++;
				}

				if(overFlag == 1)
					waitForUser("Over Exposed", "This standard cannot be used as it is over exposed");
				else {
					settingValues[activeButton] = d2s(rSum/pxN,2) + " " + d2s(gSum/pxN,2) + " " + d2s(bSum/pxN,2);
					//print("Red: "+(rSum/pxN)+" Green: " +(gSum/pxN) + " Blue: " + (bSum/pxN));


					dataString = fileDir + "," + settingsChoice + "," + thumbWidth + "," + scaledHeight + "\n";

					writeCount = 0;
					for(i=0; i<filterNames.length; i++){

						dataString = dataString + filterNames[i] + ":" + settingValues[writeCount];
						writeCount ++;
		
						for(j=0; j<standardLevels.length; j++){
							dataString = dataString + "," + standardLevels[j]   + ":" + settingValues[writeCount];
							writeCount ++;
						}

						if(i<filterNames.length -1)
							dataString = dataString + "\n";
					}

					setMetadata("Info", dataString);
					clicked = 1;
					//print(dataString);


				}// exposure test
				} // selection bounds check
				} // no selection sheck

			}//measure grey


			if(buttonTypes[activeButton] == "zero"){ // estiamte black point
					//makeRectangle(3,35, thumbWidth +5, scaledHeight + 35);
					
					rMin = 255;
					gMin = 255;
					bMin = 255;

					for(y2= 35; y2<scaledHeight + 35; y2++)
					for(x2= 5; x2<thumbWidth +5; x2++){
						v = getPixel(x2,y2);
						red = (v>>16)&0xff;
						green = (v>>8)&0xff;
						blue = v&0xff;

						if(red != 0 && green != 0 && blue != 0){ // don't measure over-exposed black pixels
							if(red < rMin)
								rMin = red;
							if(green < gMin)
								gMin = green;
							if(blue < bMin)
								bMin = blue;
						}
					}
					


					settingValues[activeButton] = d2s(rMin,2) + " " + d2s(gMin,2) + " " + d2s(bMin,2);

					dataString = fileDir + "," + settingsChoice + "," + thumbWidth + "," + scaledHeight + "\n";

					writeCount = 0;
					for(i=0; i<filterNames.length; i++){

						dataString = dataString + filterNames[i] + ":" + settingValues[writeCount];
						writeCount ++;
		
						for(j=0; j<standardLevels.length; j++){
							dataString = dataString + "," + standardLevels[j]   + ":" + settingValues[writeCount];
							writeCount ++;
						}

						if(i<filterNames.length -1)
							dataString = dataString + "\n";
					}

					setMetadata("Info", dataString);
					clicked = 1;

			}// estimate black point


			if(buttonTypes[activeButton] == "filter"){ // set image

				if(zeroFlag == 1){

					rMin = 255;
					gMin = 255;
					bMin = 255;

					for(y2= 35; y2<scaledHeight + 35; y2++)
					for(x2= 5; x2<thumbWidth +5; x2++){
						v = getPixel(x2,y2);
						red = (v>>16)&0xff;
						green = (v>>8)&0xff;
						blue = v&0xff;

						if(red != 0 && green != 0 && blue != 0){ // don't measure over-exposed black pixels
							if(red < rMin)
								rMin = red;
							if(green < gMin)
								gMin = green;
							if(blue < bMin)
								bMin = blue;
						}
					}
					


					settingValues[activeButton+1] = d2s(rMin,2) + " " + d2s(gMin,2) + " " + d2s(bMin,2);

					//dataString = fileDir + "," + settingsChoice + "," + thumbWidth + "," + scaledHeight + "\n";

					//writeCount = 0;
					//for(i=0; i<filterNames.length; i++){

					//	dataString = dataString + filterNames[i] + ":" + settingValues[writeCount];
					//	writeCount ++;
		
					//	for(j=0; j<standardLevels.length; j++){
					//		dataString = dataString + "," + standardLevels[j]   + ":" + settingValues[writeCount];
					//		writeCount ++;
					//	}

					//	if(i<filterNames.length -1)
					//		dataString = dataString + "\n";
					//}

					//setMetadata("Info", dataString);

				}//estimate black point

				settingValues[activeButton] = getInfo("slice.label");
				settingValues[activeButton] = replace(settingValues[activeButton], ":", "");

				dataString = fileDir + "," + settingsChoice + "," + thumbWidth + "," + scaledHeight + "\n";

					writeCount = 0;
					for(i=0; i<filterNames.length; i++){

						dataString = dataString + filterNames[i] + ":" + settingValues[writeCount];
						writeCount ++;
		
						for(j=0; j<standardLevels.length; j++){
							dataString = dataString + "," + standardLevels[j]   + ":" + settingValues[writeCount];
							writeCount ++;
						}

						if(i<filterNames.length -1)
							dataString = dataString + "\n";
					}

					setMetadata("Info", dataString);
					clicked = 1;
			}

			if(buttonTypes[activeButton] == "reset"){ // reset
				for(i=0; i<settingValues.length; i++)
					settingValues[i] = "not set";

				dataString = fileDir + "," + settingsChoice + "," + thumbWidth + "," + scaledHeight + "\n";

					writeCount = 0;
					for(i=0; i<filterNames.length; i++){

						dataString = dataString + filterNames[i] + ":" + settingValues[writeCount];
						writeCount ++;
		
						for(j=0; j<standardLevels.length; j++){
							dataString = dataString + "," + standardLevels[j]   + ":" + settingValues[writeCount];
							writeCount ++;
						}

						if(i<filterNames.length -1)
							dataString = dataString + "\n";
					}

					setMetadata("Info", dataString);
					clicked = 1;
				
			}

			if(buttonTypes[activeButton] == "create"){ // create mspec
				run("Generate MSPEC from Screening");
				clicked = 1;
			}


		} // button pressed

		prevButton = activeButton;

	}
	}// if photo screening is active
          wait(20);
      }
      if (getVersion>="1.37r")
          setOption("DisablePopupMenu", false);

setTool(selectedTool);
run("Photo Screening Buttons"); // restart

//run("Rounded Rect Tool...", "stroke=1 corner=2 color=blue fill=none");
//run("Rounded Rect Tool...", "stroke=1 corner=1 color=blue fill=none");




