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
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];// 1
    [appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSURL *URL = [NSURL URLWithString:event.stringValue];
    for (NSString *component in [URL pathComponents]) {
        if ([component containsString:@"="]) {
            NSArray *keyValue = [component componentsSeparatedByString:@"="];
            [[NSUserDefaults standardUserDefaults] setObject:keyValue.firstObject forKey:keyValue.lastObject];
        }
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}
    
@end
