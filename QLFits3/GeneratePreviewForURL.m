
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

	@autoreleasepool {

		CGSize maxSize = CGSizeMake(800, 800);

		FITSFile *fits = [FITSFile FITSFileWithURL:(__bridge NSURL *)url];
		[fits open];

		if ([fits countOfHDUs] >= 1 && !QLPreviewRequestIsCancelled(preview)) {
			[fits syncLoadHeaderOfHDUAtIndex:0];

/*
			NSURL *htmlURL = [[NSBundle bundleWithIdentifier:@"com.iconfactory.Provisioning"] URLForResource:@"template" withExtension:@"html"];
			NSMutableString *html = [NSMutableString stringWithContentsOfURL:htmlURL encoding:NSUTF8StringEncoding error:NULL];

			NSMutableDictionary *synthesizedInfo = [NSMutableDictionary dictionary];
			NSString *synthesizedValue = nil;

			// Do all the work here

			// Header

			NSArray *array = (NSArray *)value;
			NSArray *sortedArray = [array sortedArrayUsingSelector:@selector(compare:)];

			NSMutableString *devices = [NSMutableString string];
			[devices appendString:@"<table>\n"];
			BOOL evenRow = NO;
			for (NSString *device in sortedArray) {
				// compute the prefix for the first column of the table
				NSString *displayPrefix = @"";
				NSString *devicePrefix = [device substringToIndex:1];
				if (! [currentPrefix isEqualToString:devicePrefix]) {
					currentPrefix = devicePrefix;
					displayPrefix = [NSString stringWithFormat:@"%@ ➞ ", devicePrefix];
				}

#if !SIGNED_CODE
				// check if Xcode has seen the device
				NSString *deviceName = @"";
				NSString *deviceSoftwareVerson = @"";
				NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deviceIdentifier = %@", device];
				NSArray *matchingDevices = [savedDevices filteredArrayUsingPredicate:predicate];
				if ([matchingDevices count] > 0) {
					id matchingDevice = [matchingDevices firstObject];
					if ([matchingDevice isKindOfClass:[NSDictionary class]]) {
						NSDictionary *matchingDeviceDictionary = (NSDictionary *)matchingDevice;
						deviceName = [matchingDeviceDictionary objectForKey:@"deviceName"];
						deviceSoftwareVerson = [matchingDeviceDictionary objectForKey:@"deviceSoftwareVersion"];
					}
				}

				[devices appendFormat:@"<tr class='%s'><td>%@</td><td>%@</td><td>%@</td><td>%@</td></tr>\n", (evenRow ? "even" : "odd"), displayPrefix, device, deviceName, deviceSoftwareVerson];
#else
				[devices appendFormat:@"<tr class='%s'><td>%@</td><td>%@</td></tr>\n", (evenRow ? "even" : "odd"), displayPrefix, device];
#endif
				evenRow = !evenRow;
			}
			[devices appendString:@"</table>\n"];

			synthesizedValue = [devices copy];
			[synthesizedInfo setObject:synthesizedValue forKey:@"HeaderLinesFormatted"];

			synthesizedValue = [NSString stringWithFormat:@"%zd Device%s", [array count], ([array count] == 1 ? "" : "s")];
			[synthesizedInfo setObject:synthesizedValue forKey:@"HeaderLinesCount"];

			for (NSString *key in [synthesizedInfo allKeys]) {
				NSString *replacementValue = [synthesizedInfo objectForKey:key];
				NSString *replacementToken = [NSString stringWithFormat:@"__%@__", key];
				[html replaceOccurrencesOfString:replacementToken withString:replacementValue options:0 range:NSMakeRange(0, [html length])];
			}

			NSDictionary *properties = @{ // properties for the HTML data
										 (__bridge NSString *)kQLPreviewPropertyTextEncodingNameKey : @"UTF-8",
										 (__bridge NSString *)kQLPreviewPropertyMIMETypeKey : @"text/html" };

			QLPreviewRequestSetDataRepresentation(preview,
												  (__bridge CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding],
												  kUTTypeHTML,
												  (__bridge CFDictionaryRef)properties);
*/


			[fits syncLoadDataOfHDUAtIndex:0];

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
	}

    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview) {}
