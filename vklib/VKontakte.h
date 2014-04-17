//
//  VKontakte.h
//  SovietPosters
//
//  Created by Evgeny Rusanau on 27.12.10.
//  Copyright 2010 Macsoftex. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VKLoginDialog.h"
#import "VKRequest.h"

@class VKontakte;
@protocol VKontankteDelegate<NSObject>
@optional
-(void)vkontakteDidLogin:(NSString*)userId vkInterface:(VKontakte*)vk;
-(void)vkontakteDidNotLogin:(BOOL)canceled;
@end


@interface VKontakte : NSObject <VKLoginDialogDelegate, NSURLConnectionDelegate>

@property (nonatomic,strong) NSString *access_token;
@property (nonatomic,strong) NSDate *expirationDate;
@property (nonatomic,strong) NSString *user_id;

@property (nonatomic, readonly) BOOL authorizing;

- (id)initWithAppID:(NSString*)appid;
- (id)initWithAppID:(NSString*)appid appSecret:(NSString*)appSecret;

- (BOOL)isSessionValid;

- (void)authorize:(NSString*)permisions andDelegate:(id<VKontankteDelegate>)delegate;
- (void)logout;

-(VKRequest*)requestWithParams:(NSDictionary*)params
			   identifer:(int)identifer
				delegate:(id<VKRequestDelegate>)delegate;
-(VKRequest*)requestWithParams:(NSDictionary*)params
			   identifer:(int)identifer
				  method:(NSString*)method
				delegate:(id<VKRequestDelegate>)delegate;
-(VKRequest*)requestWithParams:(NSDictionary*)params
			   identifer:(int)identifer
				  method:(NSString*)method
				  apiUrl:(NSString*)apiUrl
				delegate:(id<VKRequestDelegate>)delegate;

-(VKRequest*)genericRequestWithParams:(NSDictionary *)params
					  identifer:(int)identifer
						 method:(NSString*)method
						 apiUrl:(NSString*)apiUrl
					   delegate:(id<VKRequestDelegate>)delegate;

@end
