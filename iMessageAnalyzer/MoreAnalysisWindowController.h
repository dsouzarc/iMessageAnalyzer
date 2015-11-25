//
//  MoreAnalysisWindowController.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/14/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MoreAnalysisViewController.h"
#import "TemporaryDatabaseManager.h"
#import "Person.h"

@interface MoreAnalysisWindowController : NSWindowController <NSWindowDelegate>

- (instancetype) initWithWindowNibName:(NSString *)windowNibName person:(Person*)person messages:(NSMutableArray*)messages;

@end
