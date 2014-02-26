//
//  BKService.h
//  BowlKit
//
//  Created by kk on 14-2-22.
//  Copyright (c) 2014年 赵凯. All rights reserved.
//

#import "MKNetworkKit.h"

@interface BKService : MKNetworkEngine

#pragma mark -
#pragma mark Configuration : Service Definition

+ (NSString *)sharerTitle;
- (NSString *)sharerTitle;
+ (NSString *)sharerId;
- (NSString *)sharerId;

- (BOOL)canComment;
- (BOOL)canRepost;
- (BOOL)hasOrgWebLink;
#pragma mark-
#pragma mark OAuth


@end
