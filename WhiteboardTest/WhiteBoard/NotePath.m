//
//  NotePath.m
//  WhiteboardTest
//
//  Created by shgbit on 2019/7/16.
//  Copyright © 2019 shgbit. All rights reserved.
//

#import "NotePath.h"

@interface NotePath()
@property(nonatomic,strong) UIBezierPath *myPath;
@end

@implementation NotePath

-(instancetype)init{
    if(self = [super init]){
        self.lineId = [[NSUUID UUID] UUIDString];
        self.lineColor = [UIColor blackColor];
        self.lineWidth = 1.0;
        self.lineType = NoteLineType_curve2;
    }
    return self;
}

////直接画
//-(void)drawStraightLine{
//    if(self.paths && self.paths.count>1){
//        //获得处理的上下文
//        CGContextRef context = UIGraphicsGetCurrentContext();
//        //线条宽
//        CGContextSetLineWidth(context, 2.0);
//        //线条颜色
//        //        CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0); //设置线条颜色第一种方法
//        CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
//
//        CGContextSetLineJoin(context, kCGLineJoinRound);
//
//        CGContextSetLineCap(context , kCGLineCapRound);
//
//        CGPoint aPoints[self.paths.count];
//        for (int i =0; i<self.paths.count; i++) {
//            NSValue *point = [self.paths objectAtIndex:i];
//            aPoints[i] = point.CGPointValue;
//        }
//        //添加线 points[]坐标数组，和count大小
//        CGContextAddLines(context, aPoints, self.paths.count);
//        //根据坐标绘制路径
//        CGContextDrawPath(context, kCGPathStroke);
//    }
//}

//UIBezierPath b贝塞尔曲线画法。
- (void)drawBezierPathLine{
    [[UIColor colorWithCGColor:self.lineColor.CGColor] set];
//    [UIColor.redColor set];
    [self.myPath stroke];
}

-(BOOL)containPoint:(CGPoint)point{
   return [self.myPath containsPoint:point];
}

//贝塞尔顺滑曲线
-(void)moveToNextSmooth:(UIBezierPath *)path index:(int) i{
    int i1 = i-2;
    int i2 = i-1;
    int i3 = i;
    int i4 = i+1;
    //检查点
    if(!(i2>=0&&i3<=self.paths.count)){
        return;
    }
    
    NSValue *v1 = i1>=0? [self.paths objectAtIndex:i1]:nil;
    NSValue *v2 = [self.paths objectAtIndex:i2];
    NSValue *v3 = [self.paths objectAtIndex:i3];
    NSValue *v4 = i4<self.paths.count?[self.paths objectAtIndex:i4]:nil;
    
    NSValue *v2_2 =  [[self getContrlPointWhithP0:v1 p1:v2 p2:v3] lastObject];
    NSValue *v3_1 = [[self getContrlPointWhithP0:v2 p1:v3 p2:v4] firstObject];
    
    [path addCurveToPoint:v3.CGPointValue controlPoint1:v2_2.CGPointValue controlPoint2:v3_1.CGPointValue];
}

//两点中点为目的点 上个点为控制点
-(void)moveToNextWhthMidePoint:(UIBezierPath *)path index:(int) i{
    int i1 = i-1;
    int i2 = i;
    NSValue *v1 = [self.paths objectAtIndex:i1];
    NSValue *v2 = [self.paths objectAtIndex:i2];
    
    CGPoint pmid =  midpoint(v1.CGPointValue, v2.CGPointValue);
    [path addQuadCurveToPoint:pmid controlPoint:v1.CGPointValue];
}
//两点中为控制点
-(void)moveToNextWhthLinePoint:(UIBezierPath *)path index:(int) i{
    int i1 = i-2;
    int i2 = i-1;
    int i3 = i;
    int i4 = i+1;
    NSValue *v3 = [self.paths objectAtIndex:i3];
    if(i1>=0&&i4<self.paths.count){
        NSValue *v1 = [self.paths objectAtIndex:i1];
        NSValue *v2 = [self.paths objectAtIndex:i2];
        NSValue *v4 = [self.paths objectAtIndex:i4];
        
        NSValue *iv =  [self intersectionWithPoint1:v1 point2:v2 point3:v3 point4:v4];
        if(iv){
            [path addQuadCurveToPoint:v3.CGPointValue controlPoint:iv.CGPointValue];
        }
        else{
            [path addLineToPoint:v3.CGPointValue];
        }
    }
    else{
        [path addLineToPoint:v3.CGPointValue];
    }
}


#pragma mark =================控制点取得方法================
CGPoint midpoint(CGPoint p0, CGPoint p1) {
    
    return (CGPoint) {
        (p0.x + p1.x) / 2.0,
        (p0.y + p1.y) / 2.0
    };
}

