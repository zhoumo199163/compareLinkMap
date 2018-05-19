//
//  LinkMapHandler.m
//  CompareLinkMap
//
//  Created by 周末 on 2018/5/12.
//  Copyright © 2018年 周末. All rights reserved.
//

#import "LinkMapHandler.h"


@implementation LinkMapHandler

+ (void)linkMapPathForChoose:(void (^)(NSString *linkMapPath))block{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = NO;
    panel.resolvesAliases = NO;
    panel.canChooseFiles = YES;
    
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            NSURL *document = [[panel URLs] objectAtIndex:0];
            block(document.path);
        }
    }];
}

+ (void)linkMapResultPathForChoose:(void (^)(NSString *resultPath))block{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = YES;
    panel.resolvesAliases = NO;
    panel.canChooseFiles = NO;
    
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            NSURL *document = [[panel URLs] objectAtIndex:0];

            NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
            
            NSString *path = @"linkMap_";
            path = [path stringByAppendingFormat:@"%ld%ld%ld.txt",(long)components.year,(long)components.month,(long)components.day];
            path = [document.path stringByAppendingPathComponent:path];
            block(path);
        }
    }];
}

/**
 检验文件是否是LinkMap文件
 */
+ (BOOL)checkLinkMapContent:(NSString *)content{
    NSArray *checkStrings = @[@"# Path:",@"# Object files:",@"# Symbols:"];
    for(NSString *checkString in checkStrings){
        NSRange objectFilesRange = [content rangeOfString:checkString];
        if(objectFilesRange.location == NSNotFound){
            return NO;
        }
    }
    return YES;
}

+ (NSDictionary *)symbolMapFromContent:(NSString *)content keyWord:(NSString *)keyWord{
    __block NSMutableDictionary <NSString *, SymbolModel *>*symbolMap = [NSMutableDictionary new];
    
    NSArray *objectFilesSeparated = [content componentsSeparatedByString:@"# Object files:"];
    NSArray *sectionsSeparated = [[objectFilesSeparated lastObject] componentsSeparatedByString:@"# Sections:"];
    NSString *objectFilesContent = [sectionsSeparated firstObject];
    NSString *sizeCountContent = [sectionsSeparated lastObject];
    NSArray <NSString *> *objectFilesLines = [objectFilesContent componentsSeparatedByString:@"\n"];
    NSArray <NSString *> *sizeLines = [sizeCountContent componentsSeparatedByString:@"\n"];
    
    [objectFilesLines enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange leftRange = [obj rangeOfString:@"["];
        NSRange rightRange = [obj rangeOfString:@"]"];
        if(leftRange.location != NSNotFound && rightRange.location != NSNotFound){
            NSString *fileKey = [obj substringToIndex:rightRange.location +1];
            NSString *fileName = [obj substringFromIndex:rightRange.location +1];
            fileName = [[fileName componentsSeparatedByString:@"/"] lastObject];
            if([keyWord isEqualToString:@""] || [fileName containsString:keyWord]){
                SymbolModel *model = [SymbolModel new];
                model.fileName = fileName;
                symbolMap[fileKey] = model;
            }
        }
    }];
    
    __block NSMutableDictionary *map = [NSMutableDictionary new];
    [sizeLines enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange leftRange = [obj rangeOfString:@"["];
        NSRange rightRange = [obj rangeOfString:@"]"];
        if(leftRange.location != NSNotFound && rightRange.location != NSNotFound){
            NSArray <NSString *>*sizeArray = [obj componentsSeparatedByString:@"\t"];
            if(sizeArray.count == 3){
                rightRange = [sizeArray.lastObject rangeOfString:@"]"];
                NSString *fileKey = [sizeArray.lastObject substringToIndex:rightRange.location+1];
                SymbolModel *model = symbolMap[fileKey];
                if(model){
                    NSUInteger size = strtoul([sizeArray[1] UTF8String], nil, 16);
                    float kb = size/1024.00;
                    model.linkMap1Size +=kb;
                    map[model.fileName] = @(model.linkMap1Size);
                }
            }
        }
    }];
    return [map copy];
}

