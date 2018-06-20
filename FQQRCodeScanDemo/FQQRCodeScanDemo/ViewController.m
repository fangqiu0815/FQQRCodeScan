//
//  ViewController.m
//  FQQRCodeScanDemo
//
//  Created by mac on 2018/6/20.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "ViewController.h"
#import "FQQRCodeScanViewController.h"
#import "TestViewController.h"
#import "TestOtherViewController.h"
#import "TestLogoViewController.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

/** <#name#> */
@property (nonatomic, copy) NSArray *dataArray;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.dataArray = @[@"扫一扫", @"扫二维码", @"扫条形码" , @"生成二维码",@"生成带logo二维码", @"生成条形码"];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text = self.dataArray[indexPath.row];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.row == 0) {
        FQQRCodeScanViewController *scanVc = [[FQQRCodeScanViewController alloc] initWithQrType:FQQRCodeScanTypeAll onFinish:^(NSString *result, NSError *error) {
            if (error) {
                NSLog(@"error: %@",error);
            } else {
                NSLog(@"扫描结果：%@",result);
                [self showInfo:result];
            }
        }];
        [self.navigationController pushViewController:scanVc animated:YES];
    } else if (indexPath.row == 1) {
        FQQRCodeScanViewController *scanVc = [[FQQRCodeScanViewController alloc] initWithQrType:FQQRCodeScanTypeQrCode onFinish:^(NSString *result, NSError *error) {
            if (error) {
                NSLog(@"error: %@",error);
            } else {
                NSLog(@"扫描结果：%@",result);
                [self showInfo:result];
            }
        }];
        [self.navigationController pushViewController:scanVc animated:YES];
    } else if (indexPath.row == 2) {
        FQQRCodeScanViewController *scanVc = [[FQQRCodeScanViewController alloc] initWithQrType:FQQRCodeScanTypeBarCode onFinish:^(NSString *result, NSError *error) {
            if (error) {
                NSLog(@"error: %@",error);
            } else {
                NSLog(@"扫描结果：%@",result);
                [self showInfo:result];
            }
        }];
        [self.navigationController pushViewController:scanVc animated:YES];
    } else if (indexPath.row == 3) {
        TestViewController *drawQrVC = [self.storyboard instantiateViewControllerWithIdentifier:@"test"];
        [self.navigationController pushViewController:drawQrVC animated:YES];
    } else if (indexPath.row == 4) {
        TestLogoViewController *drawQrVC = [self.storyboard instantiateViewControllerWithIdentifier:@"testLogo"];
        [self.navigationController pushViewController:drawQrVC animated:YES];
    }else {
        TestOtherViewController *drawBarVC = [self.storyboard instantiateViewControllerWithIdentifier:@"testOther"];
        [self.navigationController pushViewController:drawBarVC animated:YES];
    }
}

#pragma mark - Error handle
- (void)showInfo:(NSString*)str {
    [self showInfo:str andTitle:@"提示"];
}

- (void)showInfo:(NSString*)str andTitle:(NSString *)title
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:str preferredStyle:UIAlertControllerStyleAlert];
    
    
    UIAlertAction *action1 = ({
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:NULL];
        action;
    });
    [alert addAction:action1];
    [self presentViewController:alert animated:YES completion:NULL];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
