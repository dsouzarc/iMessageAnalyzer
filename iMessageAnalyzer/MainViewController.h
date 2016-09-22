//
//  MainViewController.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/27/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ChatTableViewCell.h"
#import "TextTableCellView.h"

#import "CalendarPopUpViewController.h"
#import "MoreAnalysisWindowController.h"
#import "ViewAttachmentsViewController.h"
#import "SimpleAnalyticsPopupViewController.h"

#import "NSTextField+Messages.h"

#import "MessageManager.h"

#import "Contact.h"
#import "Message.h"
#import "Attachment.h"
#import "Person.h"

#import "RSVerticallyCenteredTextFieldCell.h"
#import "ECPhoneNumberFormatter.h"

/** Shows all conversations and all messages. Central to everything */

@interface MainViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate, CalendarPopUpViewControllerDelegate, NSPopoverDelegate, SimpleAnalyticsPopUpViewControllerDelegate, MoreAnalysisWindowControllerDelegate, NSTextField_MessagesDelegate>

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil databasePath:(NSString*)databasePath;

@end