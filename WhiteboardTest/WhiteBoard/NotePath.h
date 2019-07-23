//
//  NotePath.h
//  WhiteboardTest
//
//  Created by shgbit on 2019/7/16.
//  Copyright © 2019 shgbit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WhiteboardEnum.h"

@interface NotePath : NSObject

@property (nonatomic,strong) NSString *lineId;//线id
@property (nonatomic,strong) NSArray *paths;//轨迹点
@property (nonatomic,assign) float lineWidth;//线宽
@property (nonatomic,strong) UIColor *lineColor;//颜色
@property (nonatomic,assign) NoteLineType lineType;//画线类型。
@property (nonatomic,assign) BOOL isOwer;//是否是自己的线

//- (void)drawStraightLine;

- (void)drawBezierPathLine;

- (BOOL)containPoint:(CGPoint)point;
@end

#pragma mark =================操作================
@interface NotePathOper : NSObject
@property (nonatomic,strong) NSString *operId;//操作id
@property (nonatomic,strong) NSString *lineId;//线
@property (nonatomic,assign) WhiteboardOperate oper;//操作类型。

@end

