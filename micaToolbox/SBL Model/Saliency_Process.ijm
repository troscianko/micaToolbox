batch = 0;
nz = nSlices;
w = getWidth();
h = getHeight();

scales = newArray();
sfs = newArray();
angles = newArray();
scaleStart = 0;
scaleStop = 0;
sfVals = newArray(1);

scaleCount = 0;

model = "Gabor";

for(z=0; z < nz; z++){
	setSlice(z+1);
	ts = getInfo("slice.label");
	ts = replace(ts, "SF: ", "");// DoG output
	ts = replace(ts, "SF", ""); // Gabor output
	ts = replace(ts, "scale", "");
	ts = replace(ts, "angle", "");
	ts = split(ts, "_");
	sfs = Array.concat(sfs, parseFloat(ts[0]));
	if( ts.length > 1){
		scales = Array.concat(scales, parseFloat(ts[1]));
		angles = Array.concat(angles, parseFloat(ts[2]));
	} else {
		model = "DoG";
		scales[z] = scaleCount;
		scaleCount ++;
		angles[z] = 0;
	}


	if(z==0)
		sfVals[0] = sfs[0];
	else if(z>0)
		if(sfs[z] != sfs[z-1])
			sfVals = Array.concat(sfVals, sfs[z]);
}

Array.getStatistics(scales, scaleMin, scaleMax, scaleMean, scaleSD);




octaveSeparation = 2; // Number of octave above current to analyse saliency
sigma1 = 2.0;
sigma2 = 3.2;
scaleLow = sfVals[0];
if(sfVals.length > 1)
	scaleLow = sfVals[1];
if(sfVals.length > 2)
	scaleLow = sfVals[2];

scaleHigh = sfVals[sfVals.length-1];


Dialog.create("Saliency Settings");
	Dialog.addMessage("Select the spatial scales over which to apply saliency (cpd)");
	Dialog.addNumber("From (low SF):", scaleLow);
	Dialog.addNumber("To (high SF)", scaleHigh);
	Dialog.addMessage("The number of octaves lower SF than the selected to calculate saliency");
	Dialog.addNumber("Octave separation", octaveSeparation);
	Dialog.addNumber("Centre sigma:", sigma1);
	Dialog.addNumber("Surround sigma", sigma2);
	Dialog.addCheckbox("Max pooling", true);

Dialog.show();

scaleLow = Dialog.getNumber();
scaleHigh = Dialog.getNumber();
octaveSeparation = Dialog.getNumber();
sigma1 = Dialog.getNumber();
sigma2 = Dialog.getNumber();
maxPool = Dialog.getCheckbox();

for(z=0; z < nz; z++){
	if(sfs[z] >= scaleLow && scaleStart == 0){
		scaleStart = z+1;
		scaleOffset = scales[z]; // used below for working out the relative scale offset once the stack is cropped
	}
	if(sfs[z]  <= scaleHigh)
		scaleStop = z+1;
}

if(batch == 1)
	setBatchMode(true);


ts = "duplicate range=" + scaleStart + "-" + scaleStop;
run("Duplicate...", ts);
rename("saliency bandpass");
//run("Duplicate...", "duplicate");
//run("Abs", "stack");

oID = getImageID();
nz = nSlices;


for(z=0; z < nz; z++){
	selectImage(oID);
	setSlice(z+1);
	analysisOctave = scaleMax - scales[z] + octaveSeparation - scaleOffset; //
	ts = "sigma1=" +sigma1 + " sigma2=" + sigma2 + " specify_octave=" + analysisOctave + " label=[Gabor output]";
	run("DoG ROI bandpass smooth specificOctave variance", ts);
	run("Copy");
	close();
	selectImage(oID);
	run("Paste");

}

if(batch == 1)
	setBatchMode("show");

if(model == "Gabor" && maxPool == 1)
	run("Z Max Pool", "angles=4");
else run("Z Mean");

rename("Salience");


run("Fire");
if(batch == 1){
	setBatchMode("show");
	setBatchMode(false);
}


