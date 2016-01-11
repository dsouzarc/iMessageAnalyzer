//
//  StartupWindowController.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 1/10/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "StartupViewController.h"
#import "MainWindowController.h"

/** Controls the Startup Window and View --> Shows about me page and asks for data source */

@interface StartupWindowController : NSWindowController <NSWindowDelegate, StartupViewControllerDelegate>


@end