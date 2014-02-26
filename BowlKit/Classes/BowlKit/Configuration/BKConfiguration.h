//
//  BKConfiguration.h
//  BowlKit
//
//  Created by kk on 14-1-20.
//  Copyright (c) 2014年 赵凯. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DefaultBKConfigurator;
@interface BKConfiguration : NSObject

+ (instancetype)sharedInstance;

+ (instancetype)sharedInstanceWithConfigurator:(DefaultBKConfigurator*)config;

- (id)configurationValue:(NSString*)selector withObject:(id)object;

#define BKCONFIG(_CONFIG_KEY) [[BKConfiguration sharedInstance] configurationValue:@#_CONFIG_KEY withObject:nil]
#define BKCONFIG_WITH_ARGUMENT(_CONFIG_KEY, _CONFIG_ARG) [[BKConfiguration sharedInstance] configurationValue:@#_CONFIG_KEY withObject:_CONFIG_ARG]

@end
