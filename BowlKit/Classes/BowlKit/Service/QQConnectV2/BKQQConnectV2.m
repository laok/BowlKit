//
//  BKQQConnectV2.m
//  BowlKit
//
//  Created by 凯 赵 on 12-5-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

//#import "MKNetworkKit.h"
#import <BowlKit/MKNetworkKit.h>
#import "BKQQConnectV2.h"
//#import "BK.h"
#import <BowlKit/BK.h>
#import "BKQQConnectV2OAuthView.h"
//#import "JSONKit.h"
#import <BowlKit/JSONKit.h>
//#import "NSHTTPCookieStorage+DeleteForURL.h"
#import <BowlKit/NSHTTPCookieStorage+DeleteForURL.h>

#import "BKDebug.h"
static NSString *authorizeURL1 = @"https://graph.qq.com/oauth2.0/authorize";
static NSString* kRestserverBaseURL = @"graph.qq.com";
//app key 微看 申请者 kk
//static NSString* qqWeiboV2ClientId =@"100342502";
//static NSString* qqWeiboV2SecretKey =@"1bb4ef882c824d51321ce7b13e2cde16"; 

//QQ空间 xuzhe
/*
static NSString* qqWeiboV2ClientId =@"100386597";
static NSString* qqWeiboV2SecretKey =@"44fd67f822ea3f810387ef1b633b63dc";

static NSString* qqWeiboV2RedirectURI =@"itubar.com";
*/
//老图吧key by kk
static NSString* qqWeiboV2ClientId1 =@"100335026";
//static NSString* qqWeiboV2SecretKey =@"1d08329c8c00d8265ad78cd4317a590f";
static NSString* qqWeiboV2RedirectURI1 =@"itubar.com";
//鉴权字段
static NSString *accessTokenKey = @"accessToken";
static NSString *usrname=@"usrname";
static NSString *expires_inKey=@"expires_in";
static NSString *kQQ_openid=@"openid";//命名不要与 类成员变量起名一致。。教训 by kk
//static NSString *kQQ_openkey=@"openkey";
//用户信息字段
static NSString *userInfoKey=@"userInfo";
//腾讯微博网址
//static NSString *weiboUrl = @"http://t.qq.com/";

static NSString *kQQ_uidKey=@"uid";

@interface BKQQConnectV2()<BKQQConnectAuthorizeWebViewDelegate,BKOAuthViewDelegate>

@property(nonatomic,strong,readonly)NSString* clientId;
@property(nonatomic,strong,readonly)NSURL* authorizeCallbackURL;

@property (nonatomic, strong) NSURL *authorizeURL;
//@property (nonatomic, strong) NSURL *accessURL;
//@property (nonatomic, strong) NSURL *requestURL;
- (BOOL)isAuthorized;
- (BOOL)authorize;
- (void)storeAccessToken;
- (BOOL)restoreAccessToken;
- (void)deleteStoredAccessToken;
- (void)promptAuthorization;

- (NSString *) getClientip;

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSTimeInterval expires_Time;
@property (nonatomic, strong) NSString *openid;
//@property (nonatomic, strong) NSString *openkey;
@property (nonatomic,strong) NSString* clientip4QQ;
@end

@implementation BKQQConnectV2
@synthesize accessToken;
@synthesize name ;
@synthesize expires_Time;
@synthesize openid ;
@synthesize clientip4QQ ;

#pragma mark – init
+ (id) sharedInstance {
    static dispatch_once_t onceToken = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&onceToken, ^{
        _sharedObject = [[BKQQConnectV2 alloc]initWithHostName:kRestserverBaseURL apiPath:nil customHeaderFields:nil];
        [_sharedObject loadConfig];
    });
    return _sharedObject;
}
-(void)loadConfig
{
    //OAUTH2
    _clientId=@"100335026";
    _authorizeCallbackURL = [NSURL URLWithString:@"itubar.com"];
    
    //固定值，不需要改变
    _authorizeURL= [NSURL URLWithString:@"https://graph.qq.com/oauth2.0/authorize"];
}

+ (NSString *)sharerTitle
{
    return @"QQ互联开放平台";
}

