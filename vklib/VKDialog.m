//
//  VKDialog.m
//  SovietPosters
//
//  Created by Evgeny Rusanau on 24.12.10.
//  Copyright 2010 Macsoftex. All rights reserved.
//

#import "VKDialog.h"

#import <QuartzCore/QuartzCore.h>

#import "LabeledActivityView.h"

static CGFloat kPadding = 0;
static CGFloat kBorderWidth_iphone = 0;
static CGFloat kBorderWidth_ipad = 10;
static CGFloat kTitleHeight = 0;
static CGFloat kCloseButtonWidth = 30;

static CGFloat kBORDER_RADIUS_iphone = 0.0;
static CGFloat kCONTENT_RADIUS_iphone = 0.0;
static CGFloat kBORDER_RADIUS_ipad = 6.0;
static CGFloat kCONTENT_RADIUS_ipad = 4.0;

#define TITLE_COLOR [UIColor blueColor]

@implementation VKDialog
{
    CGPoint oldOffset;
    
    LabeledActivityView *activityViewLabeled;
    
    UIInterfaceOrientation _orientation;
    
    UIView *_backgroundView;
    UIView *_border;
    UILabel *_titleLabel;
    
    UIWebView *_webview;
    
    NSString *_title;
    
    NSString *_url;
    
    id context;
}

-(id)initWithUrl:(NSString*)url
{
	if (self = [super init])
	{
		_url = url;
        _orientation = UIInterfaceOrientationPortrait;
	}
	
	return self;
}

- (void)showAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:_url]];
	[_webview loadRequest:request];
}

- (void)dissmissAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context_
{
	[_backgroundView removeFromSuperview];
    
    context = nil;
}

- (CGAffineTransform)transformForOrientation {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        return CGAffineTransformMakeRotation(M_PI*1.5);
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return CGAffineTransformMakeRotation(M_PI/2);
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGAffineTransformMakeRotation(-M_PI);
    } else {
        return CGAffineTransformIdentity;
    }
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (BOOL)shouldRotateToOrientation:(UIInterfaceOrientation)orientation {
    if (orientation == _orientation) {
        return NO;
    } else {
        return orientation == UIInterfaceOrientationLandscapeLeft
        || orientation == UIInterfaceOrientationLandscapeRight
        || orientation == UIInterfaceOrientationPortrait
        || orientation == UIInterfaceOrientationPortraitUpsideDown;
    }
}

-(void)sizeToFitOrientation
{
    _backgroundView.transform = CGAffineTransformIdentity;
    
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    CGRect frame = _backgroundView.superview.frame;
    CGPoint center = CGPointMake(frame.size.width*0.5, frame.size.height*0.5);;
    
    CGFloat width = floor(frame.size.width) - kPadding * 2;
    CGFloat height = floor(frame.size.height) - kPadding * 2;
    
    CGRect rect;
    
    _orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (UIInterfaceOrientationIsLandscape(_orientation)) {
        rect = CGRectMake(0, 
                          0, 
                          height, 
                          width - statusBarFrame.size.width);
        
        if (_orientation == UIInterfaceOrientationLandscapeLeft)
            center.x+=statusBarFrame.size.width*0.5;
        else
            center.x-=statusBarFrame.size.width*0.5;

    } else {
        rect = CGRectMake(0, 
                          0, 
                          width,
                          height - statusBarFrame.size.height);
        
        if (_orientation == UIInterfaceOrientationPortrait)
            center.y+=statusBarFrame.size.height*0.5;
        else
            center.y-=statusBarFrame.size.height*0.5;
    }
    
    _backgroundView.frame = rect;
    _backgroundView.center = center;
    _backgroundView.transform = [self transformForOrientation];
}

- (void)deviceOrientationDidChange:(void*)object {
    if ([self shouldRotateToOrientation:[UIApplication sharedApplication].statusBarOrientation])
    {
        CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
        [self sizeToFitOrientation];    
        [UIView commitAnimations];
        
        [self updateWebViewOrientation];
    }
}

