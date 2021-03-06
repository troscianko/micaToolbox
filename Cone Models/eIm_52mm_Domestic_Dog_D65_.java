// Code automatically generated by 'Generate Cone Mapping Model' script by Jolyon Troscianko

//Model fits:
//lw 0.9969031444470172
//sw 0.996680692197188


// Generated: 2019/2/4   13:40:33


import ij.*;
import ij.plugin.filter.PlugInFilter;
import ij.process.*;

public class eIm_52mm_Domestic_Dog_D65_ implements PlugInFilter {

ImageStack stack;
	public int setup(String arg, ImagePlus imp) { 
	stack = imp.getStack(); 
	return DOES_32 + STACK_REQUIRED; 
	}
public void run(ImageProcessor ip) {

IJ.showStatus("Cone Mapping");
float[] visibleR;
float[] visibleG;
float[] visibleB;
float[] uvB;
float[] uvR;
int w = stack.getWidth();
int h = stack.getHeight();
int dimension = w*h;

float[] lw = new float[dimension];
float[] sw = new float[dimension];

visibleR = (float[]) stack.getPixels(1);
visibleG = (float[]) stack.getPixels(2);
visibleB = (float[]) stack.getPixels(3);
uvB = (float[]) stack.getPixels(4);
uvR = (float[]) stack.getPixels(5);

for (int i=0;i<dimension;i++) {
lw[i] = (float) (-0.006952739061219245 +(visibleR[i]*9.308821454125934E-4)+(visibleG[i]*0.008734034548514765)+(visibleB[i]*0.0010615546607767301)+(uvB[i]*-0.003608511813112302)+(uvR[i]*0.0035063898860363497)+(visibleR[i]*visibleG[i]*2.7565020642089665E-6)+(visibleR[i]*visibleB[i]*2.521946941475203E-5)+(visibleR[i]*uvB[i]*3.4899807105368134E-5)+(visibleR[i]*uvR[i]*-6.417371624967944E-5)+(visibleG[i]*visibleB[i]*-3.669495754608653E-5)+(visibleG[i]*uvB[i]*2.714125323806843E-6)+(visibleG[i]*uvR[i]*3.767978105889038E-5)+(visibleB[i]*uvB[i]*1.0701781853368332E-4)+(visibleB[i]*uvR[i]*-1.3967318135781452E-4)+(uvB[i]*uvR[i]*3.605289281692267E-5));
sw[i] = (float) (-0.006437752386359915 +(visibleR[i]*3.758141383459189E-4)+(visibleG[i]*-0.0034946844802759783)+(visibleB[i]*0.01067430649150692)+(uvB[i]*-0.0017790002564465363)+(uvR[i]*0.0049019010901509875)+(visibleR[i]*visibleG[i]*-8.584678648173102E-6)+(visibleR[i]*visibleB[i]*8.425454177132242E-5)+(visibleR[i]*uvB[i]*6.483316483002837E-6)+(visibleR[i]*uvR[i]*-8.550747906163326E-5)+(visibleG[i]*visibleB[i]*-5.673137616475426E-5)+(visibleG[i]*uvB[i]*-2.6824845528388385E-4)+(visibleG[i]*uvR[i]*3.731015356650513E-4)+(visibleB[i]*uvB[i]*4.4544041927447545E-4)+(visibleB[i]*uvR[i]*-5.658509339632206E-4)+(uvB[i]*uvR[i]*8.248885749369358E-5));
IJ.showProgress((float) i/dimension);
}

ImageStack outStack = new ImageStack(w, h);
outStack.addSlice("lw", lw);
outStack.addSlice("sw", sw);
new ImagePlus("Output", outStack).show();

}
}
