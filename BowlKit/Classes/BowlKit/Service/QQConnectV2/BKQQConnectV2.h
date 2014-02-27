//
//  BKQQConnectV2.h
//  BowlKit
//
//  Created by 凯 赵 on 12-12-7.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//
//http://wiki.opensns.qq.com/wiki/%E3%80%90QQ%E7%99%BB%E5%BD%95%E3%80%91%E7%A7%BB%E5%8A%A8%E5%BA%94%E7%94%A8%E6%8E%A5%E5%85%A5
#import <UIKit/UIKit.h>

#import "BKService.h"
//#import <BowlKit/BKService.h>


@interface BKQQConnectV2 : BKService

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


//指定一个图片URL地址抓取后上传
-(MKNetworkOperation*)  updateUrl:(NSString*)text
                         imageUrl:(NSString *)imageUrl
                     onCompletion:(MKNKJsonResponseBlock) completionBlock
                          onError:(MKNKJsonErrorBlock) errorBlock;

//发表文字微博
-(MKNetworkOperation*)  update:(NSString*)text
                      imageUrl:(NSString *)imageUrl
                         image:(UIImage*)image
                  onCompletion:(MKNKJsonResponseBlock) completionBlock
                       onError:(MKNKJsonErrorBlock) errorBlock;

-(void) test_qq_api;
@end
