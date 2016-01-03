//
//  DropPlotMessageAnalyzerViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/25/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "DropPlotMessageAnalyzerViewController.h"

@interface DropPlotMessageAnalyzerViewController ()

@property (strong, nonatomic) TemporaryDatabaseManager *messageManager;
@property (strong, nonatomic) Person *person;

@property (strong) IBOutlet CPTGraphHostingView *graphHostingView;
@property (strong, nonatomic) CPTXYGraph *graph;

@property (nonatomic, readwrite, assign) double minimumValueForXAxis;
@property (nonatomic, readwrite, assign) double maximumValueForXAxis;
@property (nonatomic, readwrite, assign) double minimumValueForYAxis;
@property (nonatomic, readwrite, assign) double maximumValueForYAxis;
@property (nonatomic, readwrite, assign) double majorIntervalLengthForX;
@property (nonatomic, readwrite, assign) double majorIntervalLengthForY;

@property (nonatomic, readwrite, assign) double totalMaximumYValue;
@property BOOL isZoomedOut;

@property (nonatomic, readwrite, strong) NSArray<NSDictionary *> *mainDataPoints;

@property (nonatomic, readwrite, strong) CPTPlotSpaceAnnotation *zoomAnnotation;
@property (nonatomic, readwrite, strong) CPTPlotSpace *mainPlot;
@property (nonatomic, readwrite, assign) CGPoint dragStart;
@property (nonatomic, readwrite, assign) CGPoint dragEnd;

@property (strong, nonatomic) NSDate *startDate;
@property (strong, nonatomic) NSDate *endDate;
@property (strong, nonatomic) NSDateFormatter *monthDateYearFormatter;

@property (strong, nonatomic) CPTPlotSpaceAnnotation *yValueAnnotation;

@property (strong, nonatomic) NSCalendar *calendar;

@end

@implementation DropPlotMessageAnalyzerViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil person:(Person *)person temporaryDatabase:(TemporaryDatabaseManager *)temporaryDatabase firstMessageDate:(NSDate *)firstMessage
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        self.messageManager = temporaryDatabase;
        self.person = person;
        
        self.calendar = [NSCalendar currentCalendar];
        [self.calendar setTimeZone:[NSTimeZone systemTimeZone]];
        
        self.monthDateYearFormatter = [[NSDateFormatter alloc] init];
        [self.monthDateYearFormatter setDateFormat:@"MM/dd/yy"];
        self.isZoomedOut = YES;
        
        self.mainDataPoints = [[NSMutableArray alloc] init];
        self.zoomAnnotation = nil;
        self.dragStart = CGPointZero;
        self.dragEnd = CGPointZero;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateDataWithThisConversationMessages];
    
    CPTXYGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.graphHostingView.frame];
    [graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    self.graph = graph;
    self.graphHostingView.hostedGraph = self.graph;
    
    self.graph.paddingLeft = 0.0;
    self.graph.paddingTop = 0.0;
    self.graph.paddingRight = 0.0;
    self.graph.paddingBottom = 0.0;
    
    self.graph.plotAreaFrame.paddingLeft = 55.0;
    self.graph.plotAreaFrame.paddingTop = 40.0;
    self.graph.plotAreaFrame.paddingRight = 40.0;
    self.graph.plotAreaFrame.paddingBottom = 35.0;
    
    self.graph.plotAreaFrame.plotArea.fill = self.graph.plotAreaFrame.fill;
    self.graph.plotAreaFrame.fill = nil;
    
    self.graph.plotAreaFrame.borderLineStyle = nil;
    self.graph.plotAreaFrame.cornerRadius = 0.0;
    self.graph.plotAreaFrame.masksToBorder = NO;
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@(0)
                                                    length:@(366)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@(0)
                                                    length:@(self.totalMaximumYValue)];
    
    [plotSpace setDelegate:self];
    [plotSpace setAllowsUserInteraction:YES];
    
    // Create the main plot for the delimited data
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] initWithFrame:self.graph.bounds];
    dataSourceLinePlot.identifier = @"Data Source Plot";
    dataSourceLinePlot.delegate = self;
    
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth = 1.0;
    lineStyle.lineColor = [CPTColor whiteColor];
    dataSourceLinePlot.dataLineStyle = lineStyle;
    
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    [textStyle setFontSize:8.0f];
    [textStyle setColor:[CPTColor colorWithCGColor:[[NSColor grayColor] CGColor]]];
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    
    //Y AXIS
    CPTXYAxis *yAxis = axisSet.yAxis;
    yAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic; //CPTAxisLabelingPolicyNone;
    yAxis.labelingPolicy = CPTAxisLabelingPolicyFixedInterval;
    //yAxis.minorTicksPerInterval = 9;
    yAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    yAxis.majorIntervalLength = @([self getScale:(self.totalMaximumYValue)]);
    
    //X AXIS
    CPTXYAxis *xAxis = [axisSet xAxis];
    xAxis.labelingPolicy = CPTAxisLabelingPolicyNone;
    [xAxis setMajorIntervalLength:[NSNumber numberWithDouble:30.0]];
    [xAxis setMinorTickLineStyle:nil];
    [xAxis setLabelingPolicy:CPTAxisLabelingPolicyNone];
    [xAxis setLabelTextStyle:textStyle];
    [xAxis setLabelRotation:M_PI/6];
    
    NSDictionary *results = [self getTickLocationsAndLabelsForMonths];
    xAxis.majorTickLocations = results[@"tickLocations"];
    xAxis.axisLabels = results[@"tickLabels"];
    
    CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    plotSymbol.fill = [CPTFill fillWithColor:[CPTColor whiteColor]];
    plotSymbol.size = CGSizeMake(5.0, 5.0);
    dataSourceLinePlot.plotSymbol = plotSymbol;
    
    dataSourceLinePlot.dataSource = self;
    [self.graph addPlot:dataSourceLinePlot];
}

