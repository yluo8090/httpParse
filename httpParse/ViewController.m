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
#import "Reachability.h"

#import <netdb.h>
#import <net/if.h>

#import <dlfcn.h>
#import <arpa/inet.h>
#import <netinet/in.h>
#import <ifaddrs.h>
#import "getgateway.h"

typedef NS_ENUM(NSUInteger, signalStatus) {
    signalGood = 1,
    signalNormal,
    signalBad,
    signalUnKnow,
};

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self netWork];
    
    NSLog(@"localAddress:%@",[self getGatewayIpForCurrentWiFi]);
    NSLog(@"isWifi:%@",[self checkNetworkState] ? @"YES" : @"NO");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)netWork{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    //设置非校验证书模式
    manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    manager.securityPolicy.allowInvalidCertificates = YES;
    [manager.securityPolicy setValidatesDomainName:NO];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    //@"https://192.168.1.1/cgi-bin/luci?luci_username=root&luci_password=admin"
    [manager GET:@"https://192.168.1.1/cgi-bin/luci?luci_username=root&luci_password=admin" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSString *html = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        if (html) {
            [self signalStatus:[self parseHtml:html]];
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


//信号强度返回
- (signalStatus)signalStatus:(NSString *)signal{
    signalStatus status;
    NSString *str1 = [signal stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSString *str2 = [str1 stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *signalStr = [str2 stringByReplacingOccurrencesOfString:@"dBm" withString:@""];
    
    NSInteger sig = [signalStr integerValue];
    
    if (sig >= -90 && sig <= -41) {
        status = signalGood;
    }else if (sig >= -105 && sig < -90 ){
        status = signalNormal;
    }else if (sig >= -120 && sig < -105){
        status = signalBad;
    }else{
        status = signalUnKnow;
    }
    
    NSLog(@"subsignal:%lu",(unsigned long)status);
    
    return status;
}





#pragma mark - tools
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

//获取网关
- (NSString *)getGatewayIpForCurrentWiFi {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        //*/
        while(temp_addr != NULL) {
            /*/
             int i=255;
             while((i--)>0)
             //*/
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    // Get NSString from C String //ifa_addr
                    //ifa->ifa_dstaddr is the broadcast address, which explains the "255's"
                    //                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)];
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    /*
                     //routerIP----192.168.1.255 广播地址
                     NSLog(@"broadcast address--%@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr)]);
                     //--192.168.1.106 本机地址
                     NSLog(@"local device ip--%@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]);
                     //--255.255.255.0 子网掩码地址
                     NSLog(@"netmask--%@",[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr)]);
                     //--en0 端口地址
                     NSLog(@"interface--%@",[NSString stringWithUTF8String:temp_addr->ifa_name]);
                     */
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    in_addr_t i = inet_addr([address cStringUsingEncoding:NSUTF8StringEncoding]);
    in_addr_t* x = &i;
    unsigned char *s = getdefaultgateway(x);
    NSString *ip=[NSString stringWithFormat:@"%d.%d.%d.%d",s[0],s[1],s[2],s[3]];
    free(s);
    return ip;
}

//是否连接wifi
- (BOOL)checkNetworkState{
    BOOL ret;
    struct ifaddrs * first_ifaddr, * current_ifaddr;
    NSMutableArray* activeInterfaceNames = [[NSMutableArray alloc] init];
    getifaddrs( &first_ifaddr );
    current_ifaddr = first_ifaddr;
    while( current_ifaddr!=NULL )
    {
        if( current_ifaddr->ifa_addr->sa_family==0x02 )
        {
            [activeInterfaceNames addObject:[NSString stringWithFormat:@"%s", current_ifaddr->ifa_name]];
        }
        current_ifaddr = current_ifaddr->ifa_next;
    }
    ret = [activeInterfaceNames containsObject:@"en0"] || [activeInterfaceNames containsObject:@"en1"];
    return ret;
}


@end
