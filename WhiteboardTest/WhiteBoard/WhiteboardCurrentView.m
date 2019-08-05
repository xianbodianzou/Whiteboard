//
//  WhiteboardCurrentView.m
//  WhiteboardTest
//
//  Created by shgbit on 2019/7/16.
//  Copyright © 2019 shgbit. All rights reserved.
//

#import "WhiteboardCurrentView.h"
#import "NotePath.h"

@interface WhiteboardCurrentView()
@property (nonatomic,strong) NotePath *currentNotePath;//当前j笔记
@property (nonatomic,strong) NSMutableArray *currentPathStrokes;//当前一个笔记中的所有笔画
@property (nonatomic,strong) NSMutableArray *arrPoint;//删除点
@end

@implementation WhiteboardCurrentView


-(instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
//        self.mode = WhiteboardMode_draw;//默认画模式
//        self.currentLineColor = [UIColor blackColor];
//        self.currentLineWidth = 1.0;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    //测试数据
    if(self.currentNotePath){
        [self.currentNotePath drawBezierPathLine];
    }

}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
   
    CGPoint point =  [self getTapPoint:touches];
     //    NSLog(@"开始点：%@",@(point));
    if([self callBack_getMode] ==  WhiteboardMode_draw){
        [self newCurrentPath:point];
    }
    else{
        [self newCurrentDPath:point];
    }
    

}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    CGPoint point =  [self getTapPoint:touches];
    //    NSLog(@"移动点：%@",@(point));
    if([self callBack_getMode] == WhiteboardMode_draw){
        [self updateCurrentPath:point];
        [self setNeedsDisplay];
    }
    else{
        [self updateCurrentDPath:point];
    }
}
-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //完成画线
    CGPoint point =  [self getTapPoint:touches];
    //    NSLog(@"结束点：%@",@(point));
    if([self callBack_getMode] == WhiteboardMode_draw){
        [self updateCurrentPath:point];
        [self callback_compeleteFullPathStrokes];
        //本地刷新
        [self setNeedsDisplay];
    }
    //删除点
    else if([self callBack_getMode] ==WhiteboardMode_erase){
        [self updateCurrentDPath:point];
        [self callback_earsePoint];
    }
    
}

-(CGPoint)getTapPoint:(NSSet<UITouch *> *)touches{
    UITouch * touch = touches.anyObject;//获取触摸对象
    CGPoint p0 =  [touch locationInView:self];
    return p0;
}

-(void)newCurrentDPath:(CGPoint)point{
    self.arrPoint = [[NSMutableArray alloc] init];
    [self.arrPoint addObject:[NSValue valueWithCGPoint:point]];
}
-(void)updateCurrentDPath:(CGPoint)point{
    [self.arrPoint addObject:[NSValue valueWithCGPoint:point]];
}

-(void)newCurrentPath:(CGPoint) point{
    self.currentNotePath = [[NotePath alloc] init];
    self.currentNotePath.lineWidth = [self callback_getLineWidth];
    self.currentNotePath.lineColor = [self callback_getLineColor];
    self.currentNotePath.lineType = [self callback_getLineType];
    self.currentPathStrokes = [[NSMutableArray alloc] init];
    [self.currentPathStrokes addObject:[NSValue valueWithCGPoint:point]];
}

-(void)updateCurrentPath:(CGPoint) point{
    [self.currentPathStrokes addObject:[NSValue valueWithCGPoint:point]];
    [self.currentNotePath setPathPoints:[self.currentPathStrokes copy]];
}


#pragma mark =================代理================
-(void)callback_compeleteFullPathStrokes{
    if(self.delegate && [self.delegate respondsToSelector:@selector(compeleteFullPathStrokes:)]){
        [self.currentNotePath setPathPoints:[self.currentPathStrokes copy] compelete:YES];
        [self.delegate compeleteFullPathStrokes:self.currentNotePath];
        self.currentNotePath = nil;
    }
}

-(void)callback_earsePoint{
    if(self.delegate && [self.delegate respondsToSelector:@selector(earsePoint:)]){
        [self.delegate earsePoint:self.arrPoint];
        self.arrPoint = nil;
    }
}

-(float)callback_getLineWidth{
    if(self.delegate && [self.delegate respondsToSelector:@selector(wc_getLineWidth)]){
        return [self.delegate wc_getLineWidth];
    }
    return 1.0;
}

-(UIColor *)callback_getLineColor{
    if(self.delegate && [self.delegate respondsToSelector:@selector(wc_getLineColor)]){
        return [self.delegate wc_getLineColor];
    }
    return [UIColor blackColor];
}

-(NoteLineType)callback_getLineType{
    if(self.delegate && [self.delegate respondsToSelector:@selector(wc_getLineType)]){
        return [self.delegate wc_getLineType];
    }
    return NoteLineType_straight;
}

-(WhiteboardMode)callBack_getMode{
    if(self.delegate && [self.delegate respondsToSelector:@selector(wc_getMode)]){
        return [self.delegate wc_getMode];
    }
    return WhiteboardMode_draw;
}

@end
