

function shift(offsets){

	setBatchMode(true);
	selectImage("ManualAlign");
	setSlice(2);
	makeRectangle(offsets[0], offsets[1], offsets[3], offsets[4]);

	run("Paste");
	setBatchMode(false);

	print(alignResultsTable, "\\Clear");
	print(alignResultsTable, "\\Update:" + -1*offsets[0]+"\t" + -1*offsets[1] +"\t" + offsets[2]);

}//shift function


function scale(offsets){

	setBatchMode(true);
	selectImage("align2");
	run("Scale...", "x=" + offsets[2] +" y=" + offsets[2] +" interpolation=Bilinear create title=scaled.tif");
	offsets[3] = getWidth();
	offsets[4] = getHeight();
	run("Select All");
	run("Copy");
	close();


	selectImage("ManualAlign");
	setSlice(2);
	makeRectangle(offsets[0], offsets[1], offsets[3], offsets[4]);

	run("Paste");
	setBatchMode(false);

	print(alignResultsTable, "\\Clear");
	print(alignResultsTable, "\\Update:" + -1*offsets[0]+"\t" + -1*offsets[1] +"\t" + offsets[2]);
	return(offsets);

}//shift function

//→↓←↑
// PASTE

//run("Select None");
//makeRectangle(0,0,getWidth(), getHeight());
//makeRectangle(3, 6, 1344, 1800);
//run("Paste");

//pasteScript = "imp = IJ.getImage()\; \n IJ.run(imp, \"Select All\", \"\")\;\n IJ.run(imp, \"Paste\", \"\")\;";
//print(pasteScript);
//eval("script", pasteScript);

// SET UP TABLE:

	alignResultsTable = "[Alignment Results]";
	run("New... ", "name="+alignResultsTable+" type=Table");

	// show log window:
	logScript =
		"lw = WindowManager.getFrame('Alignment Results');\n"+
		"if (lw!=null) {\n"+
		"   lw.setLocation("+ (screenWidth - 390) +",20);\n"+
		"   lw.setSize(380, 200)\n"+
		"}\n";
	eval("script", logScript); 

	print(alignResultsTable, "\\Headings:x offset\ty offset\tscale");
	print(alignResultsTable, "0" +"\t" + "0" +"\t" + "1");

// SET UP IMAGES

	setBatchMode(true);

	selectImage("align1");
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	run("Select All");

	run("Copy");
	run("Internal Clipboard");
	rename("ManualAlign");
	run("Add Slice");
	run("Make Composite", "display=Composite");
	setSlice(1);
	run("Yellow");
	run("Enhance Contrast", "saturated=0.05");
	

	selectImage("align2");
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	run("Select All");

	run("Copy");
//	run("Internal Clipboard");
//	rename("align2Scaled");

	selectImage("ManualAlign");
	setSlice(2);
	run("Paste");
	run("Blue");
	run("Enhance Contrast", "saturated=0.05");
	//setPasteMode("Copy");



	selectImage("ManualAlign");

	setBatchMode(false);
	run("Paste");


// BUTTONS:

selectImage("ManualAlign");
Overlay.remove;
w=getWidth();
h=getHeight();

smallSide = w;
if(h<w)
	smallSide = h;

buttonScaler = smallSide/250;


acceptW = 35 * buttonScaler;
acceptH=20 *buttonScaler; //(this will be doubled)
acceptX = (w/2) - (acceptW/2);
acceptY=h-acceptH;

s1W = 10*buttonScaler;
s1H = 8*buttonScaler;
s1X = 22*buttonScaler;
s1Y = 6*buttonScaler;

l1W = 10*buttonScaler;
l1H = 8*buttonScaler;
l1X = 5*buttonScaler;
l1Y = 6*buttonScaler;




setColor(0,0,0);
setLineWidth(acceptH);
Overlay.drawLine(acceptX,acceptY,acceptX+acceptW,acceptY);
Overlay.show;

setLineWidth(s1H);
Overlay.drawLine(s1X, s1Y, s1X+s1Y, s1Y);
Overlay.drawLine(l1X, l1Y, l1X+l1Y, l1Y);
Overlay.show;

setColor(200,200,200);
setFont("SansSerif", round(10*buttonScaler));
Overlay.drawString("Accept", acceptX, acceptY + round(5*buttonScaler));
Overlay.drawString("-", s1X, s1Y + round(3*buttonScaler));
Overlay.drawString("+", l1X, l1Y + round(3*buttonScaler));
Overlay.show;

      if (getVersion>="1.37r")
          setOption("DisablePopupMenu", true);

	leftButton=16;
	clicked=0;
	tool2=0;
	mouseDown = 0;
	setTool("point");
	offsets=newArray(0,0,1, getWidth(), getHeight());


      while (clicked==0) {
 	getCursorLoc(x, y, z, flags);


		// switch mouse pointer while over the buttons:
		if (x>acceptX &&  y>acceptY-acceptH && x<acceptX+acceptW && y<acceptY+acceptH)
			tool=1;
			//setTool("hand");
		else if (x>s1X &&  y>s1Y-s1H && x<s1X+s1W && y<s1Y+s1H)
			tool=1;
		else if (x>l1X &&  y>l1Y-l1H && x<l1X+l1W && y<l1Y+l1H)
			tool=1;
		else
			tool=0;

		if(tool != tool2)
			if(tool == 0)
				setTool("point");
			if(tool == 1)
				setTool("hand");
		tool2=tool;


	// if button is clicked:
	if (flags&leftButton!=0){
		

		if (x>acceptX &&  y>acceptY-acceptH && x<acceptX+acceptW && y<acceptY+acceptH)
			clicked=1; // accept button clicked
		else if (x>s1X &&  y>s1Y-s1H && x<s1X+s1W && y<s1Y+s1H){
			offsets[2] = offsets[2]-0.002;
			scale(offsets);
		}else if (x>l1X &&  y>l1Y-l1H && x<l1X+l1W && y<l1Y+l1H){
			offsets[2] = offsets[2]+0.002;
			scale(offsets);
		}
		else if(mouseDown==0){
			 //shift();
			mouseDown = 1;
			xStart = x;
			yStart = y;
		}

	}

	if(flags&leftButton==0 && mouseDown ==1){
		mouseDown = 0;
		xStop = x;
		yStop = y;
		offsets[0] = offsets[0] + (xStop-xStart);
		offsets[1] = offsets[1] + (yStop-yStart);
		//offsets[0] = offsets[0] + (xStart-xStop);
		//offsets[1] = offsets[1] + (yStart-yStop);
		shift(offsets);
	}
          wait(10);
      }

setTool("multipoint");
setTool("rectangle");


Overlay.remove;

