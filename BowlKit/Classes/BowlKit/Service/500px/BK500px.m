//
//  BK500px.m
//  BowlKit
//
//  Created by 凯 赵 on 12-7-24.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "BK500px.h"
//#import "BK.h"
#import <BowlKit/BK.h>
//#import "JSONKit.h"
#import <BowlKit/JSONKit.h>
//#import "NSHTTPCookieStorage+DeleteForURL.h"
#import <BowlKit/NSHTTPCookieStorage+DeleteForURL.h>

//#import "BKActivityIndicator.h"
#import <BowlKit/BKActivityIndicator.h>
#import <CommonCrypto/CommonHMAC.h>
//#include "Base64Transcoder.h"
#import <BowlKit/Base64Transcoder.h>

//#import "OARequestParameter.h"
#import <BowlKit/OARequestParameter.h>
//#import "OAConsumer.h"
#import <BowlKit/OAConsumer.h>
//#import "OAToken.h"
#import <BowlKit/OAToken.h>
#import "BKDebug.h"

//开发api文档
//https://github.com/500px/api-documentation
//http://500px.com/settings/applications
///////500px鉴权信息 for oauth1.0a 账户：onlyyoujack@gmail.com////
#define MKHostName4500px @"https://api.500px.com/v1"
#define OAuthConsumerKey  @"A9jg5S6LuUi9nqCzuJ67nRXyv0jQSNMlL57RIyI7"
#define OAuthSecretKey @"WO7LS6yiSD5b35WuMvT74ZOt1uYmBozaFwA5ufgd"

#define RequestTokenURL    @"https://api.500px.com/v1/oauth/request_token"
#define AuthorizeURL       @"https://api.500px.com/v1/oauth/authorize"
#define AccessTokenURL     @"https://api.500px.com/v1/oauth/access_token"
#define SHK500pxRedirectURI @"http://yourdomain.com/callback" //请求consumerkey时，500px要求定义

//用户信息
static NSString *userInfoKey=@"userInfo";
///////////////////////

@interface BK500px()
- (void)storeAccessToken;
- (BOOL)restoreAccessToken;
- (void)deleteStoredAccessToken;
- (BOOL)authorize;
- (void)promptAuthorization;

@property (nonatomic, strong) OAConsumer *consumer;
@property (nonatomic, strong) OAToken *accessToken;
@property (nonatomic, strong) OAToken *requestToken;
@property (nonatomic, strong) NSString * timestamp;
@property (nonatomic, strong) NSString * nonce;

@property (nonatomic, strong) NSDictionary *authorizeResponseQueryVars;

@end

@implementation BK500px
@synthesize timestamp,nonce;
@synthesize consumer,accessToken,requestToken,authorizeResponseQueryVars;//for oauth 1.0a

#pragma mark – init
+ (id) sharedInstance {
    static dispatch_once_t onceToken = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&onceToken, ^{
        _sharedObject = [[BK500px alloc]initWithHostName:nil apiPath:nil customHeaderFields:nil];
    });
    return _sharedObject;
}

- (void)_generateTimestamp
{
    timestamp = [NSString stringWithFormat:@"%ld", time(NULL)];
}

+ (NSString *)sharerTitle
{
    return @"500px";
}
- (void) logout
{
    [NSHTTPCookieStorage deleteCookiesForURL:[NSURL URLWithString:AuthorizeURL]];
    return [self deleteStoredAccessToken];
}
- (BOOL)islogin
{
    return [self isAuthorized];
}
- (BOOL)autologin
{
    return [self authorize];
}

