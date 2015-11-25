//
//  DropPlotMessageAnalyzerViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/25/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "DropPlotMessageAnalyzerViewController.h"

@interface DropPlotMessageAnalyzerViewController ()

@property (strong, nonatomic) MessageManager *messageManager;
@property (strong, nonatomic) Person *person;

@property (strong) IBOutlet CPTGraphHostingView *graphHostingView;
@property (strong, nonatomic) CPTXYGraph *graph;

@property (nonatomic, readwrite, assign) double minimumValueForXAxis;
@property (nonatomic, readwrite, assign) double maximumValueForXAxis;
@property (nonatomic, readwrite, assign) double minimumValueForYAxis;
@property (nonatomic, readwrite, assign) double maximumValueForYAxis;
@property (nonatomic, readwrite, assign) double majorIntervalLengthForX;
@property (nonatomic, readwrite, assign) double majorIntervalLengthForY;
@property (nonatomic, readwrite, strong) NSArray<NSDictionary *> *dataPoints;

@property (nonatomic, readwrite, strong) CPTPlotSpaceAnnotation *zoomAnnotation;
@property (nonatomic, readwrite, assign) CGPoint dragStart;
@property (nonatomic, readwrite, assign) CGPoint dragEnd;

@end

@implementation DropPlotMessageAnalyzerViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil person:(Person *)person
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        self.person = person;
        self.messageManager = [MessageManager getInstance];
        
        self.dataPoints     = [[NSMutableArray alloc] init];
        self.zoomAnnotation = nil;
        self.dragStart      = CGPointZero;
        self.dragEnd        = CGPointZero;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CPTXYGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.graphHostingView.frame];
    [graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    self.graph = graph;
    self.graphHostingView.hostedGraph = self.graph;
    
    self.graph.paddingLeft   = 0.0;
    self.graph.paddingTop    = 0.0;
    self.graph.paddingRight  = 0.0;
    self.graph.paddingBottom = 0.0;
    
    self.graph.plotAreaFrame.paddingLeft   = 55.0;
    self.graph.plotAreaFrame.paddingTop    = 40.0;
    self.graph.plotAreaFrame.paddingRight  = 40.0;
    self.graph.plotAreaFrame.paddingBottom = 35.0;
    
    self.graph.plotAreaFrame.plotArea.fill = self.graph.plotAreaFrame.fill;
    self.graph.plotAreaFrame.fill          = nil;
    
    self.graph.plotAreaFrame.borderLineStyle = nil;
    self.graph.plotAreaFrame.cornerRadius    = 0.0;
    self.graph.plotAreaFrame.masksToBorder   = NO;
    
    // Setup plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@(30)
                                                    length:@(20)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@(30)
                                                    length:@(20)];
    
    // this allows the plot to respond to mouse events
    [plotSpace setDelegate:self];
    [plotSpace setAllowsUserInteraction:YES];
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    
    CPTXYAxis *x = axisSet.xAxis;
    x.minorTicksPerInterval = 9;
    x.majorIntervalLength   = @(self.majorIntervalLengthForX);
    x.labelOffset           = 5.0;
    x.axisConstraints       = [CPTConstraints constraintWithLowerOffset:0.0];
    
    CPTXYAxis *y = axisSet.yAxis;
    y.minorTicksPerInterval = 9;
    y.majorIntervalLength   = @(self.majorIntervalLengthForY);
    y.labelOffset           = 5.0;
    y.axisConstraints       = [CPTConstraints constraintWithLowerOffset:0.0];
    
    // Create the main plot for the delimited data
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] initWithFrame:self.graph.bounds];
    dataSourceLinePlot.identifier = @"Data Source Plot";
    
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth              = 1.0;
    lineStyle.lineColor              = [CPTColor whiteColor];
    dataSourceLinePlot.dataLineStyle = lineStyle;
    
    dataSourceLinePlot.dataSource = self;
    [self.graph addPlot:dataSourceLinePlot];
    
    NSError *error;
    [self readFromData:nil ofType:@"CSVDocument" error:&error];
    [self.graph reloadData];
    
}

-(NSData *)dataOfType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.
    
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    
    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.
    
    if ( outError != NULL ) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return nil;
}

