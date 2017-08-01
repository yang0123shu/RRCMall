//
//  AppDelegate.m
//  RRCMall
//
//  Created by 阳书成 on 2017/7/6.
//  Copyright © 2017年 shenzhenRRC. All rights reserved.
//

#import "AppDelegate.h"
#import "WKWebViewController.h"
#import "Reachability.h"
#import "ViewController.h"
#import "Pingpp.h"


//#import <ShareSDK/ShareSDK.h>
//#import <ShareSDKConnector/ShareSDKConnector.h>
////腾讯开放平台（对应QQ和QQ空间）SDK头文件
//#import <TencentOpenAPI/TencentOAuth.h>
//#import <TencentOpenAPI/QQApiInterface.h>
////微信SDK头文件
//#import "WXApi.h"
#import "MOBShareSDKHelper.h"
@interface AppDelegate ()<UIScrollViewDelegate>
{
    Reachability *rea;
    
    UIWindow *throuWindow;
    NSMutableArray *images;
    UIScrollView *throughView;
    UIPageControl *pageCtl;
    UIButton *lastBtn;
}
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
   
//    else{
        [self setRootView];
        rea = [Reachability reachabilityWithHostName:@"https://baidu.com"];
        [rea startNotifier];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:kReachabilityChangedNotification object:nil];
//    }
    
    [Pingpp setDebugMode:YES];
    NSLog(@"ping++版本 = %@",[Pingpp version]);
    [self.window makeKeyAndVisible];
//    [self settingShareSDK];
    return YES;
}

//-(void)settingShareSDK
//{
//    [ShareSDK registerActivePlatforms:@[
//                                        @(SSDKPlatformTypeWechat),
//                                        @(SSDKPlatformTypeQQ)
//                                        ]
//                             onImport:^(SSDKPlatformType platformType)
//     {
//         switch (platformType)
//         {
//             case SSDKPlatformTypeWechat:
//                 [ShareSDKConnector connectWeChat:[WXApi class]];
//                 break;
//             case SSDKPlatformTypeQQ:
//                 [ShareSDKConnector connectQQ:[QQApiInterface class] tencentOAuthClass:[TencentOAuth class]];
//                 break;
//             default:
//                 break;
//         }
//     }
//                      onConfiguration:^(SSDKPlatformType platformType, NSMutableDictionary *appInfo)
//     {
//         switch (platformType)
//         {
//             case SSDKPlatformTypeWechat:
//                 [appInfo SSDKSetupWeChatByAppId:WECHATAPPID
//                                       appSecret:WECHATAPPKEY];
//                 break;
//             case SSDKPlatformTypeQQ:
//                 [appInfo SSDKSetupQQByAppId:QQAPPID
//                                      appKey:QQAPPKEY
//                                    authType:SSDKAuthTypeBoth];
//                 break;
//             default:
//                 break;
//         }
//     }];
//    
//}

-(void)setRootView
{
    WKWebViewController *vc = [[WKWebViewController alloc]init];
    [vc loadWebURLSring:kBaseURL];
    //    [vc loadWebHTMLSring:@"属性选择器"];
    vc.isNavHidden = YES;
    UINavigationController *navi = [[UINavigationController alloc]initWithRootViewController:vc];
    navi.navigationBarHidden = YES;
    self.window.rootViewController = navi;
    
    //    self.window.rootViewController = [[ViewController alloc]init];
}

