
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>

#import "ObjCFITSIO.h"
#import "Common.h"
#import "cdlzscale.h"

#define DRAW_IMAGE_IN_QL_CONTEXT 0

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
		BOOL success = NO;

		NSString *synthesizedValue = nil;
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
			// We differentiate the often-encountered case of 1 Header + 1 Data from all the others.
			// If # HDU > 1, we suppose a sructure of 1 main HDU followed by extensions

			NSString *title = ([fits countOfHDUs] == 1) ? @"Header" : @"Header of Main HDU";
			[synthesizedInfo setObject:title forKey:@"HeaderTitle"];

			success = [fits syncLoadHeaderOfMainHDU];

			NSMutableString *headerString = [NSMutableString string];
			[headerString appendString:@"<table>\n"];

			if (success) {
				FITSHeader *header = [[fits mainHDU] header];

				synthesizedValue = [NSString stringWithFormat:@"(%zd line%s)", [header countOfLines], ([header countOfLines] == 1 ? "" : "s")];
				[synthesizedInfo setObject:synthesizedValue forKey:@"HeaderLinesCount"];

				for (NSUInteger i = 0; i < [header countOfLines]; i++) {
					FITSHeaderLine *headerLine = [header lineAtIndex:i];
					[headerString appendFormat:@"<tr><td class=FITSHeaderKey>%@</td><td> = </td>", headerLine.key];
					[headerString appendFormat:@"<td class=FITSHeaderValue>%@</td><td> / </td>", headerLine.value];
					[headerString appendFormat:@"<td class=FITSHeaderComment>%@</td></tr>", headerLine.comment];
				}
			}

			[headerString appendString:@"</table>\n"];

			synthesizedValue = [headerString copy];
			[synthesizedInfo setObject:synthesizedValue forKey:@"HeaderLinesFormatted"];


			for (NSUInteger i = 0; i < [fits countOfHDUs]; i++) {
				success = [fits syncLoadDataOfHDUAtIndex:i];
				if (success) {
					FITSHDU *hdu = [fits HDUAtIndex:i];

					if (i == 0) {
						NSString *tabFirstTitle = ([fits countOfHDUs] == 1) ? @"Show Data" : @"Show Extensions";
						[synthesizedInfo setObject:tabFirstTitle forKey:@"SecondaryTabFirstTitle"];
						NSString *tabSecondTitle = ([fits countOfHDUs] == 1) ? @"Show Header" : @"Show Header of Main HDU";
						[synthesizedInfo setObject:tabSecondTitle forKey:@"SecondaryTabSecondTitle"];
					}

					if ([hdu type] == FITSHDUTypeImage) {
						NSString *objectName = [[hdu header] stringValueForKey:@"OBJECT"];
						FITSImage *img = [hdu image];
						CGSize maxSize = CGSizeMake(800.0, 800.0);

						if (objectName == nil) objectName = [(__bridge NSURL *)url lastPathComponent];
						NSDictionary *options = @{(__bridge NSString *)kQLPreviewPropertyDisplayNameKey: objectName,
												  (__bridge NSNumber *)kQLPreviewPropertyWidthKey: @(800),
												  (__bridge NSNumber *)kQLPreviewPropertyHeightKey: @(800)};

						// We use "NSUserName" to avoid collisions for plugins installed on whole system in multi-users machines.
						NSString *HDUImageFileName = [NSString stringWithFormat:@"/tmp/QLFits3_%@_ext%lu.tiff", NSUserName(), i+1];

						if ([img is2D]) {
							CGImageRef cgImage = [img CGImageScaledToSize:maxSize];
							if (cgImage != NULL) {
								if (DRAW_IMAGE_IN_QL_CONTEXT) {
									CGContextRef context = QLPreviewRequestCreateContext(preview, maxSize, true, (__bridge CFDictionaryRef)options);
									CGRect renderRect = CGRectMake(0., 0., maxSize.width, maxSize.height);
									CGContextDrawImage(context, renderRect, cgImage);
									DrawObjectName(context, renderRect.size, objectName);
									QLPreviewRequestFlushContext(preview, context);
									CFRelease(context);
								}
								else {
									NSImage *img = [[NSImage alloc] initWithCGImage:cgImage size:maxSize];
									success = [[img TIFFRepresentation] writeToFile:HDUImageFileName atomically:YES];
								}
							}
						}
						else if ([img is1D]) {
							FITSSpectrum *spectrum = [img spectrum];
							if (spectrum != nil) {
								if (DRAW_IMAGE_IN_QL_CONTEXT) {
									CGContextRef context = QLPreviewRequestCreateContext(preview, maxSize, true, (__bridge CFDictionaryRef)options);
									DrawSpectrumCanvas(context, maxSize);
									DrawSpectrum(context, maxSize, spectrum);
									DrawObjectName(context, maxSize, objectName);
									CGContextFlush(context);
									QLPreviewRequestFlushContext(preview, context);
									CFRelease(context);
								}
								else {
									NSImage *img = [[NSImage alloc] initWithSize:maxSize];
									[img lockFocus];
									CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
									DrawSpectrumCanvas(context, maxSize);
									DrawSpectrum(context, maxSize, spectrum);
									DrawObjectName(context, maxSize, objectName);
									CGContextFlush(context);
									[img unlockFocus];
									success = [[img TIFFRepresentation] writeToFile:HDUImageFileName atomically:YES];
								}
							}
						}
					}
				}
			}
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

		NSDictionary *properties = @{(__bridge NSString *)kQLPreviewPropertyTextEncodingNameKey : @"UTF-8",
									 (__bridge NSString *)kQLPreviewPropertyMIMETypeKey : @"text/html",
									 (__bridge NSNumber *)kQLPreviewPropertyWidthKey : @(800),
									 (__bridge NSNumber *)kQLPreviewPropertyHeightKey : @(800) };

		QLPreviewRequestSetDataRepresentation(preview,
											  (__bridge CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding],
											  kUTTypeHTML,
											  (__bridge CFDictionaryRef)properties);

	}

    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview) {}
