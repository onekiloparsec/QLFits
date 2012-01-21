//
//  PrefsController.m
//
//  Created by Cédric Foellmi on 26/09/09.
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

#import "PrefsController.h"

#define QUICKLOOK_CFBUNDLEID	CFSTR("com.softtenebraslux.qlfitsgenerator")

@implementation PrefsController

- (id)initWithBundle:(NSBundle *)bundle 
{
	self = [super initWithBundle:bundle];
    if (self != nil) {
		stateDico = [NSDictionary dictionaryWithObjectsAndKeys:
					 [NSNumber numberWithBool:YES], @"block", 
					 [NSNumber numberWithBool:NO], @"none", 
					 @"Stars are black on a white sky.", @"negative", 
					 @"Stars are white on a black sky.", @"positive", 				
					 nil];
        
		currentVersion = @"2.4.0";
	}
    return self;
}

- (void)dealloc 
{
    [stateDico release];
    [currentVersion release];
	[super dealloc];
}

- (int)resetQuicklookManager 
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/qlmanage"];
    [task setArguments:[NSArray arrayWithObjects:@"-r", nil]];
    [task launch];
    [task waitUntilExit];	
	int status = [task terminationStatus];	
	[task release];
	return status;
}

- (int)savePreferenceKey:(NSString *)prefKey withValue:(NSString *)prefValue 
{
	CFStringRef cfPrefKey   = (CFStringRef)prefKey;
	CFStringRef cfPrefValue = (CFStringRef)prefValue;	
//	NSLog(@"Setting key %@ to value %@ for %@", cfPrefKey, cfPrefValue, QUICKLOOK_CFBUNDLEID);
	CFPreferencesSetValue(cfPrefKey, cfPrefValue, QUICKLOOK_CFBUNDLEID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize(QUICKLOOK_CFBUNDLEID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	return noErr;
}

- (void) mainViewDidLoad 
{
	if (currentVersion) {
		[versionMessage setStringValue:[[NSString stringWithString:@"Current version: "] stringByAppendingString:currentVersion]];
    }
			
	CFStringRef prefKey1   = CFSTR("showQuickSummary"); 
	CFStringRef prefValue1 = (CFStringRef)CFPreferencesCopyAppValue(prefKey1, QUICKLOOK_CFBUNDLEID);
	if (prefValue1) {
		[quickSummaryCheckbox setState:[[stateDico valueForKey:(NSString *)prefValue1] boolValue]];
	} 
	else {
		[self savePreferenceKey:@"showQuickSummary" withValue:DEFAULT_SHOWQUICKSUMMARY];
		[quickSummaryCheckbox setState:[[stateDico valueForKey:DEFAULT_SHOWQUICKSUMMARY] boolValue]];
	}
	
	CFStringRef prefKey2   = CFSTR("showESOLinks"); 
	CFStringRef prefValue2 = (CFStringRef)CFPreferencesCopyAppValue(prefKey2, QUICKLOOK_CFBUNDLEID);
	if (prefValue2) {
		[esoLinksCheckbox setState:[[stateDico valueForKey:(NSString *)prefValue2] boolValue]];	
	} 
	else {
		[self savePreferenceKey:@"showESOLinks" withValue:DEFAULT_SHOWESOLINKS];
		[esoLinksCheckbox setState:[[stateDico valueForKey:DEFAULT_SHOWESOLINKS] boolValue]];
	}
	
	CFStringRef prefKey3   = CFSTR("defaultHeightForHeaderFrame"); 
	CFStringRef prefValue3 = (CFStringRef)CFPreferencesCopyAppValue(prefKey3, QUICKLOOK_CFBUNDLEID);
	if (prefValue3) {
		[headerHeightPopup selectItemWithTitle:(NSString *)prefValue3];
	} 
	else {
		[headerHeightPopup selectItemWithTitle:DEFAULT_HEADERHEIGHT];
		[self savePreferenceKey:@"defaultHeightForHeaderFrame" withValue:DEFAULT_HEADERHEIGHT];
	}

	CFStringRef prefKey4   = CFSTR("headerFontSize"); 
	CFStringRef prefValue4 = (CFStringRef)CFPreferencesCopyAppValue(prefKey4, QUICKLOOK_CFBUNDLEID);
	if (prefValue4) {
		[headerFontSizePopup selectItemWithTitle:(NSString *)prefValue4];
	} 
	else {
		[headerFontSizePopup selectItemWithTitle:DEFAULT_HEADERFONTSIZE];
		[self savePreferenceKey:@"headerFontSize" withValue:DEFAULT_HEADERFONTSIZE];
	}

	CFStringRef prefKey5   = CFSTR("appearanceStyleName"); 
	CFStringRef prefValue5 = (CFStringRef)CFPreferencesCopyAppValue(prefKey5, QUICKLOOK_CFBUNDLEID);
	if (prefValue5) {
		[stylesPopup selectItemWithTitle:(NSString *)prefValue5];
	} 
	else {
		[stylesPopup selectItemWithTitle:DEFAULT_APPEARANCESTYLE];
		[self savePreferenceKey:@"appearanceStyleName" withValue:DEFAULT_APPEARANCESTYLE];
	}

	CFStringRef prefValue6 = (CFStringRef)CFPreferencesCopyAppValue(CFSTR("previewImageColorMode"), QUICKLOOK_CFBUNDLEID);
	if (prefValue6) {
		[previewColorModePopup selectItemWithTitle:(NSString *)prefValue6];
		[previewColorModeMessage setStringValue:[stateDico valueForKey:(NSString *)prefValue6]];		
	} 
	else {
		[previewColorModePopup selectItemWithTitle:DEFAULT_IMAGECOLORMODE];
		[previewColorModeMessage setStringValue:[stateDico valueForKey:DEFAULT_IMAGECOLORMODE]];				
		[self savePreferenceKey:@"previewImageColorMode" withValue:DEFAULT_IMAGECOLORMODE];
	}

	CFStringRef prefValue7 = (CFStringRef)CFPreferencesCopyAppValue(CFSTR("thumbnailImageColorMode"), QUICKLOOK_CFBUNDLEID);
	if (prefValue7) {
		[thumbnailColorModePopup selectItemWithTitle:(NSString *)prefValue7];
		[thumbnailColorModeMessage setStringValue:[stateDico valueForKey:(NSString *)prefValue7]];		
	} 
	else {
		[thumbnailColorModePopup selectItemWithTitle:DEFAULT_IMAGECOLORMODE];
		[thumbnailColorModeMessage setStringValue:[stateDico valueForKey:DEFAULT_IMAGECOLORMODE]];
		[self savePreferenceKey:@"thumbnailImageColorMode" withValue:DEFAULT_IMAGECOLORMODE];
	}
}


- (IBAction)summaryCheckboxClicked:(id)sender 
{
    if ([sender state]) {
		[self savePreferenceKey:@"showQuickSummary" withValue:@"block"]; // These are CSS keys for 'divs'.
	}
    else {
		[self savePreferenceKey:@"showQuickSummary" withValue:@"none"];
	}
	[self resetQuicklookManager];
}

- (IBAction)linksCheckboxClicked:(id)sender 
{
    if ([sender state]) {
		[self savePreferenceKey:@"showESOLinks" withValue:@"block"];
	}
    else {
		[self savePreferenceKey:@"showESOLinks" withValue:@"none"];
	}
	[self resetQuicklookManager];
}

- (IBAction)chooseHeaderFrameHeight:(id)sender 
{
	[self savePreferenceKey:@"defaultHeightForHeaderFrame" withValue:[headerHeightPopup titleOfSelectedItem]];
	[self resetQuicklookManager];
}

- (IBAction)chooseAppearanceStyle:(id)sender 
{
	[self savePreferenceKey:@"appearanceStyleName" withValue:[stylesPopup titleOfSelectedItem]];
	[self resetQuicklookManager];
}

- (IBAction)chooseHeaderFontSize:(id)sender 
{
	[self savePreferenceKey:@"headerFontSize" withValue:[headerFontSizePopup titleOfSelectedItem]];
	[self resetQuicklookManager];
}

- (IBAction)choosePreviewColorMode:(id)sender 
{
	NSString *colorMode = [NSString stringWithString:[previewColorModePopup titleOfSelectedItem]];
	[self savePreferenceKey:@"previewImageColorMode" withValue:colorMode];
	[previewColorModeMessage setStringValue:[stateDico valueForKey:colorMode]];
	[self resetQuicklookManager];
}

- (IBAction)chooseThumbnailColorMode:(id)sender 
{
	NSString *colorMode = [NSString stringWithString:[thumbnailColorModePopup titleOfSelectedItem]];
	[self savePreferenceKey:@"thumbnailImageColorMode" withValue:colorMode];
	[thumbnailColorModeMessage setStringValue:[stateDico valueForKey:colorMode]];
	[self resetQuicklookManager];
}

- (IBAction)resetToDefaultValues:(id)sender 
{
	[self savePreferenceKey:@"showQuickSummary" withValue:DEFAULT_SHOWQUICKSUMMARY];
	[quickSummaryCheckbox setState:[[stateDico valueForKey:DEFAULT_SHOWQUICKSUMMARY] boolValue]];
	
	[self savePreferenceKey:@"showESOLinks" withValue:DEFAULT_SHOWESOLINKS];
	[esoLinksCheckbox setState:[[stateDico valueForKey:DEFAULT_SHOWESOLINKS] boolValue]];
	
	[self savePreferenceKey:@"defaultHeightForHeaderFrame" withValue:DEFAULT_HEADERHEIGHT];
	[headerHeightPopup selectItemWithTitle:DEFAULT_HEADERHEIGHT];

	[self savePreferenceKey:@"headerFontSize" withValue:DEFAULT_HEADERFONTSIZE];
	[headerFontSizePopup selectItemWithTitle:DEFAULT_HEADERFONTSIZE];
	
	[self savePreferenceKey:@"appearanceStyleName" withValue:DEFAULT_APPEARANCESTYLE];
	[stylesPopup selectItemWithTitle:DEFAULT_APPEARANCESTYLE];
	
	[self savePreferenceKey:@"previewImageColorMode" withValue:DEFAULT_IMAGECOLORMODE];;
	[previewColorModePopup selectItemWithTitle:DEFAULT_IMAGECOLORMODE];
	[previewColorModeMessage setStringValue:[stateDico valueForKey:DEFAULT_IMAGECOLORMODE]];	
	
	[self savePreferenceKey:@"thumbnailImageColorMode" withValue:DEFAULT_IMAGECOLORMODE];;
	[thumbnailColorModePopup selectItemWithTitle:DEFAULT_IMAGECOLORMODE];
	[thumbnailColorModeMessage setStringValue:[stateDico valueForKey:DEFAULT_IMAGECOLORMODE]];	

	[self resetQuicklookManager];
}

- (IBAction)openjQueryURL:(id)sender 
{
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSURL *url = [NSURL URLWithString:@"http://jqueryui.com/themeroller/#themeGallery"];
	[ws openURL:url];
}

- (IBAction)openSoftTenebrasLuxURL:(id)sender 
{
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSURL *url = [NSURL URLWithString:@"http://www.softtenebraslux.com"];
	[ws openURL:url];
}

@end