/****************************************************************
 *
 *              CPTPLOTDATASOURCE DELEGATE
 *
 *****************************************************************/

# pragma mark CPTPLOTDATASOURCE_DELEGATE

-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDraggedEvent:(id)event atPoint:(CGPoint)interactionPoint
{
    CPTPlotSpaceAnnotation *annotation = self.zoomAnnotation;
    
    if (annotation) {
        CPTPlotArea *plotArea = self.graph.plotAreaFrame.plotArea;
        CGRect plotBounds = plotArea.bounds;
        
        // convert the dragStart and dragEnd values to plot coordinates
        CGPoint dragStartInPlotArea = [self.graph convertPoint:self.dragStart toLayer:plotArea];
        CGPoint dragEndInPlotArea   = [self.graph convertPoint:interactionPoint toLayer:plotArea];
        
        // create the dragrect from dragStart to the current location
        CGFloat endX = MAX(MIN(dragEndInPlotArea.x, CGRectGetMaxX(plotBounds)), CGRectGetMinX(plotBounds));
        CGFloat endY = MAX(MIN(dragEndInPlotArea.y, CGRectGetMaxY(plotBounds)), CGRectGetMinY(plotBounds));
        CGRect borderRect = CGRectMake( dragStartInPlotArea.x, dragStartInPlotArea.y,
                                       (endX - dragStartInPlotArea.x),
                                       (endY - dragStartInPlotArea.y) );
        
        annotation.contentAnchorPoint = CGPointMake(dragEndInPlotArea.x >= dragStartInPlotArea.x ? 0.0 : 1.0,
                                                    dragEndInPlotArea.y >= dragStartInPlotArea.y ? 0.0 : 1.0);
        annotation.contentLayer.frame = borderRect;
    }
    
    return NO;
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    NSLog(@"SIZE: %ld", self.mainDataPoints.count);
    return self.mainDataPoints.count;
}

-(id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y");
    return self.mainDataPoints[index][key];
}

- (void) plotSpace:(CPTPlotSpace *)space didChangePlotRangeForCoordinate:(CPTCoordinate)coordinate
{
    //NSLog(@"CHANGED!!");
}

- (CPTLayer*) dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)idx
{
    if(self.isZoomedOut) {
        return nil;
    }
    
    NSDictionary *valueDict = self.mainDataPoints[(int)idx];
    CPTTextLayer *label = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%d", [valueDict[@"y"] intValue]]];
    CPTMutableTextStyle *textStyle = [label.textStyle mutableCopy];
    textStyle.color = [CPTColor yellowColor];
    label.textStyle = textStyle;
    return label;
}

