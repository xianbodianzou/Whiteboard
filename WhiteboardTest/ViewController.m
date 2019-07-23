//
//  ViewController.m
//  WhiteboardTest
//
//  Created by shgbit on 2019/7/16.
//  Copyright © 2019 shgbit. All rights reserved.
//

#import "ViewController.h"
#import "WhiteboardView.h"
#import "WhiteboardCurrentView.h"
#import "NotePath.h"

@interface ViewController ()
@property(nonatomic,strong) WhiteboardView *board;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    WhiteboardView *wv = [[WhiteboardView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:wv];
    [self.view sendSubviewToBack:wv];
    
    self.board = wv;
//    NSValue *v1 =  [NSValue valueWithCGPoint: CGPointMake(1, 3)];
//    NSValue *v2 =  [NSValue valueWithCGPoint: CGPointMake(2, 1)];
//    NSValue *v3 =  [NSValue valueWithCGPoint: CGPointMake(3, 2)];
//    NSValue *v4 =  [NSValue valueWithCGPoint: CGPointMake(5, 3)];
//    
//    NSValue *interp =   [self intersectionWithPoint1:v1 point2:v2 point3:v3 point4:v4];
//    
//    NSLog(@"相交点：%@",interp);
}

- (IBAction)presentClick:(id)sender {
    
    
}
- (IBAction)modeChangeAction:(UISegmentedControl *)sender {
    if(sender.selectedSegmentIndex==0){
        self.board.currentMode = WhiteboardMode_draw;
    }
    else{
        self.board.currentMode = WhiteboardMode_erase;
    }
    
}
- (IBAction)backAction:(id)sender {
    [self.board back];
}
- (IBAction)forwardAction:(id)sender {
    [self.board forword];
}

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

@end