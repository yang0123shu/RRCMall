//
//  MXNetworkTool.m
//  mobilexlib
//
//  Created by 阳书成 on 2017/6/6.
//
//

#import "RRCNetworkTool.h"
#import "AFNetworking.h"
//#import "ToolsForJS.h"
#import "MBProgressHUD.h"

//#define kBaseURL @"https://ebank.ynrcc.com/pweb/"
#define kHost @"http://app.jiiiiiin.cn/payment-mall-server"
#define kVersion @"2.06"
@interface RRCNetworkTool()<NSURLSessionDelegate>
{
    AFURLSessionManager *manager;
    AFHTTPSessionManager *httpManager;
    NSString *sessionIdString;
    NSURLSession *session;
}


@end

@implementation RRCNetworkTool
static RRCNetworkTool *tool = nil;
static NSString *boundaryStr = @"--";   // 分隔字符串
static NSString *randomIDStr;           // 本次上传标示字符串
static NSString *uploadID;              // 上传(php)脚本中，接收文件字段

+(instancetype)shareTool
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tool = [[self alloc]init];
    });
    return tool;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        randomIDStr = @"V2ymHFg03ehbqgZCaKO6jy";
        uploadID = @"Img1";
        
        httpManager = [AFHTTPSessionManager manager];
//        AFHTTPRequestSerializer *seri = [AFHTTPRequestSerializer serializer];
        
//        [seri setValue:kVersion forHTTPHeaderField:MOBILEVER_KEY];
//        [seri setValue:[UIDevice currentDevice].systemName forHTTPHeaderField:MOBILEDEVICE_KEY];
//        [seri setValue:@"MOBILEBANK"  forHTTPHeaderField:MOBILEAPP_KEY];
//        [seri setValue:@"0"  forHTTPHeaderField:ISPORTAL_KEY];
//        [seri setValue:@"0"  forHTTPHeaderField:ISIPHONE3_KEY];
//        [seri setValue:[ToolsForJS uniqueGlobalDeviceIdentifier] forHTTPHeaderField:@"BSMobileDeviceId"];
//        NSString *strContentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", randomIDStr];
//        [seri setValue:strContentType forHTTPHeaderField:@"Content-Type"];
////        httpManager.requestSerializer = seri;
//        session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:0];
//        AFSecurityPolicy *poli = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
//        httpManager.securityPolicy = poli;
//        [self setDefaultTimeOutInterval];
        
        
    }
    return self;
}