- (void) scatterPlot:(CPTScatterPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)idx
{
    if(self.yValueAnnotation) {
        [self.graph.plotAreaFrame.plotArea removeAnnotation:self.yValueAnnotation];
        self.yValueAnnotation = nil;
    }
    
    CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
    hitAnnotationTextStyle.color = [CPTColor yellowColor];
    hitAnnotationTextStyle.fontSize = 16.0f;
    hitAnnotationTextStyle.fontName = @"Helvetica-Bold";
    
    NSString *yValue = [self.mainDataPoints[idx][@"y"] stringValue];
    NSNumber *x = [NSNumber numberWithInt:(int) idx];
    NSNumber *y = self.mainDataPoints[idx][@"y"];
    NSArray *anchorPoint = [NSArray arrayWithObjects:x, y, nil];
    
    CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:yValue style:hitAnnotationTextStyle];
    self.yValueAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:(CPTXYPlotSpace *)self.graph.defaultPlotSpace  anchorPlotPoint:anchorPoint];
    self.yValueAnnotation.contentLayer = textLayer;
    self.yValueAnnotation.displacement = CGPointMake(0.0f, 10.0f);
    [self.graph.plotAreaFrame.plotArea addAnnotation:self.yValueAnnotation];
    
    NSLog(@"CLICKED: %@\t%@", self.mainDataPoints[idx][@"x"], self.mainDataPoints[idx][@"y"]);
}


/****************************************************************
 *
 *              CPTPLOT DELEGATE
 *
 *****************************************************************/

# pragma mark CPTPLOT_DELEGATE

- (BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDownEvent:(id)event atPoint:(CGPoint)interactionPoint
{
    if (!self.zoomAnnotation) {
        self.dragStart = interactionPoint;
        
        CPTPlotArea *plotArea = self.graph.plotAreaFrame.plotArea;
        CGPoint dragStartInPlotArea = [self.graph convertPoint:self.dragStart toLayer:plotArea];
        
        if (CGRectContainsPoint(plotArea.bounds, dragStartInPlotArea)) {
            // create the zoom rectangle
            // first a bordered layer to draw the zoomrect
            CPTBorderedLayer *zoomRectangleLayer = [[CPTBorderedLayer alloc] initWithFrame:CGRectNull];
            
            CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
            lineStyle.lineColor = [CPTColor darkGrayColor];
            lineStyle.lineWidth = 1.0;
            zoomRectangleLayer.borderLineStyle = lineStyle;
            
            CPTColor *transparentFillColor = [[CPTColor blueColor] colorWithAlphaComponent:0.2];
            zoomRectangleLayer.fill = [CPTFill fillWithColor:transparentFillColor];
            
            double start[2];
            [self.graph.defaultPlotSpace doublePrecisionPlotPoint:start numberOfCoordinates:2 forPlotAreaViewPoint:dragStartInPlotArea];
            CPTNumberArray anchorPoint = @[@(start[CPTCoordinateX]),
                                           @(start[CPTCoordinateY])];
            
            // now create the annotation
            CPTPlotSpace *defaultSpace = self.graph.defaultPlotSpace;
            if (defaultSpace) {
                CPTPlotSpaceAnnotation *annotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:defaultSpace anchorPlotPoint:anchorPoint];
                annotation.contentLayer = zoomRectangleLayer;
                self.zoomAnnotation = annotation;
                
                [self.graph.plotAreaFrame.plotArea addAnnotation:annotation];
            }
        }
    }
    
    return NO;
}

