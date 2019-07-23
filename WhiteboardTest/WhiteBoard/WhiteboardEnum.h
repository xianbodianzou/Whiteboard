//
//  WhiteboardEnum.h
//  WhiteboardTest
//
//  Created by shgbit on 2019/7/22.
//  Copyright © 2019 shgbit. All rights reserved.
//

#ifndef WhiteboardEnum_h
#define WhiteboardEnum_h

typedef enum : NSUInteger {
    NoteLineType_straight, //一次曲线 即直线
    NoteLineType_curve0,   //二次曲线 目标点为 中点，控制点为 前一点
    NoteLineType_curve1,   //二次曲线 目标点为 第二点  两条线交点
    NoteLineType_curve2,   //三次曲线 目标点为 第二点  两个控制点
} NoteLineType;

typedef enum : NSUInteger {
    WhiteboardMode_move,//没有特殊操作
    WhiteboardMode_draw,//画
    WhiteboardMode_erase,//擦除
} WhiteboardMode;

typedef enum : NSUInteger {
    WhiteboardOperate_add,//增加
    WhiteboardOperate_erase,//擦除
} WhiteboardOperate;

#endif /* WhiteboardEnum_h */
