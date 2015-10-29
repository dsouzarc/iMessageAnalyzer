//
//  MainViewController.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/27/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MessageManager.h"

#import "ChatTableViewCell.h"

#import "Contact.h"
#import "Message.h"
#import "Person.h"

@interface MainViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@end
