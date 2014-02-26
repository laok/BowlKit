//
//  SuppressPerformSelectorWarning.h
//  BowlKit
//
//  Created by kk on 14-1-20.
//  Copyright (c) 2014年 赵凯. All rights reserved.
//

#ifndef BowlKit_SuppressPerformSelectorWarning_h
#define BowlKit_SuppressPerformSelectorWarning_h

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

#endif
