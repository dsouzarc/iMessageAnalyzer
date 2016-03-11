//
//  AppDelegate.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/1/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (strong, nonatomic) MainWindowController *mainWindowController;
@property (strong, nonatomic) StartupWindowController *startupWindowController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    if([Constants isDevelopmentMode]) {
        self.mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController" databasePath:pathToDevelopmentDB];
        [self.mainWindowController showWindow:self];
        [self.mainWindowController.window makeKeyAndOrderFront:self];
        
        return;
    }
    
    self.startupWindowController = [[StartupWindowController alloc] initWithWindowNibName:@"StartupWindowController"];
    [self.startupWindowController showWindow:self];
    [self.startupWindowController.window makeKeyAndOrderFront:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[DatabaseManager getInstance] deleteDatabase];
}

@end