+ (NSString *)compareLinkMapContent1:(NSString *)content1 linkMapContent2:(NSString *)content2 keyWord:(NSString *)keyWord isOnlyShowLibrary:(BOOL)onlyLibrary sortKeyWord:(NSString *)sortKey{
    NSMutableString *result = [NSMutableString new];
     result =[@"比较结果\t\tLinkMap1\t\tLinkMap2\t\t名称\r\n\r\n" mutableCopy];
    NSDictionary *result1 = [LinkMapHandler symbolMapFromContent:content1 keyWord:keyWord];
    NSDictionary *result2 = [LinkMapHandler symbolMapFromContent:content2 keyWord:keyWord];
    
    NSMutableDictionary *tmpResult2 = [result2 mutableCopy];
   __block NSMutableArray *addModels = [NSMutableArray new];
  __block  NSMutableArray *deleteModels = [NSMutableArray new];
   __block NSMutableArray *compareModels = [NSMutableArray new];
    
    [result1 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSNumber *value = result2[key];
        SymbolModel *model = [SymbolModel new];
        model.fileName = key;
        model.linkMap1Size = [obj floatValue];
        model.linkMap2Size = [value floatValue];
        if(value){
            float compare = [value floatValue] - [obj floatValue];
            model.compareSize = compare;
            [tmpResult2 removeObjectForKey:key];
            [compareModels addObject:model];
        }else{
            [deleteModels addObject:model];
        }

    }];
    
    [tmpResult2 enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        SymbolModel *model = [SymbolModel new];
        model.fileName = key;
        model.linkMap1Size = 0;
        model.linkMap2Size = [obj floatValue];
        model.compareSize = [obj floatValue];
        [addModels addObject:model];
    }];
    
    if(onlyLibrary){
        [compareModels addObjectsFromArray:addModels];
        [compareModels addObjectsFromArray:deleteModels];
        compareModels = [[LinkMapHandler libraryForModels:compareModels] mutableCopy];
        [addModels removeAllObjects];
        [deleteModels removeAllObjects];
    }
    
    addModels = [LinkMapHandler descend:addModels sortKeyWord:sortKey];
    deleteModels = [LinkMapHandler descend:deleteModels sortKeyWord:sortKey];
    compareModels = [LinkMapHandler descend:compareModels sortKeyWord:sortKey];
    
    [result appendString:[LinkMapHandler contentForModels:addModels].copy];
    [result appendString:[LinkMapHandler contentForModels:deleteModels].copy];
    [result appendString:[LinkMapHandler contentForModels:compareModels].copy];
   
    return result;
}

// 降序排序
+ (NSMutableArray <SymbolModel *>*)descend:(NSMutableArray <SymbolModel *>*)array sortKeyWord:(NSString *)sortKey{
    NSArray <SymbolModel *>*newArray = [array sortedArrayUsingComparator:^NSComparisonResult(SymbolModel *obj1, SymbolModel *obj2) {
        float value1 = obj1.compareSize;
        float value2 = obj2.compareSize;
        if([sortKey isEqualToString:@"linkMap1"]){
             value1 = obj1.linkMap1Size;
             value2 = obj2.linkMap1Size;
        }else if ([sortKey isEqualToString:@"linkMap2"]){
            value1 = obj1.linkMap2Size;
            value2 = obj2.linkMap2Size;
        }
        if( value1> value2){
            return NSOrderedAscending;
        }
        else{
            return NSOrderedDescending;
        }
    }];
    return [newArray mutableCopy];
}

+ (NSMutableString *)contentForModels:(NSArray <SymbolModel *>*)models{
    NSMutableString *content = [NSMutableString new];
    __block float compareCount = 0;
    __block float linkMap1Count = 0;
    __block float linkMap2Count = 0;
    [models enumerateObjectsUsingBlock:^(SymbolModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        compareCount += obj.compareSize;
        linkMap1Count += obj.linkMap1Size;
        linkMap2Count += obj.linkMap2Size;
       [content appendFormat:@"   %0.2fK\t\t%0.2fK\t\t%0.2fK\t\t%@\r\n",obj.compareSize,obj.linkMap1Size,obj.linkMap2Size,obj.fileName];
    }];
    
    if(compareCount != 0|| linkMap1Count != 0|| linkMap2Count != 0){
        [content appendString:@"\r\n"];
        [content appendString:@"总计：\r\n"];
        [content appendFormat:@"   %0.2fK\t\t%0.2fM\t\t%0.2fM\r\n",compareCount,linkMap1Count/1024.00,linkMap2Count/1024.00];
        [content appendString:@"\r\n\r\n"];
    }
    return content;
}

+ (NSArray *)libraryForModels:(NSArray <SymbolModel *>*)models{
    NSMutableDictionary *librarys = [NSMutableDictionary new];
    [models enumerateObjectsUsingBlock:^(SymbolModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *fileName = obj.fileName;
        if([fileName containsString:@"("]&&[fileName containsString:@")"]){
            NSArray *separate = [fileName componentsSeparatedByString:@"("];
            NSString *libraryName = [separate firstObject];
            SymbolModel *model = librarys[libraryName];
            if(model){
                model.compareSize += obj.compareSize;
                model.linkMap1Size += obj.linkMap1Size;
                model.linkMap2Size += obj.linkMap2Size;
            }else{
                model = [SymbolModel new];
                model.fileName = libraryName;
                model.compareSize = obj.compareSize;
                model.linkMap1Size = obj.linkMap1Size;
                model.linkMap2Size = obj.linkMap2Size;
                librarys[libraryName] = model;
            }
        }else{
            librarys[fileName] = obj;
        }
    }];
    return [librarys allValues];
}




@end
