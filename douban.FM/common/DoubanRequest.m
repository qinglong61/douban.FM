//
//  DoubanRequest.m
//  douban.FM
//
//  Created by qinglun.duan on 14-6-9.
//  Copyright (c) 2014年 duan.qinglun. All rights reserved.
//

#import "DoubanRequest.h"
#import <Cocoa/Cocoa.h>

#define kDoubanRequestTimeOutInterval   180.0
#define kDoubanRequestStringBoundary    @"DoubanRequestStringBoundary"
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

@interface DoubanRequest (Private)

- (void)appendUTF8Body:(NSMutableData *)body dataString:(NSString *)dataString;
- (NSMutableData *)postBodyHasRawData:(BOOL*)hasRawData;

- (void)handleResponseData:(NSData *)data;
- (void)failedWithError:(NSError *)error;

@end

@implementation DoubanRequest

@synthesize url;
@synthesize httpMethod;
@synthesize params;
@synthesize delegate;

#pragma mark - DoubanRequest Life Circle

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

#pragma mark - DoubanRequest Private Methods

- (void)appendUTF8Body:(NSMutableData *)body dataString:(NSString *)dataString
{
    [body appendData:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSMutableData *)postBodyHasRawData:(BOOL*)hasRawData
{
    NSString *bodyPrefixString = [NSString stringWithFormat:@"--%@\r\n", kDoubanRequestStringBoundary];
    NSString *bodySuffixString = [NSString stringWithFormat:@"\r\n--%@--\r\n", kDoubanRequestStringBoundary];
    
    NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
    
    NSMutableData *body = [NSMutableData data];
    [self appendUTF8Body:body dataString:bodyPrefixString];
    
    for (id key in [params keyEnumerator])
    {
        if (([[params valueForKey:key] isKindOfClass:[NSImage class]]) || ([[params valueForKey:key] isKindOfClass:[NSData class]]))
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
            
            if ([dataParam isKindOfClass:[NSImage class]])
            {
                NSData *imageData = [(NSImage *)dataParam TIFFRepresentation];
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
    if ([delegate respondsToSelector:@selector(request:didReceiveRawData:)]) {
        [delegate request:self didReceiveRawData:data];
    }
	
	NSError *error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
	
    if (!result) {
        result = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    }
    
	if (!data) {
		[self failedWithError:error];
	} else {
        if ([delegate respondsToSelector:@selector(request:didFinishLoadingWithResult:)]) {
            [delegate request:self didFinishLoadingWithResult:(result == nil ? data : result)];
        }
	}
}

- (void)failedWithError:(NSError *)error
{
	if ([delegate respondsToSelector:@selector(request:didFailWithError:)])
	{
		[delegate request:self didFailWithError:error];
	}
}

#pragma mark - DoubanRequest Public Methods

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
        if (([[params objectForKey:key] isKindOfClass:[NSImage class]])
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

+ (DoubanRequest *)requestWithURL:(NSString *)url
                   httpMethod:(NSString *)httpMethod
                       params:(NSDictionary *)params
                     delegate:(id<DoubanRequestDelegate>)delegate
{
    DoubanRequest *request = [[[DoubanRequest alloc] init] autorelease];
    
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
    return [DoubanRequest syncRequestWithURL:_url httpMethod:_httpMethod params:_params timeoutInterval:kDoubanRequestTimeOutInterval];
}

+ (id)syncRequestWithURL:(NSString *)_url
              httpMethod:(NSString *)_httpMethod
                  params:(NSDictionary *)_params
         timeoutInterval:(NSTimeInterval)timeoutInterval
{
    DoubanRequest *_request = [[[DoubanRequest alloc] init] autorelease];
    
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
                                     stringWithFormat:@"multipart/form-data; boundary=%@", kDoubanRequestStringBoundary];
            [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        }
    }
    
    NSError *err = nil;
    NSData *respData = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&err];
    if (err){
        return nil;
    }else{
        id result = [NSJSONSerialization JSONObjectWithData:respData options:NSJSONReadingMutableContainers error:&err];
        if (!err) {
            return result;
        }
        NSString *resultStr = [[[NSString alloc] initWithData:respData encoding:NSUTF8StringEncoding] autorelease];
        //        DLog(@"resultStr = %@", resultStr);
        return resultStr;
    }
}

+ (id)syncRequestWithRequest:(NSURLRequest *)request
{
    NSError *err = nil;
    NSData *respData = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&err];
    if (err){
        return nil;
    }else{
        id result = [NSJSONSerialization JSONObjectWithData:respData options:NSJSONReadingMutableContainers error:&err];
        if (!err) {
            return result;
        }
        NSString *resultStr = [[[NSString alloc] initWithData:respData encoding:NSUTF8StringEncoding] autorelease];
        //        DLog(@"resultStr = %@", resultStr);
        return resultStr;
    }
}

- (void)connect
{
    NSString* urlString = [[self class] serializeURL:url params:params httpMethod:httpMethod];
    //        DLog(@"%@",urlString);
    NSMutableURLRequest* request =
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                        timeoutInterval:kDoubanRequestTimeOutInterval];
    
    [request setHTTPMethod:self.httpMethod];
    if ([self.httpMethod isEqualToString: @"POST"])
    {
        BOOL hasRawData = NO;
        [request setHTTPBody:[self postBodyHasRawData:&hasRawData]];
        
        if (hasRawData)
        {
            NSString* contentType = [NSString
                                     stringWithFormat:@"multipart/form-data; boundary=%@", kDoubanRequestStringBoundary];
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