#pragma mark - oauth 1.0a 协议实现 by kk
- (void)_generateNonce
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    
    nonce = (NSString*) uuidStr;
}
- (NSString *)signClearText:(NSString *)text withSecret:(NSString *)secret 
{
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [text dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
	CCHmac(kCCHmacAlgSHA1, [secretData bytes], [secretData length], [clearTextData bytes], [clearTextData length], result);
    
    //Base64 Encoding
    
    char base64Result[32];
    size_t theResultLength = 32;
    Base64EncodeData(result, 20, base64Result, &theResultLength);
    NSData *theData = [NSData dataWithBytes:base64Result length:theResultLength];
    
    NSString *base64EncodedResult = [[NSString alloc] initWithData:theData encoding:NSUTF8StringEncoding];
    
    //return [base64EncodedResult autorelease];
    return base64EncodedResult;
}
- (NSString *)_signatureBaseString:(NSString*)httpMethod 
                               url:(NSString *)requestURL
                             token:(OAToken *)aToken
              extraOAuthParameters:(NSDictionary *)extraOAuthParameters
                          callback:(NSString*)callback
{
    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    // build a sorted array of both request parameters and OAuth header parameters
    NSMutableArray *parameterPairs = [NSMutableArray arrayWithCapacity:(7)]; // 7 being the number of OAuth params in the Signature Base String
    
    if (callback && callback.length > 0) {
        [parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_callback" value:callback] URLEncodedNameValuePair]];
    }
    
	[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_consumer_key" value:self.consumer.key] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_signature_method" value:@"HMAC-SHA1"] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_timestamp" value:timestamp] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_nonce" value:nonce] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_version" value:@"1.0"] URLEncodedNameValuePair]];
    
    
    if (![aToken.key isEqualToString:@""]) {
        [parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_token" value:aToken.key] URLEncodedNameValuePair]];
    }
    
	
	for(NSString *parameterName in [[extraOAuthParameters allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
		[parameterPairs addObject:[[OARequestParameter requestParameterWithName:[parameterName URLEncodedString] value: [[extraOAuthParameters objectForKey:parameterName] URLEncodedString]] URLEncodedNameValuePair]];
	}
     
	
    /*
	if (![[self valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"multipart/form-data"]) {
		for (OARequestParameter *param in [self parameters]) {
			[parameterPairs addObject:[param URLEncodedNameValuePair]];
		}
	}
     */
    
    NSArray *sortedPairs = [parameterPairs sortedArrayUsingSelector:@selector(compare:)];
    NSString *normalizedRequestParameters = [sortedPairs componentsJoinedByString:@"&"];
    
    // OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
    NSString *ret = [NSString stringWithFormat:@"%@&%@&%@",
					 httpMethod,
					 [requestURL URLEncodedString],
					 [normalizedRequestParameters URLEncodedString]];
	
	return ret;
}
- (NSString *)_oauthHeaderString:(NSString*)httpMethod 
                               url:(NSString *)requestURL
                             token:(OAToken *)aToken
            extraOAuthParameters:(NSDictionary *)extraOAuthParameters
                          callback:(NSString*)callback
{
    if (aToken == nil) {
        aToken = [[OAToken alloc]init];
    }
    
    [self _generateNonce];
    [self _generateTimestamp];
    
    NSString* signature = [self signClearText:[self _signatureBaseString:httpMethod url:requestURL token:aToken extraOAuthParameters:extraOAuthParameters callback:callback]
                                   withSecret:[NSString stringWithFormat:@"%@&%@",
                                               [self.consumer.secret URLEncodedString],
                                               [aToken.secret URLEncodedString]]];
    
    // set OAuth headers
    NSString *oauthToken;
    if ([aToken.key isEqualToString:@""])
        oauthToken = @""; // not used on Request Token transactions
    else
        oauthToken = [NSString stringWithFormat:@"oauth_token=\"%@\", ", [aToken.key URLEncodedString]];
    
    NSString *oauthCallback;
    if (callback && callback.length > 0)
        oauthCallback = [NSString stringWithFormat:@"oauth_callback=\"%@\", ", [callback URLEncodedString]];
    else
        oauthCallback = @"";
	
	NSMutableString *extraParameters = [NSMutableString string];
	
	// Adding the optional parameters in sorted order isn't required by the OAuth spec, but it makes it possible to hard-code expected values in the unit tests.
	for(NSString *parameterName in [[extraOAuthParameters allKeys] sortedArrayUsingSelector:@selector(compare:)])
	{
		[extraParameters appendFormat:@", %@=\"%@\"",
		 [parameterName URLEncodedString],
		 [[extraOAuthParameters objectForKey:parameterName] URLEncodedString]];
	}
    
    NSString *oauthHeader = [NSString stringWithFormat:@"OAuth realm=\"%@\", %@oauth_consumer_key=\"%@\", %@oauth_signature_method=\"%@\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", oauth_nonce=\"%@\", oauth_version=\"1.0\"%@",
                             @"",//[realm URLEncodedString],
                             oauthCallback,
                             [consumer.key URLEncodedString],
                             oauthToken,
                             @"HMAC-SHA1",//[[signatureProvider name] URLEncodedString],
                             [signature URLEncodedString],
                             timestamp,
                             nonce,
							 extraParameters];
    
    return oauthHeader;
}
- (void)tokenRequest
{
    if ([self isAuthorized]) {
        return; //用于初始化key 和 secet
    }
    
    [[BKActivityIndicator currentIndicator] displayActivity:BKLocalizedString(@"Connecting...")];

    NSString* oauthHeader = [self _oauthHeaderString:@"POST" url:RequestTokenURL token:nil extraOAuthParameters:nil callback:@""];
    
    MKNetworkOperation *op = [self operationWithURLString:RequestTokenURL
                                                   params:nil
                                               httpMethod:@"POST"];//
    
    NSDictionary *authorParams=[NSDictionary dictionaryWithObjectsAndKeys:oauthHeader,@"Authorization", nil];
    [op addHeaders:authorParams]; //设置http header字段 Authorization by kk

    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation)
     {
         // the completionBlock will be called twice. 
         // if you are interested only in new values, move that code within the else block
         
         if([completedOperation isCachedResponse]) {
             DLog(@"Data from cache %@", [completedOperation responseJSON]);
         }
         else {
             DLog(@"Data from server %@", [completedOperation responseString]);
         }
         //////////处理返回 token////////////
         [[BKActivityIndicator currentIndicator] hide];
         
         self.requestToken = [[OAToken alloc] initWithHTTPResponseBody:[completedOperation responseString]];
        // [self tokenAuthorize];
         [self promptAuthorization];
         /////////////////////////////////////////
         
         
     }errorHandler:^(MKNetworkOperation *completedOperation, NSError* error) {
         
         DLog(@"Data from server %@", [completedOperation responseString]);
         
         [[BKActivityIndicator currentIndicator] hide];
         
         [[[UIAlertView alloc] initWithTitle:@"Request Error"
                                      message:error!=nil?[error localizedDescription]:@"There was a problem requesting authorization"
                                     delegate:nil
                            cancelButtonTitle:@"Close"
                            otherButtonTitles:nil] show];
         
     }];
    
    [self enqueueOperation:op forceReload:YES];//强制请求
    BKLog(@"%@",[op curlCommandLineString]);
}
#pragma mark – OAuth 过程
- (void)storeAccessToken
{	
	[BK setAuthValue:self.accessToken.key
               forKey:@"accessKey"
            forSharer:[self sharerId]];
	
	[BK setAuthValue:self.accessToken.secret
               forKey:@"accessSecret"
			forSharer:[self sharerId]];
	
	[BK setAuthValue:self.accessToken.sessionHandle
			   forKey:@"sessionHandle"
			forSharer:[self sharerId]];
}

- (BOOL)restoreAccessToken
{
	self.consumer = [[OAConsumer alloc] initWithKey:OAuthConsumerKey secret:OAuthSecretKey] ;
	
	if (self.accessToken != nil)
		return YES;
    
	NSString *key = [BK getAuthValueForKey:@"accessKey"
                                  forSharer:[self sharerId]];
	
	NSString *secret = [BK getAuthValueForKey:@"accessSecret"
									 forSharer:[self sharerId]];
	
	NSString *sessionHandle = [BK getAuthValueForKey:@"sessionHandle"
                                            forSharer:[self sharerId]];
	
	if (key != nil && secret != nil)
	{
		self.accessToken = [[OAToken alloc] initWithKey:key secret:secret] ;
		
		if (sessionHandle != nil)
			self.accessToken.sessionHandle = sessionHandle;
		
		return self.accessToken != nil;
	}
	
	return NO;
}

- (void)deleteStoredAccessToken
{
	NSString *sharerId = [self sharerId];
	
	[BK removeAuthValueForKey:@"accessKey" forSharer:sharerId];
	[BK removeAuthValueForKey:@"accessSecret" forSharer:sharerId];
	[BK removeAuthValueForKey:@"sessionHandle" forSharer:sharerId];
    [BK removeAuthValueForKey:userInfoKey forSharer:sharerId];
    
    self.accessToken = nil;
    self.requestToken=nil;
}

- (BOOL)isAuthorized
{		
	return [self restoreAccessToken];
}

- (void)promptAuthorization
{

    //https://api.500px.com/v1/oauth/authorize?oauth_token=JlPkzZW6qdUq8Mr8RRDHHugNHbzcavkfHBfVxMmM
    
    NSURL* authorizeURL = [NSURL URLWithString:AuthorizeURL];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?oauth_token=%@", authorizeURL.absoluteString, self.requestToken.key]];
    
	BKOAuthView *auth = [[BKOAuthView alloc] initWithURL:url delegate:self];
	[[BK currentHelper] showViewController:auth];
}
- (void)tokenAuthorizeView:(BKOAuthView *)authView didFinishWithSuccess:(BOOL)success queryParams:(NSMutableDictionary *)queryParams error:(NSError *)error
{
     [[BK currentHelper] hideCurrentViewControllerAnimated:YES];
     
     if (!success)
     {
     [[[UIAlertView alloc] initWithTitle:@"Authorize Error"
     message:error!=nil?[error localizedDescription]:@"There was an error while authorizing"
     delegate:nil
     cancelButtonTitle:@"Close"
     otherButtonTitles:nil]  show];
     }	
     
     else if ([queryParams objectForKey:@"oauth_problem"])
     {
     BKLog(@"oauth_problem reported: %@", [queryParams objectForKey:@"oauth_problem"]);
     
     [[[UIAlertView alloc] initWithTitle:BKLocalizedString(@"Authorize Error")
     message:error!=nil?[error localizedDescription]:BKLocalizedString(@"There was an error while authorizing")
     delegate:nil
     cancelButtonTitle:BKLocalizedString(@"Close")
     otherButtonTitles:nil]  show];
     success = NO;
     }
     
     else 
     {
     self.authorizeResponseQueryVars = queryParams;
     
     [self tokenAccess];
     }
}

- (NSURL *)authorizeCallbackURL
{
//    BKLog(@"authorizeCallbackURL");
    return [NSURL URLWithString:SHK500pxRedirectURI];
}
- (BOOL)authorize
{
	if ([self isAuthorized])
		return YES;
	
	else 
		//[self promptAuthorization];
        [self tokenRequest];
	
	return NO;
}

- (void)tokenAuthorizeCancelledView:(BKOAuthView *)authView
{
	[[BK currentHelper] hideCurrentViewControllerAnimated:YES];	
    //[self authDidFinish:NO];
}

- (void)tokenAccess
{
	[self tokenAccess:NO];
}

- (void)tokenAccess:(BOOL)refresh
{
	if (!refresh)
		[[BKActivityIndicator currentIndicator] displayActivity:BKLocalizedString(@"Authenticating...")];
    
    NSDictionary *extraOAuthParameters=[NSDictionary dictionaryWithObjectsAndKeys:[self.authorizeResponseQueryVars objectForKey:@"oauth_verifier"],@"oauth_verifier", nil];
    self.authorizeResponseQueryVars = nil;

    
    NSString* oauthHeader = [self _oauthHeaderString:@"POST" url:AccessTokenURL 
                                               token:(refresh ? accessToken : requestToken) 
                                extraOAuthParameters:extraOAuthParameters 
                                            callback:SHK500pxRedirectURI];
    
    MKNetworkOperation *op = [self operationWithURLString:AccessTokenURL
                                                   params:nil
                                               httpMethod:@"POST"];//
    
    NSDictionary *authorParams=[NSDictionary dictionaryWithObjectsAndKeys:oauthHeader,@"Authorization", nil];
    [op addHeaders:authorParams]; //设置http header字段 Authorization by kk
    
    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation)
     {
         // the completionBlock will be called twice. 
         // if you are interested only in new values, move that code within the else block
         
         if([completedOperation isCachedResponse]) {
             DLog(@"Data from cache %@", [completedOperation responseJSON]);
         }
         else {
             DLog(@"Data from server %@", [completedOperation responseString]);
         }
         //////////处理返回 token////////////
         [[BKActivityIndicator currentIndicator] hide];
         
         self.accessToken = [[OAToken alloc] initWithHTTPResponseBody:[completedOperation responseString]];
         [self storeAccessToken];
         /////////////////////////////////////////
         
         [self getCurrentUserInfo];
     }errorHandler:^(MKNetworkOperation *completedOperation, NSError* error) {
         
         DLog(@"Data from server %@", [completedOperation responseString]);
         
         [[BKActivityIndicator currentIndicator] hide];
         
         [[[UIAlertView alloc] initWithTitle:@"Request Error"
                                      message:error!=nil?[error localizedDescription]:@"There was a problem requesting authorization"
                                     delegate:nil
                            cancelButtonTitle:@"Close"
                            otherButtonTitles:nil] show];
         NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:@"err",@"status",nil];
         [[NSNotificationCenter defaultCenter]postNotificationName:[self sharerId] object:nil userInfo:info];
         
     }];
    
    [self enqueueOperation:op forceReload:YES];//强制请求
    BKLog(@"%@",[op curlCommandLineString]);
}
#pragma mark – API接口
-(MKNetworkOperation*)  requestAPI:(NSString*)apiPath
                        httpMethod:(NSString *)httpMethod
                            params:(NSDictionary *)params
                      onCompletion:(MKNKJsonResponseBlock) completionBlock
                           onError:(MKNKJsonErrorBlock) errorBlock{
    
    if (![self authorize]) {
        return nil;
    }
    
     //https://github.com/500px/api-documentation
     //https://api.500px.com/v1/photos?feature=popular
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [mutableParams setObject:OAuthConsumerKey forKey:@"consumer_key"];
     
    NSString* url = [NSString stringWithFormat:@"%@/%@",MKHostName4500px,apiPath];
    NSString* oauthHeader = [self _oauthHeaderString:httpMethod url:url token:self.accessToken extraOAuthParameters:mutableParams callback:@""];
    
    MKNetworkOperation *op = [self operationWithURLString: url
                                              params:mutableParams
                                          httpMethod:httpMethod];//不强制使用https
    
    NSDictionary *authorParams=[NSDictionary dictionaryWithObjectsAndKeys:oauthHeader,@"Authorization", nil];
    [op addHeaders:authorParams]; //设置http header字段 Authorization by kk
    
    
    BKLog(@"%@",[op curlCommandLineString]);
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation)
     {
         completionBlock([[completedOperation responseString]objectFromJSONString]);
         
     }errorHandler:^(MKNetworkOperation *completedOperation, NSError* error) {
         errorBlock([[completedOperation responseString]objectFromJSONString], error);
     }];
    
    [self enqueueOperation:op forceReload:YES];//强制请求
    
    return op;
}

