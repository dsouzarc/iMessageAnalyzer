//
//  MainWindowController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/27/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "MainWindowController.h"

@interface MainWindowController ()

@property (strong, nonatomic) MainViewController *mainViewController;

@end

@implementation MainWindowController

- (instancetype) initWithWindowNibName:(NSString *)windowNibName databasePath:(NSString *)databasePath
{
    self = [super initWithWindowNibName:windowNibName];
    
    if(self) {
        self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:[NSBundle mainBundle] databasePath:databasePath];
    }
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self.window setContentViewController:self.mainViewController];
    //[self.window setShowsResizeIndicator:NO];
    [self.window setTitle:@"iMessage Analyzer"];
}

/*- (NSSize) windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    return self.window.frame.size;
}*/

@end
