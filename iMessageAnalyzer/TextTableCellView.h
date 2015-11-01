//
//  TextTableCellView.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/1/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TextTableCellView : NSTableCellView
@property (strong) IBOutlet NSTextField *rightSideTextField;
@property (strong) IBOutlet NSTextField *leftSideTextField;

@end
