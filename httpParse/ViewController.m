//
//  ViewController.m
//  httpParse
//
//  Created by LuoYao on 2017/7/11.
//  Copyright © 2017年 he8090. All rights reserved.
//

#import "ViewController.h"
#import "TFHpple.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *rssiStr = nil;
    
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"RSSI" ofType:@"html"];
    NSData *htmlData = [NSData dataWithContentsOfFile:htmlPath];
    
    TFHpple *doc = [[TFHpple alloc] initWithHTMLData:htmlData];
    NSArray *elements = [doc searchWithXPathQuery:@"//fieldset[@class='cbi-section']"];
    
    
//    TFHppleElement *element = elements[2];
//    
//    NSArray *els = [element children];
//    TFHppleElement *el = els[3];
//    
//    NSArray *es = [el children];
//    
//    TFHppleElement *e = es[9];
//    
//    NSArray *ls = [e children];
//    TFHppleElement *l = ls.lastObject;
//    
//     NSLog(@"html:%@",[l text]);
    
    
    for (TFHppleElement *elment in elements) {
        for (TFHppleElement *el in [elment children]) {
            
            NSArray *els =  [el searchWithXPathQuery:@"//table"];
            for (TFHppleElement *e in els) {
                for (TFHppleElement *table in [e children]) {
                    
                    NSArray *tables = [table children];
                    for (TFHppleElement *tr in tables) {

                        if ([[tr text] isEqualToString:@"RSSI"]) {
                            NSUInteger index = [tables indexOfObject:tr];
                            
                            TFHppleElement *rssi = tables[index + 1];
                            rssiStr = [NSString stringWithString:[rssi text]];
                        }
                    }
                }
            }
        }
    }
    
    NSLog(@"RSSI:%@",rssiStr);
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
