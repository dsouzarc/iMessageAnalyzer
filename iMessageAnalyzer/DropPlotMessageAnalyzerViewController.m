//
//  DropPlotMessageAnalyzerViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/25/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "DropPlotMessageAnalyzerViewController.h"

static NSString *mainPlotId = @"mainPlot";
static NSString *secondPlotId = @"secondPlot";

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

@property (nonatomic, readwrite, strong) NSArray<NSDictionary*> *mainDataPoints;

@property (nonatomic, readwrite, strong) CPTPlotSpaceAnnotation *zoomAnnotation;
@property (nonatomic, readwrite, assign) CGPoint dragStart;
@property (nonatomic, readwrite, assign) CGPoint dragEnd;

@property (strong, nonatomic) Constants *constants;
@property (strong, nonatomic) NSDate *startDate;
@property (strong, nonatomic) NSDate *endDate;

@property (strong, nonatomic) CPTPlotSpaceAnnotation *yValueAnnotation;

@property (nonatomic, readwrite, strong) CPTXYPlotSpace *mainPlot;
@property (strong, nonatomic) CPTXYPlotSpace *secondPlot;
@property (strong, nonatomic) NSArray<NSDictionary*> *secondDataPoints;


@end

@implementation DropPlotMessageAnalyzerViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil person:(Person *)person temporaryDatabase:(TemporaryDatabaseManager *)temporaryDatabase firstMessageDate:(NSDate *)firstMessage
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        self.messageManager = temporaryDatabase;
        self.person = person;

        self.constants = [Constants instance];

        self.isZoomedOut = YES;
        
        self.mainDataPoints = [[NSMutableArray alloc] init];
        self.zoomAnnotation = nil;
        self.dragStart = CGPointZero;
        self.dragEnd = CGPointZero;
        
        self.startDate = firstMessage;
        self.endDate = [NSDate date];
    }
    
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    NSDate *conversationStart = self.startDate;
    if([self.constants isBeginningOfMonth:conversationStart]) {
        conversationStart = [self.constants dateBySubtractingMonths:conversationStart months:1];
    }
    
    conversationStart = [self.constants dateAtBeginningOfMonth:self.startDate];
    NSDate *conversationEnd = [self.constants dateAtBeginningOfNextMonth:self.endDate];
    
    const int numMonths = [self.constants monthsBetweenDates:conversationStart endDate:conversationEnd];
    
    if(numMonths < 12) {
        int spacingMonths = 12 - numMonths;
        conversationStart = [self.constants dateBySubtractingMonths:conversationStart months:spacingMonths];
    }
    
    self.startDate = conversationStart;
    self.endDate = conversationEnd;
    
    const int numDays = [self.constants daysBetweenDates:self.startDate endDate:self.endDate];
    
    //NSLog(@"MONTHS: %d\tDAYS: %d", [self.constants monthsBetweenDates:self.startDate endDate:self.endDate], [self.constants daysBetweenDates:self.startDate endDate:self.endDate]);
    //NSLog(@"%@\t%@", [self.constants dayMonthYearString:self.startDate], [self.constants dayMonthYearString:self.endDate]);
    
    [self updateDataWithThisConversationMessages];
    
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.graphHostingView.frame];
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    [self.graphHostingView setHostedGraph:self.graph];
    
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
    
    self.mainPlot = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    self.secondPlot = [[CPTXYPlotSpace alloc] init];
    
    [self.mainPlot setIdentifier:mainPlotId];
    [self.secondPlot setIdentifier:secondPlotId];
    
    [self.mainPlot setXRange:[CPTPlotRange plotRangeWithLocation:@(0)
                                                          length:@(numDays)]];
    [self.secondPlot setXRange:self.mainPlot.xRange];
    
    [self.mainPlot setYRange:[CPTPlotRange plotRangeWithLocation:@(0)
                                                          length:@(self.totalMaximumYValue)]];
    [self.secondPlot setYRange:self.mainPlot.yRange];
    
    [self.mainPlot setAllowsUserInteraction:YES];
    [self.secondPlot setAllowsUserInteraction:YES];
    
    [self.mainPlot setDelegate:self];
    [self.secondPlot setDelegate:self];
    
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

