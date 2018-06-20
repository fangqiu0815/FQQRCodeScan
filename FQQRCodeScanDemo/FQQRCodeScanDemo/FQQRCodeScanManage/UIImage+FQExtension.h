//
//  UIImage+FQExtension.h
//  FQQRCodeScanDemo
//
//  Created by mac on 2018/6/20.
//  Copyright © 2018年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (FQExtension)

/**
 *  封装的一个category
 *
 *  @param bgImage     二维码图片
 *  @param LogoImage   需要中间显示的 LOGO
 *  @param size        你想得到多大的图片，这个方便进行大小的重新绘制
 *
 *  @return 返回一个new的Imgaeview。需要用一个image对象接受
 */
+ (UIImage *)imagewithBgImage:(UIImage *)bgImage addLogoImage:(UIImage *)LogoImage ofTheSize:(CGSize)size ;

@end