-(BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    if ( [typeName isEqualToString:@"CSVDocument"] || 1 == 1 ) {
        double minX = MAXFLOAT;
        double maxX = -MAXFLOAT;
        
        double minY = MAXFLOAT;
        double maxY = -MAXFLOAT;
        
        NSMutableArray<NSDictionary *> *newData = [[NSMutableArray alloc] init];
        
        //NSString *fileContents = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        
        // Parse CSV
        //NSUInteger length    = fileContents.length;
        //NSUInteger lineStart = 0, lineEnd = 0, contentsEnd = 0;
        //NSRange currentRange;
        
        // Read headers from the first line of the file
        //[fileContents getParagraphStart:&lineStart end:&lineEnd contentsEnd:&contentsEnd forRange:NSMakeRange(lineEnd, 0)];
        //		currentRange = NSMakeRange(lineStart, contentsEnd - lineStart);
        //		CPTStringArray columnHeaders = [[fileContents substringWithRange:currentRange] arrayByParsingCSVLine];
        //		NSLog([columnHeaders objectAtIndex:0]);
        
        /*while ( lineEnd < length ) {
            [fileContents getParagraphStart:&lineStart end:&lineEnd contentsEnd:&contentsEnd forRange:NSMakeRange(lineEnd, 0)];
            currentRange = NSMakeRange(lineStart, contentsEnd - lineStart);
            CPTStringArray columnValues = [self getSomeData]; //[[fileContents substringWithRange:currentRange] arrayByParsingCSVLine];
            
            double xValue = [columnValues[0] doubleValue];
            double yValue = [columnValues[1] doubleValue];
            if ( xValue < minX ) {
                minX = xValue;
            }
            if ( xValue > maxX ) {
                maxX = xValue;
            }
            if ( yValue < minY ) {
                minY = yValue;
            }
            if ( yValue > maxY ) {
                maxY = yValue;
            }
            
        }*/
        
        CPTStringArray array = [self getSomeData];
        
        for(int i = 0; i < array.count - 1; i+=2) {
            int xValue = [array[i] intValue];
            int yValue = [array[i + 1] intValue];
            
            if ( xValue < minX ) {
                minX = xValue;
            }
            if ( xValue > maxX ) {
                maxX = xValue;
            }
            if ( yValue < minY ) {
                minY = yValue;
            }
            if ( yValue > maxY ) {
                maxY = yValue;
            }
            [newData addObject:@{ @"x": @(xValue),
                                  @"y": @(yValue) }
             ];
        }
        
        self.dataPoints = newData;
        
        double intervalX = (60 - 20) / 5.0;
        if ( intervalX > 0.0 ) {
            intervalX = pow( 10.0, ceil( log10(intervalX) ) );
        }
        self.majorIntervalLengthForX = intervalX;
        
        double intervalY = (60 - 30) / 10.0;
        if ( intervalY > 0.0 ) {
            intervalY = pow( 10.0, ceil( log10(intervalY) ) );
        }
        self.majorIntervalLengthForY = intervalY;
        
        minX = 20; //floor(minX / intervalX) * intervalX;
        minY = 20; //floor(minY / intervalY) * intervalY;
        
        self.minimumValueForXAxis = 30; //minX;
        self.maximumValueForXAxis = 70; //maxX;
        self.minimumValueForYAxis = 30; //minY;
        self.maximumValueForYAxis = 70; //maxY;
    }
    
    if ( outError != NULL ) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    
    return YES;
}

-(void)generateData
{
    /*if ( self.plotData == nil ) {
        NSMutableArray<NSDictionary *> *contentArray = [NSMutableArray array];
        for ( NSUInteger i = 0; i < 10; i++ ) {
            NSNumber *x = @(1.0 + i * 0.05);
            NSNumber *y = @(1.2 * arc4random() / (double)UINT32_MAX + 0.5);
            [contentArray addObject:@{ @"x": x, @"y": y }
             ];
        }
        self.plotData = contentArray;
    }*/
}


-(IBAction)zoomIn
{
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    CPTPlotArea *plotArea     = self.graph.plotAreaFrame.plotArea;
    
    // convert the dragStart and dragEnd values to plot coordinates
    CGPoint dragStartInPlotArea = [self.graph convertPoint:self.dragStart toLayer:plotArea];
    CGPoint dragEndInPlotArea   = [self.graph convertPoint:self.dragEnd toLayer:plotArea];
    
    double start[2], end[2];
    
    // obtain the datapoints for the drag start and end
    [plotSpace doublePrecisionPlotPoint:start numberOfCoordinates:2 forPlotAreaViewPoint:dragStartInPlotArea];
    [plotSpace doublePrecisionPlotPoint:end numberOfCoordinates:2 forPlotAreaViewPoint:dragEndInPlotArea];
    
    // recalculate the min and max values
    self.minimumValueForXAxis = MIN(start[CPTCoordinateX], end[CPTCoordinateX]);
    self.maximumValueForXAxis = MAX(start[CPTCoordinateX], end[CPTCoordinateX]);
    self.minimumValueForYAxis = MIN(start[CPTCoordinateY], end[CPTCoordinateY]);
    self.maximumValueForYAxis = MAX(start[CPTCoordinateY], end[CPTCoordinateY]);
    
    // now adjust the plot range and axes
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@(self.minimumValueForXAxis)
                                                    length:@(self.maximumValueForXAxis - self.minimumValueForXAxis)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@(self.minimumValueForYAxis)
                                                    length:@(self.maximumValueForYAxis - self.minimumValueForYAxis)];
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
}

