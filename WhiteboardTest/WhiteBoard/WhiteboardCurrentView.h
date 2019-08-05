//
//  WhiteboardCurrentView.h
//  WhiteboardTest
//
//  Created by shgbit on 2019/7/16.
//  Copyright © 2019 shgbit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WhiteboardEnum.h"

@class NotePath;
@protocol WhiteboardCurrentViewDelegate <NSObject>

//画线完成
-(void)compeleteFullPathStrokes:(NotePath *)path;
//擦除点
-(void)earsePoint:(NSArray *) points;

@optional
-(float)wc_getLineWidth;
-(UIColor *)wc_getLineColor;
-(NoteLineType)wc_getLineType;
-(WhiteboardMode)wc_getMode;
@end

@interface WhiteboardCurrentView : UIView

@property (nonatomic, weak) id<WhiteboardCurrentViewDelegate> delegate;

//@property (nonatomic,assign) WhiteboardMode mode;
////当前线宽
//@property (nonatomic,assign) float currentLineWidth;
////当前颜色
//@property (nonatomic,strong) UIColor *currentLineColor;

@end