-(BOOL) plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDraggedEvent:(id)event atPoint:(CGPoint)interactionPoint
{
    CPTPlotSpaceAnnotation *annotation = self.zoomAnnotation;
    
    if (annotation) {
        CPTPlotArea *plotArea = self.graph.plotAreaFrame.plotArea;
        CGRect plotBounds = plotArea.bounds;
        
        CGPoint dragStartInPlotArea = [self.graph convertPoint:self.dragStart toLayer:plotArea];
        CGPoint dragEndInPlotArea   = [self.graph convertPoint:interactionPoint toLayer:plotArea];
        
        CGFloat endX = MAX(MIN(dragEndInPlotArea.x, CGRectGetMaxX(plotBounds)), CGRectGetMinX(plotBounds));
        CGFloat endY = MAX(MIN(dragEndInPlotArea.y, CGRectGetMaxY(plotBounds)), CGRectGetMinY(plotBounds));
        CGRect borderRect = CGRectMake(dragStartInPlotArea.x, dragStartInPlotArea.y,
                                       (endX - dragStartInPlotArea.x),
                                       (endY - dragStartInPlotArea.y) );
        
        annotation.contentAnchorPoint = CGPointMake(dragEndInPlotArea.x >= dragStartInPlotArea.x ? 0.0 : 1.0,
                                                    dragEndInPlotArea.y >= dragStartInPlotArea.y ? 0.0 : 1.0);
        annotation.contentLayer.frame = borderRect;
    }
    
    return NO;
}

- (PlotType) getPlotType:(CPTPlot*)plot
{
    NSString *plotType = plot.plotSpace.identifier;
    
    if([plotType isEqualToString:mainPlotId]) {
        return mainPlot;
    }
    else if([plotType isEqualToString:secondPlotId]) {
        return secondPlot;
    }
    
    return noPlot;
}

- (NSUInteger) numberOfRecordsForPlot:(CPTPlot *)plot
{
    switch ([self getPlotType:plot]) {
        case mainPlot:
            NSLog(@"SIZE FOR FIRST: %ld", self.mainDataPoints.count);
            return self.mainDataPoints.count;
            break;
        case secondPlot:
            NSLog(@"SIZE FOR SECOND: %ld", self.secondDataPoints.count);
            return self.secondDataPoints.count;
        default:
            return 0;
    }
}

- (id) numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y");
    
    switch ([self getPlotType:plot]) {
        case mainPlot:
            return self.mainDataPoints[index][key];
            break;
        case secondPlot:
            return self.secondDataPoints[index][key];
        default:
            return 0;
            break;
    }
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
    
    NSDictionary *valueDict = nil;
    
    switch ([self getPlotType:plot]) {
        case mainPlot:
            valueDict = self.mainDataPoints[(int)idx];
            break;
        case secondPlot:
            valueDict = self.secondDataPoints[(int)idx];
            break;
        default:
            return nil;
            break;
    }
    
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
    
    //TODO: Show both values if they exist?
    NSString *yValue = nil;
    NSNumber *y = nil;
    
    switch ([self getPlotType:plot]) {
        case mainPlot:
            yValue = [self.mainDataPoints[idx][@"y"] stringValue];
            y = self.mainDataPoints[idx][@"y"];
            NSLog(@"CLICKED FIRST: %@\t%@", self.mainDataPoints[idx][@"x"], self.mainDataPoints[idx][@"y"]);
            break;
        case secondPlot:
            yValue = [self.secondDataPoints[idx][@"y"] stringValue];
            y = self.secondDataPoints[idx][@"y"];
            NSLog(@"CLICKED SECOND: %@\t%@", self.secondDataPoints[idx][@"x"], self.secondDataPoints[idx][@"y"]);
            break;
        default:
            NSLog(@"NIL IN plotSymbolWasSelectedAtRecordIndex");
            return;
            break;
    }

    
    NSNumber *x = [NSNumber numberWithInt:(int) idx];
    NSArray *anchorPoint = [NSArray arrayWithObjects:x, y, nil];
    
    CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:yValue style:hitAnnotationTextStyle];
    self.yValueAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:(CPTXYPlotSpace *)self.graph.defaultPlotSpace  anchorPlotPoint:anchorPoint];
    self.yValueAnnotation.contentLayer = textLayer;
    self.yValueAnnotation.displacement = CGPointMake(0.0f, 10.0f);
    [self.graph.plotAreaFrame.plotArea addAnnotation:self.yValueAnnotation];
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

