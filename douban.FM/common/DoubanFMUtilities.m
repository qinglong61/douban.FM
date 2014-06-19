//
//  DoubanFMUtilities.m
//  douban.FM
//
//  Created by qinglun.duan on 14-3-26.
//  Copyright (c) 2014年 com.pwrd. All rights reserved.
//

#import "DoubanFMUtilities.h"
#import "FBEncryptorAES.h"
#import "Constants.h"

#define EncryptKey  @"@)!@!&*"

@implementation DoubanFMUtilities

+ (NSString *)storePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoy = [paths objectAtIndex:0];
	return [documentsDirectoy stringByAppendingPathComponent:STORE_FOLDER];
}

+ (void)setStorePath:(NSString *)path
{   
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	BOOL isDirectory = NO;
    BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
    if (exists && !isDirectory) {
        [NSException raise:@"FileExistsAtCachePath" format:@"Cannot create a directory for the cache at '%@', because a file already exists", path];
    } else if (!exists) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
        if (![fileManager fileExistsAtPath:path]) {
            [NSException raise:@"FailedToCreateCacheDirectory" format:@"Failed to create a directory for the cache at '%@'", path];
        }
    }
}

+ (id)readWithFileName:(NSString *)fileName
{
    NSString *storePath = [[DoubanFMUtilities storePath] stringByAppendingPathComponent:fileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:storePath]) {
        
        NSData *data = [NSData dataWithContentsOfFile:storePath];
        
        NSData *key = [EncryptKey dataUsingEncoding:NSUTF8StringEncoding];
        NSData *decryptedData =  [FBEncryptorAES decryptData:data key:key iv:nil];
        
        //解档
        return [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
    } else {
        return nil;
    }
}

+ (BOOL)write:(id)plist fileName:(NSString *)fileName
{    
    @autoreleasepool {
        NSString *storePath = [[DoubanFMUtilities storePath] stringByAppendingPathComponent:fileName];
        
        //归档
        NSData *originaldata = [NSKeyedArchiver archivedDataWithRootObject:plist];
        
        NSData *key = [EncryptKey dataUsingEncoding:NSUTF8StringEncoding];
        NSData *encryptData = [FBEncryptorAES encryptData:originaldata key:key iv:nil];
        
        return [encryptData writeToFile:storePath atomically:YES];
    }
}

+ (void)setCookieName:(NSString *)name value:(NSString *)value
{
    name = name?name:@"";
    value = value?value:@"";
    
    NSArray *keys = [NSArray arrayWithObjects:
                     //                     NSHTTPCookieDiscard, //(session-only)
                     //                     NSHTTPCookieSecure,
                     NSHTTPCookieDomain,
                     NSHTTPCookieExpires,
                     NSHTTPCookieName,
                     NSHTTPCookiePath,
                     NSHTTPCookieValue, nil];
    NSArray *objects = [NSArray arrayWithObjects:
                        //                        @"FALSE",
                        //                        @"FALSE",
                        @".douban.fm",
                        [[NSDate date] initWithTimeIntervalSinceNow:60*60*24*365],
                        name,
                        @"/",
                        value, nil];
    NSDictionary *properties = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    NSHTTPCookie *cookie = [[[NSHTTPCookie alloc] initWithProperties:properties] autorelease];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
}

+ (NSString *)encodeURL:(NSString *)urlString
{
    return [(NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[[urlString mutableCopy] autorelease], NULL, CFSTR("￼!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8) autorelease];
}

@end