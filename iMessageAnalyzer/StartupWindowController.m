//
//  StartupWindowController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 1/10/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "StartupWindowController.h"

@interface StartupWindowController ()

@property (strong, nonatomic) MainWindowController *mainWindowController;
@property (strong, nonatomic) StartupViewController *startupViewController;

@end

@implementation StartupWindowController

- (instancetype) initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    
    if(self) {
        self.startupViewController = [[StartupViewController alloc] initWithNibName:@"StartupViewController" bundle:[NSBundle mainBundle]];
    }
    
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self.window setShowsResizeIndicator:NO];
    [self.window setTitle:@"iMessage Analyzer"];
    [self.window setBackgroundColor:[NSColor whiteColor]];
    
    [self.startupViewController setDelegate:self];
    [self.window setContentViewController:self.startupViewController];
}

- (NSSize) windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    return self.window.frame.size;
}

- (void) didWishToExit
{
    [NSApp terminate:self];
}

- (void) didWishToContinue
{
    NSString *messagesPath = [NSString stringWithFormat:@"/Users/%@/Library/Messages", NSUserName()];
    NSString *iPhonePath = [NSString stringWithFormat:@"/Users/%@/Library/Application Support/MobileSync/Backup", NSUserName()];
    
    NSString *description = [NSString stringWithFormat:@"Choose the source from which to analyze your messages:\n\nThe default Mac Messages.app: %@\n\nThe most recent iPhone backup: %@\n", messagesPath, iPhonePath];
    
    NSAlert *prompt = [[NSAlert alloc] init];
    [prompt setAlertStyle:NSWarningAlertStyle];
    [prompt setMessageText:@"Choose Messages database source"];
    [prompt setInformativeText:description];
    [prompt addButtonWithTitle:@"Messages.app"];
    [prompt addButtonWithTitle:@"iPhone backup"];
    
    [prompt beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response) {
        switch (response) {
            case NSAlertFirstButtonReturn:
                NSLog(@"MESSAGES");
                break;
            case NSAlertSecondButtonReturn:
                NSLog(@"iPHONE");
                break;
            default:
                break;
        }
    }];
}



- (void) mainWindow
{
    self.mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController"];
    [self.mainWindowController showWindow:self];
    [self.mainWindowController.window makeKeyAndOrderFront:self];
}

@end
