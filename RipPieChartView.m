//
//  RipPieChartView.m
//  RipPieChart
//
//  Created by Slava Karpenko on 11/23/08.
//  Copyright 2008 Ripdev. All rights reserved.
//

#import "RipPieChartView.h"

@implementation RipPieChartSlice

@synthesize percent;
@synthesize color;

+ (RipPieChartSlice*)sliceWithPercent:(double)p color:(UIColor*)c
{
	RipPieChartSlice* slice = [[RipPieChartSlice alloc] init];
	
	slice.percent = p;
	slice.color = c;
	
	return [slice autorelease];
}

@end


@implementation RipPieChartView
@synthesize slices;

- (void)awakeFromNib
{
	if (!self.slices)
		self.slices = [NSMutableArray arrayWithCapacity:0];
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
		self.slices = [NSMutableArray arrayWithCapacity:0];
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	// init vars
	CGPoint center;
	CGFloat currentDegrees = 0.0;
	
	center.x = rect.origin.x + (rect.size.width / 2.);
	center.y = rect.origin.y + (rect.size.height / 2.);

	for (RipPieChartSlice* slice in self.slices)
	{
		CGMutablePathRef path = CGPathCreateMutable();
		CGFloat sliceDegrees = (M_PI * 2) - (slice.percent * (M_PI * 2));
		
		CGPathAddArc(path, NULL, center.x, center.y, rect.size.height/2, currentDegrees, (currentDegrees + sliceDegrees), YES);
		CGPathAddLineToPoint(path, NULL, center.x, center.y);
		CGPathCloseSubpath(path);
		currentDegrees += sliceDegrees;
		
		CGContextSaveGState(ctx);
		
		CGContextAddPath(ctx, path);
		CGContextSetFillColorWithColor(ctx, slice.color.CGColor);
		CGContextFillPath(ctx);
		
		CGContextRestoreGState(ctx);
		
		CGPathRelease(path);
	}
	
	// Draw a nice adornment
	if (!overlayImage)
		overlayImage = [[UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"RipPieChartOverlay" ofType:@"png"]] retain];
	
	if (overlayImage)
	{
		CGContextDrawImage(ctx, rect, overlayImage.CGImage);
	}
}


- (void)dealloc {
	self.slices = nil;
	[overlayImage release];
	
    [super dealloc];
}


@end
