/*
_______________________________________________________________________

	Title: Load Multispectral Image
	Author: Jolyon Troscianko
	Date: 16/10/2014
.................................................................................................................

Description:
''''''''''''''''''''''''''''''''
This code loads multispectral images from their .mspec configuration files. Any ROIs
selected will also be loaded.

Instructions:
''''''''''''''''''''''''''''''''''''''''
Run the script and select a .mspec file (this needs to be in the same folder as the RAW
images it was created from).

_________________________________________________________________________
*/

configFilePath=File.openDialog("Select .mspec file"); // get file location
tempString = "select=["+ configFilePath+"]";

// LOAD PREVIOUSLY USED VALUES

settingsFilePath = getDirectory("plugins") + "micaToolbox/importSettings.txt";
if(File.exists(settingsFilePath) == 1){
	settingsString=File.openAsString(settingsFilePath);	// open txt data file
	defaultSettings=split(settingsString, "\n");
	outputChoice = defaultSettings[13];
} else outputChoice = "Aligned Normalised 32-bit";

outputOptions = newArray(
"Linear Normalised Reflectance Stack",
"Linear Stack",
"Linear Colour Image",
"Non-linear Colour Image",
"Non-linear Colour VIS-UV Image");

Dialog.create("Load Multispectral Image");
	Dialog.addChoice("Image output", outputOptions, outputChoice);
	Dialog.addMessage(" 'Linear Normalised Reflectance Stack': A stack of greyscale images, scaled to normalised reflectance. can be used for measuring\ndirectly, and for converting to cone-catch");
	Dialog.addMessage(" 'Linear Stack': Non-normalised greyscale stack, used it to investigate illuminance");
	Dialog.addMessage(" 'Linear Colour Image': A human-visible colour image with linear, normalised values (often looks dark, but can be measured)");
	Dialog.addMessage(" 'Non-linear Colour Image': A human-visible colour image with non-linear normalised values (less dark but not for measuring)");
	Dialog.addMessage(" 'Non-linear Colour VIS-UV Image': False colour visible/UV combination image with non-linear normalised values (not for measuring)");
	Dialog.addHelp("http://www.empiricalimaging.com/knowledge-base/creating-a-calibrated-image/");
Dialog.show();

imageOutput =  Dialog.getChoice();

if(imageOutput != outputChoice){
// SAVE PREVIOUSLY USED SETTINGS
dataFile = File.open(settingsFilePath);

	print(dataFile, defaultSettings[0]);
	print(dataFile, defaultSettings[1]);
	print(dataFile, defaultSettings[2]);
	print(dataFile, defaultSettings[3]);
	print(dataFile, defaultSettings[4]);
	print(dataFile, defaultSettings[5]);
	print(dataFile, defaultSettings[6]);
	print(dataFile, defaultSettings[7]);
	print(dataFile, defaultSettings[8]);
	print(dataFile, defaultSettings[9]);
	print(dataFile, defaultSettings[10]);
	print(dataFile, defaultSettings[11]);
	print(dataFile, defaultSettings[12]);
	print(dataFile, imageOutput);
	print(dataFile, defaultSettings[14]);
	print(dataFile, defaultSettings[15]);
	//print(dataFile, defaultSettings[16]);

File.close(dataFile);
}

setBatchMode(true);
run("Create Stack from Config File", tempString);

//run("Create Stack from Config File");
if(imageOutput == "Linear Stack")
	run("Normalise & Align Multispectral Stack", "curve=[Straight Line] align_only");
else
	run("Normalise & Align Multispectral Stack", "curve=[Straight Line]");



if(imageOutput == "Linear Stack")
	setMinAndMax(0, 65535);
else setMinAndMax(0, 100);

setSlice(1);

if(imageOutput == "Linear Colour Image"){

	if(nSlices>3){
		waitForUser("This image has more than 3 channels, only the first 3 will be shown as RGB");
		while(nSlices>3){
			setSlice(4);
			run("Delete Slice");
		}
	}

	setMinAndMax(0, 100);
	run("Make Composite", "display=Composite");
	setSlice(3);
	setMinAndMax(0, 100);
	setSlice(2);
	setMinAndMax(0, 100);
	setSlice(1);
	setMinAndMax(0, 100);
	setBatchMode(false);
}



if(imageOutput == "Non-linear Colour Image"){

	if(nSlices>3){
		waitForUser("This image has more than 3 channels, only the first 3 will be shown as RGB");
		while(nSlices>3){
			setSlice(4);
			run("Delete Slice");
		}
	}

	run("Square Root", "stack");
	setMinAndMax(0, 10);
	run("Make Composite", "display=Composite");
	setSlice(3);
	setMinAndMax(0, 10);
	setSlice(2);
	setMinAndMax(0, 10);
	setSlice(1);
	setMinAndMax(0, 10);
	setBatchMode(false);

	setColor(200, 0, 0);
	colourSwitch = colourSwitch * -1;
	setFont("SansSerif", getHeight()*0.04);


	setFont("SansSerif", getHeight()*0.02);
	setColor(200, 0, 0);
	Overlay.drawString("Non-linear image - do not measure pixel values", getWidth()*0.05, getHeight()*0.05);
	Overlay.show;

}

if(imageOutput == "Non-linear Colour VIS-UV Image"){

	if(nSlices<5){
		exit("Pseudo-UV shows the visible Green and Blue\nand UV Red channels as a composite. This image\ndoes not have enough channels");
		setBatchMode(false);
		setSlice(1);
	}

	while(nSlices>5){
		setSlice(6);
		run("Delete Slice");
	}

	setSlice(4);
	run("Delete Slice"); // delete uvB

	setSlice(1);
	run("Delete Slice"); // delete visR


	run("Square Root", "stack");
	setMinAndMax(0, 10);
	run("Make Composite", "display=Composite");
	setSlice(3);
	setMinAndMax(0, 10);
	setSlice(2);
	setMinAndMax(0, 10);
	setSlice(1);
	setMinAndMax(0, 10);

	setFont("SansSerif", getHeight()*0.02);
	setColor(200, 0, 0);
	Overlay.drawString("Non-linear image - do not measure pixel values", getWidth()*0.05, getHeight()*0.05);
	Overlay.show;


	transformInfo = "________________________________________\nThis is a false-colour image, shifting the\nchannels to show visible green, visible\nblue and uv red. Use this image to judge\nthe alignment and select ROIs, but don't\nmeasure it directly. Once you've selected\nROIs use the batch script"; 

	setBatchMode(false);
}


showStatus("Done");

run("Select None");
run("Save ROIs");
setOption("Changes", false);


setBatchMode(false);

// LOG THE LOCATION FOR ADDING ROIs

setMetadata("Info", configFilePath);
tempVal = roiManager("count"); // dummy line for opening ROI manager

print("\\Clear");

	print("__________Config File Location:__________");
	print(configFilePath);

	print("________________________________________");
	print("--------------Keyboard Shortcuts:-------------");
	print("A-F, G-L, N-Q, T-Z: create new classes of\nnumbered ROIs\n ");
	print("M: Measure mean values of current selection\n ");
	print("R: Measure mean & SD values of all ROIs\n ");
	print("S: Scale bar (draw a line along an object\nof known length. Use for automatic image\nscaling and pattern analysis)\n ");
	print("E: Egg/ellipsoid selection (use for selecting\neggs and measuring the volume/shape/\nsurface area of ellipsoids). Place a point at\nthe tip and base of the egg, and at least\nthree additional points down each side\n ");
	print("0: (zero) Save selections to .mspec image\n ");	

	print("________________________________________");
