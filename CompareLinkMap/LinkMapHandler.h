//
//  LinkMapHandler.h
//  CompareLinkMap
//
//  Created by 周末 on 2018/5/12.
//  Copyright © 2018年 周末. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "SymbolModel.h"

@interface LinkMapHandler : NSObject
/**
 选择的LinkMap文件路径
 */
+ (void)linkMapPathForChoose:(void (^)(NSString *linkMapPath))block;

/**
 选择输出文件夹

 @param block linkMap_年月日.txt
 */
+ (void)linkMapResultPathForChoose:(void (^)(NSString *resultPath))block;

/**
 检验是否是LinkMap文件
 */
+ (BOOL)checkLinkMapContent:(NSString *)content;

/**
 解析文件
 @param content1 linkMap文本内容
 @param content2 linkMap文本内容
 @param keyWord 关键字
 @param onlyLibrary 是否合并库
 @param sortKey 排序关键字
 @return 解析结果
 */
+ (NSString *)compareLinkMapContent1:(NSString *)content1 linkMapContent2:(NSString *)content2 keyWord:(NSString *)keyWord isOnlyShowLibrary:(BOOL)onlyLibrary sortKeyWord:(NSString *)sortKey;

@end
