//
//  AppDelegate.m
//  QLFitsConfig
//
//  Created by Cédric Foellmi on 08/04/15.
//  Copyright (c) 2015 onekiloparsec. All rights reserved.
//

#import "AppDelegate.h"

static NSString *suiteName = @"com.onekiloparsec.qlfitsconfig.user-defaults-suite";

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *label1;
@property (weak) IBOutlet NSTextField *label2;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self andSelector:@selector(handleAppleEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

    [[NSUserDefaults standardUserDefaults] addSuiteNamed:suiteName];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    
    NSString *optionsPath = [[NSBundle mainBundle] pathForResource:@"defaultOptions" ofType:@"plist"];
    NSDictionary *defaultOptions = [NSDictionary dictionaryWithContentsOfFile:optionsPath];
    [defaults registerDefaults:defaultOptions];
}

- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *URLString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    if (URLString) {
        NSURL *URL = [NSURL URLWithString:URLString];
        if (URL) {
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
