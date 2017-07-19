//
//  ViewController.m
//  httpParse
//
//  Created by LuoYao on 2017/7/11.
//  Copyright © 2017年 he8090. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"
#import "TFHpple.h"

#include <arpa/inet.h>
#include <netdb.h>
#include <net/if.h>
#include <ifaddrs.h>
#import <dlfcn.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self netWork];
    
    NSLog(@"localAddress:%@",[self localWiFiIPAddress]);
}


- (void)netWork{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //设置非校验证书模式
    manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    manager.securityPolicy.allowInvalidCertificates = YES;
    [manager.securityPolicy setValidatesDomainName:NO];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager GET:@"https://192.168.1.1/cgi-bin/luci?luci_username=root&luci_password=admin" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSString *html = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        if (html) {
            [self parseHtml:html];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error.description);
    }];
}

- (NSString *)parseHtml:(NSString *)htmlStr{
    
    NSString *rssiStr = nil;
    NSData *htmlData = [htmlStr dataUsingEncoding:NSUTF8StringEncoding];

    TFHpple *doc = [[TFHpple alloc] initWithHTMLData:htmlData];
    NSArray *elements = [doc searchWithXPathQuery:@"//fieldset[@class='cbi-section']"];
    
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
    NSLog(@"success:%@",[rssiStr stringByReplacingOccurrencesOfString:@"" withString:@" "]);
    return rssiStr;
}


//获取本地ip
- (NSString *) localWiFiIPAddress
{
    BOOL success;
    struct ifaddrs * addrs;
    const struct ifaddrs * cursor;
    success = getifaddrs(&addrs) == 0;
    if (success) {
        cursor = addrs;
        while (cursor != NULL) {
            // the second test keeps from picking up the loopback address
            if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0)
            {
                NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
                if ([name isEqualToString:@"en0"])  // Wi-Fi adapter
                    return [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    return nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
