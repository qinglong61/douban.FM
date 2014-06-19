//
//  DoubanBaseModel.m
//  douban.FM
//
//  Created by qinglun.duan on 14-3-27.
//  Copyright (c) 2014年 com.pwrd. All rights reserved.
//

#import "DoubanBaseModel.h"
#import <objc/runtime.h>

@implementation DoubanBaseModel

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        for (NSString *key in [dictionary allKeys]) {
            SEL setFunction = [self setterFromString:key];
            if ([self respondsToSelector:setFunction]) {
                id value = [dictionary objectForKey:key];
                if ([value isEqual:[NSNull null]]) {
                    value = nil;
                }
                [self performSelector:setFunction withObject:value];
            }
        }
    }
    return self;
}

- (NSDictionary *)dictionaryValue
{
    NSMutableDictionary *dic = [[[NSMutableDictionary alloc] init] autorelease];
    [self enumeratePropertiesUsingBlock:^(id value, NSString *propertyName) {
        if (!value) {
            value = [NSNull null];
        }
        [dic setObject:value forKey:propertyName];
    }];
    return dic;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    [self enumeratePropertiesUsingBlock:^(id value, NSString *propertyName) {
        
        objc_property_t property = class_getProperty([self class], [propertyName UTF8String]);
        const char *attributes = property_getAttributes(property);
        NSString *propertyAttributes = [NSString stringWithUTF8String:attributes];
        
        NSString *type = [self getTypeFromAttributes:propertyAttributes];
        
        if ([type isEqualToString:@"BOOL"]) {
            [encoder encodeBool:[value boolValue] forKey:propertyName];
        } else if ([type isEqualToString:@"NSUInteger"]) {
            [encoder encodeInteger:[value unsignedIntegerValue] forKey:propertyName];
        } else if ([type isEqualToString:@"NSObject"]) {
            [encoder encodeObject:value forKey:propertyName];
        }
    }];
}

- (id)initWithCoder:(NSCoder *)decoder {
    
    if(self = [super init]) {
        [self enumeratePropertiesUsingBlock:^(id value, NSString *propertyName) {
            SEL setFunction = [self setterFromString:propertyName];
            if ([self respondsToSelector:setFunction]) {
                id obj = [[decoder decodeObjectForKey:propertyName] retain];
                [self performSelector:setFunction withObject:obj];
            }
        }];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    
    DoubanBaseModel *copy = [[[self class] allocWithZone:zone] init];
    [self enumeratePropertiesUsingBlock:^(id value, NSString *propertyName) {
        SEL setFunction = [copy setterFromString:propertyName];
        if ([copy respondsToSelector:setFunction]) {
            id obj = [[value copyWithZone:zone] autorelease];
            [copy performSelector:setFunction withObject:obj];
        }
    }];
    return copy;
}

#pragma mark - helper

- (NSString *)getTypeFromAttributes:(NSString *)attributes
{
    NSString *prefix = [[attributes componentsSeparatedByString:@","] objectAtIndex:0];
    if ([prefix isEqualToString:@"TQ"]) {
        return @"NSUInteger";
    }
    if ([prefix isEqualToString:@"Tc"]) {
        return @"BOOL";
    }
    return @"NSObject";
}

- (void)enumeratePropertiesUsingBlock:(void (^)(id value, NSString *propertyName))block
{
    unsigned int count;
    objc_property_t *propertyList = class_copyPropertyList([self class], &count);
    for (int i = 0; i < count; i++)
    {
        objc_property_t property = propertyList[i];
        const char *name = property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:name];
        id value = [self performSelector:[self getterFromString:propertyName]];

        if (block) {
            block(value, propertyName);
        }
    }
}

- (SEL)setterFromString:(NSString *)str
{
    return NSSelectorFromString([[@"set" stringByAppendingString:[self capitalizedString:str]] stringByAppendingString:@":"]);
}

- (SEL)getterFromString:(NSString *)str
{
    return NSSelectorFromString(str);
}

- (NSString *)capitalizedString:(NSString *)str
{
    return [NSString stringWithFormat:@"%@%@", [[str substringToIndex:1] uppercaseString], [str substringFromIndex:1]];
}

@end
