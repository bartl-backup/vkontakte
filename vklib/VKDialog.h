//
//  VKDialog.h
//  SovietPosters
//
//  Created by Evgeny Rusanau on 24.12.10.
//  Copyright 2010 Macsoftex. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface VKDialog : NSObject <UIWebViewDelegate>

@property (nonatomic,strong) NSString *title;

-(BOOL)shouldLoadRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType;

-(id)initWithUrl:(NSString*)url;

-(void)show;
-(void)dismiss;

-(BOOL)isBadContent:(NSString *)body;
-(void)gotError:(NSError*)error;
-(void)cancelClicked;

@end
