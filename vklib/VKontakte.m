//
//  VKontakte.m
//  SovietPosters
//
//  Created by Evgeny Rusanau on 27.12.10.
//  Copyright 2010 Macsoftex. All rights reserved.
//

#import "VKontakte.h"

#import "URLParser.h"

static NSString *kApiUrl = @"https://api.vk.com/method/";

@implementation VKontakte
{
    NSURLConnection *_urlConnection;
    NSString *_loginUrl;
    
    NSString *_access_token;
    NSDate   *_expirationDate;
    NSString *_user_id;
    
    NSString *_app_id;
    NSString *_app_secret;
    NSString *_permissons;
    id<VKontankteDelegate> _delegate;
}

@synthesize access_token = _access_token,
			expirationDate = _expirationDate,
            user_id = _user_id;

- (id)initWithAppID:(NSString*)appid
{
    if (self = [super init])
	{
		_app_id = appid;
        _authorizing = NO;
	}
	
	return self;
}

- (id)initWithAppID:(NSString*)appid appSecret:(NSString*)appSecret
{
	if (self = [super init])
	{
		_app_id = appid;
        _app_secret = appSecret;
        _authorizing = NO;
	}
	
	return self;
}

-(void)showLoginDialog
{
	VKLoginDialog *loginDialog = [[VKLoginDialog alloc] initWithUrl:_loginUrl];
	loginDialog.delegate = self;
	[loginDialog show];
}

- (void)authorize:(NSString*)permisions andDelegate:(id<VKontankteDelegate>)delegate
{
    _authorizing = YES;
	
	_permissons = permisions;
	_delegate = delegate;
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            _app_id,  @"client_id",
                            permisions,  @"scope",
                            @"http://oauth.vk.com/blank.html",      @"redirect_uri",
                            @"touch",@"display",
                            @"token",@"response_type",
                            nil];
                            
    _loginUrl = [URLParser constructURL:@"http://oauth.vk.com/authorize" params:params];
    
    _urlConnection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_loginUrl]
                                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                           timeoutInterval:10]
                                                     delegate:self];
}

- (BOOL)isSessionValid
{
	if (_access_token && _expirationDate &&
				NSOrderedDescending == [_expirationDate compare:[NSDate date]])
		return YES;
	return NO;		
}

- (void)logout
{
    self.access_token = nil;
	self.expirationDate = nil;
    self.user_id = nil;
	
	NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	
	for (NSHTTPCookie* cookie in [cookies cookies]) {
		if ([[cookie domain] rangeOfString:@"vkontakte"].location != NSNotFound ||
			[[cookie domain] rangeOfString:@"vk.com"].location != NSNotFound)
			[cookies deleteCookie:cookie];
	}
}

-(VKRequest*)requestWithParams:(NSMutableDictionary*)params
				identifer:(int)identifer
					  delegate:(id<VKRequestDelegate>)delegate
{
	return [self requestWithParams:params
				  identifer:identifer
							method:@"GET"
						  delegate:delegate];
}

-(VKRequest*)requestWithParams:(NSMutableDictionary*)params
				identifer:(int)identifer
						method:(NSString*)method
					  delegate:(id<VKRequestDelegate>)delegate
{
	return [self requestWithParams:params
				  identifer:identifer
					 method:method
					 apiUrl:kApiUrl
				   delegate:delegate];
}

-(VKRequest*)requestWithParams:(NSMutableDictionary*)params
				identifer:(int)identifer
				  method:(NSString*)method
				  apiUrl:(NSString*)apiUrl
				delegate:(id<VKRequestDelegate>)delegate
{
	[params setValue:_access_token forKey:@"access_token"];
	
	
	return [self genericRequestWithParams:params
						 identifer:identifer
							method:method
							apiUrl:apiUrl
						  delegate:delegate];
}

-(VKRequest*)genericRequestWithParams:(NSMutableDictionary *)params
					  identifer:(int)identifer
						 method:(NSString*)method
						 apiUrl:(NSString*)apiUrl
					   delegate:(id<VKRequestDelegate>)delegate
{
    NSString *methodName = [params objectForKey:@"method"];
    if (methodName)
    {
        apiUrl = [apiUrl stringByAppendingString:methodName];
        [params removeObjectForKey:@"method"];
    }
    
	VKRequest* _request = [[VKRequest alloc] initWithParams:params
										 baseUrl:apiUrl
										  method:method
										delegate:delegate];
	_request.identifer = identifer;
	
	[_request sendRequest];
    
    return _request;
}

#pragma mark -
#pragma mark VKLoginDialogDelegate

-(void)didLogin:(NSDictionary*)params
{
    self.access_token = [params valueForKey:@"access_token"];
    NSString *expTime = [params valueForKey:@"expires_in"];
    if (expTime != nil) 
    {
        int expVal = [expTime intValue];
        if (expVal == 0) 
        {
            self.expirationDate = [NSDate distantFuture];
        } 
        else 
        {
            self.expirationDate = [NSDate dateWithTimeIntervalSinceNow:expVal];
        } 
    } 
    self.user_id = [params valueForKey:@"user_id"];
    
    _authorizing = NO;
    
    if ([_delegate respondsToSelector:@selector(vkontakteDidLogin:vkInterface:)])
        [_delegate vkontakteDidLogin:self.user_id vkInterface:self];
}

-(void)didNotLogin
{
    _authorizing = NO;
    
    if ([_delegate respondsToSelector:@selector(vkontakteDidNotLogin)])
		[_delegate vkontakteDidNotLogin];
}

-(void)vkDialogDidLogin:(VKLoginDialog*)dialog withParams:(NSDictionary*)params
{
    [self didLogin:params];
}

-(void)vkDialogDidNotLogin:(VKLoginDialog*)dialog
{
	[self didNotLogin];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response.URL.absoluteString rangeOfString:@"access_token"].location!=NSNotFound)
    {
        NSDictionary *params = [URLParser parseURL:response.URL.absoluteString];
        [self didLogin:params];
    }
    else
    {
        [self showLoginDialog];
    }
    
    [connection cancel];
    _urlConnection=nil;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    return request;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self showLoginDialog];
    
    _urlConnection = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _urlConnection = nil;
}


@end
