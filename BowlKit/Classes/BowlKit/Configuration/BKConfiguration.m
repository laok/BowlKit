//
//  BKConfiguration.m
//  BowlKit
//
//  Created by kk on 14-1-20.
//  Copyright (c) 2014年 赵凯. All rights reserved.
//

#import "BKConfiguration.h"
#import "DefaultBKConfigurator.h"
#import "SuppressPerformSelectorWarning.h"

@interface BKConfiguration ()
@property (readonly, strong) DefaultBKConfigurator *configurator;

- (id)initWithConfigurator:(DefaultBKConfigurator*)config;

@end

static BKConfiguration *sharedInstance = nil;

@implementation BKConfiguration

#pragma mark -
#pragma mark Instance methods

- (id)configurationValue:(NSString*)selector withObject:(id)object
{
	//BKLog(@"Looking for a configuration value for %@.", selector);
    
	SEL sel = NSSelectorFromString(selector);
	if ([self.configurator respondsToSelector:sel]) {
		id value;
        if (object) {
            SuppressPerformSelectorLeakWarning(value = [self.configurator performSelector:sel withObject:object]);
        } else {
            SuppressPerformSelectorLeakWarning(value = [self.configurator performSelector:sel]);
        }
        
		if (value) {
			//BKLog(@"Found configuration value for %@: %@", selector, [value description]);
			return value;
		}
	}
    
	//BKLog(@"Configuration value is nil or not found for %@.", selector);
	return nil;
}
#pragma mark -
#pragma mark Singleton methods
+ (instancetype)sharedInstance {
    @synchronized(self)
    {
        if (sharedInstance ==nil) {
            [NSException raise:@"IllegalStateException" format:@"BowlKit must be configured before use. Use your subclass of DefaultBKConfigurator"];
        }
    }
    return sharedInstance;
}

+ (instancetype)sharedInstanceWithConfigurator:(DefaultBKConfigurator*)config {

    if (sharedInstance != nil) {
		[NSException raise:@"IllegalStateException" format:@"BKConfiguration has already been configured with a delegate."];
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc]initWithConfigurator:config];
    });
    
    return sharedInstance;
}

-(id)initWithConfigurator:(DefaultBKConfigurator*)config{
    self = [super init];
    if (!self) {
        return nil;
    }
    _configurator = config;
    return self;
}
@end
