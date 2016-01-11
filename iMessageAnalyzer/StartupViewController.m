//
//  StartupViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 1/10/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "StartupViewController.h"

@interface StartupViewController ()

#pragma mark UI Elements

@property (strong) IBOutlet NSTextField *sourceCodeTextField;
@property (strong) IBOutlet NSTextField *emailTextField;
@property (strong) IBOutlet NSTextField *descriptionTextField;
@property (strong) IBOutlet NSButton *continueButton;

#pragma mark Private variables

@property (strong, nonatomic) NSDictionary *fontAttributes;

@end

@implementation StartupViewController


/****************************************************************
 *
 *              Constructor
 *
*****************************************************************/

# pragma mark Constructor

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        NSFont *systemFont = [NSFont systemFontOfSize:13.0f];
        NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
        paragraphStyle.alignment = NSTextAlignmentRight;
        self.fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:systemFont, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setWantsLayer:YES];
    [self.view.layer setBackgroundColor:[[NSColor whiteColor] CGColor]];
    
    [self.descriptionTextField setSelectable:YES];
    [self.descriptionTextField setAttributedStringValue:[self getDescriptionString]];
    
    [self.emailTextField setSelectable:YES];
    [self.emailTextField setAttributedStringValue:[self getEmailTextFieldAsString]];
    
    [self.sourceCodeTextField setSelectable:YES];
    [self.sourceCodeTextField setAttributedStringValue:[self getSourceCodeString]];
    
    [[self.view window] setDefaultButtonCell:[self.continueButton cell]];
    [self.continueButton setBezelStyle:NSRoundedBezelStyle];
}


/****************************************************************
 *
 *              Auxillary methods
 *
*****************************************************************/

# pragma mark Auxillary methods

- (NSMutableAttributedString*) getEmailTextFieldAsString
{
    NSString *text = @"dsouzarc@gmail.com";
    NSString *link = @"mailto:dsouzarc@gmail.com";
    
    NSMutableAttributedString *attributedCode = [[NSMutableAttributedString alloc] initWithString:text attributes:self.fontAttributes];
    [self linkifyAttributedString:attributedCode linkValue:link range:NSMakeRange(0, text.length)];
    return attributedCode;
}

- (NSMutableAttributedString*) getSourceCodeString
{
    NSString *text = @"github.com/dsouzarc";
    NSString *link = @"https://github.com/dsouzarc/iMessageAnalyzer";
    
    NSMutableAttributedString *attributedCode = [[NSMutableAttributedString alloc] initWithString:text attributes:self.fontAttributes];
    [self linkifyAttributedString:attributedCode linkValue:link range:NSMakeRange(0, text.length)];
    
    return attributedCode;
}

- (NSMutableAttributedString*) getDescriptionString
{
    NSMutableString *description = [[NSMutableString alloc] initWithString:@""];
    [description appendString:@"Analyzes a user's iMessages and texts to understand a user and their friends' messaging habits.\n\n"];
    [description appendString:@"Graphs data like messages over time, and computes other statistics like word frequencies\n\n"];
    [description appendString:@"All calculations are done locally; no information is transmitted over the Internet.\n\n"];
    [description appendString:@"Also adds some unique functionality from Messages.app to provide a better experience, including a refined search for messages.\n\n"];
    [description appendString:@"A full description can be found on this page."];
    
    NSMutableAttributedString *attributedDescription = [[NSMutableAttributedString alloc] initWithString:description attributes:self.fontAttributes];
    NSRange urlRange = [description rangeOfString:@"this page."];
    NSString *linkValue = @"https://github.com/dsouzarc/iMessageAnalyzer#analyzes-a-users-imessages-while-providing-cool-functionality";
    [self linkifyAttributedString:attributedDescription linkValue:linkValue range:urlRange];
    
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    [attributedDescription addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, attributedDescription.length)];
    
    return attributedDescription;
}

- (void) linkifyAttributedString:(NSMutableAttributedString*)attributedString linkValue:(NSString*)linkValue range:(NSRange)range
{
    [attributedString addAttribute:NSLinkAttributeName value:linkValue range:range];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    [attributedString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:range];
}

/****************************************************************
 *
 *              Button clicks
 *
*****************************************************************/

# pragma mark Button clicks

- (IBAction)continueButton:(id)sender {
    [self.delegate didWishToContinue];
}

- (IBAction)exitButton:(id)sender {
    [self.delegate didWishToExit];
}

@end