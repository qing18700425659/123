//
//  ViewController.m
//  BBG_HTTP_Demo
//
//  Created by 大鹏 on 16/8/2.
//  Copyright © 2016年 dongchen. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"
#import "BBGManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[[BBGManager alloc]init] getAdvListByType:@1 zone_id:@1];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
