//
//  AppDelegate.m
//  QLFitsConfig
//
//  Created by Cédric Foellmi on 08/04/15.
//  Copyright (c) 2015 onekiloparsec. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *label1;
@property (weak) IBOutlet NSTextField *label2;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];// 1
    [appleEventManager setEventHandler:self andSelector:@selector(handleAppleEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    self.label1.stringValue = NSStringFromSelector(@selector(handleAppleEvent:withReplyEvent:));
    self.label2.stringValue = [NSString stringWithFormat:@"Respond to selector? %@", [self respondsToSelector:@selector(handleAppleEvent:withReplyEvent:)] ? @"YES" : @"NO"];
}

- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    self.label1.stringValue = ([[event paramDescriptorForKeyword:keyDirectObject] stringValue]) ?: @"(null)";
    self.label2.stringValue = @"(debug)";

    NSString *URLString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    if (URLString) {
        NSURL *URL = [NSURL URLWithString:URLString];
        if (URL) {
            static NSString *suiteName = @"com.onekiloparsec.qlfitsconfig.user-defaults-suite";
            [[NSUserDefaults standardUserDefaults] addSuiteNamed:suiteName];
            NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
            
            for (NSString *component in [URL pathComponents]) {
                if ([component containsString:@"="]) {
                    NSArray *keyValue = [component componentsSeparatedByString:@"="];
                    [defaults setObject:keyValue.lastObject forKey:keyValue.firstObject];
                }
            }
            
            [defaults synchronize];
        }
    }
}

@end
