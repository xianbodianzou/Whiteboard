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
        else if(f.oper == WhiteboardOperate_eraseAll){
            [self.eraseIds addObjectsFromArray:f.lineIds];
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
        else if(f.oper == WhiteboardOperate_eraseAll){
            [self.eraseIds removeObjectsInArray:f.lineIds];
        }
        [self generateAvailablePaths];
        [self setNeedsDisplay];
    }
}

-(void)eraseAll{
    NSArray *arr =  [self getALLAvailablePathIds];
    if(arr.count){
        NotePathOper *oper = [[NotePathOper alloc] init];
        oper.oper = WhiteboardOperate_eraseAll;
        oper.lineIds = arr;
        
        [self.eraseIds addObjectsFromArray: arr];
        [self.operHis addObject: oper];
        [self.operUndo removeAllObjects];
        
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
    self.currentLineWidth = 4.0;
    self.currentLineColor = [UIColor blackColor];
    self.currentLineType = NoteLineType_straight;
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

//获取所有有效pathid
-(NSArray *)getALLAvailablePathIds{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (NSString *lineid in self.addIds) {
        //排除被擦除的
        if(![self.eraseIds containsObject:lineid]){
            NotePath *path = [self.dicPaths objectForKey:lineid];
            if(path){
                [arr addObject:path.lineId];
            }
        }
    }
    return [arr copy];
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

//获取密集擦除点
-(NSArray *)getCorErasePoints:(NSArray *)oldPoints{
    NSMutableArray *tmp = [[NSMutableArray alloc] init];
    if(oldPoints.count>1){
        for (int i=0; i<oldPoints.count-1; i++) {
            CGPoint p1 = ((NSValue *)oldPoints[i]).CGPointValue;
            CGPoint p2 = ((NSValue *)oldPoints[i+1]).CGPointValue;
            float dis =  [self getDisP1:p1 p2:p2];
            float angle =  [self comAngle: [self getvectorP1:p1 p2:p2]];
            int dengfeng = ceil(dis/1);
            for (int j=0; j<dengfeng; j++) {
                float r = j*dis/dengfeng;
                CGPoint pd = [self getPoint:p1 vector:angle r:r];
                [tmp addObject: [NSValue valueWithCGPoint:pd]];
            }
        }
    }
    NSLog(@"___%@",tmp);
    return [tmp copy];
}


#pragma mark =================WhiteboardCurrentViewDelegate================
-(void)compeleteFullPathStrokes:(NotePath *)path{
    [self randomTest];
    
    [self addNotepath:path];//加入笔画
    [self.operUndo removeAllObjects];//回撤笔画清除
    [self setNeedsDisplay];
}

-(void)earsePoint:(NSArray *)points{
    if(!self.notePaths) return;

    //找出删除的线
    NotePath *erasePath;
    
    NSArray *newErasePoints = [self getCorErasePoints:points];
    
    for (NotePath *notepath in self.notePaths) {
        for (NSValue *dpv in newErasePoints) {
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


#pragma mark =================几何算法================

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

//根据起始点，向量，距离 取得 坐标
-(CGPoint)getPoint:(CGPoint) p vector:(float)vector r:(float)r{
    float x = r*cosf(DegreesToRadian(vector))+p.x;
    float y = r*sinf(DegreesToRadian(vector))+p.y;
    CGPoint pp = CGPointMake(x, y) ;
    //    NSLog(@"切点：%@",NSStringFromCGPoint(pp));
    return pp;
}
@end


