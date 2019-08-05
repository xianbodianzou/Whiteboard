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
@property (nonatomic,strong) NSArray *pathPoints;//轨迹点
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

#pragma mark =================线段属性================
@interface ZZLineRpoint : NSObject
@property (nonatomic,assign) float vector;
@property (nonatomic,assign) CGPoint p1;
@property (nonatomic,assign) float r1;
@property (nonatomic,assign) CGPoint p2;
@property (nonatomic,assign) float r2;
@property (nonatomic,assign) CGPoint lsP;
@property (nonatomic,assign) CGPoint lsP_ex;
@property (nonatomic,assign) CGPoint leP;
@property (nonatomic,assign) CGPoint lep_ex;
@property (nonatomic,assign) CGPoint rsP;
@property (nonatomic,assign) CGPoint rsP_ex;
@property (nonatomic,assign) CGPoint reP;
@property (nonatomic,assign) CGPoint reP_ex;
@end



