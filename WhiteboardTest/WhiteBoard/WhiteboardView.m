//
//  WhiteboardView.m
//  WhiteboardTest
//
//  Created by shgbit on 2019/7/16.
//  Copyright © 2019 shgbit. All rights reserved.
//

#import "WhiteboardView.h"
#import "WhiteboardCurrentView.h"
#import "NotePath.h"

@interface WhiteboardView()<WhiteboardCurrentViewDelegate>

@property (nonatomic,strong) NSMutableArray *notePaths;
@property (nonatomic,strong) WhiteboardCurrentView *wcv;
@property (nonatomic,strong) NSMutableArray *operHis;
@property (nonatomic,strong) NSMutableArray *operUndo;

@property (nonatomic,strong) NSMutableDictionary *dicPaths;//笔画键值对
@property (nonatomic,strong) NSMutableArray *addIds;//笔画添加顺序
@property (nonatomic,strong) NSMutableArray *eraseIds;//被擦除的id

@end

@implementation WhiteboardView


-(instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        
        [self customInit];
    }
    return self;
}


-(void)layoutSubviews{
    self.wcv.frame = self.bounds;
}

- (void)drawRect:(CGRect)rect {
    
    if(self.notePaths && self.notePaths.count){
        for (NotePath *path in self.notePaths) {
            [path drawBezierPathLine];
        }
    }
    
//    CGPoint p1 = CGPointMake(100, 200);
//    CGPoint cp = CGPointMake(300, 200);
//    CGPoint p2 = CGPointMake(101, 550);
//
//    float r1c = 5;
//    float rc2 = 0;
////
////    UIBezierPath *patt = [[UIBezierPath alloc] init];
////    [patt moveToPoint:p1];
////    [patt addLineToPoint:cp];
////    [patt addLineToPoint:p2];
////    [patt stroke];
////
////
//    NSArray *arr = [self addQuadCurve:p1 ToPoint:p2 cp:cp r1c:5 rc2:0];
//    for (UIBezierPath *p in arr) {
//        [p stroke];
//    }
    
//    //获得处理的上下文
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    //线条宽
//    CGContextSetLineWidth(context, 10.0);
//    //线条颜色
//    //        CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0); //设置线条颜色第一种方法
//    CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
//    
//    CGContextSetLineJoin(context, kCGLineJoinRound);
//    
//    CGContextSetLineCap(context , kCGLineCapRound);
//    
//    CGPoint aPoints[2];
//    aPoints[0] =  CGPointMake(100, 100);
//    aPoints[1] =  CGPointMake(100, 101);
//    
//    //添加线 points[]坐标数组，和count大小
//    CGContextAddLines(context, aPoints, 2);
//    //根据坐标绘制路径
//    CGContextDrawPath(context, kCGPathStroke);

}

-(NSArray *)addQuadCurve:(CGPoint )p1 ToPoint:(CGPoint)p2 cp:(CGPoint) cp r1c:(float)r1c rc2:(float)rc2{
    float line1 = [self getDisP1:p1 p2:cp];
    float line2 = [self getDisP1:cp p2:p2];
    int dengfeng = ceil(MAX(line1, line2));
    
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
    
    NSMutableArray *patharr = [[NSMutableArray alloc] init];
    for (int i =0; i<arr.count-1; i++) {
        CGPoint p1 =  ((NSValue *)arr[i]).CGPointValue;
        CGPoint p2 =  ((NSValue *)arr[i+1]).CGPointValue;
        float w = r1c + i*(rc2-r1c)/dengfeng;
        UIBezierPath *pitem = [[UIBezierPath alloc] init];
        pitem.lineWidth = w;
        [pitem moveToPoint:p1];
        [pitem addLineToPoint:p2];
        [patharr addObject:pitem];
    }
    
    return [patharr copy];
}


#pragma mark =================公有方法================
-(void)forword{
    NotePathOper *f = [self.operUndo lastObject];
    if(f){
        [self.operUndo removeObject:f];
        [self.operHis addObject:f];
        if(f.oper == WhiteboardOperate_add){
            [self.eraseIds removeObject:f.lineId];
        }
        else if(f.oper == WhiteboardOperate_erase){
            [self.eraseIds addObject:f.lineId];
        }
        
        [self generateAvailablePaths];
        [self setNeedsDisplay];
    }
}
-(void)back{
    NotePathOper *f = [self.operHis lastObject];
    if(f){
        [self.operHis removeObject:f];
        [self.operUndo addObject:f];
        if(f.oper == WhiteboardOperate_add){
            [self.eraseIds addObject:f.lineId];
        }
        else if(f.oper == WhiteboardOperate_erase){
            [self.eraseIds removeObject:f.lineId];
        }
        [self generateAvailablePaths];
        [self setNeedsDisplay];
    }
}

