//
//  Common.h
//  Stif
//
//  Created by Cédric Foellmi on 5/4/12.
//  Copyright (c) 2012 Soft Tenebras Lux. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FITSSpectrum;

void DrawSpectrumCanvas(CGContextRef context, CGSize canvasSize);
void DrawSpectrum(CGContextRef context, CGSize canvasSize, FITSSpectrum *spectrum);
void DrawObjectName(CGContextRef context, CGSize canvasSize, NSString *objectName, BOOL forThumbnail, BOOL forSpectrum);