- (void) logout
{
   [NSHTTPCookieStorage deleteCookiesForURL:self.authorizeURL];
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

#pragma mark – OAuth 过程
- (NSString *) getClientip
{
    if ([clientip4QQ length]) {
        return clientip4QQ;
    }
   //通过公网服务获取当前设备公网地址，但该服务可能会失效 by kk，（最好由自己的服务器提供该服务）
    NSString* fakeip=[NSString stringWithFormat:@"%d.%d.%d.%d",
                      arc4random() % 250+1,
                      arc4random() % 250+1,
                      arc4random() % 250+1,
                      arc4random() % 250+1 ];
    
    MKNetworkOperation *op = [self operationWithURLString:@"http://automation.whatismyip.com/n09230945.asp" params:nil httpMethod:@"GET"];
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        DLog(@"Data from server %@", [completedOperation responseString]);
        NSString *ip = [completedOperation responseString];
        NSArray *array = [ip componentsSeparatedByString:@"."]; //从字符A中分隔成2个元素的数组
        if ([array count]==4 || [[array objectAtIndex:0]intValue]<=255 ||[[array objectAtIndex:1]intValue]<=255 ||[[array objectAtIndex:2]intValue]<=255 ||[[array objectAtIndex:3]intValue] <= 255 ) {
            self.clientip4QQ = ip;
        }else {
            self.clientip4QQ=fakeip;
        }
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        clientip4QQ = fakeip;
        DLog(@"Data from server %@", [completedOperation responseString]);
    }];
    
    [self enqueueOperation:op forceReload:YES];//强制请求
    
    return fakeip;
}

- (void)storeAccessToken
{	
     BKLog(@"%@,%@,%lf,%@",self.accessToken,self.name,self.expires_Time,self.sharerId);
	 NSString *sharerId = [self sharerId];
	[BK setAuthValue:self.accessToken forKey:accessTokenKey forSharer:sharerId];
    [BK setAuthValue:self.name forKey:usrname forSharer:sharerId];
    [BK setAuthValue:[NSString stringWithFormat:@"%lf", self.expires_Time] forKey:expires_inKey forSharer:sharerId];
    [BK setAuthValue:self.openid forKey:kQQ_openid forSharer:sharerId];
    [BK setAuthValue:self.openid forKey:kQQ_uidKey forSharer:sharerId];
//    [SHK setAuthValue:self.openkey forKey:kQQ_openkey forSharer:sharerId];
}

- (BOOL)restoreAccessToken
{
    if (self.expires_Time>0 && [[NSDate date] timeIntervalSince1970] > self.expires_Time){
        //时间过期，强制logout 
        [self deleteStoredAccessToken];
        return NO;
    }
    
	if ([self.accessToken length] && /*[self.name length] &&*/ [[NSDate date] timeIntervalSince1970] < self.expires_Time &&
        /*[self.openkey length] &&*/ [self.openid length])
		return YES;
    
    NSString *sharerId = [self sharerId];
	self.accessToken = [BK getAuthValueForKey:accessTokenKey forSharer:sharerId];
    self.name = [BK getAuthValueForKey:usrname forSharer:sharerId];
    self.expires_Time = [[BK getAuthValueForKey:expires_inKey forSharer:sharerId]doubleValue];
    self.openid = [BK getAuthValueForKey:kQQ_openid forSharer:sharerId];
//    self.openkey = [SHK getAuthValueForKey:kQQ_openkey forSharer:sharerId];
	
    if ([[NSDate date] timeIntervalSince1970] > self.expires_Time){
        //时间过期，强制logout 
        [self deleteStoredAccessToken];
        return NO;
    }
    
    BKLog(@"%@,%@,%lf,%@",self.accessToken,self.name,self.expires_Time,self.openid);
	return ([self.accessToken length] && /*[self.name length] &&*/ [[NSDate date] timeIntervalSince1970] < self.expires_Time &&/* [self.openkey length] &&*/ [self.openid length]);
}

