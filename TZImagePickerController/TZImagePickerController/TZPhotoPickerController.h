//
//  TZPhotoPickerController.h
//  TZImagePickerController
//
//  Created by mr.scorpion on 15/12/24.
//  Copyright © 2015年 mr.scorpion. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TZAlbumModel;
@interface TZPhotoPickerController : UIViewController

@property (nonatomic, strong) TZAlbumModel *model;
@property (nonatomic, copy) void (^backButtonClickHandle)(TZAlbumModel *model);
@property (nonatomic, copy) void(^snycompleted)(UIImage *image, NSString *filePath, NSInteger durationTime);
@end
