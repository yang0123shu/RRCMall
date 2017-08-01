//
//  MXNetworkTool.h
//  mobilexlib
//
//  Created by 阳书成 on 2017/6/6.
//
//

#import <Foundation/Foundation.h>
#import "GTMBase64.h"
#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, MXRequestMethod) {
    MXRequestMethodPost,
    MXRequestMethodGet,
    MXRequestMethodUploadImages,
    MXRequestMethodUploadZIP,
    MXRequestMethodPostImages
};

@interface RRCNetworkTool : NSObject



/**
 是否需要显示原生HUD遮罩
 */
@property (nonatomic,assign) BOOL needHUD;

/**
 生成单例对象

 @return 返回单例对象
 */
+(instancetype)shareTool;


/**
 设置请求超时时间

 @param timeout 超时秒数
 */
-(void)setRequestTimeOut:(NSTimeInterval)timeout;


/**
 发起网络请求

 @param method 请求类型
 @param urlString url,只需传交易码***.do，自动添加前面的域名和端口，还有后面拼接的内容
 @param params 参数，如果上传文件，则设置NSData数据为UploadData这个Key的值
 @param success 成功回调状态码和响应体
 @param failure 失败回调错误信息
 */
-(void)requestForMethod:(MXRequestMethod)method urlString:(NSString*)urlString params:(NSDictionary*)params success:(void (^)(NSInteger statusCode, id responseObject))success
                failure:(void (^)(NSError *error))failure;


- (void)uploadFileWithURL:(NSString *)url imageDic:(NSDictionary *)imgDic pramDic:(NSDictionary *)pramDic success:(void (^)(NSInteger statusCode, id responseObject))success
                  failure:(void (^)(NSError *error))failure;

/**
 上传zip包

 @param url 上传服务器地址
 @param zipDic zip字典
 @param pramDic 参数
 */
- (void)uploadZIPFileWithURL:(NSString *)url imageDic:(NSDictionary *)zipDic pramDic:(NSDictionary *)pramDic success:(void (^)(NSInteger statusCode, id responseObject))success
                     failure:(void (^)(NSError *error))failure;

//-(UIImage*)generateBarCodeWithContentString:(NSString *)content;
@end
