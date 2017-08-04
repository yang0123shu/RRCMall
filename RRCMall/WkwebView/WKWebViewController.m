//
//  WKWebViewController.m
//  WKWebViewOC
//
//  Created by XiaoFeng on 2016/11/24.
//  Copyright © 2016年 XiaoFeng. All rights reserved.
//  QQ群: 384089763 欢迎加入
//  github链接: https://github.com/XFIOSXiaoFeng/WKWebView


#import "WKWebViewController.h"

#import <WebKit/WKWebView.h>
#import <WebKit/WebKit.h>

#import "RRCNetworkTool.h"
#import "Pingpp.h"
#import "Masonry.h"
#import "MOBShareSDKHelper.h"
typedef enum{
    loadWebURLString = 0,
    loadWebHTMLString,
    POSTWebURLString,
}wkWebLoadType;

static void *WkwebBrowserContext = &WkwebBrowserContext;

@interface WKWebViewController ()<WKNavigationDelegate,UIScrollViewDelegate,WKUIDelegate,WKScriptMessageHandler,UINavigationControllerDelegate,UINavigationBarDelegate>

{
    NSMutableArray *images;
    UIScrollView *throughView;
    UIPageControl *pageCtl;
    UIButton *lastBtn;
    UIView *statusBarView;
    BOOL hideNavi;
    NSLayoutConstraint *statusViewHeightCons;
    NSLayoutConstraint *webViewTopCons;
    NSLayoutConstraint *progressViewHeigthCons;
    NSLayoutConstraint *progressViewTopCons;
    BOOL webViewDidFinishLoad;
    UIImageView *waitingImageView;
}
@property (nonatomic, strong) WKWebView *wkWebView;
//设置加载进度条
@property (nonatomic,strong) UIProgressView *progressView;
//仅当第一次的时候加载本地JS
@property(nonatomic,assign) BOOL needLoadJSPOST;
//网页加载的类型
@property(nonatomic,assign) wkWebLoadType loadType;
//保存的网址链接
@property (nonatomic, copy) NSString *URLString;
//保存POST请求体
@property (nonatomic, copy) NSString *postData;
//保存请求链接
@property (nonatomic)NSMutableArray* snapShotsArray;
//返回按钮
@property (nonatomic)UIBarButtonItem* customBackBarItem;
//关闭按钮
@property (nonatomic)UIBarButtonItem* closeButtonItem;

@end

