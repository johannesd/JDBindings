//
//  UIButton+JDSetTitle.m
//
//  Created by Johannes Dörr on 10.05.14.
//  Copyright (c) 2014 Johannes Dörr. All rights reserved.
//

#import "UIButton+JDSetTitle.h"

@implementation UIButton (SetTitle)

- (void)setTitle:(NSString *)title
{
    [self setTitle:title forState:UIControlStateNormal];
}

- (NSString *)title
{
    return [self titleForState:UIControlStateNormal];
}

- (void)setTitleColor:(UIColor *)color
{
    [self setTitleColor:color forState:UIControlStateNormal];
}

- (UIColor *)titleColor
{
    return [self titleColorForState:UIControlStateNormal];
}

@end
