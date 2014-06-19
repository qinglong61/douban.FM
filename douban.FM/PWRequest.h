//
//  PWRequest.h
//  testlib
//
//  Created by qinglun.duan on 13-4-3.
//  Copyright (c) 2013年 laohu.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class PWRequest;

@protocol PWRequestDelegate <NSObject>
@optional
- (void)request:(PWRequest *)request didReceiveResponse:(NSURLResponse *)response;
- (void)request:(PWRequest *)request didReceiveRawData:(NSData *)data;
- (void)request:(PWRequest *)request didFailWithError:(NSError *)error;
- (void)request:(PWRequest *)request didFinishLoadingWithResult:(id)result;
@end

@interface PWRequest : NSObject
{
    NSString                        *url;
    NSString                        *httpMethod;
    NSDictionary                    *params;
    
    NSURLConnection                 *connection;
    NSMutableData                   *responseData;
    
    id<PWRequestDelegate>    delegate;
}

@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *httpMethod;
@property (nonatomic, retain) NSDictionary *params;
@property (nonatomic, assign) id<PWRequestDelegate> delegate;

+ (PWRequest *)requestWithURL:(NSString *)url
                          httpMethod:(NSString *)httpMethod
                              params:(NSDictionary *)params
                            delegate:(id<PWRequestDelegate>)delegate;

+ (id)syncRequestWithURL:(NSString *)url
                    httpMethod:(NSString *)httpMethod
                        params:(NSDictionary *)params;
+ (id)syncRequestWithURL:(NSString *)_url
              httpMethod:(NSString *)_httpMethod
                  params:(NSDictionary *)_params
         timeoutInterval:(NSTimeInterval)timeoutInterval;

+ (NSString *)getParamValueFromUrl:(NSString*)url paramName:(NSString *)paramName;
+ (NSString *)serializeURL:(NSString *)baseURL params:(NSDictionary *)params httpMethod:(NSString *)httpMethod;

- (void)connect;
- (void)disconnect;

@end