@implementation WKWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    //加载web页面
    [self webViewloadURLType];
    self.view.backgroundColor = [UIColor whiteColor];
    //添加到主控制器上
    [self.view addSubview:self.wkWebView];
    //添加进度条
    [self.view addSubview:self.progressView];
    //    self.navigationController.navigationBarHidden = YES;
    //创建一个高20的假状态栏
    statusBarView = [[UIView alloc] init];
    //设置成绿色
    statusBarView.backgroundColor=[UIColor colorWithWhite:1 alpha:1];
    // 添加到 navigationBar 上
    [self.view addSubview:statusBarView];
    
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
    [self.navigationController.navigationBar setBackgroundImage:[self imageWithColor:[UIColor whiteColor]] forBarMetrics:UIBarMetricsDefault];
    
    if (_isNavHidden) {
        self.navigationController.navigationBarHidden = YES;
        [statusBarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.view.mas_left);
            make.top.equalTo(self.view.mas_top);
            make.right.equalTo(self.view.mas_right);
            make.height.equalTo(@20);
        }];
        [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.view.mas_left);
            make.top.equalTo(statusBarView.mas_bottom);
            make.width.equalTo(self.view.mas_width);
            make.height.equalTo(@3);
        }];
        [self.wkWebView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.view.mas_left);
            make.top.equalTo(self.progressView.mas_bottom);
            make.width.equalTo(self.view.mas_width);
            make.bottom.equalTo(self.view.mas_bottom);
        }];
    }
    else{
        self.navigationController.navigationBarHidden = NO;
        [statusBarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.view.mas_left);
            make.top.equalTo(self.view.mas_top);
            make.right.equalTo(self.view.mas_right);
            make.height.equalTo(@0);
        }];
        [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.view.mas_left);
            make.top.equalTo(self.view.mas_top).offset(64);
            make.width.equalTo(self.view.mas_width);
            make.height.equalTo(@3);
        }];
        [self.wkWebView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.view.mas_left);
            make.top.equalTo(self.progressView.mas_bottom);
            make.width.equalTo(self.view.mas_width);
            make.height.equalTo(@(kScreenHeight - 67));
        }];
    }
    
    
    //添加右边刷新按钮
    //    UIBarButtonItem *roadLoad = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(roadLoadClicked)];
    //    self.navigationItem.rightBarButtonItem = roadLoad;
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString *isUsed = [defaults valueForKey:IsUsedKey];
    
    if (!isUsed) {
        [self displayWelcomeImageScrollView];
    }
    else {
        waitingImageView = [[UIImageView alloc]init];
        waitingImageView.image = [UIImage imageNamed:@"lauche.jpg"];
        [[UIApplication sharedApplication].keyWindow addSubview:waitingImageView];
        [waitingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.right.bottom.equalTo([UIApplication sharedApplication].keyWindow);
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}


- (UIImage *)imageWithColor:(UIColor*)color
{
    CGRect rect=CGRectMake(0,0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

-(void)displayWelcomeImageScrollView
{
    [UIApplication sharedApplication].statusBarHidden = YES;
    CGRect frame = [[UIScreen mainScreen] bounds];
    //    throuview = [[UIview alloc]initWithFrame:frame];
    //    throuview.backgroundColor = [UIColor whiteColor];
    //    [self.view addSubview:throuview];
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
    throughView.showsVerticalScrollIndicator = NO;
    throughView.showsHorizontalScrollIndicator = NO;
    throughView.backgroundColor = [UIColor whiteColor];
    throughView.contentSize = CGSizeMake(throughView.frame.size.width * images.count, throughView.frame.size.height);
    [self.view addSubview:throughView];
    [self.view bringSubviewToFront:throughView];
    
    for (int i = 0; i <images.count; i ++) {
        UIImage *image = [UIImage imageNamed:images[i]];
        UIImageView *sigleImageView = [[UIImageView alloc]initWithImage:image];
        sigleImageView.frame = CGRectMake(throughView.frame.size.width * i, 0, throughView.frame.size.width, throughView.frame.size.height);
        sigleImageView.backgroundColor = [UIColor whiteColor];
        sigleImageView.contentMode = UIViewContentModeScaleToFill;
        [throughView addSubview:sigleImageView];
    }
    CGRect pageCtlFrame = CGRectMake(self.view.frame.size.width / 2 - 60, throughView.frame.size.height - 40, 120, 30);
    pageCtl = [[UIPageControl alloc]initWithFrame:pageCtlFrame];
    pageCtl.numberOfPages = images.count;
    pageCtl.currentPage = 0;
    pageCtl.backgroundColor = [UIColor clearColor];
    
    pageCtl.hidesForSinglePage = YES;
    
    pageCtl.pageIndicatorTintColor = [UIColor groupTableViewBackgroundColor];
    pageCtl.currentPageIndicatorTintColor = [UIColor redColor];
    
    [self.view addSubview:pageCtl];
    //    [self.view bringSubviewToFront:pageCtl];
    
    
    lastBtn = [[UIButton alloc]initWithFrame:CGRectMake(throughView.frame.size.width - 100, throughView.frame.size.height - 60, 80, 30)];
    [lastBtn setTitle:@"不再显示" forState:UIControlStateNormal];
    lastBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    lastBtn.hidden = YES;
    lastBtn.layer.borderColor = (__bridge CGColorRef _Nullable)([UIColor whiteColor]);
    lastBtn.layer.cornerRadius = 5;
    lastBtn.layer.borderWidth  = 0.7;
    [lastBtn addTarget:self action:@selector(toHideThroughView) forControlEvents:UIControlEventTouchUpInside];
    [lastBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.view addSubview:lastBtn];
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
        [self.view bringSubviewToFront:[self wkWebView]];
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

- (void)roadLoadClicked{
    [self.wkWebView reload];
}

-(void)customBackItemClicked{
    if (webViewDidFinishLoad) {
        [self.wkWebView evaluateJavaScript:@"mobileXObj.onHeaderBarTapBck('')" completionHandler:nil];
    }
    else{
        [self.navigationController popViewControllerAnimated:YES];
        [self.wkWebView setNavigationDelegate:nil];
        [self.wkWebView setUIDelegate:nil];
    }
}
-(void)closeItemClicked{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark ================ 加载方式 ================

- (void)webViewloadURLType{
    switch (self.loadType) {
        case loadWebURLString:{
            //创建一个NSURLRequest 的对象
            NSMutableURLRequest * Request_zsj = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.URLString]];
            Request_zsj.timeoutInterval = 30;
            //加载网页
            [self.wkWebView loadRequest:Request_zsj];
            break;
        }
        case loadWebHTMLString:{
            [self loadHostPathURL:self.URLString];
            break;
        }
        case POSTWebURLString:{
            // JS发送POST的Flag，为真的时候会调用JS的POST方法
            self.needLoadJSPOST = YES;
            //POST使用预先加载本地JS方法的html实现，请确认WKJSPOST存在
            [self loadHostPathURL:@"WKJSPOST"];
            break;
        }
    }
}

- (void)loadHostPathURL:(NSString *)url{
    //获取JS所在的路径
    NSString *path = [[NSBundle mainBundle] pathForResource:url ofType:@"html"];
    //获得html内容
    NSString *html = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    //加载js
    [self.wkWebView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
}

// 调用JS发送POST请求
- (void)postRequestWithJS {
    // 拼装成调用JavaScript的字符串
    NSString *jscript = [NSString stringWithFormat:@"post('%@',{%@});", self.URLString, self.postData];
    // 调用JS代码
    [self.wkWebView evaluateJavaScript:jscript completionHandler:^(id object, NSError * _Nullable error) {
    }];
}


- (void)loadWebURLSring:(NSString *)string{
    self.URLString = string;
    self.loadType = loadWebURLString;
}

- (void)loadWebHTMLSring:(NSString *)string{
    self.URLString = string;
    self.loadType = loadWebHTMLString;
}

- (void)POSTWebURLSring:(NSString *)string postData:(NSString *)postData{
    self.URLString = string;
    self.postData = postData;
    self.loadType = POSTWebURLString;
}

//#pragma mark   ============== URL pay 开始支付 ==============
//
//- (void)payWithUrlOrder:(NSString*)urlOrder
//{
//    if (urlOrder.length > 0) {
//        __weak XFWkwebView* wself = self;
//        [[AlipaySDK defaultService] payUrlOrder:urlOrder fromScheme:@"giftcardios" callback:^(NSDictionary* result) {
//            // 处理支付结果
//            NSLog(@"===============%@", result);
//            // isProcessUrlPay 代表 支付宝已经处理该URL
//            if ([result[@"isProcessUrlPay"] boolValue]) {
//                // returnUrl 代表 第三方App需要跳转的成功页URL
//                NSString* urlStr = result[@"returnUrl"];
//                [wself loadWithUrlStr:urlStr];
//            }
//        }];
//    }
//}
//
//- (void)WXPayWithParam:(NSDictionary *)WXparam{
//
//}
////url支付成功回调地址
//- (void)loadWithUrlStr:(NSString*)urlStr
//{
//    if (urlStr.length > 0) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSURLRequest *webRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestReturnCacheDataElseLoad
//                                                    timeoutInterval:15];
//            [self.wkWebView loadRequest:webRequest];
//        });
//    }
//}

#pragma mark ================ 自定义返回/关闭按钮 ================

-(void)updateNavigationItems{
    if (self.wkWebView.canGoBack) {
        UIBarButtonItem *spaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        spaceButtonItem.width = -6.5;
        
        [self.navigationItem setLeftBarButtonItems:@[spaceButtonItem,self.customBackBarItem,self.closeButtonItem] animated:NO];
    }else{
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        [self.navigationItem setLeftBarButtonItems:@[self.customBackBarItem]];
    }
}
//请求链接处理
-(void)pushCurrentSnapshotViewWithRequest:(NSURLRequest*)request{
    //    NSLog(@"push with request %@",request);
    NSURLRequest* lastRequest = (NSURLRequest*)[[self.snapShotsArray lastObject] objectForKey:@"request"];
    
    //如果url是很奇怪的就不push
    if ([request.URL.absoluteString isEqualToString:@"about:blank"]) {
        //        NSLog(@"about blank!! return");
        return;
    }
    //如果url一样就不进行push
    if ([lastRequest.URL.absoluteString isEqualToString:request.URL.absoluteString]) {
        return;
    }
    UIView* currentSnapShotView = [self.wkWebView snapshotViewAfterScreenUpdates:YES];
    [self.snapShotsArray addObject:
     @{@"request":request,@"snapShotView":currentSnapShotView}];
}

#pragma mark ================ WKNavigationDelegate ================

//这个是网页加载完成，导航的变化
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    /*
     主意：这个方法是当网页的内容全部显示（网页内的所有图片必须都正常显示）的时候调用（不是出现的时候就调用），，否则不显示，或则部分显示时这个方法就不调用。
     */
    // 判断是否需要加载（仅在第一次加载）
    if (self.needLoadJSPOST) {
        // 调用使用JS发送POST请求的方法
        [self postRequestWithJS];
        // 将Flag置为NO（后面就不需要加载了）
        self.needLoadJSPOST = NO;
    }
    // 获取加载网页的标题
    //    self.progressView.hidden = YES;
    [self.progressView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0);
    }];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateNavigationItems];
    webViewDidFinishLoad = YES;
}