- (void)deleteStoredAccessToken
{
	NSString *sharerId = [self sharerId];
	
    [BK removeAuthValueForKey:accessTokenKey forSharer:sharerId];
    [BK removeAuthValueForKey:usrname forSharer:sharerId];
    [BK removeAuthValueForKey:expires_inKey forSharer:sharerId];
    [BK removeAuthValueForKey:kQQ_openid forSharer:sharerId];
//    [SHK removeAuthValueForKey:kQQ_openkey forSharer:sharerId];
    [BK removeAuthValueForKey:userInfoKey forSharer:sharerId];
    
    self.accessToken =nil;
    self.name=nil;
    self.expires_Time=0;
    self.openid = nil;
//    self.openkey = nil;
}

- (BOOL)isAuthorized
{		
	return [self restoreAccessToken];
}

- (void)promptAuthorization
{
    /*
     https://graph.qq.com/oauth2.0/authorize?status_version=v2.0&response_type=token&type=user_agent&scope=get_user_info%2Cadd_share%2Cadd_topic%2Cadd_one_blog%2Clist_album%2Cupload_pic%2Clist_photo%2Cadd_album%2Ccheck_page_fans&client_id=100266567&redirect_uri=www.qq.com&status_os=5.000000&status_machine=iPhone%20Simulator&display=mobile
     */
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"token", @"response_type",
                                   self.clientId, @"client_id",
                                   @"user_agent", @"type",
                                   self.authorizeCallbackURL, @"redirect_uri",
                                   @"mobile", @"display",
								   [NSString stringWithFormat:@"%f",[[[UIDevice currentDevice] systemVersion] floatValue]],@"status_os",
								   [[UIDevice currentDevice] name],@"status_machine",
                                   @"v2.0",@"status_version",
                                   nil];
    
    //根据需求,获取api权限，显示在客户端授权页面
    NSMutableArray* permissions = [NSMutableArray arrayWithObjects:@"get_user_info",
                                   @"add_share",@"check_page_fans", @"add_t",@"del_t", @"add_pic_t",
                                   @"get_repost_list",@"get_info", @"get_other_info", @"get_fanslist",
                                   @"get_idollist",@"add_idol",@"del_idol",nil];
    
    if (permissions != nil) {
		NSString* scope = [permissions componentsJoinedByString:@","];
		[params setValue:scope forKey:@"scope"];
	}

     NSString* finall_url = [NSString stringWithFormat:@"%@?%@", self.authorizeURL.absoluteString,
                            [params urlEncodedKeyValueString]];
    
    NSURL* url=[NSURL URLWithString:finall_url];
    BKQQConnectV2OAuthView *auth = [[BKQQConnectV2OAuthView alloc] initWithURL:url delegate:self];
	[[BK currentHelper] showViewController:auth];
}

- (void)tokenAuthorizeView:(BKOAuthView *)authView didFinishWithSuccess:(BOOL)success queryParams:(NSMutableDictionary *)queryParams error:(NSError *)error
{
#warning 无网络状态下，授权页面会授权失败，此时，是否应该有所提示呢？
    if (!success && error) {
        BKLog(@"%@",[error localizedDescription]);
        [[[UIAlertView alloc] initWithTitle:@"Request Error"
                                    message:error!=nil?[error localizedDescription]:@"There was a problem requesting authorization"
                                   delegate:nil
                          cancelButtonTitle:@"Close"
                          otherButtonTitles:nil] show];
    }
    BKLog(@"tokenAuthorizeView");
}

- (BOOL)authorize
{
	if ([self isAuthorized])
		return YES;
	
	else 
		[self promptAuthorization];
	
	return NO;
}

- (void)tokenAuthorizeCancelledView:(BKOAuthView *)authView
{
	[[BK currentHelper] hideCurrentViewControllerAnimated:YES];	
    //[self authDidFinish:NO];
}