-(void)displayWelcomeImageScrollView
{
    [UIApplication sharedApplication].statusBarHidden = YES;
    CGRect frame = [[UIScreen mainScreen] bounds];
//    throuWindow = [[UIWindow alloc]initWithFrame:frame];
//    throuWindow.backgroundColor = [UIColor whiteColor];
//    [self.window addSubview:throuWindow];
    NSArray *imageNames;
    if ([UIScreen mainScreen].bounds.size.height == 480) {
        imageNames = @[@"G1_4.jpg",@"G2_4.jpg",@"G3_4.jpg"];
    }
    else if ([UIScreen mainScreen].bounds.size.height == 568)
    {
        imageNames = @[@"G1_5.jpg",@"G2_5.jpg",@"G3_5.jpg"];
    }
    else if ([UIScreen mainScreen].bounds.size.height == 667)
    {
        imageNames = @[@"G1_6.jpg",@"G2_6.jpg",@"G3_6.jpg"];
    }
    else if ([UIScreen mainScreen].bounds.size.height >= 736)
    {
        imageNames = @[@"G1_6P.jpg",@"G2_6P.jpg",@"G3_6P.jpg"];
    }
    images = [NSMutableArray arrayWithArray:imageNames];
    throughView = [[UIScrollView alloc]initWithFrame:frame];
    throughView.pagingEnabled = YES;
//    throughView.directionalLockEnabled = NO;
    throughView.delegate = self;
    throughView.backgroundColor = [UIColor redColor];
//    throughView.showsVerticalScrollIndicator = NO;
//    throughView.showsHorizontalScrollIndicator = NO;
    throughView.backgroundColor = [UIColor whiteColor];
    throughView.contentSize = CGSizeMake(throughView.frame.size.width * images.count, throughView.frame.size.height);
    [self.window addSubview:throughView];
    [self.window bringSubviewToFront:throughView];
    
    for (int i = 0; i <images.count; i ++) {
        UIImage *image = [UIImage imageNamed:images[i]];
        UIImageView *sigleImageView = [[UIImageView alloc]initWithImage:image];
        sigleImageView.frame = CGRectMake(throughView.frame.size.width * i, 0, throughView.frame.size.width, throughView.frame.size.height);
        sigleImageView.backgroundColor = [UIColor whiteColor];
        sigleImageView.contentMode = UIViewContentModeScaleToFill;
        [throughView addSubview:sigleImageView];
    }
    CGRect pageCtlFrame = CGRectMake(self.window.frame.size.width / 2 - 60, throughView.frame.size.height - 40, 120, 30);
    pageCtl = [[UIPageControl alloc]initWithFrame:pageCtlFrame];
    pageCtl.numberOfPages = images.count;
    pageCtl.currentPage = 0;
    pageCtl.backgroundColor = [UIColor clearColor];
    
    pageCtl.hidesForSinglePage = YES;
    
    pageCtl.pageIndicatorTintColor = [UIColor groupTableViewBackgroundColor];
    pageCtl.currentPageIndicatorTintColor = [UIColor redColor];
    
    [self.window addSubview:pageCtl];
//    [self.window bringSubviewToFront:pageCtl];
    
    
    lastBtn = [[UIButton alloc]initWithFrame:CGRectMake(throughView.frame.size.width - 100, throughView.frame.size.height - 60, 80, 30)];
    [lastBtn setTitle:@"不再显示" forState:UIControlStateNormal];
    lastBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    lastBtn.hidden = YES;
    lastBtn.layer.borderColor = (__bridge CGColorRef _Nullable)([UIColor whiteColor]);
    lastBtn.layer.cornerRadius = 5;
    lastBtn.layer.borderWidth  = 0.7;
    [lastBtn addTarget:self action:@selector(toHideThroughView) forControlEvents:UIControlEventTouchUpInside];
    [lastBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.window addSubview:lastBtn];
}

-(void)toHideThroughView
{
    [UIView animateWithDuration:0.7 animations:^{
        throughView.alpha = 0.2;
        //        [throughView.heightAnchor constraintEqualToConstant:0].active = YES;
    }completion:^(BOOL finished) {
        
        //            [self creatMainView];
        [throughView removeFromSuperview];
        [pageCtl removeFromSuperview];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *dic = [defaults dictionaryRepresentation];
        for (NSString *key in dic.allKeys) {
            if (([key rangeOfString:@"isUsed"].location != NSNotFound) && ![key isEqualToString:IsUsedKey]) {
                [defaults removeObjectForKey:key];
            }
        }
        [defaults setValue:@"YES" forKey:IsUsedKey];
        lastBtn.hidden = YES;
        [UIApplication sharedApplication].statusBarHidden = NO;
        [self setRootView];
        rea = [Reachability reachabilityWithHostName:@"https://baidu.com"];
        [rea startNotifier];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:kReachabilityChangedNotification object:nil];
        
    }];
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger pageNum = (NSInteger)(scrollView.contentOffset.x/scrollView.bounds.size.width);
    pageCtl.currentPage = pageNum;
    if (pageNum == images.count - 1) {
        lastBtn.hidden = NO;
    }
    if (pageNum == images.count) {
        [self toHideThroughView];
    }
}

-(void)networkStatusChanged:(NSNotification*)notification
{
    switch (rea.currentReachabilityStatus) {
        case NotReachable:
        {
            NSLog(@"网络不可用");
        }
            break;
        case ReachableViaWWAN:
        {
            NSLog(@"移动网络");
        }
            break;
        case ReachableViaWiFi:
        {
            NSLog(@"WIFI网络");
        }
            break;
        default:
            break;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


//为了能正确获得结果回调请在工程 AppDelegate 文件中调用 ｀[Pingpp handleOpenURL:url withCompletion:nil]`。\
//如果该方法的第二个参数传 nil，请在在 `createPayment` 方法的 `Completion` 中处理回调结果。否则，在这里处理结果。\
//如果你使用了微信分享、登录等一些看起来在这里“冲突”的模块，你可以先判断 url 的 host 来决定调用哪一方的方法。\
//也可以先调用 Ping++ 的方法，如果 return 的值为 false，表示这个 url 不是支付相关的，你再调用模块的方法。
// iOS 8 及以下请用这个
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"url.host = %@",url.host);
    return [Pingpp handleOpenURL:url withCompletion:nil];
}

// iOS 9 以上请用这个
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary *)options {
    NSLog(@"iOS 9+ url.host = %@",url.host);
    if ([url.host rangeOfString:@"ping"].location != NSNotFound) {
        return [Pingpp handleOpenURL:url withCompletion:nil];
    }
//    return [[UIApplication sharedApplication] handleOpenURL:url withCompletion:nil];
    return YES;
}


@end