-(void)setDefaultTimeOutInterval{
    [httpManager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    httpManager.requestSerializer.timeoutInterval = 20;
    [httpManager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    _needHUD = NO;
//    [httpManager.requestSerializer setValue:@"text/html; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

-(void)setRequestTimeOut:(NSTimeInterval)timeout
{
    [httpManager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    httpManager.requestSerializer.timeoutInterval = timeout;
    [httpManager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
}

-(void)requestForMethod:(MXRequestMethod)method urlString:(NSString*)urlString params:(NSDictionary*)params success:(void (^)(NSInteger statusCode, id responseObject))success
                failure:(void (^)(NSError *error))failure
{
    NSString *appendedURLString = [NSString stringWithFormat:@"%@",urlString];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSLog(@"请求头 ====== %@",httpManager.requestSerializer.HTTPRequestHeaders);
    MBProgressHUD *hud;
    if (_needHUD) {
        hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.label.text = @"加载中...";
    }
    if (method == MXRequestMethodGet) {
        [httpManager GET:appendedURLString parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (_needHUD) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:YES];
                    
                });
            }
            NSHTTPURLResponse *resp = (NSHTTPURLResponse*)task.response;
            [self setDefaultTimeOutInterval];
            success(resp.statusCode,responseObject);
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (_needHUD) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:YES];
                    
                });
            }
            failure(error);
            [self setDefaultTimeOutInterval];
        }];
    }else if (method == MXRequestMethodPost){
        [httpManager POST:appendedURLString parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (_needHUD) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:YES];
                    
                });
            }
            [self setDefaultTimeOutInterval];
            NSHTTPURLResponse *resp = (NSHTTPURLResponse*)task.response;
            success(resp.statusCode,responseObject);
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (_needHUD) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:YES];
                    
                });
            }
            [self setDefaultTimeOutInterval];
            failure(error);
        }];
    }
    else if (method == MXRequestMethodPostImages){
        NSMutableDictionary *muParams = [NSMutableDictionary dictionaryWithDictionary:params];
        NSArray *images = [params objectForKey:@"UploadImagesData"];
        NSMutableData *dataM = [NSMutableData data];
        for (int i = 0; i < images.count; i ++) {
            NSString *topStr = [self topStringWithMimeType:@"image/jpeg" uploadFile:[NSString stringWithFormat:@"Img%d",i+1]];
            [dataM appendData:[topStr dataUsingEncoding:NSUTF8StringEncoding]];
            [dataM appendData:UIImageJPEGRepresentation(images[i], 0.4)];
        }
        [muParams removeObjectForKey:@"UploadImagesData"];
        [httpManager POST:appendedURLString parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            for (int i = 0; i < images.count; i++) {
                UIImage *image = images[i];
                NSData *imageData = UIImageJPEGRepresentation(image, 0.4);
                NSMutableData *dataM = [NSMutableData data];
                for (int i = 0; i < images.count; i ++) {
                    NSString *topStr = [self topStringWithMimeType:@"image/jpeg" uploadFile:[NSString stringWithFormat:@"Img%d",i+1]];
                    [dataM appendData:[topStr dataUsingEncoding:NSUTF8StringEncoding]];
                    [dataM appendData:imageData];
                }
                //                [formData appendPartWithFormData:imageData name:[NSString stringWithFormat:@"Img%d",i+1]]; //
                [formData appendPartWithFileData:dataM name:[NSString stringWithFormat:@"Img%d",i] fileName:[NSString stringWithFormat:@"Img%d",i] mimeType:@"image/jpeg"];
            }
            //            UIImage *image = images[0];
            //            NSData *imageData = UIImageJPEGRepresentation(image, 0.4);
            ////            [formData appendPartWithFormData:imageData name:[NSString stringWithFormat:@"Img%d",1]];
            //            [formData appendPartWithFileData:imageData name:@"Img1" fileName:@"Img1" mimeType:@"image/jpeg"];
        } progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (_needHUD) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:YES];
                    
                });
            }
            [self setDefaultTimeOutInterval];
            NSHTTPURLResponse *resp = (NSHTTPURLResponse*)task.response;
            success(resp.statusCode,responseObject);
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (_needHUD) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:YES];
                    
                });
            }
            [self setDefaultTimeOutInterval];
            failure(error);
        }];  
    }
    
    else if (method == MXRequestMethodUploadImages){
        [self setRequestTimeOut:60];
//        [httpManager.requestSerializer setValue:@"multipart/form-data;boundary=-------------V2ymHFg03ehbqgZCaKO6jy" forHTTPHeaderField:@"Content-Type"];
//         httpManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"multipart/form-data", @"application/json", @"text/html", @"image/jpeg", @"image/png", @"application/octet-stream", @"text/json", nil];
        NSMutableDictionary *muParmas = [NSMutableDictionary dictionaryWithDictionary:params];
        if ([muParmas.allKeys containsObject:@"UploadImagesData"]) {
            [muParmas removeObjectForKey:@"UploadImagesData"];
        }
        
        NSArray *images = [params objectForKey:@"UploadImagesData"];
        [httpManager POST:appendedURLString parameters:muParmas constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            for (int i = 0; i < images.count; i++) {
                UIImage *image = images[i];
                NSData *imageData = UIImageJPEGRepresentation(image, 0.4);
//                [formData appendPartWithFormData:imageData name:[NSString stringWithFormat:@"Img%d",i+1]]; //
                [formData appendPartWithFileData:imageData name:@"upload" fileName:[NSString stringWithFormat:@"Img%d",i] mimeType:@"image/jpeg"];
            }
//            UIImage *image = images[0];
//            NSData *imageData = UIImageJPEGRepresentation(image, 0.4);
////            [formData appendPartWithFormData:imageData name:[NSString stringWithFormat:@"Img%d",1]];
//            [formData appendPartWithFileData:imageData name:@"Img1" fileName:@"Img1" mimeType:@"image/jpeg"];
        } progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
            });
            [self setDefaultTimeOutInterval];
            NSHTTPURLResponse *resp = (NSHTTPURLResponse*)task.response;
            success(resp.statusCode,responseObject);
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
            });
            [self setDefaultTimeOutInterval];
            failure(error);
        }];
    }
    
}


