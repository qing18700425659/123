

#import "BBGManager.h"
//#import "TabBarViewController.h"
//#import "RegisterViewController.h"
//#import "LoginViewController.h"
//#import "PublishViewController.h"

#import <CommonCrypto/CommonDigest.h>

//#import "NSString+md5Extend.h"
//#import "NSDictionary+Extension.h"
#import "AFNetworking.h"

#define pageSize 10

@implementation BBGManager



#pragma mark 单例
static id manager;
+ (id) shareManager{
    if (!manager) {
        manager = [[self alloc]init];
    }
    return manager;
}

#pragma mark 获取广告列表
- (void)getAdvListByType : (NSNumber *)type zone_id : (NSString *)zone_id{
//  e10adc3949ba59abbe56e057f20f883e
//    NSString *result = [BBGManager md5:@"123456"];
    
    
//    NSLog(@"%@",[result lowercaseString]);
    NSDictionary *dic;
    //增加设备唯一标识
    NSString *imei = @"abcdefg123456";
    
        dic = @{
                @"imei" : imei,
                @"state":@1,//1启用，0关闭
                @"curPage":@1,
                @"pageSize":@pageSize,
                @"type_id":type
                };
    NSString *url = @"http://172.16.3.237/broadcast/?action=adv&func=getAdvList";
    
//    dic.urlLinkParam
    
//    NSString *params = [NSString stringWithFormat:@"imei=%@&state=%@&curPage=%@&pageSize=%@&type_id=%@",imei,@1,@1,@pageSize,type];
//    NSLog(@"手动的：%@",params);
    
    NSString *params = [self urlWithDict:dic];
//    NSLog(@"自动的：%@",params);
    
    //追加签名
    NSString *bobao_token = [self getBobao_tokenWithParams:params url:url];
    NSMutableDictionary *muDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    
    //在签名前，不要将SPM与Bobao_token列入参数范围
    [muDic addEntriesFromDictionary:@{@"spm":self.getSPM,@"bobao_token":bobao_token}];
    
     NSLog(@"%@&%@&spm=%@&bobao_token=%@",url,params,[muDic valueForKey:@"spm"],[muDic valueForKey:@"bobao_token"]);
    
     AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:url parameters:muDic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        self.response = responseObject;
        if ([responseObject[@"code"] isEqualToNumber:@1]){
            if ([type intValue] == 1) {
                [[NSNotificationCenter defaultCenter]postNotificationName:@"获取广告列表" object:responseObject[@"message"]];
            }
            else{
                [[NSNotificationCenter defaultCenter]postNotificationName:@"小喇叭广告" object:responseObject[@"message"]];
            }
        }
        else{
            NSLog(@"获取广告列表❌");
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"广告接口error: %@", error.localizedDescription);
        
    }];

    
}



#pragma mark - 播报哥🔐
#pragma mark 加密第一部分-spm
///播报哥签名！SPM = iPhone4S.1.7.0.1462946400.0
- (NSString *)getSPM
{
    //手机型号.版本号.用户ID.整点时间戳.是否校验用户真实性
    //    iPhone4S.1.7.0.1462946400.0
    //时间戳 整点
    NSTimeInterval interVal = [[NSDate date] timeIntervalSince1970];
    NSString *time = [NSString stringWithFormat:@"%d",(int)interVal / 3600 * 3600];
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    
    //组合spm
    NSMutableString *spm = [NSMutableString string];
    //A.iOS source_id
    NSString *source_id = @"iPhone";
    [spm appendFormat:@"%@.",source_id];//iPhone5S.
    
    //B.版本号
    //    NSString *app_BundleVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    [spm appendFormat:@"%@",app_Version];//iPhone5S.1.7
    
    //C.用户id
    [spm appendFormat:@".%@",[self getUserID]];//iPhone5S.1.7.0
    //D.时间戳
    [spm appendFormat:@".%@",time];//iPhone5S.1.7.0.1462946400
    //E.1为检测用户 0不
    [spm appendString:@".0"];//iPhone5S.1.7.0.1462946400.0
    return spm;
}



#pragma mark 加密第二部分-产品签名
/**
 * 签名生成BobaoToken 
 * 整点时间戳 15:06 -> 15:00
 * @param params 签名需要将所有请求参数都传入 a.php?clientVersion='v1.0'&b=123
 * @param url 签名的网址完成的请求网址
 */
- (NSString *)getBobao_tokenWithParams : (NSString *)params  url:(NSString *)url{
    //时间戳 整点
    NSTimeInterval interVal = [[NSDate date] timeIntervalSince1970];
    NSString *time = [NSString stringWithFormat:@"%d",(int)interVal / 3600 * 3600];
    //A.iOS source_id
    NSString *source_id = @"iPhone";
    // 加密的第二部分
    //bobao_token：产品签名
    NSString *BBGKey = @"bobaogeHongHe3V1drzrT1";
    
    //参数为空
    if ([params isEqualToString:@""]) {
        //拼接完整url
        url = [NSString stringWithFormat:@"%@&sourceID=%@&time=%@&token_key=%@",
               url, source_id, time, BBGKey ];
    }else{
        //拼接完整url
        url = [NSString stringWithFormat:@"%@&%@&sourceID=%@&time=%@&token_key=%@",
           url, params, source_id, time, BBGKey ];
    }
    
    //排序
    NSArray *subURL = [url componentsSeparatedByString:[NSString stringWithFormat:@"%@/?",@"http://172.16.3.237/broadcast"]];
    
    NSArray *subValue = [subURL[1] componentsSeparatedByString:@"&"];
    subValue = [subValue sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    
    //根据排序结果 获取所有value
    NSMutableArray *valueArray = [NSMutableArray array];
    for (int i = 0; i < [subValue count]; i++) {
        NSString *value = [subValue[i] componentsSeparatedByString:@"="][1];
        [valueArray addObject:value];
    }
    //拼接bobao_token
    NSMutableString *bobao_token = [NSMutableString string];
    for (int i = 0; i < [valueArray count]; i++) {
        [bobao_token appendString:[NSString stringWithFormat:@"%@",valueArray[i]]];
    }
    return [BBGManager md5:bobao_token];
}

#pragma mark - 公共方法
- (NSString *) getUserID
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *user = [userDefaults objectForKey:@"userInfo"];
    if (user ==nil) {
        return @"0";
    }
    return [user valueForKey:@"user_id"];
}

+ (NSString *) md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result );
    NSString *tempstr= [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
    return [tempstr lowercaseString];
}

/**
 * 将字典转成网络请求链接的形式
 *
 *
 */
- (NSString *)urlWithDict:(NSDictionary *)dict{
    //-------公共方法，将字典转成链接形式-------
    
    //取出所有的键或值，存入一个数组
    NSArray *keys = [dict allKeys];
    
//    [NSString stringWithFormat:@"%@=%@&%@=%@",
//     key[0],[dict valueForKey:key[0]],
//     key[1],[dict valueForKey:key[1]]
//     ];
    //-------????怎么将最后一个一个&去掉-------
    NSMutableString *string = [NSMutableString string];
    //用一个循环
    for (NSString *str in keys) {
    
        if ([str isEqualToString:[keys firstObject]]) {
            [string appendFormat:@"%@=%@",str,[dict valueForKey:str]];
        }else{
            [string appendFormat:@"&%@=%@",str,[dict valueForKey:str]];
        }
    }
    
    return string;
    
}



@end