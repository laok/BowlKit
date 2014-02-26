//
//  BK500px.h
//  BowlKit
//
//  Created by 凯 赵 on 12-7-24.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//
//https://github.com/500px/api-documentation
#import <UIKit/UIKit.h>
//#import "BKOAuthView.h"
#import <BowlKit/BKOAuthView.h>
//#import "BKService.h"
#import <BowlKit/BKService.h>

@interface BK500px : BKService <BKOAuthViewDelegate>

+ (id) sharedInstance ;

- (void)logout;
- (BOOL)islogin;
- (BOOL)autologin;

//通用请求接口
-(MKNetworkOperation*)  requestAPI:(NSString*)apiPath
                        httpMethod:(NSString *)httpMethod
                            params:(NSDictionary *)params
                      onCompletion:(MKNKJsonResponseBlock) completionBlock
                           onError:(MKNKJsonErrorBlock) errorBlock;

-(MKNetworkOperation*)  requestNoAuthAPI:(NSString*)apiPath
                        httpMethod:(NSString *)httpMethod
                            params:(NSDictionary *)params
                      onCompletion:(MKNKJsonResponseBlock) completionBlock
                           onError:(MKNKJsonErrorBlock) errorBlock;

-(MKNetworkOperation*)  update:(NSString*)text
                        image:(UIImage *)image
                      onCompletion:(MKNKJsonResponseBlock) completionBlock
                           onError:(MKNKJsonErrorBlock) errorBlock;

//-(void)test;
@end
