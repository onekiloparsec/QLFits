//
//  PrefsController.h
//
//  Created by Cédric Foellmi on 25/09/09.
//
//  See excellent article in: http://www.cocoarocket.com/articles/sysprefpanes.html
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

#import <PreferencePanes/PreferencePanes.h>
#import "Constants.h"

@interface PrefsController : NSPreferencePane 
{
	IBOutlet NSButton		*quickSummaryCheckbox;
	IBOutlet NSButton		*esoLinksCheckbox;
	IBOutlet NSButton		*visitJQueryUIWebsite;
	IBOutlet NSButton		*checkForUpdateButton;
	IBOutlet NSPopUpButton	*stylesPopup;
	IBOutlet NSPopUpButton	*headerHeightPopup;
	IBOutlet NSPopUpButton	*headerFontSizePopup;
	IBOutlet NSPopUpButton	*previewColorModePopup;
	IBOutlet NSPopUpButton	*thumbnailColorModePopup;
	IBOutlet NSTextField	*versionMessage;
	IBOutlet NSTextField	*previewColorModeMessage;
	IBOutlet NSTextField	*thumbnailColorModeMessage;
	IBOutlet NSView			*spinView;
	NSDictionary			*stateDico;
	NSString				*currentVersion;
}

- (void) mainViewDidLoad;
//- (void) didUnselect;

- (IBAction)summaryCheckboxClicked:(id)sender;
- (IBAction)linksCheckboxClicked:(id)sender;
- (IBAction)resetToDefaultValues:(id)sender;
- (IBAction)chooseAppearanceStyle:(id)sender;
- (IBAction)chooseHeaderFrameHeight:(id)sender;
- (IBAction)chooseHeaderFontSize:(id)sender;
- (IBAction)choosePreviewColorMode:(id)sender;
- (IBAction)chooseThumbnailColorMode:(id)sender;
- (IBAction)openjQueryURL:(id)sender;
- (IBAction)openSoftTenebrasLuxURL:(id)sender;

@end