//开始加载
-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    //开始加载的时候，让加载进度条显示
    self.progressView.hidden = NO;
}

//内容返回时调用
-(void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{}

//服务器请求跳转的时候调用
-(void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{
    
}

//服务器开始请求的时候调用
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *absolutString = [navigationAction.request.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"decidePolicyForNavigationAction absoluteString = %@",absolutString);
    if ([absolutString hasPrefix:JSPREHEADER]) {
        //        处理bs协议
        decisionHandler(WKNavigationActionPolicyCancel);
        if ([absolutString rangeOfString:JSPAYCHARGE].location != NSNotFound) {
            NSUInteger idx = [JSPREHEADER length];
            NSArray *items = [[absolutString substringFromIndex:idx] componentsSeparatedByString:JSPARAMDELIMIT];
            NSString *callBackFunction = nil;
            NSString *allParamJSONString = [items[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSError *error;
            NSMutableDictionary *allPramsDic = [NSJSONSerialization JSONObjectWithData:[allParamJSONString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
            NSDictionary *params;
            NSString *transcode;
            if (!error) {
                if (allPramsDic.allKeys.count > 0) {
                    callBackFunction = [allPramsDic objectForKey:@"callback"];
                    transcode = [allPramsDic objectForKey:@"transcode"];
                    NSLog(@"格式 = %@",[[allPramsDic objectForKey:@"params"] class]);
                    if ([[allPramsDic objectForKey:@"params"] isKindOfClass:[NSString class]]) {
                        params = [NSJSONSerialization JSONObjectWithData:[[allPramsDic objectForKey:@"params"] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                    }
                    else if ([[allPramsDic objectForKey:@"params"] isKindOfClass:[NSDictionary class]]){
                        params = [allPramsDic objectForKey:@"params"];
                    }
                    
                    [[RRCNetworkTool shareTool] requestForMethod:MXRequestMethodPost urlString:transcode params:params success:^(NSInteger statusCode, id responseObject) {
                        if ([[[responseObject objectForKey:@"res"] objectForKey:@"dataMap"] objectForKey:@"charge"]) {
                            [Pingpp createPayment:[[[responseObject objectForKey:@"res"] objectForKey:@"dataMap"] objectForKey:@"charge"] viewController:self appURLScheme:kURLScheme withCompletion:^(NSString *result, PingppError *pingError) {
                                if (pingError == nil) {
                                    if (callBackFunction) {
                                        NSError *error;
                                        
                                        NSDictionary *dicCallback = @{
                                                                      @"response":result
                                                                      };
                                        NSString *resp = nil;
                                        
                                        
                                        resp = [[NSString alloc]initWithData:[NSJSONSerialization dataWithJSONObject:dicCallback options:0 error:&error] encoding:NSUTF8StringEncoding];
                                        if (!resp) {
                                            NSLog(@"字典转json字符串错误:%@",error);
                                        }else{
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [self.wkWebView evaluateJavaScript:[NSString stringWithFormat:@"%@('%@')",callBackFunction,resp] completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                                                    
                                                }];
                                            });
                                        }
                                    }
                                } else {
                                    NSLog(@"PingppError: code=%lu msg=%@", (unsigned  long)pingError.code, [pingError getMsg]);
                                    if (callBackFunction) {
                                        NSError *error;
                                        
                                        NSDictionary *dicCallback = @{
                                                                      @"response":[pingError getMsg]
                                                                      };
                                        NSString *resp = nil;
                                        
                                        
                                        resp = [[NSString alloc]initWithData:[NSJSONSerialization dataWithJSONObject:dicCallback options:0 error:&error] encoding:NSUTF8StringEncoding];
                                        if (!resp) {
                                            NSLog(@"字典转json字符串错误:%@",error);
                                        }else{
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [self.wkWebView evaluateJavaScript:[NSString stringWithFormat:@"%@('%@')",callBackFunction,resp] completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                                                    
                                                }];
                                            });
                                        }
                                    }
                                }
                            }];
                        }
                    } failure:^(NSError *error) {
                        
                    }];
                }
            }
            
        }
        else if ([absolutString rangeOfString:JSSHAREINFO].location != NSNotFound){
            //bs://shareinfo???{params:{title:xxx,text:xxx,image:xxx,url:xxx}}
            NSUInteger idx = [JSPREHEADER length];
            NSArray *items = [[absolutString substringFromIndex:idx] componentsSeparatedByString:JSPARAMDELIMIT];
            
            NSString *allParamJSONString = [items[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSError *error;
            NSMutableDictionary *allPramsDic = [NSJSONSerialization JSONObjectWithData:[allParamJSONString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
            if (!error) {
                if (allPramsDic.allKeys.count > 0) {
                    if (![allPramsDic objectForKey:@"image"]) {
                        
                    }
                    MOBShareSDKHelper *helper = [MOBShareSDKHelper shareInstance];
                    [helper shareWithParams:allPramsDic];
                }
            }
        }
        else if ([absolutString rangeOfString:JSSETNAVIBARVISIBLE].location != NSNotFound){
            NSUInteger idx = [JSPREHEADER length];
            NSArray *items = [[absolutString substringFromIndex:idx] componentsSeparatedByString:JSPARAMDELIMIT];
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            
            NSString *allParamJSONString = [items[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSError *error;
            NSMutableDictionary *allPramsDic = [NSJSONSerialization JSONObjectWithData:[allParamJSONString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
            if (!error) {
                if (allPramsDic.allKeys.count > 0) {
                    if ([[allPramsDic objectForKey:@"params"] isKindOfClass:[NSString class]]) {
                        params = [NSJSONSerialization JSONObjectWithData:[[allPramsDic objectForKey:@"params"] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:&error];
                    }
                    else if ([[allPramsDic objectForKey:@"params"] isKindOfClass:[NSDictionary class]]){
                        params = [allPramsDic objectForKey:@"params"];
                    }
                    BOOL naviShow = [[params objectForKey:@"visible"] boolValue];//true=显示导航栏，false=隐藏导航栏
                    if (naviShow) {
                        if (self.navigationController.navigationBarHidden == YES) {
                            [self.navigationController setNavigationBarHidden:NO animated:NO];
                            [statusBarView mas_updateConstraints:^(MASConstraintMaker *make) {
                                make.height.equalTo(@0);
                            }];
                            [self.progressView mas_updateConstraints:^(MASConstraintMaker *make) {
                                make.top.equalTo(self.view.mas_top);
                                make.height.equalTo(@0);
                            }];
                            [self.wkWebView mas_updateConstraints:^(MASConstraintMaker *make) {
                                make.top.equalTo(self.view.mas_top);
                            }];
                            self.title = [params objectForKey:@"title"];
                        }
                    }
                    else{
                        if (self.navigationController.navigationBarHidden == NO) {
                            [self.navigationController setNavigationBarHidden:YES animated:NO];
                            statusBarView.backgroundColor = [UIColor whiteColor];
                            [self.view addSubview:statusBarView];
                            [statusBarView mas_updateConstraints:^(MASConstraintMaker *make) {
                                make.top.equalTo(self.view.mas_top);
                                make.left.equalTo(self.view.mas_left);
                                make.right.equalTo(self.view.mas_right);
                                make.height.equalTo(@20);
                            }];
                            [self.progressView mas_updateConstraints:^(MASConstraintMaker *make) {
                                make.top.equalTo(statusBarView.mas_bottom);
                                make.left.equalTo(self.view.mas_left);
                                make.right.equalTo(self.view.mas_right);
                                make.height.equalTo(@0);
                            }];
                            [self.wkWebView mas_updateConstraints:^(MASConstraintMaker *make) {
                                make.top.equalTo(self.view.mas_top).offset(20);
                                make.left.equalTo(self.view.mas_left);
                                make.right.equalTo(self.view.mas_right);
                                make.bottom.equalTo(self.view.mas_bottom);
                            }];
                        }
                        
                    }
                }
            }
        }else if ([absolutString rangeOfString:JSH5PAGELOADED].location != NSNotFound){
            [waitingImageView removeFromSuperview];
        }if ([absolutString rangeOfString:JSGETMOBILEANDEVNINFO].location != NSNotFound){
            NSUInteger idx = [JSPREHEADER length];
            NSArray *items = [[absolutString substringFromIndex:idx] componentsSeparatedByString:JSPARAMDELIMIT];
            NSString *callBackFunction = nil;
            NSString *allParamJSONString = [items[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSError *error;
            NSMutableDictionary *allPramsDic = [NSJSONSerialization JSONObjectWithData:[allParamJSONString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
            if (!error) {
                if (allPramsDic.allKeys.count > 0) {
                    callBackFunction = [allPramsDic objectForKey:@"callback"];
                }
                if (callBackFunction) {
                    NSError *error;
                    NSString *resp = nil;
                    
                    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
                    [dict setObject:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? IPHONEDEVICE : IPADDEVICE forKey:MOBILEDEVICE_KEY];
//                    [dict setObject:mobileApp forKey:MOBILEAPP_KEY];
//                    [dict setObject:mobileVer forKey:MOBILEVER_KEY];
//                    [dict setObject:isIphone3 forKey:ISIPHONE3_KEY];
//                    [dict setObject:serverUrl forKey:SERVERURL];
                    
//                    NSString * devid = [ToolForHTJS uniqueGlobalDeviceIdentifier];
//                    [dict setObject:devid forKey:MOBILEDEVICEID_KEY];
                    
//                    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
//                    NSDictionary * data = [defaults dictionaryForKey:ALLSAVEDDATA];
//                    if (data == nil) {
//                        data = [NSDictionary dictionary];
//                    }
//                    [dict setObject:data forKey:ALLSAVEDDATA];
                    
                    NSDictionary *responseObject = @{
                                                     @"transcode":[items[0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                                     @"response":dict
                                                     };
                    
                    resp = [[NSString alloc]initWithData:[NSJSONSerialization dataWithJSONObject:responseObject options:0 error:&error] encoding:NSUTF8StringEncoding];
                    if (!resp) {
                        NSLog(@"字典转json字符串错误:%@",error);
                    }else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [_wkWebView evaluateJavaScript:[NSString stringWithFormat:@"%@('%@')",callBackFunction,resp] completionHandler:nil];
                        });
                    }
                }
            }
        }
        else if ([absolutString rangeOfString:@"commit"].location != NSNotFound){
            NSUInteger idx = [JSPREHEADER length];
            NSArray *items = [[absolutString substringFromIndex:idx] componentsSeparatedByString:JSPARAMDELIMIT];
            NSString *transCode = nil;
            NSString *callBackFunction = nil;
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            
            NSString *allParamJSONString = [items[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSError *error;
            NSMutableDictionary *allPramsDic = [NSJSONSerialization JSONObjectWithData:[allParamJSONString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
            if (!error) {
                if (allPramsDic.allKeys.count > 0) {
                    transCode = [allPramsDic objectForKey:@"transcode"];
                    if ([[allPramsDic objectForKey:@"params"] isKindOfClass:[NSString class]]) {
                        params = [NSJSONSerialization JSONObjectWithData:[[allPramsDic objectForKey:@"params"] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:&error];
                    }
                    else if ([[allPramsDic objectForKey:@"params"] isKindOfClass:[NSDictionary class]]){
                        params = [allPramsDic objectForKey:@"params"];
                    }
                    callBackFunction = [allPramsDic objectForKey:@"callback"];
                    NSDictionary *responseObject = @{@"ReturnCode":@"NONE RESPONSE",
                                                     @"ReturnMessage":[GTMBase64 stringByEncodingData:[@"无返回" dataUsingEncoding:NSUTF8StringEncoding]]};
                    if (callBackFunction) {
                        NSError *error;
                        
                        NSDictionary *dicCallback = @{
                                                      @"transcode":transCode,
                                                      @"response":responseObject
                                                      };
                        NSString *resp = nil;
                        
                        
                        resp = [[NSString alloc]initWithData:[NSJSONSerialization dataWithJSONObject:dicCallback options:0 error:&error] encoding:NSUTF8StringEncoding];
                        if (!resp) {
                            NSLog(@"字典转json字符串错误:%@",error);
                        }else{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.wkWebView evaluateJavaScript:[NSString stringWithFormat:@"%@('%@')",callBackFunction,resp] completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                                    
                                }];
                            });
                        }
                    }
                    else{
                        NSDictionary *responseObject = @{@"ReturnCode":@"NONE RESPONSE",
                                                         @"ReturnMessage":[GTMBase64 stringByEncodingData:[@"无返回" dataUsingEncoding:NSUTF8StringEncoding]]};
                        NSError *error;
                        
                        NSDictionary *dicCallback = @{
                                                      @"transcode":transCode,
                                                      @"response":responseObject
                                                      };
                        NSString *resp = nil;
                        
                        
                        resp = [[NSString alloc]initWithData:[NSJSONSerialization dataWithJSONObject:dicCallback options:0 error:&error] encoding:NSUTF8StringEncoding];
                        if (!resp) {
                            NSLog(@"字典转json字符串错误:%@",error);
                        }else{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.wkWebView evaluateJavaScript:[NSString stringWithFormat:@"%@('%@')",callBackFunction,resp] completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                                    
                                }];
                            });
                        }
                    }
                }
            }
            else{
                NSDictionary *responseObject = @{@"ReturnCode":@"NONE RESPONSE",
                                                 @"ReturnMessage":[GTMBase64 stringByEncodingData:[@"无返回" dataUsingEncoding:NSUTF8StringEncoding]]};
                NSError *error;
                
                NSDictionary *dicCallback = @{
                                              @"transcode":transCode,
                                              @"response":responseObject
                                              };
                NSString *resp = nil;
                
                
                resp = [[NSString alloc]initWithData:[NSJSONSerialization dataWithJSONObject:dicCallback options:0 error:&error] encoding:NSUTF8StringEncoding];
                if (!resp) {
                    NSLog(@"字典转json字符串错误:%@",error);
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.wkWebView evaluateJavaScript:[NSString stringWithFormat:@"%@('%@')",callBackFunction,resp] completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                            
                        }];
                    });
                }
            }
        }
        else{
            
        }
    }
    else{
        //        WKNavigationType type = navigationAction.navigationType;
        //        switch (type) {
        //            case WKNavigationTypeLinkActivated: {
        //                [self pushCurrentSnapshotViewWithRequest:navigationAction.request];
        //                break;
        //            }
        //            case WKNavigationTypeFormSubmitted: {
        //                [self pushCurrentSnapshotViewWithRequest:navigationAction.request];
        //                break;
        //            }
        //            case WKNavigationTypeBackForward: {
        //                break;
        //            }
        //            case WKNavigationTypeReload: {
        //                break;
        //            }
        //            case WKNavigationTypeFormResubmitted: {
        //                break;
        //            }
        //            case WKNavigationTypeOther: {
        //                [self pushCurrentSnapshotViewWithRequest:navigationAction.request];
        //                break;
        //            }
        //            default: {
        //                break;
        //            }
        //        }
        //        [self updateNavigationItems];
        decisionHandler(WKNavigationActionPolicyAllow);
        
    }
}

// 内容加载失败时候调用
-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    NSLog(@"页面加载超时");
    [self.progressView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0);
    }];
}

//跳转失败的时候调用
-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    NSLog(@"加载失败 = %@",error.localizedDescription);
    [self.progressView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@0);
    }];
}

