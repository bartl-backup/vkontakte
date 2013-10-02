//
//  VKInterfaceHolder.h
//  vkaudio
//
//  Created by Evgeny Rusanov on 06.08.12.
//  Copyright (c) 2012 Evgeny Rusanov. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VKontakte.h"

@interface VKInterfaceHolder : NSObject

+(VKInterfaceHolder*)sharedVKInterfaceHolder;

@property (nonatomic, readonly, retain) VKontakte *vk;

-(void)logout;

@end
