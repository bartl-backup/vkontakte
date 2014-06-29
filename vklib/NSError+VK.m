//
//  NSError+VK.m
//  photomovie
//
//  Created by Evgeny Rusanov on 15.01.13.
//  Copyright (c) 2013 Macsoftex. All rights reserved.
//

#import "NSError+VK.h"

@implementation NSError (VK)

-(BOOL)vk_needRelogin
{
    return [[[self.userInfo valueForKey:@"error"] valueForKey:@"error_code"] integerValue] == 5;
}

@end