//进度条
-(void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{}

#pragma mark ================ WKUIDelegate ================

// 获取js 里面的提示
-(void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
}

// js 信息的交流
-(void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
}

// 交互。可输入的文本。
-(void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"textinput" message:@"JS调用输入框" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor redColor];
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler([[alert.textFields lastObject] text]);
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
    
}

//KVO监听进度条
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.wkWebView) {
        [self.progressView setAlpha:1.0f];
        BOOL animated = self.wkWebView.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.wkWebView.estimatedProgress animated:animated];
        
        // Once complete, fade out UIProgressView
        if(self.wkWebView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark ================ WKScriptMessageHandler ================

//拦截执行网页中的JS方法
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    
    //服务器固定格式写法 view.webkit.messageHandlers.名字.postMessage(内容);
    //客户端写法 message.name isEqualToString:@"名字"]
    NSLog(@"MSG = %@",message);
    if ([message.name isEqualToString:@"WXPay"]) {
        NSLog(@"%@", message.body);
        //调用微信支付方法
        //        [self WXPayWithParam:message.body];
    }
    if ([message.name isEqualToString:@"AppModel"]) {
        NSLog(@"%@",message.body);
    }
}

#pragma mark ================ 懒加载 ================

- (WKWebView *)wkWebView{
    if (!_wkWebView) {
        //设置网页的配置文件
        WKWebViewConfiguration * Configuration = [[WKWebViewConfiguration alloc]init];
        //允许视频播放
        Configuration.allowsAirPlayForMediaPlayback = YES;
        // 允许在线播放
        Configuration.allowsInlineMediaPlayback = YES;
        // 允许可以与网页交互，选择视图
        Configuration.selectionGranularity = YES;
        // web内容处理池
        Configuration.processPool = [[WKProcessPool alloc] init];
        //自定义配置,一般用于 js调用oc方法(OC拦截URL中的数据做自定义操作)
        WKUserContentController * UserContentController = [[WKUserContentController alloc]init];
        // 添加消息处理，注意：self指代的对象需要遵守WKScriptMessageHandler协议，结束时需要移除
        [UserContentController addScriptMessageHandler:self name:@"WXPay"];
        [UserContentController addScriptMessageHandler:self name:@"AppModel"];
        
        // 是否支持记忆读取
        Configuration.suppressesIncrementalRendering = YES;
        // 允许用户更改网页的设置
        Configuration.userContentController = UserContentController;
        
        CGRect frame = CGRectMake(0, 20, kScreenWidth,kScreenHeight-20);
        if (!_isNavHidden) {
            frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight - 64);
        }
        _wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:Configuration];
        _wkWebView.backgroundColor = [UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1.0];
        // 设置代理
        _wkWebView.navigationDelegate = self;
        _wkWebView.UIDelegate = self;
        //kvo 添加进度监控
        [_wkWebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:0 context:WkwebBrowserContext];
        //开启手势触摸
        _wkWebView.allowsBackForwardNavigationGestures = YES;
        // 设置 可以前进 和 后退
        //适应你设定的尺寸
        [_wkWebView sizeToFit];
    }
    return _wkWebView;
}

