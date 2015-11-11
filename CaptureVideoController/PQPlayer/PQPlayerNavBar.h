//
//  PQPlayerNavBar.h
//  Player
//
//  Created by jianting on 14-5-21.
//  Copyright (c) 2014年 jianting. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PQPlayerNavBar;
@protocol PQPlayerNavBarDelegate <NSObject>

- (void)PQPlayerNavBarGoback:(PQPlayerNavBar *)navbar;

@end

@interface PQPlayerNavBar : UIView

@property (nonatomic, assign) id<PQPlayerNavBarDelegate> delegate;

@property (nonatomic, retain) UILabel * titleLabel;

@end