- (CPTStringArray) getSomeData
{
    CPTMutableStringArray array = [NSMutableArray array];
    
    for(int i = 0; i < 10; i++) {
        
        int num = [self getRandomIntWithUpperbound:60 lowerBound:20];
        int num2 = [self getRandomIntWithUpperbound:60 lowerBound:30];
        
        [array addObject:[NSString stringWithFormat:@"%d", num]];
        [array addObject:[NSString stringWithFormat:@"%d", num2]];
        NSLog(@"%d\t%d", num, num2);
    }
    
    return array;
}

- (int) getRandomIntWithUpperbound:(int)upperbound lowerBound:(int)lowerBound
{
    return lowerBound + arc4random() % (upperbound - lowerBound);
}

-(IBAction)zoomOut
{
    double minX = MAXFLOAT;
    double maxX = -MAXFLOAT;
    
    double minY = MAXFLOAT;
    double maxY = -MAXFLOAT;
    
    // get the ful range min and max values
    for ( NSDictionary<NSString *, NSNumber *> *xyValues in self.dataPoints ) {
        double xVal = [xyValues[@"x"] doubleValue];
        
        minX = fmin(xVal, minX);
        maxX = fmax(xVal, maxX);
        
        double yVal = [xyValues[@"y"] doubleValue];
        
        minY = fmin(yVal, minY);
        maxY = fmax(yVal, maxY);
    }
    
    double intervalX = self.majorIntervalLengthForX;
    double intervalY = self.majorIntervalLengthForY;
    
    minX = floor(minX / intervalX) * intervalX;
    minY = floor(minY / intervalY) * intervalY;
    
    self.minimumValueForXAxis = minX;
    self.maximumValueForXAxis = maxX;
    self.minimumValueForYAxis = minY;
    self.maximumValueForYAxis = maxY;
    
    // now adjust the plot range and axes
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@(minX)
                                                    length:@(ceil( (maxX - minX) / intervalX ) * intervalX)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@(minY)
                                                    length:@(ceil( (maxY - minY) / intervalY ) * intervalY)];
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyFixedInterval;
    axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyFixedInterval;
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    NSLog(@"CALLED: %ld", self.dataPoints.count);
    return self.dataPoints.count;
}

-(id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y");
    NSLog(@"Also called");
    return self.dataPoints[index][key];
}

#pragma mark -
#pragma mark Plot Space Delegate Methods


-(IBAction)exportToPDF:(id)sender
{
    NSSavePanel *pdfSavingDialog = [NSSavePanel savePanel];
    
    [pdfSavingDialog setAllowedFileTypes:@[@"pdf"]];
    
    if ( [pdfSavingDialog runModal] == NSOKButton ) {
        NSData *dataForPDF = [self.graph dataForPDFRepresentationOfLayer];
        
        NSURL *url = [pdfSavingDialog URL];
        if ( url ) {
            [dataForPDF writeToURL:url atomically:NO];
        }
    }
}