-(void)uploadImages:(NSArray<UIImage*>*)images urlString:(NSString*)urlString params:(NSDictionary*)params progress:(nullable void (^)(NSProgress * _Nonnull))uploadProgress
            success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
            failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] fromData:[NSData data] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
    }];
    [task resume];
}







#pragma mark - 私有方法
- (NSString *)topStringWithMimeType:(NSString *)mimeType uploadFile:(NSString *)uploadFile
{
    NSMutableString *strM = [NSMutableString string];
    
    [strM appendFormat:@"\r\n%@%@\r\n", boundaryStr, randomIDStr];
    [strM appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", uploadFile,uploadFile];
    [strM appendFormat:@"Content-Type: %@\r\n\r\n", mimeType];
    
    NSLog(@"%@", strM);
    return [strM copy];
}

- (NSString *)topStringWithMimeType:(NSString *)mimeType uploadFile:(NSString *)uploadFile isStart:(BOOL)isStart
{
    NSMutableString *strM = [NSMutableString string];
    
    [strM appendFormat:@"\r\n%@%@\r\n", boundaryStr, randomIDStr];
    [strM appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", uploadFile,uploadFile];
    [strM appendFormat:@"Content-Type: %@\r\n\r\n", mimeType];
    
    NSLog(@"%@", strM);
    return [strM copy];
}

- (NSString *)bottomString:(NSString *)key value:(NSString *)value
{
    NSMutableString *strM = [NSMutableString string];
    
    [strM appendFormat:@"\r\n%@%@\r\n", boundaryStr, randomIDStr];
    [strM appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key];
    [strM appendFormat:@"%@\r\n",value];
    
    
    NSLog(@"bottomString ========== %@", strM);
    return [strM copy];
}

#pragma mark - 上传文件
- (void)uploadFileWithURL:(NSString *)url imageDic:(NSDictionary *)imgDic pramDic:(NSDictionary *)pramDic success:(void (^)(NSInteger statusCode, id responseObject))success
                  failure:(void (^)(NSError *error))failure
{
    // 1> 数据体
    
    
    
    NSMutableData *dataM = [NSMutableData data];
    
    //    [dataM appendData:[boundaryStr dataUsingEncoding:NSUTF8StringEncoding]];
    for (NSString *name  in [imgDic allKeys]) {
        NSString *topStr = [self topStringWithMimeType:@"image/jpeg" uploadFile:name];
        [dataM appendData:[topStr dataUsingEncoding:NSUTF8StringEncoding]];
        [dataM appendData:[imgDic valueForKey:name]];
    }
    
    for (NSString *name  in [pramDic allKeys]) {
        NSString *bottomStr = [self bottomString:name value:[pramDic valueForKey:name]];
        [dataM appendData:[bottomStr dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [dataM appendData:[[NSString stringWithFormat:@"%@%@--\r\n", boundaryStr, randomIDStr] dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    
    // 1. Request
    NSString *appendedURLString = [NSString stringWithFormat:@"%@%@?BankId=9999&LoginType=K&_locale=zh_CN",kHost,url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:appendedURLString] cachePolicy:0 timeoutInterval:40];
    
    // dataM出了作用域就会被释放,因此不用copy
    request.HTTPBody = dataM;
    //    NSLog(@"%@",dataM);
    
    // 2> 设置Request的头属性
    request.HTTPMethod = @"POST";
    
    // 3> 设置Content-Length
    NSString *strLength = [NSString stringWithFormat:@"%ld", (long)dataM.length];
    [request setValue:strLength forHTTPHeaderField:@"Content-Length"];
    
    // 4> 设置Content-Type
//    NSString *strContentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", randomIDStr];
//    [request setValue:strContentType forHTTPHeaderField:@"Content-Type"];
    
//    [request setValue:kVersion forHTTPHeaderField:MOBILEVER_KEY];
//    [request setValue:[UIDevice currentDevice].systemName forHTTPHeaderField:MOBILEDEVICE_KEY];
//    [request setValue:@"MOBILEBANK"  forHTTPHeaderField:MOBILEAPP_KEY];
//    [request setValue:@"0"  forHTTPHeaderField:ISPORTAL_KEY];
//    [request setValue:@"0"  forHTTPHeaderField:ISIPHONE3_KEY];
//    [request setValue:[ToolsForJS uniqueGlobalDeviceIdentifier] forHTTPHeaderField:@"BSMobileDeviceId"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    // 3> 连接服务器发送请求
//    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
//        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
//        if (connectionError) {
//            NSLog(@"%@",connectionError);
//            failure(connectionError);
//            return;
//        }
//        
//        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSLog(@"%@", result);
//        success(((NSHTTPURLResponse*)response).statusCode,[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);
//    }];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error) {
            NSLog(@"%@",error);
            failure(error);
            return;
        }
        
        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@", result);
        success(((NSHTTPURLResponse*)response).statusCode,[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);
    }];
    [task resume];
}

#pragma mark 上传zip包
- (void)uploadZIPFileWithURL:(NSString *)url imageDic:(NSDictionary *)zipDic pramDic:(NSDictionary *)pramDic success:(void (^)(NSInteger statusCode, id responseObject))success
                     failure:(void (^)(NSError *error))failure
{
    // 1> 数据体
    
    
    
    NSMutableData *dataM = [NSMutableData data];
    
    //    [dataM appendData:[boundaryStr dataUsingEncoding:NSUTF8StringEncoding]];
    for (NSString *name  in [zipDic allKeys]) {
        NSMutableString *strM = [NSMutableString string];
        
        [strM appendFormat:@"\r\n%@%@\r\n", boundaryStr, randomIDStr];
        [strM appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", name,name];
        [strM appendFormat:@"Content-Type: %@\r\n\r\n", @"application/zip"];
        [dataM appendData:[strM dataUsingEncoding:NSUTF8StringEncoding]];
        [dataM appendData:[zipDic valueForKey:name]];
    }
    
    for (NSString *name  in [pramDic allKeys]) {
        NSString *bottomStr = [self bottomString:name value:[pramDic valueForKey:name]];
        [dataM appendData:[bottomStr dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [dataM appendData:[[NSString stringWithFormat:@"%@%@--\r\n", boundaryStr, randomIDStr] dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    
    // 1. Request
    NSString *appendedURLString = [NSString stringWithFormat:@"%@%@?BankId=9999&LoginType=K&_locale=zh_CN",kHost,url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:appendedURLString] cachePolicy:0 timeoutInterval:120];
    
    // dataM出了作用域就会被释放,因此不用copy
    request.HTTPBody = dataM;
    //    NSLog(@"%@",dataM);
    
    // 2> 设置Request的头属性
    request.HTTPMethod = @"POST";
    
    // 3> 设置Content-Length
    NSString *strLength = [NSString stringWithFormat:@"%ld", (long)dataM.length];
    [request setValue:strLength forHTTPHeaderField:@"Content-Length"];
    
    // 4> 设置Content-Type
//    NSString *strContentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", randomIDStr];
//    [request setValue:strContentType forHTTPHeaderField:@"Content-Type"];
    
//    [request setValue:kVersion forHTTPHeaderField:MOBILEVER_KEY];
//    [request setValue:[UIDevice currentDevice].systemName forHTTPHeaderField:MOBILEDEVICE_KEY];
//    [request setValue:@"MOBILEBANK"  forHTTPHeaderField:MOBILEAPP_KEY];
//    [request setValue:@"0"  forHTTPHeaderField:ISPORTAL_KEY];
//    [request setValue:@"0"  forHTTPHeaderField:ISIPHONE3_KEY];
//    [request setValue:[ToolsForJS uniqueGlobalDeviceIdentifier] forHTTPHeaderField:@"BSMobileDeviceId"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    // 3> 连接服务器发送请求
//    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
//        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
//        if (connectionError) {
//            NSLog(@"%@",connectionError);
//            failure(connectionError);
//            return;
//        }
//        
//        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSLog(@"%@", result);
//        success(((NSHTTPURLResponse*)response).statusCode,[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);
//    }];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error) {
            NSLog(@"%@",error);
            failure(error);
            return;
        }
        
        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@", result);
        success(((NSHTTPURLResponse*)response).statusCode,[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]);
    }];
    [task resume];
}


//-(UIImage*)generateBarCodeWithContentString:(NSString*)content
//{
//    NKDCode128Barcode *codeObj = [[NKDCode128Barcode alloc]initWithContent:content];
//    UIImage *img = [UIImage imageFromBarcode:codeObj];
//    return img;
//}
@end