-(void)show
{
	context = self;
    
	UIView *view;
    
    CGFloat kBorderWidth;
    CGFloat BORDER_RADIUS;
    CGFloat CONTENT_RADIUS;
    CGRect startRect;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        kBorderWidth = kBorderWidth_iphone;
        BORDER_RADIUS = kBORDER_RADIUS_iphone;
        CONTENT_RADIUS = kCONTENT_RADIUS_iphone;
        
        startRect = CGRectMake(0, 0, 100, 100);
    }
    else
    {
        kBorderWidth = kBorderWidth_ipad;
        BORDER_RADIUS = kBORDER_RADIUS_ipad;
        CONTENT_RADIUS = kCONTENT_RADIUS_ipad;
        
        startRect = CGRectMake(0, 0, 300, 400);
    }
        
    
    UIWindow* window = [UIApplication sharedApplication].keyWindow;
    if (!window) {
        window = [[UIApplication sharedApplication].windows objectAtIndex:0];
    }
    view = window;
    
    CGRect statusbarFrame = [UIApplication sharedApplication].statusBarFrame;
    CGRect backgroundFrame = view.frame;
    backgroundFrame.origin.y    = statusbarFrame.size.height;
    backgroundFrame.size.height-= statusbarFrame.size.height;
	
    

	_backgroundView = [[UIView alloc] initWithFrame:startRect];
	_backgroundView.backgroundColor = [UIColor clearColor];
	
	[view addSubview:_backgroundView];
    
    
	
	CGRect borderRect;
    borderRect = CGRectMake(0,
                            kPadding+kPadding*0.5,
                            _backgroundView.frame.size.width,
                            _backgroundView.frame.size.height-2*kPadding);
	
	_border = [[UIView alloc] initWithFrame:borderRect];
	_border.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.8];
	[_backgroundView addSubview:_border];
	_border.alpha = 0.0;
	[_border.layer setBorderColor: [[UIColor grayColor] CGColor]];
	[_border.layer setBorderWidth: 1.0];
	[_border.layer setCornerRadius:BORDER_RADIUS];
	[_border.layer setMasksToBounds:YES];
	_border.autoresizingMask = UIViewAutoresizingFlexibleWidth | 
                                UIViewAutoresizingFlexibleHeight
    ;
    
    
    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(showAnimationDidStop:finished:context:)];
	_border.alpha = 1.0;
	[UIView commitAnimations];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(kBorderWidth,
                                                                    kBorderWidth,
                                                                    _border.bounds.size.width - 2*kBorderWidth,
                                                                    _border.bounds.size.height - 2*kBorderWidth)];
    contentView.backgroundColor = [UIColor clearColor];
    contentView.layer.cornerRadius = CONTENT_RADIUS;
    contentView.clipsToBounds = YES;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_border addSubview:contentView];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 
															0, 
															contentView.bounds.size.width, 
															kTitleHeight)];
	_titleLabel.backgroundColor = TITLE_COLOR;
	_titleLabel.textColor = [UIColor whiteColor];
	_titleLabel.font = [UIFont boldSystemFontOfSize:14];
	_titleLabel.numberOfLines = 1;
	_titleLabel.adjustsFontSizeToFitWidth = NO;
	_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_titleLabel.text = _title;
	[contentView addSubview:_titleLabel];
    
    _webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 
														   kTitleHeight, 
														   contentView.bounds.size.width, 
														   contentView.bounds.size.height-kTitleHeight)];
	_webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_webview.delegate = self;
	[contentView addSubview:_webview];
    
    UIImage* closeImage = [UIImage imageNamed:@"VKDialog.bundle/images/close.png"];
	UIColor* color = [UIColor colorWithRed:167.0/255 green:184.0/255 blue:216.0/255 alpha:1];
    UIButton *_closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_closeButton setImage:closeImage forState:UIControlStateNormal];
    [_closeButton setTitleColor:color forState:UIControlStateNormal];
    [_closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [_closeButton addTarget:self action:@selector(cancel)
		   forControlEvents:UIControlEventTouchUpInside];
	_closeButton.frame = CGRectMake(contentView.bounds.size.width-kCloseButtonWidth,
									0,
									kCloseButtonWidth,
									kCloseButtonWidth);
	_closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	_closeButton.showsTouchWhenHighlighted = YES;
	[_webview.scrollView addSubview:_closeButton];
    
    [self sizeToFitOrientation];
    
    [self addObservers];
    
    activityViewLabeled = [[LabeledActivityView alloc] initWithFrame:CGRectMake(0, 0, 120, 90)];
    activityViewLabeled.center = CGPointMake(_webview.frame.size.width*0.5, _webview.frame.size.height*0.5);
    activityViewLabeled.text = NSLocalizedString(@"Loading...", @"");
    activityViewLabeled.hidden = YES;
    activityViewLabeled.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [_webview addSubview:activityViewLabeled];
    
    return;
}

