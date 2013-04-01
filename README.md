QLFits 2
========

QLFits is a OSX Quicklook plugin for FITS (Flexible Image transport System) files (used by astronomers worldwide to store and share their data.)

It has been originally developed by Cédric Foellmi (Soft Tenebras Lux). 

[Direct download](http://www.softtenebraslux.com/download.php?software=qlfits) (from the SoftTenebrasLux' website).

It is released open source under the [GNU General Public Licence](http://en.wikipedia.org/wiki/GNU_General_Public_License).

The following command line is run at the end of the Xcode build phase to ensure the QuickLook daemon is restarted:

    /bin/sh qlmanage -r
    
Once done, you can enjoy seeing the content of your FITS files directly in the Finder!

<img src="Resources/QLFits2.0_snap1.png" width=1047px>
<img src="Resources/QLFits2.0_snap2.png" width=616px>
<img src="Resources/QLFits2.0_snap3.png" width=616px>
<img src="Resources/QLFits2.2_snap4.png" width=748px>

Note that you can use [FITSImporter](https://github.com/SoftTenebrasLux/FITSImporter), the OSX Spotlight plugin for FITS file as good companion.