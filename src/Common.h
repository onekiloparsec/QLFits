//
//  CommonCanvas.h
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
#import <Foundation/Foundation.h>

void *prepareCanvasForSpectrum(NSString *objectNameString, int pad, int width, int height, BOOL forThumbnail);
void *drawSpectrumXAxis(float wstart, float wstop, int nx, int pad);
void *drawSpectrumYAxis(float datamin, float datamax, int ny, int pad);
void *drawDemoLabel(int width, int height);
void *drawObjectLabel(NSString *objectNameString, int nx, int ny, float aSize, float blueColor);

NSData *getFitsHeaderAsHTML(CFBundleRef myBundle, 
							CFURLRef url, 
							NSString *nimages, 
							NSString *height, 
							NSString *headerFontSize,
							NSString *showQuickSummary, 
							NSString *showESOLinks, 
							NSString *appearanceStyleName, 
							int *status);
