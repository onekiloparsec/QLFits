
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

		NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.onekiloparsec.QLFits3"];

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

			for (NSUInteger i = 0; i < [fits countOfHDUs]; i++) {
				// We use "NSUserName" to avoid collisions for plugins installed on whole system in multi-users machines.
				NSString *HDUImageFileName = [NSString stringWithFormat:@"QLFits3_%@_HDU%lu.tiff", NSUserName(), i+1];
				NSString *HDUImageFilePath = [[bundle resourcePath] stringByAppendingPathComponent:HDUImageFileName];

				// Table anchor is declared in template.html
				[HDULinesString appendString:@"\n<tr><td class=\"HDULine\">\n"];
//				[HDULinesString appendFormat:@"<div class=\"container\" id=\"HDU%lu\">\n", (unsigned long)i];
//
//				// HDU line table row
//				[HDULinesString appendString:@"\t<div class=\"header\">\n"];
//				[HDULinesString appendFormat:@"\t\t<div class=\"label\">Header #%lu</div>\n", (unsigned long)i];
//				[HDULinesString appendFormat:
//				 @"\t\t<div class=\"detail\"><a href=\"#toggle%lu\" onclick=\"toggleDetails(%lu);\" id=\"toggle_button%lu\">Show Data</a></div>\n",
//				 (unsigned long)i, (unsigned long)i, (unsigned long)i];
//				[HDULinesString appendString:@"\t</div>\n"];

				// FITS Data
				success = [fits syncLoadDataOfHDUAtIndex:i];
				if (success) {
					FITSHDU *hdu = [fits HDUAtIndex:i];

					if ([hdu type] == FITSHDUTypeImage) {
						NSString *objectName = [[hdu header] stringValueForKey:@"OBJECT"];
						FITSImage *img = [hdu image];
						CGSize maxSize = CGSizeMake(800.0, 800.0);

						if (objectName == nil) objectName = [(__bridge NSURL *)url lastPathComponent];
						NSDictionary *options = @{(__bridge NSString *)kQLPreviewPropertyDisplayNameKey: objectName,
												  (__bridge NSNumber *)kQLPreviewPropertyWidthKey: @(800),
												  (__bridge NSNumber *)kQLPreviewPropertyHeightKey: @(800)};

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
									success = [[img TIFFRepresentation] writeToFile:HDUImageFilePath atomically:YES];

									NSDictionary *attachement = @{(__bridge NSString *)kQLPreviewPropertyMIMETypeKey: @"image/tiff",
																  (__bridge NSString *)kQLPreviewPropertyAttachmentDataKey: [img TIFFRepresentation]};

									[attachements setObject:attachement forKey:[NSString stringWithFormat:@"HDUData%lu", i]];
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

									success = [[img TIFFRepresentation] writeToFile:HDUImageFilePath atomically:YES];

									NSDictionary *attachement = @{(__bridge NSString *)kQLPreviewPropertyMIMETypeKey: @"image/tiff",
																  (__bridge NSString *)kQLPreviewPropertyAttachmentDataKey: [img TIFFRepresentation]};

									[attachements setObject:attachement forKey:[NSString stringWithFormat:@"HDUData%lu", i]];
								}
							}
						}
					}
				}

				// FITS Data Div
				[HDULinesString appendFormat:@"\t<div class=\"FITSData\" id=\"HDUData%lu\">\n", (unsigned long)i];
				[HDULinesString appendFormat:@"\t\t<div class=\"data\"><img src=\"cid:%@\" border=0 width=100%% /></div>\n", HDUImageFileName];
				[HDULinesString appendString:@"\t</div>\n"];

				// FITS Header
				NSMutableString *headerString = [NSMutableString stringWithString:@""];
				success = [fits syncLoadHeaderOfHDUAtIndex:i];
				if (success) {
					[headerString appendString:@"\t\t<table>\n"];
					FITSHeader *header = [[fits mainHDU] header];

					for (NSUInteger i = 0; i < [header countOfLines]; i++) {
						FITSHeaderLine *headerLine = [header lineAtIndex:i];
						[headerString appendFormat:@"\t\t<tr><td class=FITSHeaderKey>%@</td><td> = </td>", headerLine.key];
						[headerString appendFormat:@"<td class=FITSHeaderValue>%@</td><td> / </td>", headerLine.value];
						[headerString appendFormat:@"<td class=FITSHeaderComment>%@</td></tr>\n", headerLine.comment];
					}

					[headerString appendString:@"\t\t</table>\n"];
				}

				// FITS Header Div
				[HDULinesString appendFormat:@"\t<div class=\"FITSHeader\" id=\"HDUHeader%lu\" style=\"display:none;\">\n", (unsigned long)i];
				[HDULinesString appendFormat:@"%@", headerString];
				[HDULinesString appendString:@"\t</div>\n"]; // Header div

				[HDULinesString appendString:@"</div>\n"]; // Whole HDU container div
				[HDULinesString appendString:@"</td></tr>"];

			}

			[synthesizedInfo setObject:HDULinesString forKey:@"HDUTableLines"];
		}

		NSString *versionString = [[bundle infoDictionary] objectForKey:@"CFBundleVersion"];
		[synthesizedInfo setObject:versionString forKey:@"BundleVersion"];

		NSURL *htmlURL = [bundle URLForResource:@"template" withExtension:@"html"];
		NSMutableString *html = [NSMutableString stringWithContentsOfURL:htmlURL encoding:NSUTF8StringEncoding error:NULL];

		for (NSString *key in [synthesizedInfo allKeys]) {
			NSString *replacementValue = [synthesizedInfo objectForKey:key];
			NSString *replacementToken = [NSString stringWithFormat:@"__%@__", key];
			[html replaceOccurrencesOfString:replacementToken withString:replacementValue options:0 range:NSMakeRange(0, [html length])];
		}

//		NSLog(@"%@", html);

		QLPreviewRequestSetDataRepresentation(preview,
											  (__bridge CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding],
											  kUTTypeHTML,
											  (__bridge CFDictionaryRef)previewProperties);

	}

    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview) {}
