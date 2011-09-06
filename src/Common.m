//
//  CommonCanvas.m
//  QLFits
//
//  Created by Cédric Foellmi on 19/09/09.
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

#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

#import "Common.h"
#import "Constants.h"

NSData *getFitsHeaderAsHTML(CFBundleRef bundle, 
							CFURLRef url, 
							NSString *nimages, 
							NSString *height, 
							NSString *headerFontSize,
							NSString *showQuickSummary, 
							NSString *showESOLinks, 
							NSString *appearanceStyleName, 
							int *status) 
{
	NSString *cmd = [[NSBundle mainBundle] pathForResource:@"getFitsHeaderAsHTML.py" ofType:nil];    
	NSString *target = [[(NSURL *)url absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
	NSLog(@"[QLFits] Python processing of header and file organisation.");
    NSTask *task = [[NSTask alloc] init];
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *fileHandle = [pipe fileHandleForReading];

    [task setStandardOutput:pipe];
    [task setStandardError:pipe];
    [task setLaunchPath:@"/System/Library/Frameworks/Python.framework/Versions/Current/bin/python"];
    [task setArguments:[NSArray arrayWithObjects:
						cmd, 
						target, 
						nimages, 
						height, 
						headerFontSize, 
						showQuickSummary, 
						showESOLinks, 
						appearanceStyleName, 
						nil]];
    
    [task launch];
	
    NSData *data = [fileHandle readDataToEndOfFile];
    [task waitUntilExit];
	
    [fileHandle closeFile];	
	[task release];
    
    return data;
}


void *drawObjectLabel(NSString *objectNameString, int nx, int ny, float aSize, float blueColorValue) 
{
	NSColor *blueColor = [NSColor colorWithCalibratedRed:0.0f
												   green:0.0f 
													blue:blueColorValue 
												   alpha:1.0f];
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSFont fontWithName:@"Futura" size:aSize], 
								NSFontAttributeName, 
								blueColor, 
								NSForegroundColorAttributeName, nil];
	
	NSAttributedString *objectLabel = [[NSAttributedString alloc] initWithString:objectNameString attributes:attributes];	
	NSSize size = [objectLabel size];	
	[objectLabel drawAtPoint:NSMakePoint(nx/10.0f, ny-size.height-20.0f)];
	[objectLabel release];
	
	return noErr;
}

void *prepareCanvasForSpectrum(NSString *objectNameString, int pad, int width, int height, BOOL forThumbnail) 
{
	[[NSColor whiteColor] set];
	NSRect back = NSMakeRect(0, 0, width+pad+50, height+pad+50);
	NSRectFill(back);
	
	[[NSColor blackColor] set];
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:0.5];
	NSPoint point = NSMakePoint(pad, pad);
	[path moveToPoint:point];
	point.y += height;
	[path lineToPoint:point];					
	point.x += width;
	[path lineToPoint:point];					
	point.y -= height;
	[path lineToPoint:point];					
	point.x -= width;
	[path lineToPoint:point];					
	[path stroke];
	
	float aSize = floor(pow(width/2.0f, 0.5f));
	
	if (forThumbnail == NO) {
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSFont fontWithName:@"Helvetica" size:aSize], 
									NSFontAttributeName,
									[NSColor blackColor], 
									NSForegroundColorAttributeName, nil];						
				
		NSAttributedString *notice = [[NSAttributedString alloc] 
									   initWithString:@"Tick positions are only good indications." 
									   attributes:attributes];	
		
		[notice drawAtPoint:NSMakePoint(20, height+pad+10)];
		[notice release];
	}
	
	aSize = (forThumbnail) ? 90.0f : floor(pow(width, 0.5)); 
	
	NSDictionary *objectAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSFont fontWithName:@"Futura" size:aSize], 
									  NSFontAttributeName,
									  [NSColor colorWithCalibratedRed:0. green:0. blue:0.5 alpha:1.0], 
									  NSForegroundColorAttributeName, nil];
	
	NSAttributedString *objectLabel = [[NSAttributedString alloc] initWithString:objectNameString attributes:objectAttributes];	
	[objectLabel drawAtPoint:NSMakePoint(1.5*pad, height*0.9)];
	[objectLabel release];
	
	return noErr;	
}

