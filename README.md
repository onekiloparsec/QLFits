QLFits 3
========

_Note: QLFits2 was broken on OX 10.9 Mavericks! This is the new QLFits3._

QLFits is a OSX Quicklook plugin for FITS (Flexible Image transport System) files (used by astronomers worldwide to store and share their data.)

QLFits 3 is an entirely new implementation of QLFits, using the open-source project [ObjCFITSIO](https://github.com/onekiloparsec/ObjCFITSIO)

*[Download the latest binary.](http://onekilopars.ec/softwares/QLFits3.qlgenerator.tar.gz)*

Put it in _/Library/QuickLook_ or _~/Library/QuickLook_ and run the command, to reset the quicklook daemon (it is safe and instantaneous):

    /bin/sh qlmanage -r

Enjoy seeing the content of your FITS files in the Finder:

<img src="Resources/QLFits3_Finder_Screenshot.png" width=700px>
<img src="Resources/QLFits3_QL_Window.png" width=700px>


Project Notes For Developers
----------------------------

It is released open source under the [GNU General Public Licence](http://en.wikipedia.org/wiki/GNU_General_Public_License).

The following command line is run at the end of the Xcode build phase to ensure the QuickLook daemon is restarted:

    /bin/sh qlmanage -r
    
Once done, you can enjoy seeing the content of your FITS files directly in the Finder!

Note that you can use [FITSImporter](https://github.com/onekiloparsec/FITSImporter), the OSX Spotlight plugin for FITS file as good companion.

* The plug-in code must be signed. The "Code Signing Identity" build setting is to the "Developer ID: *" automatic setting. If you don't have a Developer ID, get creative.

* There is a Copy Files build phase that puts the Debug build of Provisioning.qlgenerator in your ~/Library/QuickLook folder.

* QuickLook plug-ins sometimes don't like to install. Learn to use "qlmanage -r" to reset the daemon. Using "qlmanage -m plugins" will tell you if the plug-in has been recognized. Sometimes you have to login and out before the plug-in is recognized.


