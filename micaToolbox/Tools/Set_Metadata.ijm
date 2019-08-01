Dialog.create("Set Image Metadata");

	Dialog.addString("String:", "");

Dialog.show();

s = Dialog.getString();

setMetadata("Info", s);
