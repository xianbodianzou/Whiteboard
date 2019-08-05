//
//  WhiteboardView.h
//  WhiteboardTest
//
//  Created by shgbit on 2019/7/16.
//  Copyright © 2019 shgbit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WhiteboardEnum.h"

@interface WhiteboardView : UIView

//当前线模式
@property (nonatomic,assign) WhiteboardMode currentMode;
//当前线宽
@property (nonatomic,assign) float currentLineWidth;
//当前颜色
@property (nonatomic,strong) UIColor *currentLineColor;
//线类型
@property (nonatomic,assign) NoteLineType currentLineType;

//前进
-(void)forword;
//后退
-(void)back;

@end
