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
    [self.window setBackgroundColor:[NSColor whiteColor]];
    [self.window setContentViewController:self.startupViewController];
    [self.window setShowsResizeIndicator:NO];
    [self.window setTitle:@"iMessage Analyzer"];
}

- (NSSize) windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    return self.window.frame.size;
}

- (void) mainWindow
{
    self.mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController"];
    [self.mainWindowController showWindow:self];
    [self.mainWindowController.window makeKeyAndOrderFront:self];
}

@end
