//
//  PQPlayerDefines.h
//  Player
//
//  Created by jianting on 14-5-20.
//  Copyright (c) 2014年 jianting. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#define PQ_EXTERN extern "C"
#else
#define PQ_EXTERN extern
#endif

//屏幕尺寸
#define KDefaultScreenWidth CGRectGetWidth([[UIScreen mainScreen] bounds])
#define kDefaultScreenHeight CGRectGetHeight([[UIScreen mainScreen] bounds])