- (BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceUpEvent:(id)event atPoint:(CGPoint)interactionPoint
{
    CPTPlotSpaceAnnotation *annotation = self.zoomAnnotation;
    
    if (annotation) {
        self.dragEnd = interactionPoint;
        
        // double-click to completely zoom out
        if ([event clickCount] == 2) {
            CPTPlotArea *plotArea = self.graph.plotAreaFrame.plotArea;
            CGPoint dragEndInPlotArea = [self.graph convertPoint:interactionPoint toLayer:plotArea];
            
            if (CGRectContainsPoint(plotArea.bounds, dragEndInPlotArea)) {
                [self zoomOut];
            }
        }
        else if (!CGPointEqualToPoint(self.dragStart, self.dragEnd)) {
            // no accidental drag, so zoom in
            [self zoomIn];
        }
        
        // and we're done with the drag
        [self.graph.plotAreaFrame.plotArea removeAnnotation:annotation];
        self.zoomAnnotation = nil;
        
        self.dragStart = CGPointZero;
        self.dragEnd = CGPointZero;
    }
    
    return NO;
}

- (BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceCancelledEvent:(id)event atPoint:(CGPoint)interactionPoint
{
    CPTPlotSpaceAnnotation *annotation = self.zoomAnnotation;
    
    if (annotation) {
        [self.graph.plotAreaFrame.plotArea removeAnnotation:annotation];
        self.zoomAnnotation = nil;
        self.dragStart = CGPointZero;
        self.dragEnd = CGPointZero;
    }
    
    return NO;
}


/****************************************************************
 *
 *              ZOOM METHODS
 *
 *****************************************************************/

# pragma mark ZOOM_METHODS

-(IBAction)zoomIn
{
    self.isZoomedOut = NO;
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    CPTPlotArea *plotArea     = self.graph.plotAreaFrame.plotArea;
    
    // convert the dragStart and dragEnd values to plot coordinates
    CGPoint dragStartInPlotArea = [self.graph convertPoint:self.dragStart toLayer:plotArea];
    CGPoint dragEndInPlotArea = [self.graph convertPoint:self.dragEnd toLayer:plotArea];
    
    double start[2], end[2];
    
    // obtain the mainDataPoints for the drag start and end
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
    axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    
    int startDay = (int) self.minimumValueForXAxis;
    int endDay = (int) self.maximumValueForXAxis;
    
    NSDictionary *results = [self getLabelsAndLocationsForStartDay:startDay endDay:endDay];
    axisSet.xAxis.majorTickLocations = results[@"tickLocations"];
    axisSet.xAxis.axisLabels = results[@"tickLabels"];
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyNone;
}

- (IBAction)zoomOut
{
    self.isZoomedOut = YES;
    if(self.yValueAnnotation) {
        [self.graph.plotAreaFrame.plotArea removeAnnotation:self.yValueAnnotation];
        self.yValueAnnotation = nil;
    }
    
    double minX = 0;
    double maxX = 366;
    
    double minY = 0;
    
    double intervalX = self.majorIntervalLengthForX;
    double intervalY = self.majorIntervalLengthForY;
    
    minX = floor(minX / intervalX) * intervalX;
    minY = floor(minY / intervalY) * intervalY;
    
    self.minimumValueForXAxis = minX;
    self.maximumValueForXAxis = maxX;
    self.minimumValueForYAxis = 0;
    
    // now adjust the plot range and axes
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@(0)
                                                    length:@(maxX)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@(0)
                                                    length:@(self.totalMaximumYValue)];
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    NSDictionary *results = [self getTickLocationsAndLabelsForMonths];
    axisSet.xAxis.majorTickLocations = results[@"tickLocations"];
    axisSet.xAxis.axisLabels = results[@"tickLabels"];
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyNone;
    
    axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic; //CPTAxisLabelingPolicyNone;
    axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyFixedInterval;
    axisSet.yAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    axisSet.yAxis.majorIntervalLength = @([self getScale:self.totalMaximumYValue]);
}


/****************************************************************
 *
 *              MISC METHODS
 *
 *****************************************************************/

# pragma mark MISC_METHODS

- (double) getMaxYAndUpdateDictionary:(NSMutableArray<NSDictionary*>**)data allMessages:(NSMutableArray*)allMessages startTime:(int)startTime endTime:(int)endTime
{
    NSDate *methodStart = [NSDate date];
    
    const int timeInterval = 60 * 60 * 24;
    
    int counter = 0;
    int hour = 0;
    
    double maxY = 0;
    
    NSMutableArray<NSDictionary*> *newData = *data;
    
    while(startTime < endTime && counter < allMessages.count) {
        Message *message = allMessages[counter];
        
        //Message occurs after time interval
        if([message.dateSent timeIntervalSinceReferenceDate] > (startTime + timeInterval)) {
            [newData addObject:@{@"x": @(hour), @"y": @(0)}];
        }
        else {
            int numMessages = 0;
            while([message.dateSent timeIntervalSinceReferenceDate] <= (startTime + timeInterval) && counter+1 < allMessages.count) {
                numMessages++;
                counter++;
                message = allMessages[counter];
            }
            
            [newData addObject:@{@"x": @(hour), @"y": @(numMessages)}];
            
            if(numMessages > maxY) {
                maxY = numMessages;
            }
        }
        
        hour++;
        startTime += timeInterval;
    }
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"executionTime = %f", executionTime);
    
    return maxY;
}

- (int) getScale:(int)maxY
{
    maxY = maxY * (11.0 / 10);
    
    int maxBigTicks = 10;
    
    int numMessagesRounded = maxY;
    
    //Round up to the nearest 10
    if(maxY <= 10) {
        return 1;
    }
    else if(maxY <= 20) {
        return 2;
    }
    if(maxY < 200) {
        numMessagesRounded = (10 * floor(maxY / 10 + 1));
    }
    
    //To the nearest 50
    else if(maxY < 1000) {
        numMessagesRounded = (50 * floor(maxY / 50 + 1));
    }
    
    //To the nearest 100
    else {
        numMessagesRounded = (100 * floor(maxY / 100 + 1));
    }
    
    return numMessagesRounded / maxBigTicks;
}