- (void)requestAccessTokenWithAuthorizeCode:(NSString *)code
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            code, @"access_token", nil];
    
    //注意：获取token的apipath 与微薄功能调用api 路径不一致
    //https://open.t.qq.com/cgi-bin/oauth2/access_token?client_id=APP_KEY&client_secret=APP_SECRET&redirect_uri=http://www.myurl.com/example&grant_type=authorization_code&code=CODE
    MKNetworkOperation *op = [self operationWithURLString:@"https://graph.qq.com/oauth2.0/me"
                                              params:params
                                               httpMethod:@"GET"];//
    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation)
     {
         [[BK currentHelper] hideCurrentViewControllerAnimated:YES];


         NSString* respString = [completedOperation responseString];
         if ([[respString substringToIndex:8] isEqualToString:@"callback"]) {
             respString = [respString substringWithRange:NSMakeRange(10, [respString length]-13)];
         }
         
         NSMutableDictionary* dict = [respString objectFromJSONString];
         
         //采用mknetwork的json解析，在这里会解析错误
         //{"client_id":"100266567","openid":"A0335258CCF963C9357B634228BA57B4"}
         if ([dict isKindOfClass:[NSDictionary class]])
         {
            // NSString *client_id_test = [dict objectForKey:@"client_id"];
            // NSString *openid_test = [dict objectForKey:@"openid"];
             self.openid = [dict objectForKey:@"openid"];
             [self storeAccessToken];
             [self getCurrentUserInfo];
         }
         
     }errorHandler:^(MKNetworkOperation *completedOperation, NSError* error) {
         
         NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:@"err",@"status",nil];
         [[NSNotificationCenter defaultCenter]postNotificationName:[self sharerId] object:nil userInfo:info];
         DLog(@"Data from server %@", [completedOperation responseString]);
     }];
    
    [self enqueueOperation:op forceReload:YES];//强制请求
    
}
- (void)authorizeWebView:(BKQQConnectV2OAuthView *)webView didReceiveAuthorizeCode:(NSString *)code
{
    // 授权过程被 取消
    if (![code isEqualToString:@"21330"])//腾讯微薄，授权过程，页面取消，会返回登陆，而不是如新浪微薄授权一样，返回错误码
    {
        //注意查找数据的格式一定是：CODE&openid=OPENID&openkey=OPENKEY，否则查找错误
        //access_token & key & expires_in
        //BEF3F7C7BB00DBABF2210A926C414B02&key=e89cd66b107e19c5f741a2843a2af1f1&expires_in=7776000
        
        NSRange key = [code rangeOfString:@"&key="];
        NSRange expires= [code rangeOfString:@"&expires_in="];
        BOOL hasKey=YES;
        if (key.length) {
            hasKey=expires.location>key.location;
        }
        if (/*key.location != NSNotFound &&*/
            expires.location != NSNotFound && hasKey) {
            
            NSString* token_code =  [code substringWithRange:NSMakeRange(0,expires.location)];//注意：自2013.10.9日发现qq互联oauth2授权返回code不再提供key参数，而修改
            if (key.location !=NSNotFound) {
                token_code =  [code substringWithRange:NSMakeRange(0,key.location)];
            }
//            NSString* open_key= [code substringWithRange:NSMakeRange(key.location + key.length,expires.location-key.length-key.location)];
            NSString* expires_in=[code substringFromIndex:expires.location+expires.length];
            
            self.accessToken = token_code;
            NSInteger seconds = [expires_in intValue];
            self.expires_Time = [[NSDate date] timeIntervalSince1970] + seconds;
            
//            self.openkey = open_key;
            [self requestAccessTokenWithAuthorizeCode:token_code];
        }
        //todo:授权解析code错误的处理 by kk
        //add here
        [[BK currentHelper] hideCurrentViewControllerAnimated:YES];
    }
    else 
    {
        [[BK currentHelper] hideCurrentViewControllerAnimated:YES];
    }
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
    //=====================
    //https://open.t.qq.com/api/REQUEST_METHOD?oauth_consumer_key=APP_KEY&access_token=ACCESSTOKEN&openid=OPENID&clientip=CLIENTIP&oauth_version=2.a&scope=all
    //=====================
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
//    [mutableParams setObject:qqWeiboV2ClientId forKey:@"oauth_consumer_key"];
//    [mutableParams setObject:self.accessToken forKey:@"access_token"];
//    [mutableParams setObject:self.openid forKey:@"openid"];
//    
//    [mutableParams setObject:[self getClientip] forKey:@"clientip"];
//    [mutableParams setObject:@"2.a" forKey:@"oauth_version"];
//    [mutableParams setObject:@"all" forKey:@"scope"];
    
    [mutableParams setValue:@"json" forKey:@"format"];
	[mutableParams setValue:self.clientId forKey:@"oauth_consumer_key"];
	[mutableParams setValue:self.accessToken forKey:@"access_token"];
	[mutableParams setValue:self.openid forKey:@"openid"];

    
    MKNetworkOperation *op = [self operationWithPath:apiPath
                                              params:mutableParams
                                          httpMethod:httpMethod
                                                 ssl:YES];//强制使用https
    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation)
     {
         BKLog(@"%@",[completedOperation responseString]);
         completionBlock([[completedOperation responseString]objectFromJSONString]);
         
     }errorHandler:^(MKNetworkOperation *completedOperation, NSError* error) {
         //============临时处理======
         NSMutableDictionary* dict = [[completedOperation responseString] objectFromJSONString];
         if ([dict isKindOfClass:[NSDictionary class]])
         {
             int error_code = [[dict objectForKey:@"error_code"] intValue] ;
//             NSString* error= [dict objectForKey:@"error"];
             switch (error_code) {
                 case 21327:
                     BKLog(@"%@,%d",error,error_code);
                     
                     [self deleteStoredAccessToken];
                     break;
                     
                 default:
                     break;
             }
             
         }
         //========================
         errorBlock([[completedOperation responseString]objectFromJSONString], error);
     }];
    
    [self enqueueOperation:op forceReload:YES];//强制请求
    
    return op;
}


