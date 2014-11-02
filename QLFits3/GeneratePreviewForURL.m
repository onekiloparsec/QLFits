#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import "ObjCFITSIO.h"
#import "Common.h"
#import "cdlzscale.h"
#import "DebugLog.h"

#define MAX_HDU_COUNT 10

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    DebugLog(@"Previewing %@", (__bridge NSURL *)url);
    
    @autoreleasepool {
        NSMutableDictionary *previewProperties = [NSMutableDictionary dictionary];
        [previewProperties setObject:@"UTF-8" forKey:(__bridge NSString *)kQLPreviewPropertyTextEncodingNameKey];
        [previewProperties setObject:@"text/html" forKey:(__bridge NSString *)kQLPreviewPropertyMIMETypeKey];
        [previewProperties setObject:@(800) forKey:(__bridge NSString *)kQLPreviewPropertyWidthKey];
        [previewProperties setObject:@(800) forKey:(__bridge NSString *)kQLPreviewPropertyHeightKey];
        
        NSMutableDictionary *attachements = [NSMutableDictionary dictionary];
        [previewProperties setObject:attachements forKey:(__bridge NSString *)kQLPreviewPropertyAttachmentsKey];
        
        NSMutableDictionary *synthesizedInfo = [NSMutableDictionary dictionary];
        [synthesizedInfo setObject:[[(__bridge NSURL *)url absoluteString] lastPathComponent] forKey:@"FileName"];
        
        NSDictionary *shortSummary = [FITSFile FITSFileShortSummaryWithURL:(__bridge NSURL *)url];
        [synthesizedInfo setObject:(shortSummary) ? shortSummary[@"summary"] : @"" forKey:@"ContentSummary"];
        
        FITSFile *fits = [FITSFile FITSFileWithURL:(__bridge NSURL *)url];
        [fits open];
        
        if ([fits countOfHDUs] == 0 || QLPreviewRequestIsCancelled(preview)) {
            [fits close];
        }
        else {
            NSMutableString *HDULinesString = [NSMutableString string];
            
            for (NSUInteger i = 0; i < MIN(MAX_HDU_COUNT, [fits countOfHDUs]); i++) {
                // We use "NSUserName" to avoid collisions for plugins installed on whole system in multi-users machines.
                NSString *HDUImageFileName = [NSString stringWithFormat:@"QLFits3_%@_HDU%lu.tiff", NSUserName(), i+1];
                
                // Table anchor is declared in template.html
                [HDULinesString appendString:@"\n\t\t<tr><td class=\"HDULine\">\n"];
                [HDULinesString appendString:@"\t\t<div class=\"container\" id=\"HDU\">\n"];
                
                // HDU line table row
                [HDULinesString appendString:@"\n\t\t\t<div class=\"header\">\n"];
                [HDULinesString appendFormat:@"\t\t\t\t<div class=\"label\">HDU %lu", (unsigned long)i];
                
                // FITS Data
                BOOL hasData = [fits syncLoadDataOfHDUAtIndex:i];
                FITSHDU *hdu = [fits HDUAtIndex:i];
                
                [fits syncLoadHeaderOfHDUAtIndex:i];
                NSString *objectName = [[hdu header] stringValueForKey:@"OBJECT"];
                
                if (hasData) {
                    if ([hdu type] == FITSHDUTypeImage) {
                        FITSImage *fitsImage = [hdu image];
                        
                        BOOL isEmptySize = FITSIsEmptySize(fitsImage.size);
                        hasData &= !isEmptySize;
                        
                        NSMutableString *titleString = [NSMutableString string];
                        if (!isEmptySize) {
                            [titleString appendString:@"&nbsp;&nbsp; –– &nbsp;&nbsp;"];
                        }
                        
                        CGSize maxSize = CGSizeMake(800.0, 800.0);
                        NSImage *img = [[NSImage alloc] initWithSize:maxSize];
                        [img lockFocus];
                        
                        CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
                        
                        if ([fitsImage is2D]) {
                            [titleString appendFormat:@"Image, size: %@", NSStringFromFITSSize(fitsImage.size)];
                            CGImageRef cgImage = [fitsImage CGImageScaledToSize:maxSize];
                            if (cgImage != NULL) {
                                CGRect renderRect = CGRectMake(0., 0., maxSize.width, maxSize.height);
                                CGContextDrawImage(context, renderRect, cgImage);
                                DrawObjectName(context, maxSize, objectName, NO, NO);
                            }
                        }
                        else if ([fitsImage is1D]) {
                            FITSSpectrum *spectrum = [fitsImage spectrum];
                            [titleString appendFormat:@"Spectrum, length: %lu", spectrum.numberOfPoints];
                            
                            if (spectrum != nil) {
                                DrawSpectrumCanvas(context, maxSize);
                                DrawSpectrum(context, maxSize, spectrum);
                                DrawObjectName(context, maxSize, objectName, NO, YES);
                            }
                        }
                        else {
                            if (!isEmptySize) {
                                [titleString appendFormat:@"Data Unit, size: %@", NSStringFromFITSSize(fitsImage.size)];
                            }
                        }
                        
                        CGContextFlush(context);
                        [img unlockFocus];
                        
                        NSDictionary *attachement = @{(__bridge NSString *)kQLPreviewPropertyMIMETypeKey: @"image/tiff",
                            (__bridge NSString *)kQLPreviewPropertyAttachmentDataKey: [img TIFFRepresentation]};
                        
                        [attachements setObject:attachement forKey:HDUImageFileName];
                        [HDULinesString appendString:titleString];
                    }
                }
                
                [HDULinesString appendString:@"</div>\n"]; // div class="label"
                
                if (hasData) {
                    [HDULinesString appendString:@"\t\t\t\t<div class=\"detail\">"];
                    [HDULinesString appendFormat:@"<a href=\"#toggle%lu\" ", (unsigned long)i];
                    [HDULinesString appendFormat:@"onclick=\"toggleDetails(%lu);\" ", (unsigned long)i];
                    [HDULinesString appendFormat:@"id=\"toggle_button%lu\">Show Header</a></div>\n", (unsigned long)i];
                }
                
                [HDULinesString appendString:@"\t\t\t</div>\n\n"]; // HDULine header.
                
                if (hasData) {
                    // FITS Data Div
                    [HDULinesString appendFormat:@"\t\t\t<div class=\"FITSData\" id=\"HDUData%lu\">\n", (unsigned long)i];
                    [HDULinesString appendFormat:@"\t\t\t\t<div class=\"data\"><img src=\"cid:%@\" border=0 width=100%% /></div>\n", HDUImageFileName];
                    [HDULinesString appendString:@"\t\t\t</div>\n"];
                }
                
                // FITS Header
                NSMutableString *headerString = [NSMutableString stringWithString:@""];
                [headerString appendString:@"\t\t\t<table>\n"];
                FITSHeader *header = [hdu header];
                
                for (NSUInteger i = 0; i < [header countOfLines]; i++) {
                    FITSHeaderLine *headerLine = [header lineAtIndex:i];
                    [headerString appendFormat:@"\t\t\t\t<tr><td class=FITSHeaderKey>%@</td><td> = </td>", headerLine.key];
                    [headerString appendFormat:@"<td class=FITSHeaderValue>%@</td><td> / </td>", headerLine.value];
                    [headerString appendFormat:@"<td class=FITSHeaderComment>%@</td></tr>\n", headerLine.comment];
                }
                
                [headerString appendString:@"\t\t\t</table>\n"];
                
                // FITS Header Div
                NSString *display = (hasData) ? @"none" : @"block";
                [HDULinesString appendFormat:@"\n\t\t\t<div class=\"FITSHeader\" id=\"HDUHeader%lu\" style=\"display:%@;\">\n", (unsigned long)i, display];
                [HDULinesString appendFormat:@"%@", headerString];
                [HDULinesString appendString:@"\t\t\t</div>\n\n"]; // FITS Header div
                
                [HDULinesString appendString:@"\t\t</div>\n"]; // Whole HDU container div
                [HDULinesString appendString:@"\t\t</td></tr>\n"];
                
            }
            
            if ([fits countOfHDUs] > MAX_HDU_COUNT) {
                [HDULinesString appendFormat:
                 @"<div style=\"text-align:center\">For speed reasons, only %i out of %li HDUs are previewed.</div>",
                 MAX_HDU_COUNT, [fits countOfHDUs]];
            }
            
            [synthesizedInfo setObject:HDULinesString forKey:@"HDUTableLines"];
        }
        
        NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.onekiloparsec.QLFits3"];
        NSString *versionString = [[bundle infoDictionary] objectForKey:@"CFBundleVersion"];
        [synthesizedInfo setObject:versionString forKey:@"BundleVersion"];
        
        NSURL *htmlURL = [bundle URLForResource:@"template" withExtension:@"html"];
        NSMutableString *html = [NSMutableString stringWithContentsOfURL:htmlURL encoding:NSUTF8StringEncoding error:NULL];
        
        for (NSString *key in [synthesizedInfo allKeys]) {
            NSString *replacementValue = [synthesizedInfo objectForKey:key];
            NSString *replacementToken = [NSString stringWithFormat:@"__%@__", key];
            [html replaceOccurrencesOfString:replacementToken withString:replacementValue options:0 range:NSMakeRange(0, [html length])];
        }
        
//#ifdef DEBUG
//        NSLog(@"%@", html);
//#endif
        
        QLPreviewRequestSetDataRepresentation(preview,
                                              (__bridge CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding],
                                              kUTTypeHTML,
                                              (__bridge CFDictionaryRef)previewProperties);
        
    }
    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
