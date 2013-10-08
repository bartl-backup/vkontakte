//
//  VKInterfaceHolder.m
//  vkaudio
//
//  Created by Evgeny Rusanov on 06.08.12.
//  Copyright (c) 2012 Evgeny Rusanov. All rights reserved.
//

#import "VKInterfaceHolder.h"

#define VKAPPID                     @"3066492"

@implementation VKInterfaceHolder

@synthesize vk = _vk;

+(VKInterfaceHolder*)sharedVKInterfaceHolder
{
    static VKInterfaceHolder *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VKInterfaceHolder alloc] init];
    });
    return instance;
}

-(VKontakte*)vk
{
    if (!_vk)
    {
        _vk = [[VKontakte alloc] initWithAppID:VKAPPID];
        [self initVkontakte];
    }
    
    return _vk;
}

-(void)initVkontakte
{
    self.vk.user_id = [[NSUserDefaults standardUserDefaults] valueForKey:@"VKontakte_me"];
    self.vk.access_token = [[NSUserDefaults standardUserDefaults] valueForKey:@"VKontakte_AccessToken"];
    self.vk.expirationDate = [[NSUserDefaults standardUserDefaults] valueForKey:@"VKontakte_ExpirationDate"];
}

-(void)logout
{
    [self.vk logout];
    [[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"VKontakte_me"];
	[[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"VKontakte_AccessToken"];
	[[NSUserDefaults standardUserDefaults] setValue:nil forKey:@"VKontakte_ExpirationDate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.vk.user_id = nil;
    self.vk.access_token = nil;
    self.vk.expirationDate = nil;
    
}

@end