//根据 三个 取得两个控制点（中点的前后 控制点）
-(NSArray *)getContrlPointWhithP0:(NSValue *)p0 p1:(NSValue *)p1 p2:(NSValue *)p2{
    
    if((p0&&p1)||(p1&&p2)){
        //起点 没有 补充
        if(!p0){
            CGPoint pb = p1.CGPointValue;
            CGPoint pc = p2.CGPointValue;
            p0 =  [NSValue valueWithCGPoint:(CGPointMake((pb.x-pc.x)/2+pb.x, (pb.y-pc.y)/2+pb.y))];
            
        }
        else if(!p2){
            CGPoint pa = p0.CGPointValue;
            CGPoint pb = p1.CGPointValue;
            p2 =  [NSValue valueWithCGPoint:(CGPointMake((pb.x-pa.x)/2+pb.x, (pb.y-pa.y)/2+pb.y))];
        }
    }
    else{
        //传入的值 错误
        return nil;
    }
    
    
    CGPoint pa = p0.CGPointValue;
    CGPoint pb = p1.CGPointValue;
    CGPoint pc = p2.CGPointValue;
    
    CGPoint pm_ab = CGPointMake((pa.x+pb.x)/2.0, (pa.y+pb.y)/2.0);
    CGPoint pm_bc = CGPointMake((pb.x+pc.x)/2.0, (pb.y+pc.y)/2.0);
    CGPoint pm_abbc =  CGPointMake((pm_ab.x+pm_bc.x)/2, (pm_ab.y+pm_bc.y)/2);
    
    
    float dis_x = pb.x - pm_abbc.x;
    float dis_y = pb.y - pm_abbc.y;
    
    
    CGPoint p_fre = CGPointMake((dis_x + pm_ab.x), (dis_y + pm_ab.y));
    CGPoint p_nex = CGPointMake((dis_x + pm_bc.x), (dis_y + pm_bc.y));
    
    return @[[NSValue valueWithCGPoint:p_fre],[NSValue valueWithCGPoint:p_nex]];
}


//相交点 控制法
-(NSValue *)intersectionWithPoint1:(NSValue *)point1 point2:(NSValue *)point2 point3:(NSValue *)point3 point4:(NSValue *)point4{
    CGPoint p1 = point1.CGPointValue;
    CGPoint p2 = point2.CGPointValue;
    CGPoint p3 = point3.CGPointValue;
    CGPoint p4 = point4.CGPointValue;
    
    float a1 = p2.y - p1.y;
    float b1 = p2.x - p1.x;
    float c1 = b1*p1.y - a1*p1.x;
    
    float a2 = p4.y - p3.y;
    float b2 = p4.x - p3.x;
    float c2 = b2*p3.y - a2*p3.x;
    
    b1 = -1*b1;
    b2 = -1*b2;
    
    //无解或无穷多解
    if(a1*b2 -a2*b1 ==0){
        return nil;
    }
    
    float ix = (b1*c2-b2*c1)/(a1*b2 -a2*b1);
    float iy = (c1*a2-c2*a1)/(a1*b2 -a2*b1);
    
    
    return [NSValue valueWithCGPoint:CGPointMake(ix, iy)];
}

#pragma mark =================setters================
-(void)setPaths:(NSArray *)paths{
    _paths = paths;
    
    //直接计算出路径 避免重复计算
    if(_paths && _paths.count>1){
        UIBezierPath *path = [[UIBezierPath alloc] init];
        path.lineCapStyle = kCGLineCapRound; //线条拐角
        path.lineJoinStyle = kCGLineJoinRound; //终点处理
        path.lineWidth = self.lineWidth;
 
        //颜色无法在这边设置
        
        for (int i =0; i<_paths.count; i++)  {
            CGPoint point = ((NSValue *)[_paths objectAtIndex:i]).CGPointValue;
            if(i==0){
                [path moveToPoint: point];
            }
            else{
                if(self.lineType ==NoteLineType_straight){
                    //直接化直线
                    [path addLineToPoint:point];
                }
                else if(self.lineType == NoteLineType_curve0){
                    //两点中点为目的点 上个点为控制点
                    [self moveToNextWhthMidePoint:path index:i];
                }
                else if(self.lineType == NoteLineType_curve1){
                    //两条直线相交获取控制点
                    [self moveToNextWhthLinePoint:path index:i];
                }
                else {
                    //贝思尔顺滑曲线
                    [self moveToNextSmooth:path index:i];
                }
            }
        }
        
        self.myPath = path;
    }
    else{
        self.myPath = nil;
    }
}

@end


#pragma mark =================操作================
@implementation NotePathOper
-(instancetype)init{
    if(self=[super init]){
        self.operId = [[NSUUID UUID] UUIDString];
    }
    return self;
}
@end
