//
//  MainWindowController.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/27/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MainViewController.h"

@interface MainWindowController : NSWindowController <NSWindowDelegate>

- (instancetype) initWithWindowNibName:(NSString *)windowNibName databasePath:(NSString *)databasePath;

@end