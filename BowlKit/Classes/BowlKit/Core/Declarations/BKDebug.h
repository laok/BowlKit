//
//  Debug.h
//  BowlKit
//
//  Created by kk on 14-1-20.
//  Copyright (c) 2014年 赵凯. All rights reserved.
//

#ifndef BowlKit_Debug_h
#define BowlKit_Debug_h

#define _BKDebugShowLogs

#ifdef _BKDebugShowLogs
#define BKDebugShowLogs			1
#define BKLog( s, ... ) NSLog( @"<%s %@:(%d)> %@", __func__, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define BKDebugShowLogs			0
#define BKLog( s, ... )
#endif

#endif
