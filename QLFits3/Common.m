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
//        const char *objName = [objectName UTF8String];
//        CGFloat fontPoint = (forSpectrum && forThumbnail) ? 56.0 : 24.0;
//        CGFontRef font = CGFontCreateWithFontName((CFStringRef)@"Futura");
//        CGContextSetFont(context, font);
//        CGContextSetFontSize(context, fontPoint);
//        CGContextSetTextDrawingMode(context, kCGTextFillStroke);
//        CGContextSetRGBStrokeColor(context, 1., 1., 1., 0.6);
//        CGContextSetRGBFillColor(context, 0.0, 0.5, 1.0, 1.0);
//        CGFloat h = (forThumbnail) ? (canvasSize.height-1.5*pad)/2.0 : canvasSize.height-1.5*pad;
//        CGContextShowTextAtPoint(context,
//                                 (canvasSize.width - strlen(objName)/2*fontPoint)/2.0,
//                                 h,
//                                 objName,
//                                 strlen(objName));

        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        const char *objName = [objectName UTF8String];
        CGFloat fontPoint = (forSpectrum && forThumbnail) ? 56.0 : 24.0;


        // Create a path which bounds the area where you will be drawing text.
        // The path need not be rectangular.
        CGMutablePathRef path = CGPathCreateMutable();
                  
        // In this simple example, initialize a rectangular path.
        CGFloat x = (canvasSize.width - strlen(objName)/2*fontPoint)/2.0;
        CGFloat y = (forThumbnail) ? (canvasSize.height-1.5*pad)/2.0 : canvasSize.height-1.5*pad;

        CGRect bounds = CGRectMake(x, y, canvasSize.width, canvasSize.height);
        CGPathAddRect(path, NULL, bounds);
        
        // Create a mutable attributed string with a max length of 0.
        // The max length is a hint as to how much internal storage to reserve.
        // 0 means no hint.
        CFMutableAttributedStringRef attrString =
                 CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
         
        // Copy the textString into the newly created attrString
        CFAttributedStringReplaceString (attrString, CFRangeMake(0, 0), (__bridge CFStringRef)objectName);
         
        // Create a color that will be added as an attribute to the attrString.
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        CGFloat components[] = { 1.0, 1.0, 1.0, 0.6 };
        CGColorRef black = CGColorCreate(rgbColorSpace, components);
        CGColorSpaceRelease(rgbColorSpace);
         
        // Set the color of the first 12 chars to red.
        CFAttributedStringSetAttribute(attrString, CFRangeMake(0, 12), kCTForegroundColorAttributeName, black);
         
                
        // Create the framesetter with the attributed string.
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attrString);
        CFRelease(attrString);
         
        // Create a frame.
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
         
        // Draw the specified frame in the given context.
        CTFrameDraw(frame, context);
         
        // Release the objects we used.
        CFRelease(frame);
        CFRelease(path);
        CFRelease(framesetter);
	}
}

void DrawHDUSummary(CGContextRef context, CGSize canvasSize, NSString *summaryString, BOOL forThumbnail, BOOL forSpectrum)
{
//    if (summaryString != nil && [summaryString length] > 0) {
//        const char *summary = [summaryString UTF8String];
//        CGFloat fontPoint = (forSpectrum && forThumbnail) ? 46.0 : 20.0;
//        CGFontRef font = CGFontCreateWithFontName((CFStringRef)@"Futura");
//        CGContextSetFont(context, font);
//        CGContextSetFontSize(context, fontPoint);
//        CGContextSetTextDrawingMode(context, kCGTextFillStroke);
//        CGContextSetRGBStrokeColor(context, 1., 1., 1., 0.6);
//        CGContextSetRGBFillColor(context, 0.0, 0.5, 1.0, 1.0);
//        
//        CGFloat h = (forThumbnail) ? (canvasSize.height-1.5*pad)/2.0 : canvasSize.height-1.5*pad;
//        CGContextShowTextAtPoint(context,
//                                 (canvasSize.width - strlen(summary)/2*fontPoint)/2.0,
//                                 h - 70,
//                                 summary,
//                                 strlen(summary));
//    }
}

