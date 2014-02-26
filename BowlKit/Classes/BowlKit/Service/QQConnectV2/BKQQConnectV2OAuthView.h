//
//  BKQQConnectV2OAuthView.h
//  BowlKit
//
//  Created by zhaokai on 12/7/12.
//#import "BKOAuthView.h"
//#import "BKOAuthView.h"
#import <BowlKit/BKOAuthView.h>
//#import "BKService.h"
#import <BowlKit/BKService.h>


@class BKQQConnectV2OAuthView;
@protocol BKQQConnectAuthorizeWebViewDelegate <NSObject>

- (void)authorizeWebView:(BKQQConnectV2OAuthView *)webView didReceiveAuthorizeCode:(NSString *)code;

@end

@interface BKQQConnectV2OAuthView : BKOAuthView

@end