-(CGPoint)getWindowOffset
{
    CGFloat yOffset = 150;
    CGFloat xOffset = 150;
    
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    switch (interfaceOrientation)
    {
        case UIInterfaceOrientationPortrait:
            xOffset = 0;
            yOffset = -150;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            xOffset = 0;
            yOffset = 150;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            xOffset = -150;
            yOffset = 0;
            break;
        case UIInterfaceOrientationLandscapeRight:
            xOffset = 150;
            yOffset = 0;
            break;
    }
    
    return CGPointMake(xOffset, yOffset);
}

-(void)offsetWindow:(CGPoint)offset
{
    _backgroundView.frame = CGRectOffset(_backgroundView.frame, offset.x, offset.y);
}

-(void)keyboardWillShow:(NSNotification*)n
{
    return;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        CGPoint offset = [self getWindowOffset];
        
        CGFloat duration = [[n.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        __weak typeof(self) pself = self;
        [UIView animateWithDuration:duration
                     animations:^{
                         [pself offsetWindow:offset];
                     }];
        
        oldOffset = offset;
        
     }
}

-(void)keyboardWillHide:(NSNotification*)n
{
    [_webview.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    
    return;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        CGPoint offset = [self getWindowOffset];
        offset.x*=-1;
        offset.y*=-1;
        
        __weak typeof(self) pself = self;
        CGFloat duration = [[n.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        [UIView animateWithDuration:duration
                         animations:^{
                             [pself offsetWindow:offset];
                         }];
        
        oldOffset = CGPointZero;
    }
}

-(void)setTitle:(NSString*)str
{
	_title = str;
	
	if (_titleLabel)
		_titleLabel.text = _title;
}

-(void)cancelClicked
{
    
}

-(void)cancel
{
    [self cancelClicked];
	[self dismiss];
}

-(void)dismiss
{
	CGRect startRect = CGRectMake((_backgroundView.bounds.size.width-100)*0.5, 
								  (_backgroundView.bounds.size.height-100)*0.5, 
								  100, 
								  100);
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(dissmissAnimationDidStop:finished:context:)];
	_border.alpha = 0.0;
	_border.frame = startRect;
	[UIView commitAnimations];	
	
	[_webview stopLoading];
	_webview.delegate = nil;
}

- (void)dealloc {
    [self removeObservers];
}

-(void)updateWebViewOrientation
{
    return;
    
    NSInteger width = (NSInteger)_webview.frame.size.width;
    
    [_webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:
                                                      @"document.getElementById('touch_layout').style.width=\"%ldpx\";"
                                                       "document.getElementById('login_submit').style.width=\"%ldpx\";", (long)width, width-46]];
    
    if (!CGPointEqualToPoint(CGPointZero, oldOffset))
    {
        oldOffset = [self getWindowOffset];
        __weak typeof(self) pself = self;
        [UIView animateWithDuration:0.2
                         animations:^{
                             [pself offsetWindow:oldOffset];
                         }];        
    }
}

-(BOOL)shouldLoadRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
	return YES;
}

#pragma mark -
#pragma mark WebViewDelegate

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") 
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"Ok", @"")
                      otherButtonTitles:nil] show];
    [self gotError:error];
}

-(void)gotError:(NSError *)error
{
    [self dismiss];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    activityViewLabeled.hidden = NO;
}

-(BOOL)isBadContent:(NSString*)body
{
    return NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    activityViewLabeled.hidden = YES;
    
    NSString *body = [[webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ( [self isBadContent:body] )
    {
        return;
    }

    [webView stringByEvaluatingJavaScriptFromString:@"var e = document.createElement('input'); e.setAttribute('type','submit'); e.setAttribute('style','position:absolute;top:-1000px;'); document.getElementById('login_submit').appendChild(e);"];
    [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('box').getElementsByTagName('h1')[0].style.padding='11px 15px 11px 15px'; document.getElementById('touch_footer').style.padding='10px 5px'; var items=document.getElementsByClassName('apps_access_item'); for (var i=0; i<items.length; i++) items[i].style.margin='7px 0';"];

    [self updateWebViewOrientation];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	return [self shouldLoadRequest:request navigationType:navigationType];
}

@end
