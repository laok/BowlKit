//
//  BKQQConnectV2OAuthView.m
//  BowlKit
//
//  Created by zhaokai on 5/13/12.

#import "BKQQConnectV2OAuthView.h"

@implementation BKQQConnectV2OAuthView

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{		
    NSRange range = [request.URL.absoluteString rangeOfString:@"access_token="];
    
    if (range.location != NSNotFound)
    {
        NSString *code = [request.URL.absoluteString substringFromIndex:range.location + range.length];
        
        if ([delegate respondsToSelector:@selector(authorizeWebView:didReceiveAuthorizeCode:)])
        {
            [delegate authorizeWebView:self didReceiveAuthorizeCode:code];
        }
        return NO;
    }
    
    return YES;
}


@end
