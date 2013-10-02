//
//  VKLoginDialog.h
//  SovietPosters
//
//  Created by Evgeny Rusanau on 27.12.10.
//  Copyright 2010 Macsoftex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VKDialog.h"

@class VKLoginDialog;

@protocol VKLoginDialogDelegate<NSObject>
@optional
-(void)vkDialogDidLogin:(VKLoginDialog*)dialog withParams:(NSDictionary*)params;
-(void)vkDialogDidNotLogin:(VKLoginDialog*)dialog;
@end


@interface VKLoginDialog : VKDialog 

@property (nonatomic,weak) id<VKLoginDialogDelegate> delegate;

@end