-(MKNetworkOperation*)  requestNoAuthAPI:(NSString*)apiPath
                        httpMethod:(NSString *)httpMethod
                            params:(NSDictionary *)params
                      onCompletion:(MKNKJsonResponseBlock) completionBlock
                           onError:(MKNKJsonErrorBlock) errorBlock{
    

    
    //https://github.com/500px/api-documentation
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [mutableParams setObject:OAuthConsumerKey forKey:@"consumer_key"];
    
    NSString* url = [NSString stringWithFormat:@"%@/%@",MKHostName4500px,apiPath];
    NSString* oauthHeader = [self _oauthHeaderString:httpMethod url:url token:self.accessToken extraOAuthParameters:mutableParams callback:@""];
    
    MKNetworkOperation *op = [self operationWithURLString: url
                                                   params:mutableParams
                                               httpMethod:httpMethod];//不强制使用https
    
    NSDictionary *authorParams=[NSDictionary dictionaryWithObjectsAndKeys:oauthHeader,@"Authorization", nil];
    [op addHeaders:authorParams]; //设置http header字段 Authorization by kk
    
    
    BKLog(@"%@",[op curlCommandLineString]);
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation)
     {
         completionBlock([[completedOperation responseString]objectFromJSONString]);
         
     }errorHandler:^(MKNetworkOperation *completedOperation, NSError* error) {
         errorBlock([[completedOperation responseString]objectFromJSONString], error);
     }];
    
    [self enqueueOperation:op forceReload:YES];//强制请求
    
    return op;
}