void *drawSpectrumAxis(NSString *label, float start, float stop, int npix, int pad, BOOL isVertical) 
{	
	// Look for the level of ticks. It is the order-of-magnitude level
	// Typically, normalized spectra between 1 and 1000. 
	// For flux-calibrated, betweem 1e-20, 1e-3.
	double cutStart, cutStop, level;
	int jj;
	
	for (jj = 0; jj < 40; jj++) {
		if ((stop-start) < 2*pow(10., ((double)jj/2.0f-15.0f))) {
			level = pow(10.0f, floor(((double)jj/2.0f-15.0f)-1.0f));
			break;
		}
	}
	
	// start and stop are image boundaries.
	// cutStart and cutStop are values of the first and last tick values.
	cutStart = level*(ceil(start/level));
	cutStop  = level*(floor(stop/level));
	double shift  = (cutStart - start)/(stop - start) * npix;
	double scale  = (cutStop - cutStart)/(stop - start);
	double tickInterval = 0.0f;
	double n = floor(log10(cutStop - cutStart));
	
	// Get ticks interval length.
	for (jj = 0; jj < 40; jj++) {
		int interval = round((cutStop - cutStart)/(pow(10., ((double)jj/2.0f-15.0f)+n))) + 1.0f;
		if ((interval >= 5.0f) && (interval <= 15.0f)) {
			tickInterval = pow(10.0f, ceil(((double)jj/2.0f-15.0f)+n));
			break;
		}
	}
	
	int ntickIntervals = (cutStop-cutStart)/tickInterval;
	NSPoint pos = NSMakePoint(0.0f, 30.0f);
	NSBezierPath *path = [NSBezierPath bezierPath];	
	
	float aSize = floor(pow(npix/2.0f, 0.5f));
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSFont fontWithName:@"Helvetica" size:aSize], 
								NSFontAttributeName,
								[NSColor blackColor], 
								NSForegroundColorAttributeName, nil];						
	
//	if (DEBUG) { NSLog(@"[QLFits] Ticks: cutStart = %g, #ticks = %i, interval=%g", cutStart, ntickIntervals+1, tickInterval); }
	for (jj = 0; jj <= ntickIntervals; jj++) {
		double currentTick = cutStart + jj*tickInterval;
        NSString *stringLabel = nil;
		if (isVertical == true) {
			if (start <= 1e-5) {
				stringLabel = [NSString stringWithFormat:@"%.3g", currentTick];
            }
            else if (start >= 100) {
				stringLabel = [NSString stringWithFormat:@"%.0f", currentTick];
			} 
            else {
				stringLabel = [NSString stringWithFormat:@"%.2f", currentTick];
			}
			
            NSAttributedString *tickLabel = [[NSAttributedString alloc] initWithString:stringLabel attributes:attributes];
			NSSize size = [tickLabel size];
			pos.y = pad + shift + (currentTick - cutStart)/(cutStop - cutStart)*npix*scale;
			[path moveToPoint:NSMakePoint(pad, pos.y)];
			[path lineToPoint:NSMakePoint(pad+30, pos.y)];
			[tickLabel drawAtPoint:NSMakePoint(50 - size.width/2, pos.y - size.height/2)];
			[tickLabel release];
		} 
        else {
            NSString *stringLabel = [NSString stringWithFormat:@"%.1f", currentTick];
			NSAttributedString *tickLabel = [[NSAttributedString alloc] initWithString:stringLabel attributes:attributes];
			NSSize size = [tickLabel size];
			pos.x = pad + shift + (currentTick - cutStart)/(cutStop - cutStart)*npix*scale;
			[path moveToPoint:NSMakePoint(pos.x, pad)];
			[path lineToPoint:NSMakePoint(pos.x, pad+30)];
			[tickLabel drawAtPoint:NSMakePoint(pos.x - size.width/2, 50)];
			[tickLabel release];
		}
	}
	[path stroke];
	
	NSAttributedString *axisLabel = [[NSAttributedString alloc] initWithString:label attributes:attributes];
	NSSize size = [axisLabel size];
	if (isVertical == YES) {	
		pos.x = 10.0f;		
		pos.y = pad + npix/2.0f - size.height/2.0f;
	} 
	else {
		pos.x = pad + npix/2.0f - size.width/2.0f;
		pos.y = 10.0f;
	}
	[axisLabel drawAtPoint:pos];
	[axisLabel release];
	
	return noErr;
}


void *drawSpectrumXAxis(float wstart, float wstop, int nx, int pad) 
{
	drawSpectrumAxis(@"'Wavelength' (Angstroems, Nanometers, Microns or Pixels)", wstart, wstop, nx, pad, NO);
 	return noErr;
}

void *drawSpectrumYAxis(float datamin, float datamax, int ny, int pad) 
{
	drawSpectrumAxis(@"'Flux'", datamin, datamax, ny, pad, YES);
	return noErr;
}
