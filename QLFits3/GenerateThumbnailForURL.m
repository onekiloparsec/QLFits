#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import "Common.h"
#import "DebugLog.h"
#import <ObjCFITSIO/ObjCFITSIO.h>

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    DebugLog(@"Thumbnailing %@", (__bridge NSURL *)url);
    
    FITSFile *fits = [FITSFile FITSFileWithURL:(__bridge NSURL *)url];
    [fits open];
    
    if ([fits countOfHDUs] >= 1) {
        [fits syncLoadDataOfHDUAtIndex:0];
        [fits syncLoadHeaderOfHDUAtIndex:0];
        // no success?
        
        FITSHDU *hdu = [[fits HDUs] objectAtIndex:0];
        NSString *objectName = [[hdu header] stringValueForKey:@"OBJECT"];
        
        if ([hdu type] == FITSHDUTypeImage) {
            FITSImage *img = [hdu image];
            if (FITSIsEmptySize(img.size) && [fits countOfHDUs] > 1) {
                [fits syncLoadDataOfHDUAtIndex:1];
                img = [[fits HDUAtIndex:1] image];
            }
            
            if ([img is2D]) {
                CGImageRef cgImage = [img CGImageScaledToSize:maxSize];
                if (cgImage != NULL) {
                    CGContextRef context = QLThumbnailRequestCreateContext(thumbnail, maxSize, true, NULL);
                    CGRect renderRect = CGRectMake(0., 0., maxSize.width, maxSize.height);
                    CGContextDrawImage(context, renderRect, cgImage);
                    DrawObjectName(context, renderRect.size, objectName, YES, NO);
                    QLThumbnailRequestFlushContext(thumbnail, context);
                    CFRelease(context);
                }
            }
            else if ([img is1D]) {
                FITSSpectrum *spectrum = [img spectrum];
                
                CGFloat imgScale = 1.0;
                if (img.size.nx > 2000.0f) {
                    imgScale = img.size.nx/2000.0f;
                }
                
                CGSize canvasSize = CGSizeMake(img.size.nx/imgScale, img.size.nx/imgScale);
                CGContextRef context = QLThumbnailRequestCreateContext(thumbnail, canvasSize, true, NULL);
                DrawSpectrumCanvas(context, canvasSize);
                DrawSpectrum(context, canvasSize, spectrum);
                DrawObjectName(context, canvasSize, objectName, YES, YES);
                QLThumbnailRequestFlushContext(thumbnail, context);
                CFRelease(context);
            }
        }
    }
    
    return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}
