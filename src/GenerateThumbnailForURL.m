//
//  GenerateThumbnailForURL.m
//  QLFits
//
//  Created by CŽdric Foellmi on 14/10/08.
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
#include <WebKit/WebKit.h>
#import "Common.h"
#import "CocoaFITS.h"
#import "Constants.h"

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, 
								 QLThumbnailRequestRef thumbnail, 
								 CFURLRef url, 
								 CFStringRef contentTypeUTI, 
								 CFDictionaryRef options, 
								 CGSize maxSize)
{
	float minSize = 50.0f;
    if (maxSize.width < minSize || maxSize.height < minSize) {
        return noErr;
	}

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
	NSString *targetCFS = [NSString stringWithString:[[(NSURL *)url absoluteURL] path]];
	NSLog(@"[QLFits] Fits file to be loaded %@", targetCFS);
	CocoaFITS *fits = [[CocoaFITS alloc] initWithFilename:targetCFS];
	NSLog(@"[QLFits] Fits has %i extensions and %i with data.", fits.numberOfExtensions, fits.numberOfExtensionsWithData);
	
	// NO DATA, HTML header only - a webView is created, from which an image is extracted and rendered into a context.
	if (fits.numberOfExtensionsWithData == 0) {
		NSRect renderRect = NSMakeRect(0.0, 0.0, 600.0, 800.0);
		float scale = maxSize.height/800.0;
		NSSize scaleSize = NSMakeSize(scale, scale);
		CGSize thumbSize = NSSizeToCGSize(NSMakeSize(maxSize.width, maxSize.height));	
		CFBundleRef bundle = QLThumbnailRequestGetGeneratorBundle(thumbnail);

		int status;
		NSData *data = getFitsHeaderAsHTML(bundle, url, @"0", @"1000", @"11", @"none", @"none", @"smoothness", &status);
		
		WebView* webView = [[WebView alloc] initWithFrame:renderRect];
		[webView scaleUnitSquareToSize:scaleSize];
		[[[webView mainFrame] frameView] setAllowsScrolling:NO];
		[[webView mainFrame] loadData:data MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:nil];
	
		while([webView isLoading]) { 
			CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true);
		}

		CGContextRef context = QLThumbnailRequestCreateContext(thumbnail, thumbSize, false, NULL);
		if(context != NULL) {
			NSGraphicsContext* nsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)context flipped:[webView isFlipped]];
			[webView displayRectIgnoringOpacity:[webView bounds] inContext:nsContext];
			QLThumbnailRequestFlushContext(thumbnail, context);
			CFRelease(context);
		}
	
	} 
	else {
		int status;
		status = [fits loadExtension:fits.numberOfFirstExtensionWithData];	
		NSLog(@"[QLFits] Is extenstion correctly loaded (0=YES): %i", status);

		char *objectName = [fits headerValueForKeyword:"OBJECT"];
		NSString *objectNameString = [[NSString stringWithFormat:@"%s", objectName] stringByReplacingOccurrencesOfString:@"'" withString:@""];
		// The above line is needed for the string being drawn correctly into the image. Do not nest inside NSAttributedString init.

		CFStringRef appID = CFSTR("com.softtenebraslux.qlfitsgenerator");
		CFStringRef prefColorMode    = (CFStringRef)CFPreferencesCopyAppValue(CFSTR("thumbnailImageColorMode"), appID);
		
		CGSize thumbSize = NSSizeToCGSize(NSMakeSize(maxSize.width, maxSize.height));
		CGContextRef cgContext = QLThumbnailRequestCreateContext(thumbnail, thumbSize, true, NULL);
		if(cgContext) {		
			
			if ([fits isAnImage]) {
				NSLog(@"[QLFits] Creating image with size x=%i, y=%i", fits.nx, fits.ny);	

				NSSize canvasSize = NSMakeSize(fits.nx, fits.ny);
				NSImage *fitsImage = [[NSImage alloc] initWithSize:canvasSize];
				[fitsImage lockFocus];
				
				NSLog(@"[QLFits] Processing image.");
				unsigned char *imageData = [fits prepareDataForBitmapRepWithLinearScaling];
				unsigned char *imageDataPlane[1];
				imageDataPlane[0] = imageData;
				
				float labelBlueIntensity;
				NSBitmapImageRep *bitmapRep = nil; ;
				if (CFStringCompare(prefColorMode, CFSTR("negative"), 0) == 0) {
					labelBlueIntensity = 0.5;
					bitmapRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:imageDataPlane 
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
					labelBlueIntensity = 0.9;
					bitmapRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:imageDataPlane 
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

				drawObjectLabel(objectNameString, fits.nx, fits.ny, 90., labelBlueIntensity);
				[fitsImage unlockFocus];

				NSLog(@"[QLFits] Drawing image into context.");			
				NSBitmapImageRep *bitmapRep2 = [[NSBitmapImageRep alloc] initWithData:[fitsImage TIFFRepresentation]];
				CGImageRef finalFitsImage = [bitmapRep2 CGImage];
				CGRect renderRect = CGRectMake(0., 0., maxSize.width*fits.nx/fits.ny, maxSize.height);			
				CGContextDrawImage(cgContext, renderRect, finalFitsImage);
				free(imageData);
				
			} 
			else {								
				int jj, pad = 50, imgScale = 1;			
				if (fits.nx > 2000.0f) { 
					imgScale = fits.nx/2000.0f; 
				}
				NSLog(@"[QLFits] Creating image with size x=%i, y=%i (scaling factor %i)", \
					  fits.nx/imgScale+pad+30, fits.nx/imgScale+pad+30, imgScale);
				
				NSSize canvasSize = NSMakeSize(fits.nx/imgScale+pad+20, fits.nx/imgScale+pad+10.f);
				NSImage *fitsImage = [[NSImage alloc] initWithSize:canvasSize];
				[fitsImage lockFocus];

				NSLog(@"[QLFits] Processing spectrum.");
				prepareCanvasForSpectrum(objectNameString, pad, (int)fits.nx/imgScale, (int)fits.nx/imgScale, YES);
				[fits findDataminDatamax];
				
				[[NSColor blackColor] set];
				NSBezierPath *path = [NSBezierPath bezierPath];	
				NSPoint point = NSMakePoint(pad, pad);
				[path setLineWidth:1.];
				for (jj = 0; jj < fits.nx/imgScale; jj++) {
					point.x = pad+jj;
					point.y = ([fits dataValueAtIndex:(int)jj*imgScale] - fits.datamin)/(fits.datamax - fits.datamin) * fits.nx/imgScale; 
					if (jj == 0) { 
						[path moveToPoint:point]; 
					} 
					else { 
						[path lineToPoint:point]; 
					}
				}
				[path stroke];
				
				[fitsImage unlockFocus];
				NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithData:[fitsImage TIFFRepresentation]];
				CGImageRef finalFitsImage = [bitmapRep CGImage];
				CGRect renderRect = CGRectMake(0., 0., maxSize.width, maxSize.height);
				CGContextDrawImage(cgContext, renderRect, finalFitsImage);
				
			} // - end of thumbnail generation for spectrum
			
			QLThumbnailRequestFlushContext(thumbnail, cgContext);
			CFRelease(cgContext);
			
		} // - end of thumbnail generation for the case where numberOfExtensionWithData > 0
		
	} 
	[pool release];
	
	return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
