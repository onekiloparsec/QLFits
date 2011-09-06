//
//  CocoaFITS.h
//  QLFits
//
//  Created by Cédric Foellmi on 13/07/09.
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
//
//
// HYPOTHESIS: 
// - PTYPE_FLOAT is OK. No need for PTYPE_DOUBLE.
// - Extensions with data are contiguous (#n, #n+1, #n+2... with n >= 0).
// - Properties are that of the last loaded extension (waiting for a CocoaFITSExtension object...).

#import <Cocoa/Cocoa.h>
#import "qfits.h"

@interface CocoaFITS : NSObject {
	qfitsloader		ql;
	NSString		*filename;
	int				numberOfExtensions;
	int				numberOfExtensionsWithData;
	int				numberOfFirstExtensionWithData;
	int				nx;
	int				ny;
	int				bitpix;	
	int				bscale;
	int				bzero;
	float			datamin;
	float			datamax;
	float			wstart;
	float			wstop;
}

- (id)initWithFilename:(NSString *)fitsFilename;
- (int)loadExtension:(int)extensionNumber;
- (void)findDataminDatamax;
- (BOOL)isAnImage;
- (unsigned char *)prepareDataForBitmapRepWithLinearScaling;
//- (unsigned char *) prepareDataForBitmapRepWithZScaling;
- (float *)prepareDataForSpectrumRep;
- (char *)headerValueForKeyword:(char *)keyword;
- (float)headerValueForKeywordAsFloat:(char *)keyword;
- (void)defineSpectrumWavelengthLimits;
- (float)dataValueAtIndex:(int)idx;

@property(assign) int numberOfExtensions, numberOfExtensionsWithData, numberOfFirstExtensionWithData;
@property(assign) int nx, ny, bitpix, bscale, bzero;
@property(assign) float datamin, datamax, wstart, wstop;

@end