- (void) updateDataWithThisConversationMessages
{
    NSMutableArray *allMessages = [self.messageManager getAllMessagesForPerson:self.person];
    
    NSMutableArray<NSDictionary*> *newData = [[NSMutableArray alloc] init];
    
    const int endTime = (int) [[[Constants instance] getDateAtEndOfYear:[NSDate date]] timeIntervalSinceReferenceDate]; //(int) [[NSDate date] timeIntervalSinceReferenceDate];
    int startTime = (int) [[[Constants instance] getDateAtBeginningOfYear:[NSDate date]] timeIntervalSinceReferenceDate];
    
    double minX = 0;
    double maxX = 60 * 60 * 365;
    
    double minY = 0;
    const double maxY = [self getMaxYAndUpdateDictionary:&newData allMessages:allMessages startTime:startTime endTime:endTime];
    self.totalMaximumYValue = maxY * (11.0 /10);

    self.mainDataPoints = newData;
    
    self.minimumValueForXAxis = minX;
    self.maximumValueForXAxis = maxX;
    self.minimumValueForYAxis = minY;
    self.maximumValueForYAxis = self.totalMaximumYValue;
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@(0)
                                                    length:@(maxX)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@(0)
                                                    length:@(self.totalMaximumYValue)];
}

- (NSDictionary*) getTickLocationsAndLabelsForMonths
{
    CPTXYAxis *xAxis = [((CPTXYAxisSet *)self.graph.axisSet) xAxis];
    
    NSMutableArray *tickLocations = [[NSMutableArray alloc] init];
    NSMutableArray *tickLabels = [[NSMutableArray alloc] init];
    for(int i = 0; i < 12; i++) {
        [tickLocations addObject:[NSNumber numberWithInt:30 * i]];
        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[[Constants instance] MonthNameString:i] textStyle:xAxis.labelTextStyle];
        label.tickLocation = [NSNumber numberWithInt:30 * i + 15];
        label.offset = 1.0f;
        label.rotation = 0;
        [tickLabels addObject:label];
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:tickLocations, @"tickLocations", tickLabels, @"tickLabels", nil];
}

- (NSDictionary*) getLabelsAndLocationsForStartDay:(int)startDay endDay:(int)endDay
{
    CPTXYAxis *xAxis = [((CPTXYAxisSet *)self.graph.axisSet) xAxis];
    
    NSMutableArray *tickLocations = [[NSMutableArray alloc] init];
    NSMutableArray *tickLabels = [[NSMutableArray alloc] init];
    
    const int difference = endDay - startDay;
    
    for(int i = 0; i < difference + 1; i++) {
        [tickLocations addObject:[NSNumber numberWithInt:i + startDay]];
        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[[Constants instance] stringForDateAfterStart:(startDay + i + 1)] textStyle:xAxis.labelTextStyle];
        label.tickLocation = [NSNumber numberWithInt:i + startDay];
        label.offset = 1.0f;
        label.rotation = M_PI/3.5f;
        [tickLabels addObject:label];
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:tickLocations, @"tickLocations", tickLabels, @"tickLabels", nil];
}


/****************************************************************
 *
 *              EXPORTING METHODS
 *
 *****************************************************************/

# pragma mark EXPORT_METHODS

-(IBAction)exportToPDF:(id)sender
{
    NSSavePanel *pdfSavingDialog = [NSSavePanel savePanel];
    
    [pdfSavingDialog setAllowedFileTypes:@[@"pdf"]];
    
    if (pdfSavingDialog.runModal == NSModalResponseOK ) {
        NSData *dataForPDF = [self.graph dataForPDFRepresentationOfLayer];
        NSURL *url = [pdfSavingDialog URL];
        if (url) {
            [dataForPDF writeToURL:url atomically:NO];
        }
    }
}

-(IBAction)exportToPNG:(id)sender
{
    NSSavePanel *pngSavingDialog = [NSSavePanel savePanel];
    [pngSavingDialog setAllowedFileTypes:@[@"png"]];
    
    if (pngSavingDialog.modalPanel == NSModalResponseOK) {
        NSImage *image = [self.graph imageOfLayer];
        NSData *tiffData = [image TIFFRepresentation];
        NSBitmapImageRep *tiffRep = [NSBitmapImageRep imageRepWithData:tiffData];
        NSData *pngData = [tiffRep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
        
        NSURL *url = [pngSavingDialog URL];
        if (url) {
            [pngData writeToURL:url atomically:NO];
        }
    }
}

@end