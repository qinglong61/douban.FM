//
//  DoubanRequest.h
//  douban.FM
//
//  Created by qinglun.duan on 14-6-9.
//  Copyright (c) 2014年 duan.qinglun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DoubanRequest;

@protocol DoubanRequestDelegate <NSObject>
@optional
- (void)request:(DoubanRequest *)request didReceiveResponse:(NSURLResponse *)response;
- (void)request:(DoubanRequest *)request didReceiveRawData:(NSData *)data;
- (void)request:(DoubanRequest *)request didFailWithError:(NSError *)error;
- (void)request:(DoubanRequest *)request didFinishLoadingWithResult:(id)result;
@end

@interface DoubanRequest : NSObject
{
    NSString                        *url;
    NSString                        *httpMethod;
    NSDictionary                    *params;
    
    NSURLConnection                 *connection;
    NSMutableData                   *responseData;
    
    id<DoubanRequestDelegate>    delegate;
}

@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *httpMethod;
@property (nonatomic, retain) NSDictionary *params;
@property (nonatomic, assign) id<DoubanRequestDelegate> delegate;

+ (DoubanRequest *)requestWithURL:(NSString *)url
                   httpMethod:(NSString *)httpMethod
                       params:(NSDictionary *)params
                     delegate:(id<DoubanRequestDelegate>)delegate;

+ (id)syncRequestWithURL:(NSString *)url
              httpMethod:(NSString *)httpMethod
                  params:(NSDictionary *)params;
+ (id)syncRequestWithURL:(NSString *)_url
              httpMethod:(NSString *)_httpMethod
                  params:(NSDictionary *)_params
         timeoutInterval:(NSTimeInterval)timeoutInterval;
+ (id)syncRequestWithRequest:(NSURLRequest *)request;

+ (NSString *)getParamValueFromUrl:(NSString*)url paramName:(NSString *)paramName;
+ (NSString *)serializeURL:(NSString *)baseURL params:(NSDictionary *)params httpMethod:(NSString *)httpMethod;

- (void)connect;
- (void)disconnect;

@end