- (CPTPlotRange*) plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate
{
    
    CPTPlotRange *updatedRange = nil;
    
    switch (coordinate) {
        case CPTCoordinateX:
            if (newRange.locationDouble < 0.0F) {
                CPTMutablePlotRange *mutableRange = [newRange mutableCopy];
                mutableRange.location = @(0.0f);
                updatedRange = mutableRange;
            }
            else {
                updatedRange = newRange;
            }
            break;
        case CPTCoordinateY:
            updatedRange = [CPTPlotRange plotRangeWithLocation:@(0) length:newRange.maxLimit];
            break;
        default:
            break;
    }
    return updatedRange;
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
    
    CPTPlotArea *plotArea = self.graph.plotAreaFrame.plotArea;
    
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
    double maxX = [self.constants daysBetweenDates:self.startDate endDate:self.endDate];
    
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

- (NSDictionary*) getMaxYAndPointsWithMessages:(NSMutableArray*)allMessages startTime:(int)startTime endTime:(int)endTime
{
    const CFTimeInterval methodStartTime = CACurrentMediaTime();
    
    const int timeInterval = 60 * 60 * 24;
    
    int counter = 0;
    int hour = 0;
    
    double maxY = 0;
    
    NSMutableArray<NSDictionary*> *newData = [[NSMutableArray alloc] init];
    
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
    
    NSLog(@"executionTime = %f", (CACurrentMediaTime() - methodStartTime));
    
    NSDictionary *results = [NSDictionary dictionaryWithObjectsAndKeys:newData, @"points",
                             [NSNumber numberWithDouble:maxY], @"maxY", nil];
    return results;
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
    
    const int endTime = (int)[self.endDate timeIntervalSinceReferenceDate];
    int startTime = (int) [self.startDate timeIntervalSinceReferenceDate];
    
    double minX = 0;
    double maxX = [self.constants daysBetweenDates:self.startDate endDate:self.endDate] * 60 * 60; //60 * 60 * 365;
    
    double minY = 0;
    
    NSDictionary *data = [self getMaxYAndPointsWithMessages:allMessages startTime:startTime endTime:endTime];
    NSMutableArray<NSDictionary*> *newData = [data objectForKey:@"points"];
    const double maxY = [[data objectForKey:@"maxY"] doubleValue];
    
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
    
    NSDate *date = [self.startDate copy];
    
    int months = [self.constants monthsBetweenDates:self.startDate endDate:self.endDate];
    
    double tickLocation = 0;
    double labelLocation = 0;

    for(int i = 0; i < months; i++) {
        
        //TODO: MORE SPECIFIC THAN 30
        int num = [self.constants daysInMonthForDate:date]; //3
        labelLocation += (num / 2.0);
        
        //NSLog(@"NUM %d FOR: %@", num, [self.constants dayMonthYearString:date]);
        [tickLocations addObject:@(tickLocation)]; //[NSNumber numberWithInt:num * i]];
        tickLocation += num;
        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[self.constants monthYearToString:date] textStyle:xAxis.labelTextStyle];
        label.tickLocation = @(labelLocation); //[NSNumber numberWithInt:num * i + (num / 2.0)];
        labelLocation += (num / 2.0);
        label.offset = 1.0f;
        label.rotation = 0;
        [tickLabels addObject:label];
        date = [self.constants dateByAddingMonths:date months:1];
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:tickLocations, @"tickLocations", tickLabels, @"tickLabels", nil];
}

- (NSDictionary*) getLabelsAndLocationsForStartDay:(int)startDay endDay:(int)endDay
{
    NSMutableArray *tickLocations = [[NSMutableArray alloc] init];
    NSMutableArray *tickLabels = [[NSMutableArray alloc] init];
    
    const int difference = endDay - startDay;
    
    int incrementAmount = 1;
    CGFloat rotation = M_PI / 7.5;
    
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    [textStyle setFontSize:14.0f];
    [textStyle setColor:[CPTColor colorWithCGColor:[[NSColor grayColor] CGColor]]];
    
    //If the range is a few days, can be normal
    if(difference <= 14) {
        incrementAmount = 1;
    }
    else {
        incrementAmount = difference / 12.0;
    }

    for(int i = 0, dateCounter = startDay; i < difference + 1; i += incrementAmount, dateCounter += incrementAmount) {
        
        NSDate *newDate = [self.constants dateByAddingDays:self.startDate days:dateCounter];
        
        [tickLocations addObject:[NSNumber numberWithInt:i + startDay]];
        
        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[self.constants dayMonthYearString:newDate] textStyle:textStyle];
        label.tickLocation = [NSNumber numberWithInt:i + startDay];
        label.offset = 1.0f;
        label.rotation = rotation;
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