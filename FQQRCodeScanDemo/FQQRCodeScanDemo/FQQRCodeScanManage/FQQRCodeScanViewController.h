//
//  FQQRCodeScanViewController.h
//  FQQRCodeScanDemo
//
//  Created by mac on 2018/6/20.
//  Copyright © 2018年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FQQRCodeScanView.h"

@interface FQQRCodeScanViewController : UIViewController

@property (nonatomic, strong) UILabel *tipTitle;  //扫码区域下方提示文字

@property (nonatomic, strong) UIView *toolsView;  //底部显示的功能项 -box

@property (nonatomic, strong) UIButton *flashBtn; //闪光灯按钮


/**
 初始化二维码扫描控制器
 
 @param type 扫码类型
 @param finish 扫码完成回调
 @return ScanViewController对象
 */
- (instancetype)initWithQrType:(FQQRCodeScanType)type onFinish:(void (^)(NSString *result, NSError *error))finish;


/**
 识别二维码
 
 @param image UIImage对象
 @param finish 识别结果
 */
+ (void)recognizeQrCodeImage:(UIImage *)image onFinish:(void (^)(NSString *result))finish;

/**
 生成二维码【白底黑色】
 
 @param content 二维码内容字符串【数字、字符、链接等】
 @param size 生成图片的大小
 @return UIImage图片对象
 */
+ (UIImage*)createQRImageWithString:(NSString*)content QRSize:(CGSize)size;

/**
 生成二维码【白底黑色】中间带logo
 
 @param content 二维码内容字符串【数字、字符、链接等】
 @param size 生成图片的大小
 @param logoImage logo图片
 @param logoBorderColor logo边框颜色
 @return UIImage图片对象
 */

+ (UIImage*)createQRImageWithString:(NSString*)content QRSize:(CGSize)size centerLogoImage:(UIImage *)logoImage logoBorderColor:(UIColor *)logoBorderColor;


/**
 生成二维码【自定义颜色】
 
 @param content 二维码内容字符串【数字、字符、链接等】
 @param size 生成图片的大小
 @param qrColor 二维码颜色
 @param bkColor 背景色
 @return UIImage图片对象
 */
+ (UIImage* )createQRImageWithString:(NSString*)content QRSize:(CGSize)size QRColor:(UIColor*)qrColor bkColor:(UIColor*)bkColor;


/**
 生成条形码【白底黑色】
 
 @param content 条码内容【一般是数字】
 @param size 生成条码图片的大小
 @return UIImage图片对象
 */
+ (UIImage *)createBarCodeImageWithString:(NSString *)content barSize:(CGSize)size;


/**
 生成条形码【自定义颜色】
 
 @param content 条码内容【一般是数字】
 @param size 生成条码图片的大小
 @param qrColor 码颜色
 @param bkColor 背景颜色
 @return UIImage图片对象
 */
+ (UIImage* )createBarCodeImageWithString:(NSString*)content QRSize:(CGSize)size QRColor:(UIColor*)qrColor bkColor:(UIColor*)bkColor;


@end
