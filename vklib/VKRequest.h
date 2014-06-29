//
//  VKRequest.h
//  SovietPosters
//
//  Created by Evgeny Rusanau on 27.12.10.
//  Copyright 2010 Macsoftex. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VKRequest;

@protocol VKRequestDelegate<NSObject>

- (void)vk_request:(VKRequest *)request didFailWithError:(NSError *)error;
- (void)vk_request:(VKRequest *)request didLoad:(id)result;

@optional
- (void)vk_requestLoading:(VKRequest *)request;
- (void)vk_request:(VKRequest *)request didReceiveResponse:(NSURLResponse *)response;

@end


@interface VKRequest : NSObject

-(id)initWithParams:(NSMutableDictionary*)params
			baseUrl:(NSString*)baseUrl
			 method:(NSString*)method
		   delegate:(id<VKRequestDelegate>)delegate;

-(void)sendRequest;
-(void)cancel;

@property (nonatomic) NSInteger identifer;

@end
