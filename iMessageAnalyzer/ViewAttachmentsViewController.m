//
//  ViewAttachmentsViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/22/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "ViewAttachmentsViewController.h"

@interface ViewAttachmentsViewController ()

@property (strong) IBOutlet NSTableView *mainTableView;

@property (strong, nonatomic) NSMutableArray *attachments;
@property (strong, nonatomic) NSMutableArray *objectsToShow;

@property (nonatomic) NSSize defaultSize;

@end

@implementation ViewAttachmentsViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil attachments:(NSMutableArray *)attachments
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    self.attachments = attachments;
    self.views = [[NSMutableArray alloc] init];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.defaultSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 20);
    
    if(self.attachments.count == 1) {
        [self.mainTableView.enclosingScrollView setHasVerticalScroller:NO];
    }
    
    NSSize defaultSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 20);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        
        int counter = 0;
        
        for(Attachment *attachment in self.attachments) {
            NSString *type = attachment.fileType;
            NSURL *filePath = [NSURL fileURLWithPath:attachment.filePath];
            
            NSLog(@"Here: %@\t%@", type, attachment.filePath);
            NSError *error;
            
            if([type containsString:@"image/"]) {
                NSImage *image = [[NSImage alloc] initWithContentsOfFile:attachment.filePath];
                [self.objectsToShow addObject:image];
            }
            
            else if([type containsString:@"/pdf"]) {
                PDFDocument *document = [[PDFDocument alloc] initWithURL:filePath];
                PDFView *view = [[PDFView alloc] init];
                [view setFrameSize:defaultSize];
                [view setDocument:document];
                [self.views addObject:view];
            }
            
            else if([type containsString:@"video/"]) {
                
                NSView *view = [[NSView alloc] init];
                [view setFrameSize:self.view.frame.size];
                [view setFrameOrigin:CGPointMake(0, 0)];
                [self.views addObject:view];
                
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
                NSButton *button = [[NSButton alloc] init];
                [button.cell setStringValue:[NSString stringWithFormat:@"Open %@", attachment.fileName]];
                [button setTag:counter];
                [button setFrameSize:defaultSize];
                [self.views addObject:button];
            }
            counter++;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.mainTableView reloadData];
        });
        
    });
    
}
- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.views.count;
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return nil;
}

- (CGFloat) tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return self.defaultSize;
}

- (NSView*) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSObject *object = self.views[row];
    NSView *view;
    
    if([self.objectsToShow[row] isKindOfClass:[NSImage class]]) {
        NSImageView *imageView = [[NSImageView alloc] init];
        [imageView setFrameSize:defaultSize];
        imageView.animates = YES;
        imageView.canDrawSubviewsIntoLayer = YES;
        imageView.wantsLayer = YES;
        [imageView setImage:image];
        [self.views addObject:imageView];
    }
    
    NSView *view = self.views[row];
    
    [view setWantsLayer:YES];
    [view.layer setBackgroundColor:[NSColor whiteColor].CGColor];
    
    Attachment *attachment = self.attachments[row];
    
    if([attachment.fileType containsString:@"video/"]) {

        AVPlayer *player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:attachment.filePath]];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
        [playerLayer setFrame:view.frame];
        [playerLayer setBackgroundColor:[NSColor whiteColor].CGColor];
        
        [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        [self.view.layer addSublayer:playerLayer];
        [player play];
    }
    
    return view;
}


@end
