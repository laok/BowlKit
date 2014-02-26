//
//  BKService.m
//  BowlKit
//
//  Created by kk on 14-2-22.
//  Copyright (c) 2014年 赵凯. All rights reserved.
//

#import "BKService.h"

@implementation BKService

#pragma mark -
#pragma mark Configuration : Service Defination

// Each service should subclass these and return YES/NO to indicate what type of sharing they support.
// Superclass defaults to NO so that subclasses only need to add methods for types they support

+ (NSString *)sharerTitle
{
	return @"";
}

- (NSString *)sharerTitle
{
	return [[self class] sharerTitle];
}

+ (NSString *)sharerId
{
	return NSStringFromClass([self class]);
}

- (NSString *)sharerId
{
	return [[self class] sharerId];
}

- (BOOL)canComment
{
    return NO;
}
- (BOOL)canRepost
{
    return NO;
}
- (BOOL)hasOrgWebLink
{
    return NO;
}
@end
