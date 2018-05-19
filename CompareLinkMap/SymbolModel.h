//
//  SymbolModel.h
//  CompareLinkMap
//
//  Created by 周末 on 2018/5/12.
//  Copyright © 2018年 周末. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SymbolModel : NSObject

@property (nonatomic, copy) NSString *fileName;
@property (nonatomic) float linkMap1Size; // KB
@property (nonatomic) float linkMap2Size;
@property (nonatomic) float compareSize;


@end
