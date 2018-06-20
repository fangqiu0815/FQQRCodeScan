//
//  TestLogoViewController.m
//  FQQRCodeScanDemo
//
//  Created by mac on 2018/6/20.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "TestLogoViewController.h"
#import "FQQRCodeScanViewController.h"

@interface TestLogoViewController ()
@property (weak, nonatomic) IBOutlet UITextField *urlTextF;
@property (weak, nonatomic) IBOutlet UIImageView *qrImageView;

@end

@implementation TestLogoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *creatButton = [[UIBarButtonItem alloc] initWithTitle:@"生成" style:UIBarButtonItemStyleDone target:self action:@selector(createImage)];
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(saveImage)];

    self.navigationItem.rightBarButtonItems = @[saveButton ,creatButton];
}

- (void)createImage
{
    UIImage *logoImage = [UIImage imageNamed:@"icon_logo"];
    UIImage *image = [FQQRCodeScanViewController createQRImageWithString:_urlTextF.text QRSize:CGSizeMake(250, 250) centerLogoImage:logoImage logoBorderColor:[UIColor whiteColor]];
    [_qrImageView setImage:image];
}

- (void)saveImage
{
    if(_qrImageView.image) {
        UIImageWriteToSavedPhotosAlbum(_qrImageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)self);
    } else {
        [self showInfo:@"请先生成二维码"];
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSLog(@"image = %@, error = %@, contextInfo = %@", image, error, contextInfo);
    if(error) {
        [self showInfo:[NSString stringWithFormat:@"error: %@",error]];
    } else {
        [self showInfo:@"保存成功"];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