//指定一个图片URL地址抓取后上传
-(MKNetworkOperation*)  updateUrl:(NSString*)text
                         imageUrl:(NSString *)imageUrl
                     onCompletion:(MKNKJsonResponseBlock) completionBlock
                          onError:(MKNKJsonErrorBlock) errorBlock
{
    if (![self authorize]) {
        return nil;
    }
    
    NSString* apiPath=@"share/add_share";//发送一条微博到腾讯微博
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"json",@"format",
							@"图吧美图分享", @"title",
                            @"http://www.itubar.com", @"url",
                            //[text length]?text:@"图吧美图分享",@"comment",
                            [text length]?text:@"图吧美图分享",@"summary",
                            imageUrl,@"images",
                            @"4",@"type",
                            @"官网",@"site",
                            @"http://www.itubar.com",@"fromurl",
                            @"1",@"nswb",//值为1时，表示分享不默认同步到微博，其他值或者不传此参数表示默认同步到微博。
                            nil];
    
    //====================================================
    
    MKNetworkOperation* op= [self  requestAPI:apiPath
                                   httpMethod:@"POST"
                                       params:params
                                 onCompletion:^(NSDictionary* responseData){
                                      completionBlock(responseData);
                                 }onError:^(NSDictionary* responseData, NSError *error){
                                     errorBlock(responseData, error);
                                 }];
    
    
    return op;
}
-(MKNetworkOperation*)  update:(NSString*)text
                      imageUrl:(NSString *)imageUrl
                         image:(UIImage*)image
                  onCompletion:(MKNKJsonResponseBlock) completionBlock
                       onError:(MKNKJsonErrorBlock) errorBlock
{
    NSString* apiPath=@"t/add_t";
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"json",@"format",
							text, @"content",
                            [self getClientip], @"clientip",
                            nil];
    
    MKNetworkOperation* op= [self  requestAPI:apiPath
                                   httpMethod:@"POST"
                                       params:params
                                 onCompletion:^(NSDictionary* responseData){
                                     BKLog(@"success");
                                     completionBlock(responseData);
                                                                              
                                 }onError:^(NSDictionary* responseData, NSError *error){
                                     errorBlock(responseData, error);
                                 }];
    return op;
    
}

