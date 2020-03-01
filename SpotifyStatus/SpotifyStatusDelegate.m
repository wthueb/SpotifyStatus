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
@property (nonatomic, strong) NSMenuItem* loginButton;

@end

@implementation SpotifyStatusDelegate

- (void)applicationDidFinishLaunching:(NSNotification* __unused)aNotification
{
    NSMenu* menu = [[NSMenu alloc] initWithTitle:@""];
    
    self.loginButton = [[NSMenuItem alloc] initWithTitle:@"launch at login" action:@selector(toggleLoginItem) keyEquivalent:@""];
    
    [menu addItem:self.loginButton];
    [menu addItemWithTitle:NSLocalizedString(@"quit", nil) action:@selector(quit) keyEquivalent:@"q"];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    [self.statusItem setMenu:menu];
    
    NSAppleEventDescriptor* spotifyEventDescriptor = [NSAppleEventDescriptor descriptorWithBundleIdentifier:@"com.spotify.client"];
    
    OSStatus status = AEDeterminePermissionToAutomateTarget(spotifyEventDescriptor.aeDesc, typeWildCard, typeWildCard, true);
    
    if (status != 0)
    {
        printf("not authorized to access spotify, quitting\n");
        
        [self quit];
    }
    
    printf("finished loading\n");
    
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setStatusItemTitle) userInfo:nil repeats:YES];
}

- (BOOL)isPlaying
{
    NSString* cmd = @"if application \"Spotify\" is running then tell application \"Spotify\" to get player state as text";
    
    NSString* playerState = [[self executeAppleScript:cmd] stringValue];
    
    if ([playerState isEqualToString:@"playing"])
        return YES;
    
    return NO;
}

- (void)setStatusItemTitle
{
    //printf("setting title...\n");
    NSString* baseCmd = @"if application \"Spotify\" is running then tell application \"Spotify\" to %@";
    
    NSString* trackName = [[self executeAppleScript:[NSString stringWithFormat:baseCmd, @"get name of current track"]] stringValue];
    NSString* artistName = [[self executeAppleScript:[NSString stringWithFormat:baseCmd, @"get artist of current track"]] stringValue];
    
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

- (BOOL)checkLoginItemEnabled
{
    NSString* cmd = @"tell application \"System Events\" to the name of every login item contains \"SpotifyStatus\"";
    
    return [[self executeAppleScript:cmd] booleanValue];
}

- (void)toggleLoginItem
{
    if ([self checkLoginItemEnabled])
    {
        NSString* cmd = @"tell application \"System Events\" to delete login item \"SpotifyStatus\"";
        
        [self executeAppleScript:cmd];
        
        [self.loginButton setEnabled:NO];
    }
    else
    {
        NSString* path = [[NSBundle mainBundle] bundlePath];
        
        NSString* cmd = [NSString stringWithFormat:@"tell application \"System Events\" to make new login item with properties {path:\"%@\", hidden:false}", path];
        
        [self executeAppleScript:cmd];
        
        [self.loginButton setEnabled:YES];
    }
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
    if ([item action] == @selector(toggleLoginItem))
    {
        if ([self checkLoginItemEnabled])
            [self.loginButton setState:NSControlStateValueOn];
        else
            [self.loginButton setState:NSControlStateValueOff];
    }
    
    return YES;
}

- (NSAppleEventDescriptor*)executeAppleScript:(NSString*)command
{
    NSAppleScript* appleScript = [[NSAppleScript alloc] initWithSource:command];
    
    NSAppleEventDescriptor* eventDescriptor = [appleScript executeAndReturnError:nil];
    
    return eventDescriptor;
}

- (void)quit
{
    [[NSApplication sharedApplication] terminate:self];
}

@end