-(MKNetworkOperation*)  update:(NSString*)text
                         image:(UIImage *)image
                  onCompletion:(MKNKJsonResponseBlock) completionBlock
                       onError:(MKNKJsonErrorBlock) errorBlock
{
    return nil;
}


#pragma
 
-(void) getCurrentUserInfo
{
    /*
    NSString* requestPath =@"users";
    MKNetworkOperation* op = [self requestAPI:requestPath 
                                   httpMethod:@"POST" params:nil 
                                 onCompletion:^(NSDictionary *responseData) {
                                    HKDLog(@"success");
                                    HKDLog(@"%@",responseData);
                                    if([@"OK" isEqualToString:[[responseData objectForKey:@"meta"]objectForKey:@"msg"]])
                                    {
                                        NSDictionary *userDict = [[responseData objectForKey:@"response"]objectForKey:@"user"];
                                        
                                        NSString *name = [userDict objectForKey:@"name"];
                                        NSArray *blogsArray = [userDict objectForKey:@"blogs"];
                                        NSString *url = @"";
                                        
                                        for (int i = 0; i<blogsArray.count; i++) {
                                            NSInteger isPrimary = [[[blogsArray objectAtIndex:i]objectForKey:@"primary"]intValue];
                                            if(isPrimary == 1)
                                            {
                                                url = [[blogsArray objectAtIndex:i]objectForKey:@"url"];
                                                break;
                                            }      
                                        }
                                        
                                        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:name,@"screen_name",@"",@"profile_image", url,@"url",nil];
                                        NSString *userInfoStr = [info JSONString];
                                        NSString *sharerId = [self sharerId];
                                        [SHK setAuthValue:userInfoStr forKey:userInfoKey forSharer:sharerId];
                                        
                                    }
                                     NSDictionary *respInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"ok",@"status",nil];//根据需要添加更多信息
                                     [[NSNotificationCenter defaultCenter]postNotificationName:[self sharerId] object:nil userInfo:respInfo];
                                     
                                } onError:^(NSDictionary *responseData, NSError *error) {
                                     HKDLog(@"500px test error");
                                    NSDictionary *respInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"ok",@"status",nil];//根据需要添加更多信息
                                    [[NSNotificationCenter defaultCenter]postNotificationName:[self sharerId] object:nil userInfo:respInfo];
                            }];
    */
    //500px 获取用户信息 调试时，500px服务器500错误，待调
    NSDictionary *respInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"ok",@"status",nil];//根据需要添加更多信息
    [[NSNotificationCenter defaultCenter]postNotificationName:[self sharerId] object:nil userInfo:respInfo];

