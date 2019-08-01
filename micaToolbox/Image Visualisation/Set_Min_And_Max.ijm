Dialog.create("Set min and max");

Dialog.addNumber("Min", 0);
Dialog.addNumber("Max", 255);
Dialog.show();


min = Dialog.getNumber();
max = Dialog.getNumber();



for(i=0; i<nSlices; i++){
	setSlice(i+1);
	setMinAndMax(min,max);
}
