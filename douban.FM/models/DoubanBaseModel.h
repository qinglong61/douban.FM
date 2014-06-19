//
//  DoubanBaseModel.h
//  douban.FM
//
//  Created by qinglun.duan on 14-3-27.
//  Copyright (c) 2014年 com.pwrd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DoubanBaseModel : NSObject <NSCoding, NSCopying>

/**
 * @brief 初始化方法
 * @param `NSDictionary *` dictionary 用来初始化的字典，key要和Model的属性名保持一致
 * @result `id` 返回Model实例
 */
- (id)initWithDictionary:(NSDictionary *)dictionary;

/**
 * @brief 得到包含Model各属性的字典
 * @result `NSDictionary *` 返回一个包含Model属性的字典，key和属性名一样
 */
- (NSDictionary *)dictionaryValue;

@end
