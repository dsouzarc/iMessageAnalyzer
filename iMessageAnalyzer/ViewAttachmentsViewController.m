//
//  ViewAttachmentsViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/22/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "ViewAttachmentsViewController.h"

@interface ViewAttachmentsViewController ()

#pragma mark Private variables

@property (strong) IBOutlet NSTableView *mainTableView;

@property (nonatomic) NSSize defaultSize;

@property (strong, nonatomic) NSMutableArray *attachments;
@property (strong, nonatomic) NSMutableArray *objectsToShow;

@end

@implementation ViewAttachmentsViewController


/****************************************************************
 *
 *              Constructor
 *
*****************************************************************/

# pragma mark Constructor

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil attachments:(NSMutableArray *)attachments
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    self.attachments = attachments;
    self.objectsToShow = [[NSMutableArray alloc] init];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.defaultSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 20);
    
    if(self.attachments.count == 1) {
        [self.mainTableView.enclosingScrollView setHasVerticalScroller:NO];
        [self.mainTableView.enclosingScrollView setHasHorizontalScroller:NO];
        
        if(![self isIdentifiableMedia:((Attachment*) self.attachments[0]).fileType]) {
            [self.view setFrameSize:CGSizeMake(self.view.bounds.size.width, 20)];
        }
        else {
            NSTextField *notGood = [[NSTextField alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height/2, self.view.bounds.size.width, 20)];
            [notGood setEditable:NO];
            [notGood setSelectable:NO];
            [notGood setStringValue:@"Unsupported attachment or attachment not found"];
            [self.view addSubview:notGood];
        }
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        for(Attachment *attachment in self.attachments) {
            NSString *type = attachment.fileType;
            NSURL *filePath = [NSURL fileURLWithPath:attachment.filePath];

            if([type containsString:@"image/"]) {
                NSImage *image = [[NSImage alloc] initWithContentsOfFile:attachment.filePath];
                if(image) {
                    [self.objectsToShow addObject:image];
                }
            }
            
            else if([type containsString:@"/pdf"]) {
                PDFDocument *document = [[PDFDocument alloc] initWithURL:filePath];
                if(document) {
                    [self.objectsToShow addObject:document];
                }
            }
            
            else if([type containsString:@"video/"]) {
                AVPlayer *player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:attachment.filePath]];
                
                if(player) {
                    [self.objectsToShow addObject:player];
                }
                
                /*QTMovie *movie = [[QTMovie alloc] initWithURL:filePath error:&error];
                
                if(error) {
                    NSLog(@"ERROR INITIALIZING MOVIE: %@", error);
                }
                else {
                    
                    [movie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieOpenAsyncOKAttribute];
                    [movie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieOpenAsyncRequiredAttribute];
                    
                    long currentState = [[movie attributeForKey:QTMovieLoadStateAttribute] longValue];
                    
                    while(currentState == QTMovieLoadStateLoading) {
                        currentState = [[movie attributeForKey:QTMovieLoadStateAttribute] longValue];
                    }
                    
                    QTMovieView *view = [[QTMovieView alloc] init];
                    [view setMovie:movie];
                    [movie autoplay];
                    [view setFrameSize:defaultSize];
                    
                    
                    while([((NSNumber*) [movie attributeForKey:QTMovieLoadStateAttribute]) longValue] < QTMovieLoadStatePlayable) {
                        //Do nothing
                    }
                    
                    [self.views addObject:view];

                }*/
            }
            else {
                [self.objectsToShow addObject:@"Unsupported attachment or attachment not found"];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.mainTableView reloadData];
        });
        
    });
}


/****************************************************************
 *
 *              NSTableView Data Source and Delegate
 *
*****************************************************************/

# pragma mark NSTableView Data Source and Delegate

- (CGFloat) tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    Attachment *attachment = self.attachments[row];
    
    if([self isIdentifiableMedia:attachment.fileType]) {
        return self.defaultSize.height;
    }
    
    return 20;
}

- (NSView*) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSObject *object = self.objectsToShow[row];
    Attachment *attachment = self.attachments[row];
    
    NSView *view = [[NSView alloc] init];
    [view setWantsLayer:YES];
    [view.layer setBackgroundColor:[NSColor whiteColor].CGColor];
    
    CGFloat buttonOrigin = 0.0;
    
    if([object isKindOfClass:[NSImage class]]) {
        NSImage *image = (NSImage*)self.objectsToShow[row];
        NSImageView *imageView = [[NSImageView alloc] init];
        [imageView setFrameSize:self.defaultSize];
        imageView.animates = YES;
        imageView.canDrawSubviewsIntoLayer = YES;
        imageView.wantsLayer = YES;
        [imageView setImage:image];
        [view addSubview:imageView];
        
        //buttonOrigin = imageView.frame.origin.y;
    }
    
    else if([object isKindOfClass:[PDFDocument class]]) {
        PDFView *pdfView = [[PDFView alloc] init];
        [pdfView setFrameSize:self.defaultSize];
        [pdfView setDocument:(PDFDocument*)object];
        [view addSubview:pdfView];
    }
    
    else if([object isKindOfClass:[AVPlayer class]]) {
        AVPlayer *player = (AVPlayer*) object;
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
        [playerLayer setFrame:CGRectMake(0, 0, self.defaultSize.width, self.defaultSize.height)];
        [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        [view.layer addSublayer:playerLayer];
        [player play];
    }
    
    else if([object isKindOfClass:[NSString class]]) {
        NSTextField *field = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
        [field setStringValue:[NSString stringWithFormat:@"%@", object]];
        [view addSubview:field];
    }
    
    NSButton *button = [[NSButton alloc] init];
    [button setTitle:[NSString stringWithFormat:@"Open %@", attachment.fileName]];
    [button setTag:row];
    [button setFrameSize:self.defaultSize];
    [button setWantsLayer:YES];
    [button.layer setBackgroundColor:[NSColor whiteColor].CGColor];
    [button setBordered:NO];

    if([self isIdentifiableMedia:attachment.fileType]) {
        [button setFrame:CGRectMake(0, buttonOrigin == 0.0 ? 0 : buttonOrigin, self.defaultSize.width, 20)];
    }
    else {
        [button setFrame:CGRectMake(0, 0, 0, 20)];
    }
    
    [button setTarget:self];
    [button setAction:@selector(openFileClick:)];
    [view addSubview:button];
    
    return view;
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.objectsToShow.count;
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return nil;
}


/****************************************************************
 *
 *              Auxillary Methods
 *
*****************************************************************/

# pragma mark Auxillary Methods

- (BOOL) isIdentifiableMedia:(NSString*)fileType
{
    return [fileType containsString:@"video"] || [fileType containsString:@"image"] || [fileType containsString:@"pdf"];
}

- (void) openFileClick:(NSButton*)button
{
    Attachment *attachment = self.attachments[button.tag];
    [[NSWorkspace sharedWorkspace] openFile:attachment.filePath];
}


@end