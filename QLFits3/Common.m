//
//  Common.m
//  Stif
//
//  Created by Cédric Foellmi on 5/4/12.
//  Copyright (c) 2012 Soft Tenebras Lux. All rights reserved.
//

#import "Common.h"
#import <ObjCFITSIO/ObjCFITSIO.h>

static CGFloat pad = 20.0;

void DrawSpectrumCanvas(CGContextRef context, CGSize canvasSize)
{
    CGContextSetFillColorWithColor(context, CGColorCreateGenericGray(1.0, 1.0));
    CGRect rect = CGRectMake(0, 0, canvasSize.width, canvasSize.height);
    CGContextFillRect(context, rect);
    
    CGContextSetStrokeColorWithColor(context, CGColorCreateGenericGray(0.1, 1.0));
    CGContextMoveToPoint(context, pad, pad);
    CGContextAddLineToPoint(context, canvasSize.width-pad, pad);
    CGContextAddLineToPoint(context, canvasSize.width-pad, canvasSize.height-2*pad);
    CGContextAddLineToPoint(context, pad, canvasSize.height-2*pad);
    CGContextAddLineToPoint(context, pad, pad);
    CGContextStrokePath(context);
}

void DrawSpectrum(CGContextRef context, CGSize canvasSize, FITSSpectrum *spectrum)
{    
	canvasSize.width -= 2*pad;
	canvasSize.height -= 3*pad;
	
    CGFloat yMin = [spectrum minimumYValueWithUnits:FITSSpectrumYUnitsRaw];
    CGFloat yMax = [spectrum maximumYValueWithUnits:FITSSpectrumYUnitsRaw];
		
    NSArray *points = [spectrum rawPoints];
    double firstPointValue = [[points objectAtIndex:0] doubleValue];
    
    CGContextMoveToPoint(context, pad, pad + firstPointValue/(yMax-yMin)*canvasSize.height);
    
    NSUInteger count = [points count];
    for (NSUInteger i = 0; i < count; i++) {
		double value = [[points objectAtIndex:i] doubleValue];
		CGFloat x = pad + i*canvasSize.width/count;
		CGFloat y = pad + (value - yMin)/(yMax-yMin)*canvasSize.height;
        CGContextAddLineToPoint(context, x, y);
    }
    CGContextStrokePath(context);
}

void DrawObjectName(CGContextRef context, CGSize canvasSize, NSString *objectName, BOOL forThumbnail, BOOL forSpectrum)
{
	if (objectName != nil && [objectName length] > 0) {
		const char *objName = [objectName UTF8String];
		CGFloat fontPoint = (forSpectrum) ? 128.0 : 24.0;
		CGContextSelectFont(context, "Futura", fontPoint, kCGEncodingMacRoman);
		CGContextSetTextDrawingMode(context, kCGTextFillStroke);
		CGContextSetRGBStrokeColor(context, 1., 1., 1., 0.6);
		CGContextSetRGBFillColor(context, 0.0, 0.5, 1.0, 1.0);

		CGFloat h = (forThumbnail) ? (canvasSize.height-1.5*pad)/2.0 : canvasSize.height-1.5*pad;
		CGContextShowTextAtPoint(context, 
								 (canvasSize.width - strlen(objName)/2*fontPoint)/2.0, 
								 h,
								 objName, 
								 strlen(objName));   
	}
}

