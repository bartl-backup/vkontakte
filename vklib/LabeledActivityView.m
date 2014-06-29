//
//  LabeledActivityView.m
//  VKVideo
//
//  Created by Evgeny Rusanov on 11.07.12.
//  Copyright (c) 2012 Macsoftex. All rights reserved.
//

#import "LabeledActivityView.h"

@implementation LabeledActivityView
{
    UIActivityIndicatorView *activityView;
    UILabel *label;
}

@synthesize opacity;
@synthesize text = _text;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opacity = 0.8;
        
        activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:activityView];
        activityView.center = CGPointMake(floor(frame.size.width*0.5), floor(frame.size.height*0.5));
        [activityView startAnimating];
        
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor whiteColor];
        label.adjustsFontSizeToFitWidth = NO;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:label];
        
        self.backgroundColor = [UIColor clearColor];
        
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

-(void)setText:(NSString *)text_
{
    label.text = text_;
    [self setNeedsLayout];
    _text = text_;
}

- (void)layoutSubviews
{
    CGSize textSize = [self.text sizeWithFont:label.font];
    
    if (textSize.height>0.1)
    {
        CGPoint center = CGPointMake(self.bounds.size.width*0.5, self.bounds.size.height*0.5);;
        
        CGFloat allHeight = activityView.frame.size.height+textSize.height+10;
        activityView.center = CGPointMake(center.x, floor(center.y - (allHeight - activityView.frame.size.height)*0.5));
        label.frame = CGRectMake(0, 0, textSize.width, textSize.height);
        label.center = CGPointMake(center.x, floor(center.y + (allHeight - textSize.height)*0.5));
    }
    else
    {
        activityView.center = CGPointMake(self.bounds.size.width*0.5, self.bounds.size.height*0.5);
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

	CGFloat radius = 10.0f;
	CGContextBeginPath(context);
	CGContextSetGrayFillColor(context, 0.0f, self.opacity);
	CGContextMoveToPoint(context, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect));
	CGContextAddArc(context, CGRectGetMaxX(rect) - radius, CGRectGetMinY(rect) + radius, radius, 3 * (CGFloat)M_PI / 2, 0, 0);
	CGContextAddArc(context, CGRectGetMaxX(rect) - radius, CGRectGetMaxY(rect) - radius, radius, 0, (CGFloat)M_PI / 2, 0);
	CGContextAddArc(context, CGRectGetMinX(rect) + radius, CGRectGetMaxY(rect) - radius, radius, (CGFloat)M_PI / 2, (CGFloat)M_PI, 0);
	CGContextAddArc(context, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect) + radius, radius, (CGFloat)M_PI, 3 * (CGFloat)M_PI / 2, 0);
	CGContextClosePath(context);
	CGContextFillPath(context);
}

@end
