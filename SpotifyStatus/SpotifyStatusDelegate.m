//
//  AppDelegate.m
//  SpotifyStatus
//
//  Created by William Huebner on 2/27/20.
//  Copyright © 2020 William Huebner. All rights reserved.
//

#import "SpotifyStatusDelegate.h"

@interface SpotifyStatusDelegate ()

@property (nonatomic, strong) NSStatusItem* statusItem;

@end

@implementation SpotifyStatusDelegate

- (void)applicationDidFinishLaunching:(NSNotification* __unused)aNotification
{
    // hide dock icon
    [NSApp setActivationPolicy: NSApplicationActivationPolicyAccessory];
    
    NSMenu* menu = [[NSMenu alloc] initWithTitle:@""];
    
    [menu addItemWithTitle:NSLocalizedString(@"quit", nil) action:@selector(quit) keyEquivalent:@"q"];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    [self.statusItem setMenu:menu];
    
    OSStatus status;
    NSAppleEventDescriptor* targetAppEventDescriptor;
    
    targetAppEventDescriptor = [NSAppleEventDescriptor descriptorWithBundleIdentifier:@"com.spotify.client"];
    
    status = AEDeterminePermissionToAutomateTarget(targetAppEventDescriptor.aeDesc, typeWildCard, typeWildCard, true);
    
    if (status != 0)
    {
        printf("not authorized\n");
        
        [self quit];
    }

    printf("finished loading\n");
    
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setStatusItemTitle) userInfo:nil repeats:YES];
}

- (void)setStatusItemTitle
{
    //printf("setting title...\n");
    
    NSString* trackName = [[self executeAppleScript:@"get name of current track"] stringValue];
    NSString* artistName = [[self executeAppleScript:@"get artist of current track"] stringValue];
    
    //printf("track name: %s\n", [trackName UTF8String]);
    //printf("artist name: %s\n", [artistName UTF8String]);
    
    if (trackName && artistName && [self isPlaying])
    {
        NSString* titleText = [NSString stringWithFormat:@"%@ - %@", trackName, artistName];
        
        self.statusItem.button.image = nil;
        self.statusItem.button.title = titleText;
    }
    else
    {
        NSImage* image = [NSImage imageNamed:@"status_icon"];
        
        self.statusItem.button.image = image;
        self.statusItem.button.title = @"";
    }
}

- (NSAppleEventDescriptor*)executeAppleScript:(NSString*)command
{
    command = [NSString stringWithFormat:@"if application \"Spotify\" is running then tell application \"Spotify\" to %@", command];
    
    NSAppleScript* appleScript = [[NSAppleScript alloc] initWithSource:command];
    
    NSAppleEventDescriptor* eventDescriptor = [appleScript executeAndReturnError:nil];
    
    return eventDescriptor;
}

- (BOOL)isPlaying
{
    NSString* playerStateConstant = [[self executeAppleScript:@"get player state"] stringValue];
    
    if ([playerStateConstant isEqualToString:@"kPSP"])
        return YES;
    
    return NO;
}

- (void)quit
{
    [[NSApplication sharedApplication] terminate:self];
}

@end
