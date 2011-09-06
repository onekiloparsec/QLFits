//
//  GeneratePreviewForURL.m
//  QLFits
//
//  Created by Cédric Foellmi on 14/10/08.
//
/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <Cocoa/Cocoa.h>
#include <WebKit/WebKit.h>
#import "Common.h"
#import "CocoaFITS.h"
#import "Constants.h"

// -----------------------------------------------------------------------------
// GeneratePreviewForURL
// -----------------------------------------------------------------------------
OSStatus GeneratePreviewForURL(void *thisInterface, 
							   QLPreviewRequestRef preview, 
							   CFURLRef url, 
							   CFStringRef contentTypeUTI, 
							   CFDictionaryRef options)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	CocoaFITS *fits = [[CocoaFITS alloc] initWithFilename:[(NSURL *)url absoluteString]];
	char *objectName = [fits headerValueForKeyword:"OBJECT"];
	NSString *objectNameString = [[NSString stringWithFormat:@"%s", objectName] stringByReplacingOccurrencesOfString:@"'" withString:@""];
	// The above line is needed for the string being drawn correctly into the image. Do not nest inside NSAttributedString init.

	CFStringRef appID = CFSTR("com.softtenebraslux.qlfitsgenerator");
	CFStringRef prefSummary      = (CFStringRef)CFPreferencesCopyAppValue(CFSTR("showQuickSummary"), appID);	
	CFStringRef prefESOLinks     = (CFStringRef)CFPreferencesCopyAppValue(CFSTR("showESOLinks"), appID);	
	CFStringRef prefHeaderHeight = (CFStringRef)CFPreferencesCopyAppValue(CFSTR("defaultHeightForHeaderFrame"), appID);	
	CFStringRef prefHeaderFonts  = (CFStringRef)CFPreferencesCopyAppValue(CFSTR("headerFontSize"), appID);	
	CFStringRef prefStyle        = (CFStringRef)CFPreferencesCopyAppValue(CFSTR("appearanceStyleName"), appID);	
	CFStringRef prefColorMode    = (CFStringRef)CFPreferencesCopyAppValue(CFSTR("previewImageColorMode"), appID);	
	
	NSLog(@"[QLFits Prefs] Show quick summary = %@", (NSString *)prefSummary);
	NSLog(@"[QLFits Prefs] Show ESO Links = %@", (NSString *)prefESOLinks);
	NSLog(@"[QLFits Prefs] Header Height = %@", (NSString *)prefHeaderHeight);
	NSLog(@"[QLFits Prefs] Header Fonts Size = %@", (NSString *)prefHeaderFonts);
	NSLog(@"[QLFits Prefs] Appearance Style = %@", (NSString *)prefStyle);
	NSLog(@"[QLFits Prefs] Preview Image Color mode = %@", (NSString *)prefColorMode);
	NSLog(@"[QLFits Prefs] Requesting preview with HTML header and %i images/extensions.", fits.numberOfExtensionsWithData);			
	
	int ii, status;
	for (ii = 0; ii < fits.numberOfExtensionsWithData; ii++) {
		status = [fits loadExtension:fits.numberOfFirstExtensionWithData+ii];
		NSLog(@"[QLFits] Is extension correctly loaded (0=YES): %i", status);

		NSImage *fitsImage = nil;
		if ([fits isAnImage]) {
			NSLog(@"[QLFits] Creating image with size x=%i, y=%i", fits.nx, fits.ny);
			NSSize canvasSize = NSMakeSize(fits.nx, fits.ny);			
			fitsImage = [[NSImage alloc] initWithSize:canvasSize];
			[fitsImage lockFocus];
			
			NSLog(@"[QLFits] Processing image.");
			unsigned char *imageData = [fits prepareDataForBitmapRepWithLinearScaling];			
			unsigned char *imageDataPlane[1];
			imageDataPlane[0] = imageData;
			
			float labelBlueIntensity;
			NSBitmapImageRep *bitmapRep = [NSBitmapImageRep alloc];
			if (CFStringCompare(prefColorMode, CFSTR("negative"), 0) == 0) {
				NSLog(@"[QLFits] Image color mode is negative (black stars on white sky).");
				labelBlueIntensity = 0.5;
				[bitmapRep initWithBitmapDataPlanes:imageDataPlane 
										 pixelsWide:fits.nx 
										 pixelsHigh:fits.ny 
									  bitsPerSample:8 
									samplesPerPixel:1 
										   hasAlpha:NO 
										   isPlanar:YES 
									 colorSpaceName:NSCalibratedBlackColorSpace 
										bytesPerRow:fits.nx 
									   bitsPerPixel:0];
			} 
			else {
				NSLog(@"[QLFits] Image color mode is positive (white stars on black sky).");
				labelBlueIntensity = 0.9;
				[bitmapRep initWithBitmapDataPlanes:imageDataPlane 
										 pixelsWide:fits.nx 
										 pixelsHigh:fits.ny 
									  bitsPerSample:8 
									samplesPerPixel:1 
										   hasAlpha:NO 
										   isPlanar:YES 
									 colorSpaceName:NSCalibratedWhiteColorSpace 
										bytesPerRow:fits.nx 
									   bitsPerPixel:0];								
			}
			[bitmapRep draw]; 

			drawObjectLabel(objectNameString, fits.nx, fits.ny, floor(pow(fits.nx, 0.5)), labelBlueIntensity);
			[fitsImage unlockFocus];			
			free(imageData);
		
		} 
		else {
			int jj, pad = 100;
			int imgScale = 1;
			if (fits.nx > 2000.0f) { 
				imgScale = fits.nx/2000.0f; 
			}
			NSLog(@"[QLFits] Creating spectrum-image with size x=%i, y=%i (scaling factor %i)", 
                  fits.nx/imgScale+pad+50, fits.nx/imgScale+pad+50, imgScale);
	
			NSSize canvasSize = NSMakeSize(fits.nx/imgScale+pad+50.0f, fits.nx/imgScale+pad+50.0f);
			[fitsImage initWithSize:canvasSize];
			[fitsImage lockFocus];			
			NSLog(@"[QLFits] Processing spectrum.");

            int width  = (int)fits.nx/imgScale;
            int height = (int)fits.nx/imgScale;
            
			prepareCanvasForSpectrum(objectNameString, pad, width, height, NO);
			[fits defineSpectrumWavelengthLimits];
			drawSpectrumXAxis(fits.wstart, fits.wstop, width, pad);
			[fits findDataminDatamax];
			drawSpectrumYAxis(fits.datamin, fits.datamax, width, pad); // Yes, width.

			NSBezierPath *path = [NSBezierPath bezierPath];	
			NSPoint point = {pad, pad};
			[path setLineWidth:1.];
			for (jj = 0; jj < (int)fits.nx/imgScale; jj++) {
				point.x = pad+jj;
				point.y = pad+([fits dataValueAtIndex:(int)jj*imgScale] - fits.datamin)/(fits.datamax - fits.datamin) * fits.nx/imgScale; 
                
                if (point.y > height+pad)
                    point.y = height+pad;
                
				if (jj == 0)
					[path moveToPoint:point];
				else
					[path lineToPoint:point];
                
			}
			[path stroke];	
			[fitsImage unlockFocus];
		}
		NSString *extensionImageFilename = [NSString stringWithFormat:@"/tmp/QLFits_%@_ext%i.tiff", NSUserName(), ii+1];
		status = [[fitsImage TIFFRepresentation] writeToFile:extensionImageFilename atomically:YES];
		NSLog(@"[QLFits] Image %@ written as a TIFF with status (1=OK): %d.", extensionImageFilename, status);
	}
	
    CFBundleRef bundle = QLPreviewRequestGetGeneratorBundle(preview);	
	NSData *output = getFitsHeaderAsHTML(bundle, url, 
										 [NSString stringWithFormat:@"%i", fits.numberOfExtensionsWithData], 
										 (NSString *)prefHeaderHeight,
										 (NSString *)prefHeaderFonts, 
										 (NSString *)prefSummary, 
										 (NSString *)prefESOLinks, 
										 (NSString *)prefStyle, 
										 &status);
	
	NSMutableDictionary *props = [[NSMutableDictionary alloc] init];
	[props setObject:@"UTF-8" forKey:(NSString *)kQLPreviewPropertyTextEncodingNameKey];
	[props setObject:@"text/html" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];	
	[props setObject:[NSNumber numberWithInt:600] forKey:(NSString*)kQLPreviewPropertyWidthKey];
	[props setObject:[NSNumber numberWithInt:800] forKey:(NSString*)kQLPreviewPropertyHeightKey];
	NSLog(@"[QLFits] Preview ready. Go for QuickLook experience.");	
	QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)output, kUTTypeHTML, (CFDictionaryRef)props);
	
	[pool release];
	
	return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    NSLog(@"CancelingPreview...");
}
