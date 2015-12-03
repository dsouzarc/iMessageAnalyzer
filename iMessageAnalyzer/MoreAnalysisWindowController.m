//
//  MoreAnalysisWindowController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/14/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "MoreAnalysisWindowController.h"

@interface MoreAnalysisWindowController ()

@property (strong, nonatomic) MoreAnalysisViewController *moreAnalysisViewController;
@property (strong, nonatomic) TemporaryDatabaseManager *databaseManager;
@property (strong, nonatomic) NSString *windowTitle;

@end

@implementation MoreAnalysisWindowController

- (instancetype) initWithWindowNibName:(NSString *)windowNibName person:(Person *)person messages:(NSMutableArray *)messages
{
    self = [super initWithWindowNibName:windowNibName];
    
    if(self) {
        self.databaseManager = [TemporaryDatabaseManager getInstanceWithperson:person messages:messages];
        self.moreAnalysisViewController = [[MoreAnalysisViewController alloc] initWithNibName:@"MoreAnalysisViewController" bundle:[NSBundle mainBundle] person:person messages:messages databaseManager:self.databaseManager];
        self.windowTitle = [NSString stringWithFormat:@"Analysis for: %@", person.personName && person.personName.length != 0 ? person.personName : person.number];
        [self.window setContentViewController:self.moreAnalysisViewController];
        
        //CGFloat xPos = 300;
        //CGFloat yPos = 300;
        //[self.window setFrame:NSMakeRect(xPos, yPos, NSWidth([self.window frame]), NSHeight([self.window frame])) display:YES];

    }
    
    return self;
}

- (void) windowWillClose:(NSNotification *)notification
{
    [TemporaryDatabaseManager closeDatabase];
    self.databaseManager = nil;
    [self.delegate moreAnalysisWindowControllerDidClose];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    [self.window setShowsResizeIndicator:NO];
    [self.window setTitle:self.windowTitle];
}

- (NSSize) windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    return self.window.frame.size;
}

@end
