//
//  Common.h
//  FilmPicker
//
//  Created by sing on 11-5-15.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

//添加定义，在release时不会输出log
#ifndef __OPTIMIZE__
#define NSLog(...) NSLog(__VA_ARGS__)
#else
#define NSLog(...) {}
#endif

#import <Foundation/Foundation.h>

@interface Common : NSObject {
    
}

+ (UIImage *)transformToSize:(UIImage*)aSrcImage desSize:(CGSize)aDesSize;
+ (CGSize)calculateLabelSIzeByFont:(NSString*)text font:(UIFont*)font maxSize:(CGSize)aMaxSize;

+ (NSString*)converToGbkEncodingString:(NSString*)srcString;
+ (char*)converToGbkEncodingcString:(NSString*)srcString;
+ (NSData*)gbkDataConverToUtf8EncodingData:(NSData*)data;
+ (NSString*)MD5:(NSString*)srcString;
+ (NSString*)currentTimeStampForSecond;

+ (UIImage*)imageFromPath:(NSString*)imagePath;
+ (NSString*)currentDeviceID;

@end





