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
        self.operHis = [[NSMutableArray alloc] init];
        self.operUndo = [[NSMutableArray alloc] init];
        self.dicPaths = [[NSMutableDictionary alloc] init];
        self.addIds = [[NSMutableArray alloc] init];
        self.eraseIds = [[NSMutableArray alloc] init];
        self.currentLineWidth = 1.0;
        self.currentLineColor = [UIColor blackColor];
        [self customInit];
    }
    return self;
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
-(void)customInit{
    self.mode = WhiteboardMode_draw;
    self.wcv = [[WhiteboardCurrentView alloc] init];
    self.wcv.delegate = self;
    self.wcv.backgroundColor = [UIColor clearColor];
    self.wcv.mode = WhiteboardMode_draw;
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.wcv];
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

#pragma mark =================WhiteboardCurrentViewDelegate================
-(void)compeleteFullPathStrokes:(NotePath *)path{
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

#pragma mark =================getters setters================
-(NSMutableArray *)notePaths{
    if(!_notePaths){
        _notePaths = [[NSMutableArray alloc] init];
    }
    return _notePaths;
}

-(void)setMode:(WhiteboardMode)mode{
    _mode = mode;
    if(self.wcv){
        self.wcv.mode = mode;
    }
}

@end
