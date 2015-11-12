//
//  ChatTableViewCell.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/28/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ChatTableViewCell : NSTableCellView

@property (strong) IBOutlet NSTextField *contactName;
@property (strong) IBOutlet NSImageView *contactPhoto;
@property (strong) IBOutlet NSTextField *contactNumber;

@property (strong) IBOutlet NSTextField *lastMessagedOn;

@end