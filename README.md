**This repo is not maintained anymore. Please, try [QuickFits](https://apps.apple.com/us/app/quickfits/id1551075981?mt=12)**

---

QLFits 3
========

**Install** with [Homebrew](http://brew.sh):

`brew cask install qlfits`


Description
-----------

QLFits is a macOS Quicklook plugin for FITS (Flexible Image Transport System) files, used by astronomers worldwide to store and share their data. It is for macOS 10.8 and up.

QLFits 3 is an entirely new implementation of QLFits, using the open-source projects [ObjCFITSIO](https://github.com/onekiloparsec/ObjCFITSIO) and [AstroCocoaKit](https://github.com/onekiloparsec/AstroCocoaKit) written by yours truly.

QLFits3 reads the following extensions: **fits, fit, fts, ft, mt, imfits, imfit, uvfits, uvfit, pha, rmf, arf, rsp, pi, lc, evt, att, orb**. If your FITS file is not recognized, let me know (cedric at onekiloparsec.dev), the dynamic macOS type of your file might not be included in the list. See below to see what dynamic types QLFits3 recognises.

QLFits3 show all HDU  headers, and draw (when possible) all 2D images and 1D spectra.

Et voilà! Enjoy seeing the content of your FITS files in the Finder:

<img src="Resources/QLFits3_Finder_Screenshot.png" width=700px>
<img src="Resources/QLFits3_QL_Window.png" width=700px>
<img src="Resources/QLFits3_QL_Window2.png" width=700px>
<img src="Resources/QLFits3_QL_Window3.png" width=700px>

It is released open source under the [GNU General Public Licence](http://en.wikipedia.org/wiki/GNU_General_Public_License).


Installation
------------

*[Download the latest binary](https://onekiloparsec.dev/wp-content/uploads/2020/04/QLFits3.qlgenerator.zip)*

Put the QLFits3.qlgenerator bundle either in `/Library/QuickLook` or in `~/Library/QuickLook` (but only if your are an a system older than macOS 10.10 Yosemite for the latter) and run the (safe and instantaneous) command: `qlmanage -r` to reset the quicklook daemon. 


Contribute!
-----------

If you want to contibute, you need:
* A recent Mac
* A copy of [Xcode](https://itunes.apple.com/fr/app/xcode/id497799835?l=en&mt=12) (Xcode 8, as of now, December 2016, but Xcode 7 should also work)
* Some knowledge of Objective-C and C... and FITS!

Then, 

1. Simply fork this project on GitHub,
2. run `carthage update` to grab the ObjectFITSIO framework. See [this page](https://github.com/Carthage/Carthage) if you don't know Carthage.
3. Open QLFits3.xcodeproj and make your modifications (I can help), 
4. Test – see Debug below (I can also help, if time permits, business as usual), 
5. Submit a pull request (via GitHub)!


How to debug (manually)
-----------------------

* Build your (modified) QLFits3. Now, a new version is being put in `~/Library/QuickLook`
* Navigate in the Finder to look for a FITS file, and press <space>.
* Or run the command `qlmanage -p[-t] <path/to/fits/file>` to test previews (vs thumbnails) from the Terminal. 

How to debug (advanced)
-----------------------

_Note: What follows is supposed to work, but a bug in macOS prevents it, and I never found a real workaround._ 
(The error message being the following: "*** CFMessagePort: bootstrap_register(): failed 1100 (0x44c) 'Permission denied', port = 0xaf03, name = 'com.apple.CFPasteboardClient'")

The idea is first to locate the `qlmanage` binary file, and include it as the "Executable" in the "Run" section of the "QLFits3" scheme. To do so:

* Edit the "QLFits3" scheme in Xcode, select the "Run" section, "Info" tab.
* Choose "Other..." in the drop "Executable" down menu, a 'Open Dialog' will open.
* Type `open -a Finder /user/bin/` in a Terminal and locate the `qlmanage` alias.
* Drag & Drop the `qlmanage` executable from the Finder anywhere in the Open Dialog.
* Click "Choose" and close the dialog.

Now one can "Run" the QLFits3 project from within Xcode. But we haven't yet told it what to do exactly at run. So go back to the QLFits3 scheme, and choose the 'Arguments' tab of the same "Run" section. In the section "Arguments Passed On Launch" add `-p <path/to/any/of/your/fits/file>`

Use `-t` to create thrumbnails instead of previews. You can put multiple entries here, but only the first selected one will be used once qlmanage runs.

<img src="Resources/QLFits3_XcodeScheme1.png" width=700px>
<img src="Resources/QLFits3_XcodeScheme2.png" width=700px>


Project Notes For Developers
----------------------------

Note that you can use [FITSImporter](https://github.com/onekiloparsec/FITSImporter), the macOS Spotlight plugin for FITS file as good companion.

* There is a Copy Files build phase that puts the Debug build of Provisioning.qlgenerator in your /Library/QuickLook folder.

* QuickLook plug-ins sometimes don't like to install. Learn to use "qlmanage -r" to reset the daemon. Using "qlmanage -m plugins" will tell you if the plug-in has been recognized. Sometimes you have to login and out before the plug-in is recognized.


macOS dynamic types
-----------------

For custom or special file extensions, macOS assign dynamic types. QLFits3 contains a list of such types to allow it to recognize them (in addition to the filename extensions). See Info.plist file inside QLFits3.qlgenerator in case of doubt. To check the dynamic type of your FITS file, open a Terminal and type the following command `mdls <path/to/your/file> | grep kMDItemContentType`. You shluld obtain something like `kMDItemContentType             = "dyn.ah62d4rv4ge80q4pysq"`. 

List of known extensions: 

* gov.nasa.gsfc.fits
* gov.nasa.gsfc.fits-header
* com.sao.SAOImageDS9
* dyn.ah62d4rv4ge80q4pysq
* dyn.ah62d4rv4ge80q4py
* dyn.ah62d4rv4ge80q7a
* dyn.ah62d4rv4ge8047a
* dyn.ah62d4rv4ge81a4db
* dyn.ah62d4rv4ge80c6xg
* dyn.ah62d4rv4ge81e5pg
* dyn.ah62d4rv4ge81e65u
* dyn.ah62d4rv4ge81a4k
* dyn.ah62d4rv4ge80w5pgrf4a
* dyn.ah62d4rv4ge81n7xgrf4a
* dyn.ah62d4rv4ge80w5pgrf4hg
* dyn.ah62d4rv4ge81n7xgrf4hg
* dyn.ah62d4rv4ge80262
* dyn.ah62d4rv4ge80222
* dyn.ah62d4rv4ge80n7xy
* dyn.ah62d4rv4ge80c7dy
* dyn.ah62d4rv4ge8086xc
* dyn.ah62d46dzqm0gw23ssz1gw8brqz6gn25zsvu0e5dfhk2x43xmsu
* dyn.ah62d46dzqm0gw23ssz1gw8brqz6gn25zsvu0e5dfhk2x43xmsv3u


Author
------

[Cédric Foellmi](https://github.com/onekiloparsec) ([@onekiloparsec](https://twitter.com/onekiloparsec))


LICENSE & NOTES
---------------

QLFits is licensed under the MIT license and hosted on GitHub at https://github.com/onekiloparsec/QLFits/ Fork the project and feel free to send pull requests with your changes!


