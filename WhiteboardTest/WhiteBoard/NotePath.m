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
//@property(nonatomic,strong) UIBezierPath *myPathLeft;
//@property(nonatomic,strong) UIBezierPath *myPathRight;
//@property(nonatomic,strong) UIBezierPath *myFillPath;

//@property(nonatomic,strong) NSArray *leftPathPoints;
//@property(nonatomic,strong) NSArray *rightPathPoints;
//@property(nonatomic,strong) NSArray *bifengPaths;//一块一块的画
@property(nonatomic,strong) NSMutableArray *tipAllPaths;//笔锋连线全部
//@property(nonatomic,strong) NSArray *tipPahts;//笔锋连线画法
//@property(nonatomic,strong) NSArray *tipFills;//笔锋画法fill

//@property(nonatomic,strong) NSMutableDictionary *sta;//数据统计

@property(nonatomic,strong) UIBezierPath *erasePath;//擦除匹配线

@property(nonatomic,assign) BOOL isCompelete;//是否笔画完成

@end

@implementation NotePath

-(instancetype)init{
    if(self = [super init]){
        self.lineId = [[NSUUID UUID] UUIDString];
        self.lineColor = [UIColor blackColor];
        self.lineWidth = 1.0;
        self.lineType = NoteLineType_straight;
        self.tipAllPaths = [[NSMutableArray alloc] init];
//        self.sta = [[NSMutableDictionary alloc] init];
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
    
    if(self.lineType ==NoteLineType_brush||self.lineType==NoteLineType_tip){
        for (UIBezierPath *p in self.tipAllPaths) {
            [p stroke];
        }
    }
    else{
        [self.myPath stroke];
    }
}

-(BOOL)containPoint:(CGPoint)point{
//   return [self.myPath containsPoint:point];
    return [self.erasePath containsPoint:point];
}

//贝塞尔顺滑曲线
-(void)moveToNextSmooth:(UIBezierPath *)path pathPoints:(NSArray *)pathPoints index:(int) i{
    int i1 = i-2;
    int i2 = i-1;
    int i3 = i;
    int i4 = i+1;
    //检查点
    if(!(i2>=0&&i3<=self.pathPoints.count)){
        return;
    }
    
    NSValue *v1 = i1>=0? [pathPoints objectAtIndex:i1]:nil;
    NSValue *v2 = [pathPoints objectAtIndex:i2];
    NSValue *v3 = [pathPoints objectAtIndex:i3];
    NSValue *v4 = i4<pathPoints.count?[pathPoints objectAtIndex:i4]:nil;
    
    NSValue *v2_2 =  [[self getContrlPointWhithP0:v1 p1:v2 p2:v3] lastObject];
    NSValue *v3_1 = [[self getContrlPointWhithP0:v2 p1:v3 p2:v4] firstObject];
    
    [path addCurveToPoint:v3.CGPointValue controlPoint1:v2_2.CGPointValue controlPoint2:v3_1.CGPointValue];
}

//两点中点为目的点 上个点为控制点
-(void)moveToNextWhthMidePoint:(UIBezierPath *)path pathPoints:(NSArray *)pathPoints index:(int) i{
    int i1 = i-1;
    int i2 = i;
    NSValue *v1 = [pathPoints objectAtIndex:i1];
    NSValue *v2 = [pathPoints objectAtIndex:i2];
    
    CGPoint pmid =  midpoint(v1.CGPointValue, v2.CGPointValue);
    [path addQuadCurveToPoint:pmid controlPoint:v1.CGPointValue];
}
//两点中为控制点
-(void)moveToNextWhthLinePoint:(UIBezierPath *)path pathPoints:(NSArray *)pathPoints index:(int) i{
    int i1 = i-2;
    int i2 = i-1;
    int i3 = i;
    int i4 = i+1;
    NSValue *v3 = [pathPoints objectAtIndex:i3];
    if(i1>=0&&i4<self.pathPoints.count){
        NSValue *v1 = [pathPoints objectAtIndex:i1];
        NSValue *v2 = [pathPoints objectAtIndex:i2];
        NSValue *v4 = [pathPoints objectAtIndex:i4];
        
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
//笔锋3
//-(void)bifeng3:(NSArray *)paths{
//    if(paths&&paths.count>1){
//        for (int i =0; i<paths.count-1; i++) {
//            float r1 = 3;
//            float r2 = 3;
//            CGPoint p1 = ((NSValue *)paths[i]).CGPointValue;
//            CGPoint p2 = ((NSValue *)paths[i+1]).CGPointValue;
////            self addQuadCurve:<#(CGPoint)#> ToPoint:<#(CGPoint)#> cp:<#(CGPoint)#> r1c:<#(float)#> rc2:<#(float)#>
//        }
//    }
//}

////笔锋画法2
//-(void)bifeng2:(NSArray *)paths{
//    if(paths&&paths.count>1){
//        NSMutableArray *lines = [[NSMutableArray alloc] init];
//        for (int i =0; i<self.pathPoints.count-1; i++) {
//            float r1 = 3;
//            float r2 = 3;
//            CGPoint p1 = ((NSValue *)[paths objectAtIndex:i]).CGPointValue;
//            CGPoint p2 = ((NSValue *)[paths objectAtIndex:i+1]).CGPointValue;
//            ZZLineRpoint *lineRP = [self getVectorFangentR1:r1 r2:r2 p1:p1 p2:p2];
//            [lines addObject:lineRP];
//        }
//
//        if(lines.count>1){
//            NSMutableArray *paths = [[NSMutableArray alloc] init];
//            for (int i =0; i<lines.count; i++) {
//                ZZLineRpoint *l1 = [lines objectAtIndex:i];
//                if(i==0){
//                    //在点处画圆
//                    UIBezierPath *path=[UIBezierPath bezierPathWithOvalInRect:CGRectMake(l1.p1.x-l1.r1, l1.p1.y-l1.r1, l1.r1*2, l1.r1*2)];
//                    [paths addObject:path];
//                }
//
//                //在点处画圆
//                UIBezierPath *path=[UIBezierPath bezierPathWithOvalInRect:CGRectMake(l1.p2.x-l1.r2, l1.p2.y-l1.r2, l1.r2*2, l1.r2*2)];
//                [paths addObject:path];
//
//                //画梯形
//                UIBezierPath *pathT = [[UIBezierPath alloc] init];
//                [pathT moveToPoint:l1.lsP];
//                [pathT addLineToPoint:l1.leP];
//                [pathT addLineToPoint:l1.reP];
//                [pathT addLineToPoint:l1.rsP];
//                [pathT closePath];
//                [paths addObject:pathT];
//            }
//            self.bifengPaths = [paths copy];
//        }
//    }
//}

//笔锋画法
//-(void)bifeng:(NSArray *)paths{
//    if(paths&&paths.count>1){
//        NSMutableArray *lines = [[NSMutableArray alloc] init];
//        for (int i =0; i<self.pathPoints.count-1; i++) {
//            float r1 = 3;
//            float r2 = 3;
//            CGPoint p1 = ((NSValue *)[paths objectAtIndex:i]).CGPointValue;
//            CGPoint p2 = ((NSValue *)[paths objectAtIndex:i+1]).CGPointValue;
//            ZZLineRpoint *lineRP = [self getVectorFangentR1:r1 r2:r2 p1:p1 p2:p2];
//
//            [lines addObject:lineRP];
//        }
//        NSMutableArray *p1Points = [[NSMutableArray alloc] init];
//        NSMutableArray *p2Points = [[NSMutableArray alloc] init];
//
//        if(lines.count>1){
//            BOOL lastIsLeft = YES;
//            for (int i =0; i<lines.count-1; i++) {
//                ZZLineRpoint *l1 = [lines objectAtIndex:i];
//                ZZLineRpoint *l2 = [lines objectAtIndex:i+1];
//                //判断 线是左转 还是右转
//                float corner = l2.vector - l1.vector;
//                if(corner>180){
//                    corner = 360 - corner;
//                }
//                else if(corner<-180){
//                    corner = 360 +corner;
//                }
//
//                BOOL isLeft = corner<=0;
//                bool isRealLeft = corner<=0;
//                if(i==0){
//                    if(fabsf(corner)<45){
//                        isLeft = YES;
//                    }
//                }
//                else{
//                    if(fabsf(corner)<45){
//                        //方向小不改变方向
//                        isLeft = lastIsLeft;
//                    }
//                    else{
//                        isLeft = corner<=0;
//                    }
//                }
//
////                isLeft = corner<=0;
//
//                NSLog(@"向量角度：%@",isLeft?@"左":@"右");
//
//                if(i==0){
//                    //起始点
//                    if(isLeft){
//                        [p1Points addObject:[NSValue valueWithCGPoint:l1.lsP]];
//                        [p2Points addObject:[NSValue valueWithCGPoint:l1.p1]];
//                    }
//                    else{
//                        [p1Points addObject:[NSValue valueWithCGPoint:l1.p1]];
//                        [p2Points addObject:[NSValue valueWithCGPoint:l1.rsP]];
//                    }
//                }
//
//                if(isLeft){
//                    [p1Points addObject:[NSValue valueWithCGPoint:l1.leP]];
//                    if(isRealLeft) [p1Points addObject:[NSValue valueWithCGPoint:l2.lsP]];
//                    [p2Points addObject:[NSValue valueWithCGPoint:l1.p2]];
//                }
//                else{
//                    [p1Points addObject:[NSValue valueWithCGPoint:l1.p2]];
//                    [p2Points addObject:[NSValue valueWithCGPoint:l1.reP]];
//                    if(!isRealLeft) [p2Points addObject:[NSValue valueWithCGPoint:l2.rsP]];
//                }
//
//                if(i+1==lines.count-1){
//                    //结束点
//                    [p1Points addObject:[NSValue valueWithCGPoint:l2.p2]];
//                    [p2Points addObject:[NSValue valueWithCGPoint:l2.p2]];
//                }
//
//                lastIsLeft = isLeft;
//            }
//        }
//
//        self.leftPathPoints = p1Points;
//        self.rightPathPoints = p2Points;
//
//        NSLog(@"pathPoints:%@",self.pathPoints);
//        NSLog(@"leftPathPoints:%@",self.leftPathPoints);
//        NSLog(@"rightPathPoints:%@",self.rightPathPoints);
//    }
//    else{
//        self.leftPathPoints = @[];
//        self.rightPathPoints = @[];
//    }
//}

#pragma mark =================setters================

//笔画完成设置
-(void)setPathPoints:(NSArray *)paths compelete:(BOOL)compelete{
    self.isCompelete = compelete;
    [self setPathPoints:paths];
}

-(void)setPathPoints:(NSArray *)paths{
    _pathPoints = paths;
    self.myPath =  [self calcPath:_pathPoints];
}

//-(UIBezierPath *)callFillPath{
//    NSArray *lps = self.leftPathPoints;
//    NSArray *rps = [[[[NSMutableArray alloc] initWithArray:self.rightPathPoints] reverseObjectEnumerator] allObjects] ;
//    if(lps&&lps.count>1&&rps&&rps.count>1){
//        UIBezierPath *path = [[UIBezierPath alloc] init];
//        for (int i =0; i<lps.count; i++)  {
//            CGPoint point = ((NSValue *)[lps objectAtIndex:i]).CGPointValue;
//            if(i==0){
//                [path moveToPoint: point];
//            }
//            else{
//                //两点中点为目的点 上个点为控制点
//                [self moveToNextWhthMidePoint:path pathPoints:lps index:i];
//                //中点添加直线到中点
//                if(i==lps.count-1){
//                    [path addLineToPoint:point];
//                }
//            }
//        }
//
//        for (int i = 0; i<rps.count; i++) {
//            CGPoint point = ((NSValue *)[rps objectAtIndex:i]).CGPointValue;
//            if(i==0){
//
//            }
//            else{
//                //两点中点为目的点 上个点为控制点
//                [self moveToNextWhthMidePoint:path pathPoints:rps index:i];
//                //中点添加直线到中点
//                if(i==rps.count-1){
//                    [path addLineToPoint:point];
//                }
//            }
//        }
//
//        [path closePath];
//
//        return  path;
//    }
//
//    return nil;
//}


-(UIBezierPath *)calcPath:(NSArray *)pathPoints{
    //计算擦除点路径
    if(self.isCompelete&&pathPoints &&pathPoints.count>1){
        
        CGPoint pf = ((NSValue *)pathPoints[0]).CGPointValue;
        self.erasePath = [[UIBezierPath alloc] init];
        [self.erasePath moveToPoint:pf];
        
        //开始和结束补点。
        NSMutableArray *tmp = [[NSMutableArray alloc] initWithArray:pathPoints];
        [tmp insertObject:pathPoints.firstObject atIndex:0];
        [tmp addObject:pathPoints.lastObject];
        
        if(pathPoints.count>2){
            for (int i =0; i<pathPoints.count-2; i++){
                CGPoint pi1 = ((NSValue *)pathPoints[i]).CGPointValue;
                CGPoint pi2 = ((NSValue *)pathPoints[i+1]).CGPointValue;
                CGPoint pi3 = ((NSValue *)pathPoints[i+2]).CGPointValue;
                CGPoint p1 = midpoint(pi1, pi2);
                CGPoint p2 = midpoint(pi2, pi3);
                CGPoint cp = pi2;
                
                //所有点 加入擦除点路径。
                [self getQuadCurvePoints:p1 ToPoint:p2 cp:cp];
            }
        }
    }
    
    
    //直接计算出路径 避免重复计算
    if(pathPoints && pathPoints.count>1){
        UIBezierPath *path = [[UIBezierPath alloc] init];
        path.lineCapStyle = kCGLineCapRound; //线条拐角
        path.lineJoinStyle = kCGLineJoinRound; //终点处理
        path.lineWidth = self.lineWidth;
        
        //开始和结束补点。
        NSMutableArray *tmp = [[NSMutableArray alloc] initWithArray:pathPoints];
        [tmp insertObject:pathPoints.firstObject atIndex:0];
        [tmp addObject:pathPoints.lastObject];
        
        //颜色无法在这边设置
        if(self.lineType == NoteLineType_brush||self.lineType ==NoteLineType_tip){
            [self.tipAllPaths removeAllObjects];
            if(pathPoints.count>2){
                for (int i =0; i<pathPoints.count-2; i++){
                    CGPoint pi1 = ((NSValue *)pathPoints[i]).CGPointValue;
                    CGPoint pi2 = ((NSValue *)pathPoints[i+1]).CGPointValue;
                    CGPoint pi3 = ((NSValue *)pathPoints[i+2]).CGPointValue;
                    CGPoint p1 = midpoint(pi1, pi2);
                    CGPoint p2 = midpoint(pi2, pi3);
                    CGPoint cp = pi2;
                    //毛笔写法
                    [self addQuadCurve:p1 ToPoint:p2 cp:cp];
                }
            }
            //起笔修正
            if(self.lineType == NoteLineType_brush) [self corStartTip];
            //笔尾修正
            if(self.isCompelete) [self corEndTip];
        }
        else{
            for (int i =0; i<pathPoints.count; i++)  {
                CGPoint point = ((NSValue *)[pathPoints objectAtIndex:i]).CGPointValue;
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
                        [self moveToNextWhthMidePoint:path pathPoints:pathPoints index:i];
                        //中点添加直线到中点
                        if(i==pathPoints.count-1){
                            [path addLineToPoint:point];
                        }
                    }
                    else if(self.lineType == NoteLineType_curve1){
                        //两条直线相交获取控制点
                        [self moveToNextWhthLinePoint:path pathPoints:pathPoints index:i];
                    }
                    else {
                        //贝思尔顺滑曲线
                        [self moveToNextSmooth:path pathPoints:pathPoints index:i];
                    }
                }
            }
        }
        return path;
    }
    else{
        return nil;
    }
}

#pragma mark =================笔锋设计================
//修正起笔
-(void)corStartTip{
    
    int cp = 6;
    if(self.tipAllPaths.count>=cp ){
        for (int i=0; i<cp; i++) {
            UIBezierPath *p = (UIBezierPath *)self.tipAllPaths[i];
            float cw = i*8.0/cp;
            if(p.lineWidth>cw){
                p.lineWidth = cw;
            }
        }
    }
}

//笔锋修正
-(void)corEndTip{
    if(!self.tipAllPaths.count){
        return;
    }
    float lastW = 8;
    int lastCP = 50;
    
    //根据笔速修正笔锋距离
    if(self.pathPoints.count>2){
        CGPoint pl = ((NSValue *)self.pathPoints.lastObject).CGPointValue;
        CGPoint pl3 = ((NSValue *)self.pathPoints[self.pathPoints.count-3]).CGPointValue;
        
        int ccp = round([self getDisP1:pl p2:pl3]);
        
        if(lastCP>ccp){
            lastCP =ccp;
        }
    }
    
    //根据长度修正笔锋距离
    if(self.tipAllPaths.count>lastCP*2){
    }
    else{
        lastCP = (int)self.tipAllPaths.count/2;
    }
    UIBezierPath *p = (UIBezierPath *)self.tipAllPaths[lastCP];
    lastW = p.lineWidth;
    
//    NSLog(@"%@",@(lastW));
    
    for (int i=(int)self.tipAllPaths.count-1,j=0; i>0&&j<100&&j<self.tipAllPaths.count/2; i--,j++) {
        UIBezierPath *p = self.tipAllPaths[i];
        float cw = j*lastW/lastCP;
        if(p.lineWidth>cw){
            p.lineWidth = cw;
        }
    }
}

-(void)getQuadCurvePoints:(CGPoint )p1 ToPoint:(CGPoint)p2 cp:(CGPoint) cp {
    float line1 = [self getDisP1:p1 p2:cp];
    float line2 = [self getDisP1:cp p2:p2];
    int dengfeng = ceil(MAX(line1, line2));
    
    float v1c = [self comAngle:[self getvectorP1:p1 p2:cp]];
    float vc2 = [self comAngle:[self getvectorP1:cp p2:p2]];
    
    for (int i=0; i<dengfeng; i++) {
        float dis1 = line1*i/dengfeng;
        float dis2 = line2*i/dengfeng;
        
        CGPoint _p1 = [self getPoint:p1 vector:v1c r:dis1];
        CGPoint _p2 = [self getPoint:cp vector:vc2 r:dis2];
        
        float _d = [self getDisP1:_p1 p2:_p2];
        float _v = [self comAngle:[self getvectorP1:_p1 p2:_p2]];
        float _dr = _d*i/dengfeng;
        
        CGPoint pd =  [self getPoint:_p1 vector:_v r:_dr];
        
        [self.erasePath addLineToPoint:pd];
        
//        NSLog(@"%@",NSStringFromCGPoint(pd));
    }
}

//自定义的贝塞尔曲线
-(void)addQuadCurve:(CGPoint )p1 ToPoint:(CGPoint)p2 cp:(CGPoint) cp {
    float line1 = [self getDisP1:p1 p2:cp];
    float line2 = [self getDisP1:cp p2:p2];
    int dengfeng = ceil(MAX(line1, line2));

    float r1c = !line1?20:20/sqrt(line1);
    float rc2 = !line2?20:20/sqrt(line2);
    if(r1c>8) r1c = 8;
    if(rc2>8) rc2 = 8;
    
    if(self.lineType == NoteLineType_tip){
        r1c = rc2 = self.lineWidth;
    }
//    NSLog(@"%@",@(r1c));
    
    float v1c = [self comAngle:[self getvectorP1:p1 p2:cp]];
    float vc2 = [self comAngle:[self getvectorP1:cp p2:p2]];
    
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    for (int i=0; i<dengfeng; i++) {
        float dis1 = line1*i/dengfeng;
        float dis2 = line2*i/dengfeng;
        
        CGPoint _p1 = [self getPoint:p1 vector:v1c r:dis1];
        CGPoint _p2 = [self getPoint:cp vector:vc2 r:dis2];
        
        float _d = [self getDisP1:_p1 p2:_p2];
        float _v = [self comAngle:[self getvectorP1:_p1 p2:_p2]];
        float _dr = _d*i/dengfeng;
        
        CGPoint pd =  [self getPoint:_p1 vector:_v r:_dr];
        
        [arr addObject:[NSValue valueWithCGPoint:pd]];
    }
    
    [arr addObject:[NSValue valueWithCGPoint:p2]];
    NSMutableArray *patharr = [[NSMutableArray alloc] init];
    for (int i =0; i<arr.count-1; i++) {
        CGPoint p1 =  ((NSValue *)arr[i]).CGPointValue;
        CGPoint p2 =  ((NSValue *)arr[i+1]).CGPointValue;
        float w = r1c + i*(rc2-r1c)/dengfeng;
        UIBezierPath *pitem = [[UIBezierPath alloc] init];
        pitem.lineCapStyle =  kCGLineCapRound;
        pitem.lineJoinStyle = kCGLineJoinRound;
        pitem.lineWidth = w;
        [pitem moveToPoint:p1];
        [pitem addLineToPoint:p2];
        [patharr addObject:pitem];
        [self.tipAllPaths addObject:pitem];
    }
}



//获取切线向量
-(ZZLineRpoint *)getVectorFangentR1:(float) r1 r2:(float) r2 p1:(CGPoint)p1 p2:(CGPoint) p2{
    float vector12 = [self comAngle:[self getvectorP1:p1 p2:p2]];
    float dis12 =  [self getDisP1:p1 p2:p2];
    float inAngle = [self getInAngle:fabsf(r2-r1)string:dis12];
    //左边切线半径向量
    float vector12_qLeft = [self getVFLeftR1:r1 r2:r2 vector12:vector12 inAngle:inAngle];
    //右边切线半径向量
    float vector12_qRight = [self getVFTRightR1:r1 r2:r2 vector12:vector12 inAngle:inAngle];
    
    CGPoint pls = [self getPoint:p1 vector:vector12_qLeft r:r1];
    CGPoint ple =  [self getPoint:p2 vector:vector12_qLeft r:r2];
    CGPoint prs =  [self getPoint:p1 vector:vector12_qRight r:r1];
    CGPoint pre = [self getPoint:p2 vector:vector12_qRight r:r2];
    
    ZZLineRpoint *lineRPoint = [[ZZLineRpoint alloc] init];
    lineRPoint.vector =vector12;
    lineRPoint.p1 = p1;
    lineRPoint.r1 = r1;
    lineRPoint.p2 = p2;
    lineRPoint.r2 = r2;
    lineRPoint.lsP = pls;
    lineRPoint.leP = ple;
    lineRPoint.rsP = prs;
    lineRPoint.reP = pre;
    return lineRPoint;
    
}

//根据起始点，向量，距离 取得 坐标
-(CGPoint)getPoint:(CGPoint) p vector:(float)vector r:(float)r{
    float x = r*cosf(DegreesToRadian(vector))+p.x;
    float y = r*sinf(DegreesToRadian(vector))+p.y;
    CGPoint pp = CGPointMake(x, y) ;
//    NSLog(@"切点：%@",NSStringFromCGPoint(pp));
    return pp;
}

//取得右手切线向量
-(float)getVFTRightR1:(float) r1 r2:(float) r2 vector12:(float)vector12 inAngle:(float) inAngle{
    //切线向量
    float vector12_q;
    if(r1<=r2){
        vector12_q = vector12 + (90 - inAngle);
    }
    else{
        vector12_q = vector12 - (90 -inAngle);
    }
//    NSLog(@"切线右手向量：%@",@(vector12_q));
    float vector12_q_r = vector12_q + 90;
//    NSLog(@"切线右手半径向量：%@",@(vector12_q_r));
    return vector12_q_r;
}


//取得左手切线向量
-(float)getVFLeftR1:(float) r1 r2:(float) r2 vector12:(float)vector12 inAngle:(float) inAngle{
    //切线向量
    float vector12_q;
    if(r1>=r2){
        vector12_q = vector12 + (90 - inAngle);
    }
    else{
        vector12_q = vector12 - (90 -inAngle);
    }
//    NSLog(@"切线左手向量：%@",@(vector12_q));
    float vector12_q_r = vector12_q - 90;
//    NSLog(@"切线左手半径向量：%@",@(vector12_q_r));
    return vector12_q_r;
}

//余弦值 求夹角
-(float)getInAngle:(float)edge string:(float) string{
    double angle  = acos(edge/string);
    double degree = RadianToDegrees(angle);
//    NSLog(@"夹角：%@",@(degree));
    return degree;
}

//获取两点距离
-(float)getDisP1:(CGPoint) p1 p2:(CGPoint) p2{
    float dis = sqrt(pow((p2.y-p1.y), 2)+pow((p2.x-p1.x), 2));
//    NSLog(@"距离：%@",@(dis));
    return dis;
}

//获取两点向量
-(CGPoint)getvectorP1:(CGPoint) p1 p2:(CGPoint) p2{
    return CGPointMake(p2.x-p1.x,p2.y-p1.y);
}

//获取向量角度
-(float)comAngle:(CGPoint )point{
    double angle  = atan2(point.y, point.x);
    double degree = RadianToDegrees(angle);
    if(degree<0){
        degree = 360+degree;
    }
//    NSLog(@"角度：%@",@(degree));
    return degree;
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


#pragma mark =================线段属性================
@implementation ZZLineRpoint
@end
