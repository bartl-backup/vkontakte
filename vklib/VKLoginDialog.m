//
//  VKLoginDialog.m
//  SovietPosters
//
//  Created by Evgeny Rusanau on 27.12.10.
//  Copyright 2010 Macsoftex. All rights reserved.
//

#import "VKLoginDialog.h"
#import "URLParser.h"

@implementation VKLoginDialog

-(id)initWithUrl:(NSString*)url
{
	if (self = [super initWithUrl:url])
	{
		self.title = @"  VK";
	}
	
	return self;
}

-(void)dialogOk:(NSString*)url
{
	if ([_delegate respondsToSelector:@selector(vkDialogDidLogin:withParams:)])
	{
		NSMutableDictionary *params = [URLParser parseURL:url];
		
		[_delegate vkDialogDidLogin:self withParams:params];
	}
	
	[self dismiss];
}

-(void)dialogFailure
{
	if ([_delegate respondsToSelector:@selector(vkDialogDidNotLogin:)])
		[_delegate vkDialogDidNotLogin:self];
	
	[self dismiss];
}

-(void)dialogCanceled
{
    if ([_delegate respondsToSelector:@selector(vkDialogLoginCanceled:)])
        [_delegate vkDialogLoginCanceled:self];
    
    [self dismiss];
}

-(void)cancelClicked
{
    if ([_delegate respondsToSelector:@selector(vkDialogLoginCanceled:)])
        [_delegate vkDialogLoginCanceled:self];
}

-(BOOL)shouldLoadRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
// Success	http://vkontakte.ru/api/login_success.html
// Failure  http://vkontakte.ru/api/login_failure.html
	
	NSURL *url = [request URL];
    
	if (url)
	{
		if ([[url absoluteString] rangeOfString:@"access_token"].location!=NSNotFound)
		{
			[self dialogOk:[url absoluteString]];
			return NO;
		}
		else if ([[url absoluteString] rangeOfString:@"access_denied"].location!=NSNotFound ||
                 [[url absoluteString] rangeOfString:@"error"].location!=NSNotFound)
		{
            if ([[url absoluteString] rangeOfString:@"user_denied"].location!=NSNotFound)
                [self dialogCanceled];
            else
                [self dialogFailure];
			return NO;
		}
	}
	
	return YES;
}

-(BOOL)isResultContent:(NSString*)body
{
    if ( !body )
        return YES;
    
    NSRegularExpression *rx = [NSRegularExpression regularExpressionWithPattern:@"\\{ *\"[a-zA-Z0-9]+\" *: *\".+?\\}|^[ \\n]*Login success[ \\n]*$|^[ \\n]*Login failure[ \\n]*$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSUInteger n = [rx numberOfMatchesInString:body options:0 range:NSMakeRange(0,body.length)];
    
    return n!=0;
}

-(BOOL)isBadContent:(NSString *)body
{
    if ([self isResultContent:body])
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
                                    message:NSLocalizedString(@"Server VK does not respond", @"")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"Ok", @"")
                          otherButtonTitles:nil] show];
        [self dialogFailure];
        return YES;
    }
    return NO;
}

-(void)gotError:(NSError *)error
{
    [self dialogFailure];
}

@end
