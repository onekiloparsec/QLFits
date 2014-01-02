QLFits 2
========

_Note: QLFits is broken on OX 10.9 Mavericks! This is the QLFits2 branch conserved for historical purpose. Use the master branch to follow QLFits development._

QLFits is a OSX Quicklook plugin for FITS (Flexible Image transport System) files (used by astronomers worldwide to store and share their data.)

[Direct download](http://onekilopars.ec/softwares/QLFits2.3.0.pkg) (from the onekilopars.ec' website).

It is released open source under the [GNU General Public Licence](http://en.wikipedia.org/wiki/GNU_General_Public_License).

The following command line is run at the end of the Xcode build phase to ensure the QuickLook daemon is restarted:

    /bin/sh qlmanage -r
    
Once done, you can enjoy seeing the content of your FITS files directly in the Finder!

<a href="https://flattr.com/submit/auto?user_id=onekiloparsec&url=https%3A%2F%2Fgithub.com%2Fonekiloparsec%2FQLFits" target="_blank"><img src="http://api.flattr.com/button/flattr-badge-large.png" alt="Flattr this" title="Flattr this" border="0"></a> ([@onekiloparsec](https://twitter.com/onekiloparsec)). 

<img src="Resources/QLFits2.0_snap1.png" width=1047px>
<img src="Resources/QLFits2.0_snap2.png" width=616px>
<img src="Resources/QLFits2.0_snap3.png" width=616px>
<img src="Resources/QLFits2.2_snap4.png" width=748px>

Note that you can use [FITSImporter](https://github.com/onekiloparsec/FITSImporter), the OSX Spotlight plugin for FITS file as good companion.

