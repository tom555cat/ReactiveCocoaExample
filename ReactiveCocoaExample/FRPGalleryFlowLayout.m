//
//  FRPGalleryFlowLayout.m
//  ReactiveCocoaExample
//
//  Created by MAC-MiNi on 2017/8/16.
//  Copyright © 2017年 MAC-MiNi. All rights reserved.
//

#import "FRPGalleryFlowLayout.h"

@implementation FRPGalleryFlowLayout

- (instancetype)init {
    if (!(self = [super init])) {
        return nil;
    }
    
    self.itemSize = CGSizeMake(145, 145);
    self.minimumInteritemSpacing = 10;
    self.minimumLineSpacing = 10;
    self.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    
    return self;
}

@end