-(UIBarButtonItem*)customBackBarItem{
    if (!_customBackBarItem) {
        UIImage* backItemImage = [[UIImage imageNamed:@"backItemImage"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        //        UIImage* backItemHlImage = [[UIImage imageNamed:@"backItemImage-hl"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        UIButton* backButton = [[UIButton alloc] init];
        //        [backButton setTitle:@"返回" forState:UIControlStateNormal];
        //        [backButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        //        [backButton setTitleColor:[self.navigationController.navigationBar.tintColor colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        //        [backButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        [backButton setImage:backItemImage forState:UIControlStateNormal];
        //        [backButton setImage:backItemHlImage forState:UIControlStateHighlighted];
        [backButton sizeToFit];
        
        [backButton addTarget:self action:@selector(customBackItemClicked) forControlEvents:UIControlEventTouchUpInside];
        _customBackBarItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    }
    return _customBackBarItem;
}

- (UIProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
        
        // 设置进度条的色彩
        [_progressView setTrackTintColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1.0]];
        _progressView.progressTintColor = [UIColor greenColor];
    }
    return _progressView;
}

-(UIBarButtonItem*)closeButtonItem{
    if (!_closeButtonItem) {
        _closeButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeItemClicked)];
    }
    return _closeButtonItem;
}

-(NSMutableArray*)snapShotsArray{
    if (!_snapShotsArray) {
        _snapShotsArray = [NSMutableArray array];
    }
    return _snapShotsArray;
}

-(void)viewWillDisappear:(BOOL)animated{
    [self.wkWebView.configuration.userContentController removeScriptMessageHandlerForName:@"WXPay"];
    [self.wkWebView setNavigationDelegate:nil];
    [self.wkWebView setUIDelegate:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSDictionary *dic = @{
//                              @"text":@"分享测试",
//                              @"url":@"http://baidu.com",
//                              @"image":[UIImage imageNamed:@"G1_4.jpg"],
//                              @"title":@"中金商城"
//                              };
//        MOBShareSDKHelper *helper = [MOBShareSDKHelper shareInstance];
//        [helper shareWithParams:dic];
//    });
}

//注意，观察的移除
-(void)dealloc{
    [self.wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
}

@end
