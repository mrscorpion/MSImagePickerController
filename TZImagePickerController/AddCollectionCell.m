//
//  AddCollectionCell.m
//  TZImagePickerController
//
//  Created by 清风 on 16/7/4.
//  Copyright © 2016年 mr.scorpion. All rights reserved.
//

#import "AddCollectionCell.h"

@implementation AddCollectionCell
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        _imageView = [[UIImageView alloc] init];
        _imageView.image = [UIImage imageNamed:@"group_add.png"];
        _imageView.backgroundColor = [UIColor lightGrayColor];//[UIColor colorWithWhite:1.000 alpha:0.500];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_imageView];
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _imageView.frame = self.bounds;
}
@end
