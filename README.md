 [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

QLFits 3
========

_Note: QLFits2 was broken on OX 10.9 Mavericks! This is the new QLFits3. It works for Mavericks (10.9) and up._

QLFits is a OSX Quicklook plugin for FITS (Flexible Image transport System) files (used by astronomers worldwide to store and share their data.)

QLFits 3 is an entirely new implementation of QLFits, using the open-source projects [ObjCFITSIO](https://github.com/onekiloparsec/ObjCFITSIO) and [AstroCocoaKit](https://github.com/onekiloparsec/AstroCocoaKit)

Enjoy seeing the content of your FITS files in the Finder:

<img src="Resources/QLFits3_Finder_Screenshot.png" width=700px>
<img src="Resources/QLFits3_QL_Window.png" width=700px>

It is released open source under the [GNU General Public Licence](http://en.wikipedia.org/wiki/GNU_General_Public_License).


Installation
------------

*[Download the latest binary.](http://onekilopars.ec/softwares/QLFits3.qlgenerator.tar.gz)*

Put the QLFits3.qlgenerator bundle in _/Library/QuickLook_ or _~/Library/QuickLook_ and run the (safe and instantenous) command: `/bin/sh qlmanage -r` to reset the quicklook daemon. Then, enjoy seeing the content of your FITS files in the Finder:

<img src="Resources/QLFits3_Finder_Screenshot.png" width=700px>
<img src="Resources/QLFits3_QL_Window.png" width=700px>


Contribute!
-----------

If you want to contibute, you need:
* A recent Mac
* A copy of [Xcode](https://itunes.apple.com/fr/app/xcode/id497799835?l=en&mt=12) (Xcode 6, as of now, March 2015, but Xcode 5 should also work)
* A working installation of [Carthage](https://github.com/Carthage/Carthage) (Install it with Homebrew: `brew install carthage`)
* Some knowledge of Objective-C and C... and FITS!

Then, 

1. simply fork this project on GitHub, 
2. Go to the project directory, and run `carthage update`
3. make your modifications (I can help), 
4. test (I can also help, if time permits, business as usual), 
5. and submit a pull request.


How to debug
------------

In Xcode, you should locate the `qlmanage` binary file, and include it as the "Executable" in the "Run" section of the "QLFits3" scheme. To do so:

* Edit the "QLFits3" scheme in Xcode, select the "Run section"
* Choose "Other..." in the drop down, a 'Open Dialog' will open.
* Type `open -a Finder /user/bin/qlmanage` in a Terminal.
* Drag & Drop the 'qlmanage' executable from the Finder anywhere in the Open Dialog.
* Click "Choose" and close the dialog.

Now one can "Run" the QLFits3 project from within Xcode. But we haven't yet told it what to do exactly at run. So go back to the QLFits3 scheme, and choose the 'Arguments' tab of the same "Run" section. In the section "Arguments Passed On Launch" add `-p <path/to/any/of/your/fits/file>`

Use `-t` to create thrumbnails instead of previews. You can put multiple entries here, but only the first selected one will be used once qlmanage runs.

<img src="Resources/QLFits3_XcodeScheme1.png" width=700px>
<img src="Resources/QLFits3_XcodeScheme2.png" width=700px>


Project Notes For Developers
----------------------------


The following command line is run at the end of the Xcode build phase to ensure the QuickLook daemon is restarted: `/bin/sh qlmanage -r`
    
Once done, you can enjoy seeing the content of your FITS files directly in the Finder!

Note that you can use [FITSImporter](https://github.com/onekiloparsec/FITSImporter), the OSX Spotlight plugin for FITS file as good companion.

* The plug-in code must be signed. The "Code Signing Identity" build setting is to the "Developer ID: *" automatic setting. If you don't have a Developer ID, get creative.

* There is a Copy Files build phase that puts the Debug build of Provisioning.qlgenerator in your ~/Library/QuickLook folder.

* QuickLook plug-ins sometimes don't like to install. Learn to use "qlmanage -r" to reset the daemon. Using "qlmanage -m plugins" will tell you if the plug-in has been recognized. Sometimes you have to login and out before the plug-in is recognized.


