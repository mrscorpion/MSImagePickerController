//
//  TZTestCell.h
//  TZImagePickerController
//
//  Created by mr.scorpion on 16/1/3.
//  Copyright © 2016年 mr.scorpion. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TZTestCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *deleteBtn;
@property (nonatomic, assign) NSInteger row;

- (UIView *)snapshotView;

@end

