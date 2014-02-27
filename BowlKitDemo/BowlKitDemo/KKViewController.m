//
//  KKViewController.m
//  BowlKitDemo
//
//  Created by kk on 14-2-27.
//  Copyright (c) 2014年 kk. All rights reserved.
//

#import "KKViewController.h"
#import "BK500px.h"
#import "BKQQConnectV2.h"
#import "BowlKitDemoConfigurator.h"
#import "BK.h"
#import "BKConfiguration.h"

@interface KKViewController ()
- (IBAction)login500px:(id)sender;
- (IBAction)loginQQConnect:(id)sender;

@end

@implementation KKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
    DefaultBKConfigurator* config=[[BowlKitDemoConfigurator alloc]init];
    [BKConfiguration sharedInstanceWithConfigurator:config];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)login500px:(id)sender {
    
    NSLog(@"title:%@",[BK500px sharerTitle]);
    NSLog(@"id:%@",[BK500px sharerId]);
    [[BK500px sharedInstance]logout];
    if (![[BK500px sharedInstance] islogin])
    {
        [[BK500px sharedInstance] autologin];
    }
}

- (IBAction)loginQQConnect:(id)sender {
    NSLog(@"title:%@",[BKQQConnectV2 sharerTitle]);
    NSLog(@"id:%@",[BKQQConnectV2 sharerId]);
    [[BKQQConnectV2 sharedInstance]logout];
    if (![[BKQQConnectV2 sharedInstance] islogin])
    {
        [[BKQQConnectV2 sharedInstance] autologin];
    }
}
@end
