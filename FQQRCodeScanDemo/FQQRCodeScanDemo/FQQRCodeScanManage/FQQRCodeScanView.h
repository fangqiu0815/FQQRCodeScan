//
//  FQQRCodeScanView.h
//  FQQRCodeScanDemo
//
//  Created by mac on 2018/6/20.
//  Copyright © 2018年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, FQQRCodeScanType) {
    FQQRCodeScanTypeQrCode,
    FQQRCodeScanTypeBarCode,
    FQQRCodeScanTypeAll,
};

@interface FQQRCodeScanView : UIView

/**
 初始化方法

 @param frame 约束
 @param style 类型
 @return 返回值
 */
- (instancetype)initWithFrame:(CGRect)frame style:(NSString *)style;

/// 停止动画
- (void)fq_stopAnimating;

/// 扫描类型
@property (nonatomic, assign) FQQRCodeScanType scanType;




@end
