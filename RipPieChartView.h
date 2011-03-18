//
//  RipPieChartView.h
//  RipPieChart
//
//  Created by Slava Karpenko on 11/23/08.
//  Copyright 2008 Ripdev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RipPieChartSlice	: NSObject
{
	double	percent;
	UIColor* color;
}

@property (nonatomic, assign) double percent;
@property (nonatomic, retain) UIColor* color;

+ (RipPieChartSlice*)sliceWithPercent:(double)p color:(UIColor*)c;

@end


@interface RipPieChartView : UIView {
	NSMutableArray*		slices;
	UIImage* overlayImage;
}

@property (nonatomic, retain) NSMutableArray* slices;

@end
