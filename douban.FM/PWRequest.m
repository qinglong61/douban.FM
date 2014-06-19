//
//  PWRequest.m
//  testlib
//
//  Created by qinglun.duan on 13-4-3.
//  Copyright (c) 2013年 laohu.com. All rights reserved.
//

#import "PWRequest.h"
#import "WMJSONKit.h"

#define kPWRequestTimeOutInterval   180.0
#define kPWRequestStringBoundary    @"293iosfksdfkiowjksdf31jsiuwq003s02dsaffafass3qw"
#define kPWSDKErrorDomain           @"PWSDKErrorDomain"

typedef enum {
	kPWSDKErrorCodeParseError       = 200,      //解析错误
	kPWSDKErrorCodeParamsError      = 201,      //参数错误
} PWSDKErrorCode;

@interface NSString (PWEncode)
- (NSString *)URLEncodedString;

@end

@implementation NSString (PWEncode)

- (NSString *)URLEncodedStringWithCFStringEncoding:(CFStringEncoding)encoding
{
    return [(NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[[self mutableCopy] autorelease], NULL, CFSTR("￼=,!$&'()*+;@?\n\"<>#\t :/"), encoding) autorelease];
}

- (NSString *)URLEncodedString
{
	return [self URLEncodedStringWithCFStringEncoding:kCFStringEncodingUTF8];
}

@end

@interface PWRequest (Private)

- (void)appendUTF8Body:(NSMutableData *)body dataString:(NSString *)dataString;
- (NSMutableData *)postBodyHasRawData:(BOOL*)hasRawData;

- (void)handleResponseData:(NSData *)data;
- (id)parseJSONData:(NSData *)data error:(NSError **)error;

- (id)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo;
- (void)failedWithError:(NSError *)error;

@end

@implementation PWRequest

@synthesize url;
@synthesize httpMethod;
@synthesize params;
@synthesize delegate;

#pragma mark - PWRequest Life Circle

- (void)dealloc
{   
    [url release], url = nil;
    [httpMethod release], httpMethod = nil;
    [params release], params = nil;
    
    [responseData release];
	responseData = nil;
    
    [connection cancel];
    [connection release], connection = nil;
    
    [super dealloc];
}

#pragma mark - PWRequest Private Methods

- (void)appendUTF8Body:(NSMutableData *)body dataString:(NSString *)dataString
{
    [body appendData:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSMutableData *)postBodyHasRawData:(BOOL*)hasRawData
{
    NSString *bodyPrefixString = [NSString stringWithFormat:@"--%@\r\n", kPWRequestStringBoundary];
    NSString *bodySuffixString = [NSString stringWithFormat:@"\r\n--%@--\r\n", kPWRequestStringBoundary];
    
    NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
    
    NSMutableData *body = [NSMutableData data];
    [self appendUTF8Body:body dataString:bodyPrefixString];
    
    for (id key in [params keyEnumerator])
    {
        if (([[params valueForKey:key] isKindOfClass:[UIImage class]]) || ([[params valueForKey:key] isKindOfClass:[NSData class]]))
        {
            [dataDictionary setObject:[params valueForKey:key] forKey:key];
            continue;
        }
        
        [self appendUTF8Body:body dataString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n", key, [params valueForKey:key]]];
        [self appendUTF8Body:body dataString:bodyPrefixString];
    }
    
    if ([dataDictionary count] > 0)
    {
        *hasRawData = YES;
        for (id key in dataDictionary)
        {
            NSObject *dataParam = [dataDictionary valueForKey:key];
            
            if ([dataParam isKindOfClass:[UIImage class]])
            {
                NSData* imageData = UIImagePNGRepresentation((UIImage *)dataParam);
                [self appendUTF8Body:body dataString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"file\"\r\n", key]];
                [self appendUTF8Body:body dataString:@"Content-Type: image/png\r\nContent-Transfer-Encoding: binary\r\n\r\n"];
                [body appendData:imageData];
            }
            else if ([dataParam isKindOfClass:[NSData class]])
            {
                [self appendUTF8Body:body dataString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"file\"\r\n", key]];
                [self appendUTF8Body:body dataString:@"Content-Type: content/unknown\r\nContent-Transfer-Encoding: binary\r\n\r\n"];
                [body appendData:(NSData*)dataParam];
            }
            [self appendUTF8Body:body dataString:bodySuffixString];
        }
    }
    
    return body;
}