-(IBAction)exportToPNG:(id)sender
{
    NSSavePanel *pngSavingDialog = [NSSavePanel savePanel];
    
    [pngSavingDialog setAllowedFileTypes:@[@"png"]];
    
    if ( [pngSavingDialog runModal] == NSOKButton ) {
        NSImage *image            = [self.graph imageOfLayer];
        NSData *tiffData          = [image TIFFRepresentation];
        NSBitmapImageRep *tiffRep = [NSBitmapImageRep imageRepWithData:tiffData];
        NSData *pngData           = [tiffRep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
        
        NSURL *url = [pngSavingDialog URL];
        if ( url ) {
            [pngData writeToURL:url atomically:NO];
        }
    }
}


#pragma mark -
#pragma mark Plot Space Delegate Methods

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDraggedEvent:(id)event atPoint:(CGPoint)interactionPoint
{
    
    NSLog(@"Yo here 4");
    CPTPlotSpaceAnnotation *annotation = self.zoomAnnotation;
    
    if ( annotation ) {
        CPTPlotArea *plotArea = self.graph.plotAreaFrame.plotArea;
        CGRect plotBounds     = plotArea.bounds;
        
        // convert the dragStart and dragEnd values to plot coordinates
        CGPoint dragStartInPlotArea = [self.graph convertPoint:self.dragStart toLayer:plotArea];
        CGPoint dragEndInPlotArea   = [self.graph convertPoint:interactionPoint toLayer:plotArea];
        
        // create the dragrect from dragStart to the current location
        CGFloat endX      = MAX( MIN( dragEndInPlotArea.x, CGRectGetMaxX(plotBounds) ), CGRectGetMinX(plotBounds) );
        CGFloat endY      = MAX( MIN( dragEndInPlotArea.y, CGRectGetMaxY(plotBounds) ), CGRectGetMinY(plotBounds) );
        CGRect borderRect = CGRectMake( dragStartInPlotArea.x, dragStartInPlotArea.y,
                                       (endX - dragStartInPlotArea.x),
                                       (endY - dragStartInPlotArea.y) );
        
        annotation.contentAnchorPoint = CGPointMake(dragEndInPlotArea.x >= dragStartInPlotArea.x ? 0.0 : 1.0,
                                                    dragEndInPlotArea.y >= dragStartInPlotArea.y ? 0.0 : 1.0);
        annotation.contentLayer.frame = borderRect;
    }
    
    return NO;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDownEvent:(id)event atPoint:(CGPoint)interactionPoint
{
    
    NSLog(@"Yo here 3");
    if ( !self.zoomAnnotation ) {
        self.dragStart = interactionPoint;
        
        CPTPlotArea *plotArea       = self.graph.plotAreaFrame.plotArea;
        CGPoint dragStartInPlotArea = [self.graph convertPoint:self.dragStart toLayer:plotArea];
        
        if ( CGRectContainsPoint(plotArea.bounds, dragStartInPlotArea) ) {
            // create the zoom rectangle
            // first a bordered layer to draw the zoomrect
            CPTBorderedLayer *zoomRectangleLayer = [[CPTBorderedLayer alloc] initWithFrame:CGRectNull];
            
            CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
            lineStyle.lineColor                = [CPTColor darkGrayColor];
            lineStyle.lineWidth                = 1.0;
            zoomRectangleLayer.borderLineStyle = lineStyle;
            
            CPTColor *transparentFillColor = [[CPTColor blueColor] colorWithAlphaComponent:0.2];
            zoomRectangleLayer.fill = [CPTFill fillWithColor:transparentFillColor];
            
            double start[2];
            [self.graph.defaultPlotSpace doublePrecisionPlotPoint:start numberOfCoordinates:2 forPlotAreaViewPoint:dragStartInPlotArea];
            CPTNumberArray anchorPoint = @[@(start[CPTCoordinateX]),
                                           @(start[CPTCoordinateY])];
            
            // now create the annotation
            CPTPlotSpace *defaultSpace = self.graph.defaultPlotSpace;
            if ( defaultSpace ) {
                CPTPlotSpaceAnnotation *annotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:defaultSpace anchorPlotPoint:anchorPoint];
                annotation.contentLayer = zoomRectangleLayer;
                self.zoomAnnotation     = annotation;
                
                [self.graph.plotAreaFrame.plotArea addAnnotation:annotation];
            }
        }
    }
    
    return NO;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceUpEvent:(id)event atPoint:(CGPoint)interactionPoint
{
    NSLog(@"Yo here 1");
    CPTPlotSpaceAnnotation *annotation = self.zoomAnnotation;
    
    if ( annotation ) {
        self.dragEnd = interactionPoint;
        
        // double-click to completely zoom out
        if ( [event clickCount] == 2 ) {
            CPTPlotArea *plotArea     = self.graph.plotAreaFrame.plotArea;
            CGPoint dragEndInPlotArea = [self.graph convertPoint:interactionPoint toLayer:plotArea];
            
            if ( CGRectContainsPoint(plotArea.bounds, dragEndInPlotArea) ) {
                [self zoomOut];
            }
        }
        else if ( !CGPointEqualToPoint(self.dragStart, self.dragEnd) ) {
            // no accidental drag, so zoom in
            [self zoomIn];
        }
        
        // and we're done with the drag
        [self.graph.plotAreaFrame.plotArea removeAnnotation:annotation];
        self.zoomAnnotation = nil;
        
        self.dragStart = CGPointZero;
        self.dragEnd   = CGPointZero;
    }
    
    return NO;
}

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceCancelledEvent:(id)event atPoint:(CGPoint)interactionPoint
{
    
    NSLog(@"Yo here 2");
    CPTPlotSpaceAnnotation *annotation = self.zoomAnnotation;
    
    if ( annotation ) {
        [self.graph.plotAreaFrame.plotArea removeAnnotation:annotation];
        self.zoomAnnotation = nil;
        
        self.dragStart = CGPointZero;
        self.dragEnd   = CGPointZero;
    }
    
    return NO;
}
@end
