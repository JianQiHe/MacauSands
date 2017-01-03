//
//  ViewController.m
//  MacauSands
//
//  Created by HJQ on 2016/12/27.
//  Copyright © 2016年 hhh. All rights reserved.
//

//屏幕宽高
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "Masonry.h"
#import "WKCookieSyncManager.h"

@interface ViewController () <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, UIScrollViewDelegate> {
    WKWebView *_webView;
    NSString *questURL;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.navigationController.navigationBarHidden = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientChange:) name:UIDeviceOrientationDidChangeNotification object:nil];

    WKCookieSyncManager *cookiesManager = [WKCookieSyncManager sharedWKCookieSyncManager];

    // 根据生成的WKUserScript对象，初始化WKWebViewConfiguration
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.processPool = cookiesManager.processPool;
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    [userContentController addScriptMessageHandler:self name:@"aaaa"];
    configuration.userContentController = userContentController;
    configuration.preferences.javaScriptEnabled = YES;//打开JavaScript交互

    //OC注册供JS调用的方法
    [[_webView configuration].userContentController addScriptMessageHandler:self name:@"closeMe"];
    
    _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    
    //重点 设置frame时需要这样设置，如果直接设置self.view.frame 时是无法自适应屏幕的
    _webView = [[WKWebView alloc] init];
    NSURL * webURL = [NSURL URLWithString:@"http://www.pp6060.com"];
    NSURLRequest * webRequest = [NSURLRequest requestWithURL:webURL]; 
    [_webView loadRequest:webRequest];
    [self.view addSubview:_webView];
    [_webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.top.mas_equalTo(20);
    }];
    
    _webView.scrollView.bounces = NO;
    _webView.scrollView.delegate = self;
    [_webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [_webView setNavigationDelegate:self];
    [_webView setUIDelegate:self];
    [_webView setMultipleTouchEnabled:YES];
    [_webView setAutoresizesSubviews:YES];
    [_webView.scrollView setAlwaysBounceVertical:YES];
    // 这行代码可以是侧滑返回webView的上一级，而不是跟控制器（*指针对侧滑有效）
    [_webView setAllowsBackForwardNavigationGestures:true];
}

//加载页面数据完成

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
    NSLog(@"加载页面完成");
    
    NSLog(@"backlist ===%@",webView.backForwardList.backList); //访问过未返回的页面
    
    NSLog(@"forwordlst==%@",webView.backForwardList.forwardList); //访问过已返回的页面
    
    NSLog(@"url===%@",webView.backForwardList.currentItem.URL); //当前访问的页面
    
    questURL = [NSString stringWithFormat:@"%@", webView.backForwardList.currentItem.URL];
          
    //在这里可以拿到web页的相关信息 做一些操作
          
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    
    // 接口的作用是打开新窗口委托
    NSLog(@"createWebViewWithConfiguration  %@", navigationAction.request.URL);
    
    if (!navigationAction.targetFrame.isMainFrame) {
        
        [webView loadRequest:navigationAction.request];
        
    }
    
    return nil;
    
}

// 以下三个代理方法全部是与界面弹出提示框相关的，针对web界面的三种提示框
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    //    DLOG(@"msg = %@ frmae = %@",message,frame);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    
}

- (void)orientChange:(NSNotification *)noti {
    NSLog(@"屏幕变化！");
    
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait://home键在下
        {
            [[UIApplication sharedApplication] setStatusBarHidden:NO];
            [_webView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.right.bottom.mas_equalTo(0);
                make.top.mas_equalTo(20);
            }];
        }
            break;
        case UIInterfaceOrientationPortraitUpsideDown://home键在上
        case UIInterfaceOrientationLandscapeLeft://home键在左
        case UIInterfaceOrientationLandscapeRight://home键在右
        {
            
            [self callJSHiddenFullScreen];
            
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            [_webView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.left.right.bottom.mas_equalTo(0);
            }];
            
        }
            break;
            
        default:
            break;
    }
}

//scrollView滚动时，就调用该方法。任何offset值改变都调用该方法。即滚动过程中，调用多次
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    [self callJSHiddenFullScreen];
}

// 当开始滚动视图时，执行该方法。一次有效滑动（开始滑动，滑动一小段距离，只要手指不松开，只算一次滑动），只执行一次。
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    [self callJSHiddenFullScreen];
}

// 滑动scrollView，并且手指离开时执行。一次有效滑动，只执行一次。
// 当pagingEnabled属性为YES时，不调用，该方法
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    [self callJSHiddenFullScreen];
}

// 滑动视图，当手指离开屏幕那一霎那，调用该方法。一次有效滑动，只执行一次。
// decelerate,指代，当我们手指离开那一瞬后，视图是否还将继续向前滚动（一段距离），经过测试，decelerate=YES
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self callJSHiddenFullScreen];
}





- (void)callJSHiddenFullScreen {

    
    NSString *js = @"document.getElementById(\"fullscreen\").style.visibility='hidden'";
    
    if ([questURL hasPrefix:@"http://www.2079f.com"]) {
        [_webView evaluateJavaScript:js completionHandler:^(id _Nullable response, NSError * _Nullable error) {
            //TODO
            NSLog(@"%@ %@",response,error);
        }];
    }
    
}


//OC在JS调用方法做的处理
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSLog(@"JS 调用了 %@ 方法，传回参数 %@",message.name,message.body);
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
