__________MULTISPECTRAL IMAGE CALIBRATION AND ANALYSIS TOOLBOX________________

This toolbox was written by Jolyon Troscianko 2013-2019, funded by BBSRC grants
to Martin Stevens and NERC fellowship to Jolyon Troscianko.

We release our code with a Creative Commons (BY) license. Licensees may copy,
distribute, display and perform the work and make derivative works based on it 
only if they give credit by citing the relevatn papers:

Troscianko, J. & Stevens, M. (2015), Methods in Ecology & Evolution.


DCRAW is written by David Coffin, and we include a version of DCRAW with the
toolbox in line with the license for DCRAW.

IJ-dcraw is a plugin for ImageJ written by Jarek Sacha, who kindly allowed us
to distribute his plugin with this toolbox.

Further credit should be given to the sources of the spectrum database:
Arnold, S.E., Faruq, S., Savolainen, V., McOwan, P.W., and Chittka, L. (2010).
FReD: the floral reflectance database—a web portal for analyses of flower colour.
PloS One 5, e14287.

And spectral sensitivity curves for various species.


Introduction:
~~~~~~~~~~~~~~~~

Digital cameras can be powerful tools for measuring colours and patterns in a
huge range of disciplines. However, in normal 'uncalibrated' digital photographs 
the pixel values do not scale linearly with the amount of light measured by the 
sensor. This means that pixel values cannot be reliably compared between
different photos or even regions within the same photo unless the images are 
calibrated to be linear and have any lighting changes controlled for. Some 
scientists are aware of these issues, but lack convenient, user-friendly software 
to work with calibrated images, while many others continue to measure uncalibrated 
images. We have developed a toolbox that can calibrate images using many common 
consumer digital cameras, and for some cameras the images can be converted to 
“animal vision”, to measure how the scene might look to non-humans. Many animals 
can see down into the ultraviolet (UV) spectrum, such as most insects, birds, 
reptiles, amphibians, some fish and some mammals, so it is important to measure 
UV when working with these animals. Our toolbox can combine photographs taken 
through multiple colour filters, for example allowing you to combine normal 
photographs with UV photographs and convert to animal vision across their whole 
range of sensitivities.

Installation:
~~~~~~~~~~~~~~~~

-This toolbox requires a working installation of ImageJ.
-Place these files in your imagej/plugins folder.
-See the user guide for more information.

_________________MULTISPECTRAL IMAGING TOOLBOX CHANGE-LOG____________________

______________________________________________________________________________
--------------------------------15/3/2019 -----------------------------------
Update to version 2.

This is a massive upgrade, with completely overhauled functions and the entire
QCPA analysis added.

See www.empiricalimaging.com for detailed information on this release (there's
too much to list here).

______________________________________________________________________________
--------------------------------26/9/2018 -----------------------------------
Big Update:

Addition of "AcuityView" for ImageJ
Addition of user-friendly GabRat edge disruption measurement tools
User-firedly basic pixel measurement tools improved (using "R" and "M" keys 
after loading or generating an mspec image).
Non-linear and linear image support improvements. e.g. you can now specify that
the input image is already linear, or is an sRGB image. Be very wary of assuming
any image is truly sRGB though - in my experience almost no images conform to the
CIE's sRGB recommendaiton because camera dynamic ranges have improved since this
standard was created. If in doubt, try to make a custom linearisation model.
Bug fixes (due to changes in ImageJ v1.52)
Additional cameras and visual systems added
Due to the confusion caused by previous 16-bit pixel values, normalised images
are now on a reflectance scale (0-100%, though numbers outside this range are
supported as long as the sensor is not saturated), and cone-catch values are
now on a 0-1 scale. Old MSPEC images can be loaded and measured as usual, however
you will need to create new cone-mapping functions which work on the new scale!

______________________________________________________________________________
--------------------------------14/11/2016 -----------------------------------
Big update:

Support for non-linear images
The cone mapping model generation now uses the JAMA library to make the models
so no dependence on R.

______________________________________________________________________________
--------------------------------11/2/2015 -----------------------------------
Colour JND difference calculator added to go with pattern & lum measurements.
Lots of little bug fixes and neatenning of dialog boxes

--------------------------------5/1/2015 -----------------------------------
Bug fixed where importing slice labes had a limit of 4 grey standards.

--------------------------------19/12/2014 -----------------------------------

Patter & luminance distribution difference calculator fixed to work with new
output that produces multiple tables.

______________________________________________________________________________
--------------------------------4/12/2014 -----------------------------------

Added manual alignment option for when auto-align doesn't work reliably.
This was most common when images didn't have much detail for the alignment
to work with. In future it might be good to add manual scaling to this
function.

The options window for generating multispec images was too big for some
screens, so I've simplified it.

I've reduced the number of output options so that they're all 32-bit (people
shouldn't work with anything else), and alignment checking has been added.

The pseudo-uv output and visible output should make reviewing images and
selecting ROIs on dark images easier.

Image-changed flag rest on each multispectral image load, so the save image
dialog won't come up.

Bug fix in renaming RAW files.
______________________________________________________________________________
--------------------------------28/11/2014 -----------------------------------

Batch image analysis output changed from all being squeezed onto the same
big results table (with lots of zeros in the spaces), to separate results
tables for summary data, pattern spectra and luminance distributions. I still
need to add tools to analyse these results easily in one...
______________________________________________________________________________
