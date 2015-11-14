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

@property (strong, nonatomic) NSString *windowTitle;

@end

@implementation MoreAnalysisWindowController

- (instancetype) initWithWindowNibName:(NSString *)windowNibName person:(Person *)person messages:(NSMutableArray *)messages
{
    self = [super initWithWindowNibName:windowNibName];
    
    if(self) {
        self.moreAnalysisViewController = [[MoreAnalysisViewController alloc] initWithNibName:@"MoreAnalysisViewController" bundle:[NSBundle mainBundle] person:person messages:messages];
        self.windowTitle = [NSString stringWithFormat:@"Analysis for: %@", person.personName];
    }
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self.window setContentViewController:self.moreAnalysisViewController];
    
    [self.window setShowsResizeIndicator:NO];
    [self.window setTitle:self.windowTitle];
}

- (NSSize) windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    return self.window.frame.size;
}

@end
