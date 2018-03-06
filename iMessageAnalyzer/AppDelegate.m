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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

    //Development mode and my local laptop (the development DB exists)
    if([Constants isDevelopmentMode] && [[NSFileManager defaultManager] fileExistsAtPath:pathToDevelopmentDB]) {
        self.mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController"
                                                                           databasePath:pathToDevelopmentDB];
        [self.mainWindowController showWindow:self];
        [self.mainWindowController.window makeKeyAndOrderFront:self];
    }
    
    //Some other developer's laptop
    else if([Constants isDevelopmentMode]) {
        NSOpenPanel *directoryPanel = [NSOpenPanel openPanel];
        [directoryPanel setCanChooseFiles:YES];
        [directoryPanel setShowsHiddenFiles:YES];
        [directoryPanel setCanSelectHiddenExtension:YES];
        [directoryPanel setCanCreateDirectories:NO];
        [directoryPanel setCanChooseDirectories:NO];
        [directoryPanel setAllowsMultipleSelection:NO];
        [directoryPanel setTreatsFilePackagesAsDirectories:NO];
        [directoryPanel setCanHide:NO];

        [directoryPanel setTitle:@"Development mode: choose the chat database"];
        [directoryPanel setMessage:@"Choose the SQLite chat database to analyze"];
        
        [directoryPanel beginWithCompletionHandler:^(NSInteger result) {
            
            if (result == NSFileHandlingPanelOKButton) {
                NSURL *dbPathURL = [[directoryPanel URLs] objectAtIndex:0];
                NSString *dbPathString = [dbPathURL path];
                
                self.mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController"
                                                                                   databasePath:dbPathString];
                [self.mainWindowController showWindow:self];
                [self.mainWindowController.window makeKeyAndOrderFront:self];
            }
            
            //If they pressed cancel or anything else, just show the main window
            else {
                self.startupWindowController = [[StartupWindowController alloc] initWithWindowNibName:@"StartupWindowController"];
                [self.startupWindowController showWindow:self];
                [self.startupWindowController.window makeKeyAndOrderFront:self];
            }
        }];
    }
    
    //Not in development mode
    else {
        self.startupWindowController = [[StartupWindowController alloc] initWithWindowNibName:@"StartupWindowController"];
        [self.startupWindowController showWindow:self];
        [self.startupWindowController.window makeKeyAndOrderFront:self];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [[DatabaseManager getInstance] deleteDatabase];
}

- (IBAction)exportConversationAsTextFile:(id)sender
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter postNotificationName:@"exportConversationAsTextFile" object:@"exportConversationAsTextFile"];
}

- (IBAction)exportConversationsAsCSV:(id)sender
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter postNotificationName:@"exportConversationAsCSV" object:@"exportConversationAsCSV"];
}

@end