- (void)handleResponseData:(NSData *)data
{
    if ([delegate respondsToSelector:@selector(request:didReceiveRawData:)])
    {
        [delegate request:self didReceiveRawData:data];
    }
	
	NSError *error = nil;
    
	id result = [self parseJSONData:data error:&error];
	
    if (!result) {
        DLog(@"resultStr = %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
    }
    
	if (error)
	{
		[self failedWithError:error];
	}
	else
	{
        NSInteger error_code = 0;
        if([result isKindOfClass:[NSDictionary class]])
        {
            error_code = [[result objectForKey:@"code"] intValue];
        }

        if (error_code != 0)
        {
            NSString *error_description = [result objectForKey:@"msg"];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      result, @"error",
                                      error_description, NSLocalizedDescriptionKey, nil];
            NSError *error = [NSError errorWithDomain:kPWSDKErrorDomain
                                                 code:[[result objectForKey:@"code"] intValue]
                                             userInfo:userInfo];
            
            if (error_code == 1     //失败
                || error_code == 10001  //appId不存在
                || error_code == 10002  //用户不存在
                || error_code == 10003  //请求超时【时间戳误差超过30分钟】
                || error_code == 10004  //token失效
                || error_code == 10005  //签名失败
                || error_code == 10006  //格式错误,包括为空的情况
                || error_code == 10007  //图像大小错误
                || error_code == 10008  //邮箱或者手机号已经存在
                || error_code == 10009  //旧密码错误
                || error_code == 10010) //临时用户不存在
            {
                if ([delegate respondsToSelector:@selector(request:didFinishLoadingWithResult:)])
                {
                    [delegate request:self didFinishLoadingWithResult:(result == nil ? data : result)];
                }
            }
            else
            {
                [self failedWithError:error];
            }
        }
        else
        {
            if ([delegate respondsToSelector:@selector(request:didFinishLoadingWithResult:)])
            {
                [delegate request:self didFinishLoadingWithResult:(result == nil ? data : result)];
            }
        }
	}
}

- (id)parseJSONData:(NSData *)data error:(NSError **)error
{
    NSError *parseError = nil;
    
    id result = [data objectFromJSONDataWithParseOptions:WMJKParseOptionStrict error:&parseError];
	
	if (parseError && (error != nil))
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  parseError, @"error",
                                  @"Data parse error", NSLocalizedDescriptionKey, nil];
        *error = [self errorWithCode:kPWSDKErrorCodeParseError
                            userInfo:userInfo];
	}
	
	return result;
}

- (id)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
    return [NSError errorWithDomain:kPWSDKErrorDomain code:code userInfo:userInfo];
}

- (void)failedWithError:(NSError *)error
{
	if ([delegate respondsToSelector:@selector(request:didFailWithError:)])
	{
		[delegate request:self didFailWithError:error];
	}
}

#pragma mark - PWRequest Public Methods