//    NSString *table = [NSString stringWithFormat:@"%@:%@:%@" ,[self sharerId],@"null",@"null"];
//    GANTRACKEVENT2(@"sns", @"register", table);
}

//- (void) test
//{
//   // [[SHK500px sharedInstance]autologin];
//    [[SHK500px sharedInstance]logout];
//    BOOL d= [[SHK500px sharedInstance]islogin];
//    
//    NSString* apiPath=@"photos";
//    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
//                            @"popular", @"feature",//可选值popular、upcoming、editors、fresh_today、fresh_yesterday、fresh_week、user（同时需要user_id or username）
//                            //@"13872296",@"max_id",//见上文注释next_max_id
//                            
//                            //http://pcdn.500px.net/10352709/5c55195e2740bfb4bfea1d976d061d1583ca5f13/3.jpg
//                            @"3",@"image_size",/* '&image_size=3' — It will return one image_url. 也支持返回一组图片，但是目前无需要，且解析二义，暂不考虑，图片存储的规律可根据url连接得出，分1-4级，1为最小*/
//                            @"1",@"page",
//                            nil];
//    
//    MKNetworkOperation* op = [[SHK500px sharedInstance] requestNoAuthAPI:apiPath httpMethod:@"GET" params:params onCompletion:^(NSDictionary *responseData) {
//        HKDLog(@"%@",@"ok");
//    } onError:^(NSDictionary *responseData, NSError *error) {
//        HKDLog(@"%@",@"error");
//    }];
//    HKDLog(@"%@",[op curlCommandLineString]);
//}

@end
