//
//  VKRequest.m
//  SovietPosters
//
//  Created by Evgeny Rusanau on 27.12.10.
//  Copyright 2010 Macsoftex. All rights reserved.
//

#import "VKRequest.h"
#import "URLParser.h"

static NSString* kUserAgent = @"VKontakte";
static const NSTimeInterval kTimeoutInterval = 180.0;
static NSString* kStringBoundary = @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";

static const int kGeneralErrorCode = 10000;

@implementation VKRequest
{
	int _identifer;
	
	id<VKRequestDelegate> _delegate;
	
	NSMutableDictionary *_params;
	NSString *_method;
	NSString *_baseUrl;
	
	NSURLConnection*      _connection;
	NSMutableData*        _responseText;
    
    id context;
}

-(id)initWithParams:(NSMutableDictionary*)params
			baseUrl:(NSString*)baseUrl
			 method:(NSString*)method
		   delegate:(id<VKRequestDelegate>)delegate
{
	if (self = [super init])
	{
		_baseUrl  = baseUrl;
		_method   = method;
		_params   = params;
		_delegate = delegate;
	}
	
	return self;
}

-(void)cancel
{
	[_connection cancel];
	_connection = nil;
	_responseText = nil;
    
    context = nil;
}

- (void)utfAppendBody:(NSMutableData *)body data:(NSString *)data 
{
	[body appendData:[data dataUsingEncoding:NSUTF8StringEncoding]];
}

-(NSMutableData*)generatePostBody
{
	NSMutableData *body = [NSMutableData data];
	NSString *endLine = [NSString stringWithFormat:@"\r\n--%@\r\n", kStringBoundary];
	NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
	
	[self utfAppendBody:body data:[NSString stringWithFormat:@"--%@\r\n", kStringBoundary]];
	for (id key in [_params keyEnumerator]) {
		
		if (([[_params valueForKey:key] isKindOfClass:[UIImage class]])
			||([[_params valueForKey:key] isKindOfClass:[NSData class]])) 
		{
			
			[dataDictionary setObject:[_params valueForKey:key] forKey:key];
			continue;
		}
	}
	
	if ([dataDictionary count] > 0) 
	{
		for (id key in dataDictionary) 
		{
			NSObject *dataParam = [dataDictionary valueForKey:key];
			if ([dataParam isKindOfClass:[UIImage class]]) 
			{
				NSData* imageData = UIImagePNGRepresentation((UIImage*)dataParam);
				[self utfAppendBody:body
							   data:[NSString stringWithFormat:
									 @"Content-Disposition: form-data; name=\"%@\"; filename=\"%@.png\"\r\n", key, key]];
				[self utfAppendBody:body
							   data:@"Content-Type: image/png\r\n\r\n"];
				[body appendData:imageData];
			} 
			else
			{
				[self utfAppendBody:body
							   data:[NSString stringWithFormat:
									 @"Content-Disposition: form-data; filename=\"%@\"\r\n", key]];
				[self utfAppendBody:body
							   data:@"Content-Type: content/unknown\r\n\r\n"];
				[body appendData:(NSData*)dataParam];
			}
			[self utfAppendBody:body data:endLine];
			
		}
	}	
	
	return body;
}

-(void)sendRequest
{
    context = self;
    
	if ([_delegate respondsToSelector:@selector(vk_requestLoading:)]) 
	{
		[_delegate vk_requestLoading:self];
	}
	
	NSString *url = [URLParser constructURL:_baseUrl params:_params];
	
	NSMutableURLRequest* request =
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                        timeoutInterval:kTimeoutInterval];
	
	[request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
	
	
	[request setHTTPMethod:_method];
	if ([_method isEqualToString: @"POST"]) 
	{
		NSString* contentType = [NSString
								 stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary];
		[request setValue:contentType forHTTPHeaderField:@"Content-Type"];
		
		[request setHTTPBody:[self generatePostBody]];
	}
	
	_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (id)formError:(NSInteger)code userInfo:(NSDictionary *) errorData 
{
	return [NSError errorWithDomain:@"error" code:code userInfo:errorData];	
}

-(id)parseJsonResponse:data error:(NSError**)error
{
#ifdef _DEBUG
	NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSLog(@"%@",responseString);
#endif
	
	id result = [NSJSONSerialization JSONObjectWithData:data
                                                options:0
                                                  error:NULL];
	
	if (![result isKindOfClass:[NSArray class]]) 
	{
		if ([result objectForKey:@"error"] != nil) 
		{
			if (error != nil) 
			{
				*error = [self formError:kGeneralErrorCode
								userInfo:result];
			}
			return nil;
		}
		
		if ([result objectForKey:@"error_code"] != nil) 
		{
			if (error != nil) 
			{
				*error = [self formError:[[result objectForKey:@"error_code"] intValue] userInfo:result];
			}
			return nil;
		}
		
		if ([result objectForKey:@"error_msg"] != nil) 
		{
			if (error != nil) 
			{
				*error = [self formError:kGeneralErrorCode userInfo:result];
			}
		}
	}
	
	return result;
}

-(void)failWithError:(NSError*)error
{
	if ([_delegate respondsToSelector:@selector(vk_request:didFailWithError:)]) {
		[_delegate vk_request:self didFailWithError:error];
	}
    
    context = nil;
}

-(void)handleResponseData:(NSMutableData*)data
{
	if ([_delegate respondsToSelector:@selector(vk_request:didLoad:)] ||
		[_delegate respondsToSelector:@selector(vk_request:didFailWithError:)]) 
	{
#ifdef _DEBUG
        NSString *resultString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Server response: %@",resultString);
#endif        
        
		NSError* error = nil;
		id result = [self parseJsonResponse:data error:&error];
		if (error) 
		{
			[self failWithError:error];
		} 
		else if ([_delegate respondsToSelector:@selector(vk_request:didLoad:)]) 
		{
			[_delegate vk_request:self didLoad:(result == nil ? data : result)];
		}
		
	}
    
    context = nil;
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if (!_connection) return;
    
	_responseText = [[NSMutableData alloc] init];
	
	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
	if ([_delegate respondsToSelector:@selector(vk_request:didReceiveResponse:)]) {
		[_delegate vk_request:self didReceiveResponse:httpResponse];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (!_connection) return;
    
	[_responseText appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
				  willCacheResponse:(NSCachedURLResponse*)cachedResponse {    
	return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (!_connection) return;
    
	[self handleResponseData:_responseText];
	
	_responseText = nil;
	_connection = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (!_connection) return;
    
	[self failWithError:error];
	
	_responseText = nil;
	_connection = nil;
}

@end