+ (NSString *)getParamValueFromUrl:(NSString*)url paramName:(NSString *)paramName
{
    if (![paramName hasSuffix:@"="])
    {
        paramName = [NSString stringWithFormat:@"%@=", paramName];
    }
    
    NSString * str = nil;
    NSRange start = [url rangeOfString:paramName];
    if (start.location != NSNotFound)
    {
        // confirm that the parameter is not a partial name match
        unichar c = '?';
        if (start.location != 0)
        {
            c = [url characterAtIndex:start.location - 1];
        }
        if (c == '?' || c == '&' || c == '#')
        {
            NSRange end = [[url substringFromIndex:start.location+start.length] rangeOfString:@"&"];
            NSUInteger offset = start.location+start.length;
            str = end.location == NSNotFound ?
            [url substringFromIndex:offset] :
            [url substringWithRange:NSMakeRange(offset, end.location)];
            str = [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }
    return str;
}

+ (NSString *)serializeURL:(NSString *)baseURL params:(NSDictionary *)params httpMethod:(NSString *)httpMethod
{
    NSURL* parsedURL = [NSURL URLWithString:baseURL];
    NSString* queryPrefix = parsedURL.query ? @"&" : @"?";
    
    NSMutableArray* pairs = [NSMutableArray array];
    for (NSString* key in [params keyEnumerator])
    {
        if (([[params objectForKey:key] isKindOfClass:[UIImage class]])
            ||([[params objectForKey:key] isKindOfClass:[NSData class]]))
        {
            if ([httpMethod isEqualToString:@"GET"])
            {
//                DLog(@"can not use GET to upload a file");
            }
            continue;
        }
        
        NSString* escaped_value = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                      NULL, /* allocator */
                                                                                      (CFStringRef)[params objectForKey:key],
                                                                                      NULL, /* charactersToLeaveUnescaped */
                                                                                      (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                      kCFStringEncodingUTF8);
        
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
        [escaped_value release];
    }
    NSString* query = [pairs componentsJoinedByString:@"&"];
    
    return [NSString stringWithFormat:@"%@%@%@", baseURL, queryPrefix, query];
}

+ (PWRequest *)requestWithURL:(NSString *)url
                          httpMethod:(NSString *)httpMethod
                              params:(NSDictionary *)params
                            delegate:(id<PWRequestDelegate>)delegate
{
    PWRequest *request = [[[PWRequest alloc] init] autorelease];
    
    request.url = url;
    request.httpMethod = httpMethod;
    request.params = params;
    request.delegate = delegate;
    
    return request;
}

+ (id)syncRequestWithURL:(NSString *)_url
              httpMethod:(NSString *)_httpMethod
                  params:(NSDictionary *)_params
{
    return [PWRequest syncRequestWithURL:_url httpMethod:_httpMethod params:_params timeoutInterval:kPWRequestTimeOutInterval];
}

+ (id)syncRequestWithURL:(NSString *)_url
                   httpMethod:(NSString *)_httpMethod
                       params:(NSDictionary *)_params
              timeoutInterval:(NSTimeInterval)timeoutInterval
{
    PWRequest *_request = [[[PWRequest alloc] init] autorelease];
    
    NSString* urlString = [[self class] serializeURL:_url params:_params httpMethod:_httpMethod];
//    DLog(@"%@",urlString);
    NSMutableURLRequest* request =
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                        timeoutInterval:timeoutInterval];
    
    [request setHTTPMethod:_httpMethod];
    if ([_httpMethod isEqualToString: @"POST"])
    {
        BOOL hasRawData = NO;
        [request setHTTPBody:[_request postBodyHasRawData:&hasRawData]];
        
        if (hasRawData)
        {
            NSString* contentType = [NSString
                                     stringWithFormat:@"multipart/form-data; boundary=%@", kPWRequestStringBoundary];
            [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        }
    }
    
    NSError *err = nil;
    NSData *respData = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&err];
    if (err){
        return nil;
    }else{
        id result = [_request parseJSONData:respData error:&err];
        
        if (err) {
            return respData;
        } else {
            if (!result) {
                NSString *resultStr = [[[NSString alloc] initWithData:respData encoding:NSUTF8StringEncoding] autorelease];
//                DLog(@"resultStr = %@", resultStr);
                return resultStr;
            } else {
                return result;
            }
        }
    }
}

- (void)connect
{
    NSString* urlString = [[self class] serializeURL:url params:params httpMethod:httpMethod];
//        DLog(@"%@",urlString);
    NSMutableURLRequest* request =
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                        timeoutInterval:kPWRequestTimeOutInterval];
    
    [request setHTTPMethod:self.httpMethod];
    if ([self.httpMethod isEqualToString: @"POST"])
    {
        BOOL hasRawData = NO;
        [request setHTTPBody:[self postBodyHasRawData:&hasRawData]];
        
        if (hasRawData)
        {
            NSString* contentType = [NSString
                                     stringWithFormat:@"multipart/form-data; boundary=%@", kPWRequestStringBoundary];
            [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        }
    }
    
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (void)disconnect
{
    [responseData release];
	responseData = nil;
    
    [connection cancel];
    [connection release], connection = nil;
}

#pragma mark - NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	responseData = [[NSMutableData alloc] init];
	
	if ([delegate respondsToSelector:@selector(request:didReceiveResponse:)])
    {
		[delegate request:self didReceiveResponse:response];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
				  willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
	return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection
{
	[self handleResponseData:responseData];
    
	[responseData release];
	responseData = nil;
    
    [connection cancel];
	[connection release];
	connection = nil;
}

- (void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)error
{
	[self failedWithError:error];
	
	[responseData release];
	responseData = nil;
    
    [connection cancel];
	[connection release];
	connection = nil;
}

@end
