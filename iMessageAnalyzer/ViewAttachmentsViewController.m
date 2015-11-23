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
    self.objectsToShow = [[NSMutableArray alloc] init];
    
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
                [self.objectsToShow addObject:document];
            }
            
            else if([type containsString:@"video/"]) {
                AVPlayer *player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:attachment.filePath]];
                [self.objectsToShow addObject:player];
                
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
                [self.objectsToShow addObject:[[NSObject alloc] init]];
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
    return self.objectsToShow.count;
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return nil;
}

- (CGFloat) tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return self.defaultSize.height;
}

- (NSView*) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSObject *object = self.objectsToShow[row];
    Attachment *attachment = self.attachments[row];
    
    NSView *view = [[NSView alloc] init];
    [view setWantsLayer:YES];
    [view.layer setBackgroundColor:[NSColor whiteColor].CGColor];
    
    if([object isKindOfClass:[NSImage class]]) {
        NSImageView *imageView = [[NSImageView alloc] init];
        [imageView setFrameSize:self.defaultSize];
        imageView.animates = YES;
        imageView.canDrawSubviewsIntoLayer = YES;
        imageView.wantsLayer = YES;
        [imageView setImage:(NSImage*)self.objectsToShow[row]];
        [view addSubview:imageView];
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
    
    else {
        NSButton *button = [[NSButton alloc] init];
        [button.cell setStringValue:[NSString stringWithFormat:@"Open %@", attachment.fileName]];
        //[button setTag:counter];
        [button setFrameSize:self.defaultSize];
        [view addSubview:button];
    }
    
    return view;
}


@end