#pragma mark =================私有方法================
//初始化设置
-(void)customInit{
   
    self.wcv = [[WhiteboardCurrentView alloc] init];
    self.wcv.delegate = self;
    self.wcv.backgroundColor = [UIColor clearColor];
    [self addSubview:self.wcv];
    
    self.backgroundColor = [UIColor clearColor];
   
    self.operHis = [[NSMutableArray alloc] init];
    self.operUndo = [[NSMutableArray alloc] init];
    self.dicPaths = [[NSMutableDictionary alloc] init];
    self.addIds = [[NSMutableArray alloc] init];
    self.eraseIds = [[NSMutableArray alloc] init];
    
    self.currentMode = WhiteboardMode_draw;
    self.currentLineWidth = 1.0;
    self.currentLineColor = [UIColor blackColor];
    self.currentLineType = NoteLineType_tip;
}

//添加笔画
-(void)addNotepath:(NotePath *)path{
    //记录笔画字典，一次白板笔画只增不减
    [self.dicPaths setObject:path forKey:path.lineId];
    //笔画原始顺序
    [self.addIds addObject:path.lineId];
    //记录操作顺序
    [self recordOper:WhiteboardOperate_add lineId:path.lineId];
    //生成需要有效笔画
    [self generateAvailablePaths];
}
//擦除笔画
-(void)eraseNotePath:(NotePath *)path{
    //笔画擦除记录
    [self.eraseIds addObject:path.lineId];
    //记录操作顺序
     [self recordOper:WhiteboardOperate_erase lineId:path.lineId];
    //生成有效笔画
    [self generateAvailablePaths];
}

//记录操作，增加、擦除笔画
-(void)recordOper:(WhiteboardOperate) oper lineId:(NSString *)lineId{
    NotePathOper *nodeOper = [[NotePathOper alloc] init];
    nodeOper.oper = oper;
    nodeOper.lineId = lineId;
    [self.operHis addObject:nodeOper];
}

//生成需要 画笔画
-(void)generateAvailablePaths{
    //清除原有笔画
    [self.notePaths removeAllObjects];
    for (NSString *lineid in self.addIds) {
        //排除被擦除的
        if(![self.eraseIds containsObject:lineid]){
            NotePath *path = [self.dicPaths objectForKey:lineid];
            if(path){
                [self.notePaths addObject:path];
            }
        }
    }
}

//宽度 颜色 随机测试代码
-(void)randomTest{
    //测试代码
    NSUInteger r1 = arc4random_uniform(10) + 1;
    NSUInteger r2 = arc4random_uniform(255);
    NSUInteger r3 = arc4random_uniform(255);
    NSUInteger r4 = arc4random_uniform(255);
    
    self.currentLineWidth = r1;
    self.currentLineColor = [UIColor colorWithRed:r2/255.0 green:r3/255.0 blue:r4/255.0 alpha:1];
}

#pragma mark =================WhiteboardCurrentViewDelegate================
-(void)compeleteFullPathStrokes:(NotePath *)path{
//    [self randomTest];
    
    [self addNotepath:path];//加入笔画
    [self.operUndo removeAllObjects];//回撤笔画清除
    [self setNeedsDisplay];
}

-(void)earsePoint:(NSArray *)points{
    if(!self.notePaths) return;

    //找出删除的线
    NotePath *erasePath;
    for (NotePath *notepath in self.notePaths) {
        for (NSValue *dpv in points) {
            if([notepath containPoint:dpv.CGPointValue]){
                erasePath = notepath;
                break;
            }
        }
        if(erasePath) break;
    }
    
    //删线后重绘
    if(erasePath) {
        [self eraseNotePath:erasePath];//擦除笔画
        [self.operUndo removeAllObjects];//回撤笔画清除
        [self setNeedsDisplay];
    }
    
}

-(float)wc_getLineWidth{
    return self.currentLineWidth;
}

-(UIColor *)wc_getLineColor{
    return self.currentLineColor;
}

-(NoteLineType)wc_getLineType{
    return self.currentLineType;
}

-(WhiteboardMode)wc_getMode{
    return self.currentMode;
}

#pragma mark =================getters setters================
-(NSMutableArray *)notePaths{
    if(!_notePaths){
        _notePaths = [[NSMutableArray alloc] init];
    }
    return _notePaths;
}

-(void)setCurrentMode:(WhiteboardMode)mode{
    _currentMode = mode;
}

-(void)setCurrentLineWidth:(float)currentLineWidth{
    _currentLineWidth = currentLineWidth;
//    if(self.wcv){
//        self.wcv.currentLineWidth = _currentLineWidth;
//    }
}

-(void)setCurrentLineColor:(UIColor *)currentLineColor{
    _currentLineColor = currentLineColor;
//    if(self.wcv){
//        self.wcv.currentLineColor = _currentLineColor;
//    }
}


