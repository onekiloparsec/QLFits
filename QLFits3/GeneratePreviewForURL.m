
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>

#import "ObjCFITSIO.h"
#import "Common.h"
#import "cdlzscale.h"

OSStatus GeneratePreviewForURL(void *thisInterface,
							   QLPreviewRequestRef preview,
							   CFURLRef url,
							   CFStringRef
							   contentTypeUTI,
							   CFDictionaryRef options);

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);


OSStatus GeneratePreviewForURL(void *thisInterface,
							   QLPreviewRequestRef preview,
							   CFURLRef url,
							   CFStringRef contentTypeUTI,
							   CFDictionaryRef options)
{
    DebugLog(@"Previewing %@", (__bridge NSURL *)url);

	CGSize maxSize = CGSizeMake(800, 800);

    FITSFile *fits = [FITSFile FITSFileWithURL:(__bridge NSURL *)url];
    [fits open];

    if ([fits countOfHDUs] >= 1) {
		[fits syncLoadHeaderOfHDUAtIndex:0];
        [fits syncLoadImageOfHDUAtIndex:0];
        // no success

        FITSHDU *hdu = [[fits HDUs] objectAtIndex:0];
        NSString *objectName = [[hdu header] stringValueForKey:@"OBJECT"];

        if ([hdu type] == FITSHDUTypeImage) {
            FITSImage *img = [hdu image];

			NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
									 objectName, kQLPreviewPropertyDisplayNameKey,
									 [NSNumber numberWithDouble:600.0], kQLPreviewPropertyWidthKey,
									 [NSNumber numberWithDouble:500.0], kQLPreviewPropertyHeightKey,
									 nil];

            if ([img is2D]) {
                CGImageRef cgImage = [img CGImageScaledToSize:maxSize];
                if (cgImage != NULL) {
                    CGContextRef context = QLPreviewRequestCreateContext(preview, maxSize, true, (__bridge CFDictionaryRef)options);
                    CGRect renderRect = CGRectMake(0., 0., maxSize.width, maxSize.height);
                    CGContextDrawImage(context, renderRect, cgImage);
					if (objectName == nil) objectName = [(__bridge NSURL *)url lastPathComponent];
					DrawObjectName(context, renderRect.size, objectName);
                    QLPreviewRequestFlushContext(preview, context);
                    CFRelease(context);
                }
            }
            else if ([img is1D]) {
				FITSSpectrum *spectrum = [img spectrum];

				CGContextRef context = QLPreviewRequestCreateContext(preview, maxSize, true, (__bridge CFDictionaryRef)options);
                DrawSpectrumCanvas(context, maxSize);
				DrawSpectrum(context, maxSize, spectrum);
				if (objectName == nil) objectName = [(__bridge NSURL *)url lastPathComponent];
				DrawObjectName(context, maxSize, objectName);
				CGContextFlush(context);

				QLPreviewRequestFlushContext(preview, context);
                CFRelease(context);
            }
        }
    }

    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview) {}
