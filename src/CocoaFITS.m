//
//  CocoaFITS.m
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

#import "CocoaFITS.h"
#import "Constants.h"

/* Utility macros. */
#undef	max
#define	max(a,b)	(a > b ? a : b)
#undef	min
#define	min(a,b)	(a < b ? a : b)

@implementation CocoaFITS

@synthesize numberOfExtensions, numberOfExtensionsWithData, numberOfFirstExtensionWithData;
@synthesize nx, ny, bitpix, bscale, bzero, datamin, datamax;
@synthesize wstart, wstop;

- (id) initWithFilename:(NSString *)fitsFilename 
{
    self = [super init];
    if (self) {
		filename = [NSString stringWithString:fitsFilename];		
		NSLog(@"[QLFits] Init FITS object with filename %@.", filename);
		ql.filename = (char *) [filename cStringUsingEncoding:NSUTF8StringEncoding];
		ql.ptype = PTYPE_FLOAT;
		ql.pnum  = 0;			
		numberOfExtensions = qfits_query_n_ext(ql.filename) + 1;
		
		if (numberOfExtensions == 0) { 
			NSLog(@"[QLFits] Error in querying number of extensions."); 
		}
		else { 
			NSLog(@"[QLFits] Found #%i extensions.", numberOfExtensions); 
		}
		
		int ii, status;
		numberOfFirstExtensionWithData = -1;
		numberOfExtensionsWithData = 0;
		if (numberOfExtensions > 0) {
			for (ii = 0; ii < numberOfExtensions; ii++) {
				ql.xtnum = ii ;
				status = qfitsloader_init(&ql);
				if (status == 0) { 
					if (numberOfFirstExtensionWithData == -1) {numberOfFirstExtensionWithData = ii;}
					numberOfExtensionsWithData += 1; 
				} 
				else {
					NSLog(@"[QLFits] Error when attempting to load data extension #%i", ii);
				}
			}
			NSLog(@"[QLFits] FITS file has %i extensions and %i with usable/loadable data.", 
														numberOfExtensions, numberOfExtensionsWithData); 
		} 
    }
    return self;
}

- (void)dealloc
{
	[filename release];
	filename = nil;
    [super dealloc];
}

- (int)loadExtension:(int)extensionNumber 
{
	NSLog(@"[QLFits] Loading extension with data with extension number #%i.", extensionNumber);
	ql.filename = (char *) [filename cStringUsingEncoding:NSUTF8StringEncoding];
	ql.ptype = PTYPE_FLOAT;
	ql.pnum  = 0;	
	ql.xtnum = extensionNumber;
	int status;
	qfitsloader_init(&ql);
	nx = ql.lx;
	ny = ql.ly;
	bitpix = ql.bitpix;
	bscale = ql.bscale;
	bzero  = ql.bzero;
	NSLog(@"[QLFits] Ext. properties: nx %d, ny %d, bitpix %d, bscale %d, bzero %d", nx, ny, bitpix, bscale, bzero);
	status = qfits_loadpix(&ql);
	return status;
}

- (char *)headerValueForKeyword:(char *)keyword 
{
	char *result = qfits_query_hdr(ql.filename, keyword);
	if (result == NULL) { result = ""; }
	return result;
}

- (float)headerValueForKeywordAsFloat:(char *)keyword 
{
	char *value = [self headerValueForKeyword:keyword];
	if (strncmp(value, "", 0) == 0) { 
		value = "0"; 
	}
	return atof(value);
}

- (void)findDataminDatamax 
{
	int ii;
	double avg = 0;	
	datamin = 1e30;
	datamax	= -1e30;
	for (ii = 0; ii < ql.lx*ql.ly; ii++) {
		if (ql.fbuf[ii] < datamin) {datamin = ql.fbuf[ii];}
		if (ql.fbuf[ii] > datamax) {datamax = ql.fbuf[ii];}
		avg += ql.fbuf[ii];
	}
	avg = avg/(ql.lx*ql.ly);
	double sig = 0;
	for (ii = 0; ii < ql.lx*ql.ly; ii++) {
		sig += pow(ql.fbuf[ii] - avg, 2.);
	}
	sig = pow(sig/(ql.lx*ql.ly), 0.5);

	if (datamin	< avg-5*sig) { 
		datamin = avg-5*sig; 
	}
	if (datamax	> avg+5*sig) { 
		datamax = avg+5*sig; 
	}
}

- (BOOL)isAnImage 
{
	return ((self.nx > 1) && (self.ny > 1));
}

- (void)defineSpectrumWavelengthLimits 
{
	float crval1 = [self headerValueForKeywordAsFloat:"CRVAL1"];
	float crpix1 = [self headerValueForKeywordAsFloat:"CRPIX1"];
	float cdelt1 = [self headerValueForKeywordAsFloat:"CDELT1"];
	wstart = (crval1 + cdelt1 * (1 - crpix1));
	wstop  = (crval1 + cdelt1 * (nx - crpix1));
}

/*- (unsigned char *)	prepareDataForBitmapRepWithZScaling {
	unsigned char *imageData;
	int ii;
	float avg;
	imageData = malloc(nx*ny);	
	for (ii = 0; ii < nx*ny; ii++) {
		imageData[ii] = ql.fbuf[ii];
		avg += ql.fbuf[ii];
	}
	printf("%f\n", avg/(nx*ny));
	float z1, z2;
	cdl_zscale(imageData, nx, ny, 8, &z1, &z2, 0.2, 100, 10);
	if (DEBUG) {NSLog(@"[QLFits] Z Scaling process found z1=%f, z2=%f. Applying.", z1, z2);}
	
	z1 = 600;
	z2 = 650;
	
	int pmin = 1, pmax = 200;
	float scale = 0.0, dscale = (200.0 / 3.0);
	int smin, smax, pval;
	smin = (int) z1;
	smax = (int) z2;
	
//	scale = (smax == smin) ? 0. : 200. / (z2 - z1);
//	for (ii = 0; ii < nx*ny; ii++) {
//		imageData[ii] = max (pmin, min (pmax, (int)(scale * (float)((int)imageData[ii] - smin)) ));
//	}

	scale = (smax == smin) ? 0. : (1000.0 - 1.0) / (z2 - z1);
	for (ii = 0; ii < nx*ny; ii++) {
		// Scale that to the range 1-1000 and take the log. 
		pval = max (1.0, min(1000.0, (scale * (imageData[ii] - smin)) )); 
		pval = log10 (pval);
		// Now scale back to the display range 
		imageData[ii] = (unsigned char) max (pmin, min (pmax, (unsigned char)(dscale * pval) ));
		}

	if (DEBUG) {NSLog(@"[QLFits] Image ready.");}
	return imageData;
}
*/

- (unsigned char *)prepareDataForBitmapRepWithLinearScaling 
{
	unsigned char *imageData;
	int ii;
	imageData = malloc(nx*ny);
	[self findDataminDatamax];
	for (ii = 0; ii < nx*ny; ii++) {
		imageData[ii] = (ql.fbuf[ii] - datamin)/(datamax - datamin) * 255;
	}
	NSLog(@"[QLFits] Image scaled linearly.");
	return imageData;
}

- (float *)prepareDataForSpectrumRep 
{
	float *specData;
	specData = malloc(nx);
	int ii;	
	for (ii = 0; ii < nx; ii++) {	
		specData[ii] = (ql.fbuf[ii] - datamin)/(datamax - datamin) * nx;
	}
	NSLog(@"[QLFits] Spectrum ready.");
	return specData;
}

- (float)dataValueAtIndex:(int)idx 
{
	return ql.fbuf[idx];
}

@end