#pragma mark =================测试代码================

-(void)test{
    CGPoint p1 = CGPointMake(100, 100);
    float r1 = 5;
    CGPoint p2 = CGPointMake(200, 100);
    float r2 = 3;
    CGPoint p3 = CGPointMake(200, 150);
    float r3 = 4;
    CGPoint p4 = CGPointMake(100, 150);
    float r4 = 2;
    CGPoint p5 = CGPointMake(245, 333);
    float r5 = 1;
    
    ZZLineRpoint *rp12 = [self getVectorFangentR1:r1 r2:r2 p1:p1 p2:p2];
    [self drawRPoint:rp12];
    ZZLineRpoint *rp23 = [self getVectorFangentR1:r2 r2:r3 p1:p2 p2:p3];
    [self drawRPoint:rp23];
    ZZLineRpoint *rp34 = [self getVectorFangentR1:r3 r2:r4 p1:p3 p2:p4];
    [self drawRPoint:rp34];
    ZZLineRpoint *rp45 = [self getVectorFangentR1:r4 r2:r5 p1:p4 p2:p5];
    [self drawRPoint:rp45];
    
    UIBezierPath *bp1 = [[UIBezierPath alloc] init];
    [bp1 moveToPoint:rp12.lsP];
    [bp1 addLineToPoint:rp12.leP];
    [bp1 addLineToPoint:rp23.lsP];
    [bp1 addLineToPoint:rp23.leP];
    [bp1 addLineToPoint:rp34.lsP];
    [bp1 addLineToPoint:p4];
    [bp1 addLineToPoint:p5];

    [bp1 addLineToPoint:rp45.rsP];
    [bp1 addLineToPoint:rp34.reP];
    [bp1 addLineToPoint:p3];
    [bp1 addLineToPoint:p2];
    [bp1 addLineToPoint:rp12.rsP];
    [[UIColor greenColor] set];
    [bp1 stroke];
    
    NotePath *np1 = [[NotePath alloc] init];
    NSMutableArray * np1Pahts = [[NSMutableArray alloc] init];
    [np1Pahts addObject:[NSValue valueWithCGPoint:rp12.lsP]];
    [np1Pahts addObject:[NSValue valueWithCGPoint:rp12.leP]];
    [np1Pahts addObject:[NSValue valueWithCGPoint:rp23.lsP]];
    [np1Pahts addObject:[NSValue valueWithCGPoint:rp23.leP]];
    [np1Pahts addObject:[NSValue valueWithCGPoint:rp34.lsP]];
    [np1Pahts addObject:[NSValue valueWithCGPoint:p4]];
    [np1Pahts addObject:[NSValue valueWithCGPoint:p5]];
    np1.pathPoints = np1Pahts;
    [np1 drawBezierPathLine];
    
    NotePath *np2 = [[NotePath alloc] init];
    NSMutableArray * np2Pahts = [[NSMutableArray alloc] init];
    [np2Pahts addObject:[NSValue valueWithCGPoint:rp12.rsP]];
    [np2Pahts addObject:[NSValue valueWithCGPoint:p2]];
    [np2Pahts addObject:[NSValue valueWithCGPoint:p3]];
    [np2Pahts addObject:[NSValue valueWithCGPoint:rp34.reP]];
    [np2Pahts addObject:[NSValue valueWithCGPoint:rp45.rsP]];
    [np2Pahts addObject:[NSValue valueWithCGPoint:p5]];
    np2.pathPoints = np2Pahts;
    [np2 drawBezierPathLine];
}
-(void)drawRPoint:(ZZLineRpoint *)rp{
    [self drawPoint:rp.lsP];
    [self drawPoint:rp.leP];
    [self drawPoint:rp.rsP];
    [self drawPoint:rp.reP];
}
-(void)drawPoint:(CGPoint )point{
    UIBezierPath *path = [[UIBezierPath alloc] init];
    path.lineWidth = 2;
    [[UIColor redColor] set];
    [path moveToPoint:point];
    [path addLineToPoint:CGPointMake(point.x+0.5, point.y+0.5)];
    [path stroke];
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
    NSLog(@"切线右手向量：%@",@(vector12_q));
    float vector12_q_r = vector12_q + 90;
    NSLog(@"切线右手半径向量：%@",@(vector12_q_r));
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
    NSLog(@"切线左手向量：%@",@(vector12_q));
    float vector12_q_r = vector12_q - 90;
    NSLog(@"切线左手半径向量：%@",@(vector12_q_r));
    return vector12_q_r;
}

//余弦值 求夹角
-(float)getInAngle:(float)edge string:(float) string{
    double angle  = acos(edge/string);
    double degree = RadianToDegrees(angle);
    NSLog(@"夹角：%@",@(degree));
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