-(void)getCurrentUserInfo
{

    NSString* apiPath=@"user/get_user_info";
    /*MKNetworkOperation* op= */[self  requestAPI:apiPath
                                   httpMethod:@"GET"  
                                       params:nil
                                 onCompletion:^(NSDictionary* responseData){
                                     BKLog(@"success");
                                     NSInteger retVal = [[responseData objectForKey:@"ret"]intValue];
                                     if(retVal == 0)
                                     {
                                         NSString *screen_name = [responseData objectForKey:@"nickname"];
                                         NSString *headUrl = [responseData objectForKey:@"figureurl_2"];
                                         NSString *gender = [responseData objectForKey:@"gender"];
                                         //新浪约定：gender性别 m：男、f：女、n：未知 默认为 m
                                         if ([gender length]) {
                                             if ([gender isEqualToString:@"男"]) {
                                                 gender=@"m";
                                             }else if([gender isEqualToString:@"女"])
                                             {
                                                 gender=@"f";
                                             }else
                                             {
                                                 gender=@"n";
                                             }
                                         }else
                                         {
                                             gender=@"m";
                                         }
                                         NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:screen_name,@"screen_name",headUrl,@"profile_image",gender,@"gender",nil];
                                         NSString *userInfoStr = [info JSONString];
                                         
                                         NSString *sharerId = [self sharerId];
                                         [BK setAuthValue:userInfoStr forKey:userInfoKey forSharer:sharerId];

                                         NSDictionary *respInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"ok",@"status",nil];//根据需要添加更多信息
                                         [[NSNotificationCenter defaultCenter]postNotificationName:[self sharerId] object:nil userInfo:respInfo];
                                     }else{
                                         NSDictionary *respInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"err",@"status",nil];//根据需要添加更多信息
                                         [[NSNotificationCenter defaultCenter]postNotificationName:[self sharerId] object:nil userInfo:respInfo];
                                     }
                                     
                                 }onError:^(NSDictionary* responseData, NSError *error){
                                     //dosomething
                                     BKLog(@"error");
                                     NSDictionary *respInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"err",@"status",nil];//根据需要添加更多信息
                                     [[NSNotificationCenter defaultCenter]postNotificationName:[self sharerId] object:nil userInfo:respInfo];
                                 }];
    
    
}




-(void) test_qq_api
{
    /*
    @"add_share",@"check_page_fans", @"add_pic_t",
    @"get_repost_list", @"get_other_info", @"get_fanslist",
    @"get_idollist",@"add_idol",@"del_idol"
     */
    
    //已测试 add_t del_t get_info
    
    
    /*
    //==POST==========发微博  t/add_t=====================================
    //http://wiki.opensns.qq.com/wiki/%E3%80%90QQ%E7%99%BB%E5%BD%95%E3%80%91add_t
    NSString* apiPath=@"t/add_t";//发送一条微博到腾讯微博
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"json",@"format",
                            @"test",@"content",
                            nil];
    //==POST==========发微博  del_t=====================================
    //http://wiki.opensns.qq.com/wiki/%E3%80%90QQ%E7%99%BB%E5%BD%95%E3%80%91del_t
    NSString* apiPath=@"t/del_t";//发送一条微博到腾讯微博
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"json",@"format",
                            @"204208065565356",@"id",
                            nil];
    //==GET===========get_info==============================================
    NSString* apiPath=@"user/get_info";//发送一条微博到腾讯微博
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"json",@"format",
                            nil];
    */
    //==POST===========add_share==============================================
    //http://wiki.opensns.qq.com/wiki/%E3%80%90QQ%E7%99%BB%E5%BD%95%E3%80%91add_share
    NSString* apiPath=@"share/add_share";//发送一条微博到腾讯微博

    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"json",@"format",
							@"kk api 测试", @"title",
                            @"http://www.qq.com", @"url",
                            @"风云comment人物",@"comment",
                            @"乃至summary生活的方式。",@"summary",
                            @"http://img1.gtimg.com/tech/pics/hv1/95/153/847/55115285.jpg",@"images",
                            @"4",@"type",
                            @"官网",@"site",
                            @"http://www.itubar.com",@"fromurl",
								   nil];
    //====================================================
   /* MKNetworkOperation* op= */[self  requestAPI:apiPath
                                   httpMethod:@"POST"
                                       params:params
                                 onCompletion:^(NSDictionary* responseData){
                                     BKLog(@"success");
                                 }onError:^(NSDictionary* responseData, NSError *error){
                                     BKLog(@"error");
                                 }];
    
}
@end
