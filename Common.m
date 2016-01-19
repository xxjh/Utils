//
//  Common.m
//  FilmPicker
//
//  Created by sing on 11-5-15.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "Common.h"

@implementation Common

+ (UIImage *)transformToSize:(UIImage*)aSrcImage desSize:(CGSize)aDesSize
{
    UIGraphicsBeginImageContext(aDesSize);
    [aSrcImage drawInRect:CGRectMake(0, 0, aDesSize.width, aDesSize.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

//根据字体大小自动计算label大小
+ (CGSize)calculateLabelSIzeByFont:(NSString*)text font:(UIFont*)font maxSize:(CGSize)aMaxSize
{
    CGSize labelSize = [text sizeWithFont:font constrainedToSize:aMaxSize lineBreakMode:UILineBreakModeCharacterWrap];
    return labelSize;
}

+ (NSString*)converToGbkEncodingString:(NSString*)srcString
{
    NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSData *gbkData = [srcString dataUsingEncoding:gbkEncoding];
    char tempBytes[512] = {0};
    [gbkData getBytes:tempBytes length:[gbkData length]];
    NSString *retString = [NSString stringWithCString:tempBytes encoding:gbkEncoding];
    return retString;
}

//need to release return value
+ (char*)converToGbkEncodingcString:(NSString*)srcString
{
    NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSData *gbkData = [srcString dataUsingEncoding:gbkEncoding];
    NSInteger len = [gbkData length];
    char *tempBytes = malloc(len + 1);
    memset(tempBytes, 0, len + 1);
    [gbkData getBytes:tempBytes length:len];
//    NSString *temp = [NSString stringWithCString:tempBytes encoding:gbkEncoding];
//    NSLog(@"%@", temp);
    return tempBytes;
}

+ (NSData*)gbkDataConverToUtf8EncodingData:(NSData*)data
{ 
    if (data == nil) {
        NSAssert(data != nil, @"data is nil!!");
        return data;
    }
    
    NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString *gbkStrData = [[NSString alloc] initWithData:data encoding:gbkEncoding];
    
    
    if (gbkStrData == nil) {
        NSAssert(gbkStrData != nil, @"conver to gbk data failed!");
        [gbkStrData release];
        return data;
    }
    
    NSString *temp = [gbkStrData lowercaseString];
    NSRange foundRange = [temp rangeOfString:@"encoding=\"gbk\""];
    NSData *utf8Data = nil;
    //had found
    if (foundRange.location != NSNotFound) {
        NSString *utf8String = [gbkStrData stringByReplacingOccurrencesOfString:@"encoding=\"gbk\"" withString:@"encoding=\"utf-8\""];
        utf8Data = [utf8String dataUsingEncoding:NSUTF8StringEncoding];
//        NSLog(@"utf8 data : \r\n%@", utf8String);
    } else {
        utf8Data = [gbkStrData dataUsingEncoding:NSUTF8StringEncoding];
//        NSLog(@"gbk data : \r\n%@", gbkStrData);
    }
    
    [gbkStrData release];
    
    return utf8Data;
}

+ (NSString*)MD5:(NSString *)srcString
{
    const char *cStr = [srcString UTF8String];  
    unsigned char result[CC_MD5_DIGEST_LENGTH];  
    CC_MD5( cStr, strlen(cStr), result );  
    
    NSString *md5String = [NSString stringWithFormat:  
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",  
            result[0], result[1], result[2], result[3],  
            result[4], result[5], result[6], result[7],  
            result[8], result[9], result[10], result[11],  
            result[12], result[13], result[14], result[15]  
            ];
    return [md5String lowercaseString];
}

+ (NSString*)currentTimeStampForSecond
{
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
    NSTimeInterval currentDate = [date timeIntervalSince1970] * 1000;
    NSString *timeString = [NSString stringWithFormat:@"%.f", currentDate];
    [date release];
    return timeString;
}

+ (UIImage*)imageFromPath:(NSString *)imagePath
{
    UIImage *tempImage = nil;
    
    NSRange foundRange = [imagePath rangeOfString:@"http://"];
    
    //local path
    if (foundRange.location == NSNotFound) {
        tempImage = [UIImage imageNamed:imagePath];
    } else { //url path
        NSURL *url = [NSURL URLWithString:imagePath];
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
        tempImage = [[[UIImage alloc] initWithData:imageData] autorelease];
        [imageData release];
    }

    return tempImage;
}

+ (NSString*)currentDeviceID
{
    //获取设备id
//    UIDevice *device = [UIDevice currentDevice];
    NSString *deviceUID = [[NSUUID UUID] UUIDString];   //[NSString stringWithString:[device uniqueIdentifier]];
    return deviceUID;
}

#pragma mark -
#pragma mark url encode and decode

char* urlencode(unsigned char *string) {
    
    int escapecount = 0;
    
    unsigned char *src, *dest;
    
    unsigned char *newstr;
    
    
    char hextable[] = { '0', '1', '2', '3', '4', '5', '6', '7',
        
        '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' };
    
    
    if (string == NULL) return NULL;
    
    
    for (src = string; *src != 0; src++)
        
        if (!isalnum(*src)) escapecount++;
    
    newstr = (unsigned char *)malloc(strlen((const char*)string) - escapecount + (escapecount * 3) + 1);
    
    
    src = string;
    
    dest = newstr;
    
    while (*src != 0) {
        
        if (!isalnum(*src)) {
            
            *dest++ = '%';
            
            *dest++ = hextable[*src >> 4];
            
            *dest++ = hextable[*src & 0x0F];
            
            src++;
            
        } else {
            
            *dest++ = *src++;
            
        }
        
    }
    
    *dest = 0;
    
    
    return (char*)newstr;
    
}


unsigned char* urldecode(unsigned char *string) {
    
    int destlen = 0;
    
    unsigned char *src, *dest;
    
    unsigned char *newstr;
    
    
    if (string == NULL) return NULL;
    
    
    for (src = string; *src != 0; src++) {
        
        if (*src == '%') { src+=2; } /* FIXME: this isn’t robust. should check
                                      
                                      the next two chars for 0 */
        
        destlen++;
        
    }
    
    
    newstr = (unsigned char *)malloc(destlen + 1);
    
    src = string;
    
    dest = newstr;
    
    while (*src != 0) {
        
        if (*src == '%') {
            
            char h = toupper(src[1]);
            
            char l = toupper(src[2]);
            
            int vh, vl;
            
            vh = isalpha(h) ? (10+(h-'A')) : (h-'0');
                                   
                                   vl = isalpha(l) ? (10+(l-'A')) : (l-'0');
            
            *dest++ = ((vh<<4)+vl);
            
            src += 3;
            
        } else if (*src == '+') {
            
            *dest++ = ' ';
            
            src++;
            
        } else {
            
            *dest++ = *src++;
            
        }
        
    }
    
    *dest = 0;
    
    
    return newstr;
    
}

+ (NSString*)urlEncodeWithGBKEncode:(NSString*)srcString
{
    NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    const char *tempString = [srcString cStringUsingEncoding:gbkEncoding];
    char *strEncoded = urlencode((unsigned char*)tempString);
    NSString *rtnStr = [NSString stringWithFormat:@"%s", strEncoded];
    free(strEncoded);
    return rtnStr;
}

+ (UIView*)showLoadingIndicatorView:(BOOL)show parentView:(UIView*)parentView
{
    const CGFloat indictorWidth = 32;
    const CGFloat indictorHeight = 32;
    CGFloat top, left;
    
    UIActivityIndicatorView *indicatorView = nil;
    
    if (show) {
        
        //remove first if exists
        indicatorView = (UIActivityIndicatorView*)[parentView viewWithTag:kLoadingIndicatorViewTag];
        if (indicatorView != nil) {
            [indicatorView removeFromSuperview];
        }
        
        //show!!
        CGFloat width= parentView.frame.size.width, height = parentView.frame.size.height;
        
        left = (width - indictorWidth) / 2;
        top = (height - indictorHeight) / 2;
        
        //indicator view
        indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | 
                        UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        indicatorView.tag = kLoadingIndicatorViewTag;
        indicatorView.frame = CGRectMake(left, top, indictorWidth, indictorHeight);
        [parentView addSubview:indicatorView];
        [parentView bringSubviewToFront:indicatorView];
        parentView.userInteractionEnabled = NO;
        [indicatorView startAnimating];
        [indicatorView release];
        
    } else {
        indicatorView = (UIActivityIndicatorView*)[parentView viewWithTag:kLoadingIndicatorViewTag];
        if (indicatorView != nil) {
            [indicatorView stopAnimating];
            [indicatorView removeFromSuperview];
        }
        parentView.userInteractionEnabled = YES;
    }
    return indicatorView;
}

+ (UIView*)showLoadingIndicatorView:(BOOL)show parentView:(UIView*)parentView includeBackgroundView:(BOOL)include
{
    const CGFloat indictorWidth = 32;
    const CGFloat indictorHeight = 32;
    const CGFloat bgViewWidth = 200;
    const CGFloat bgViewHeight = 120;
    CGFloat top, left;
    
    UIView *bgView = nil; 
    UIActivityIndicatorView *indicatorView = nil;
    
    if (show) {
        CGFloat width= parentView.frame.size.width, height = parentView.frame.size.height;
        
        left = (width - bgViewWidth) / 2;
        top = (height - bgViewHeight) / 2;
        
        //bgView
        UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(left, top, bgViewWidth, bgViewHeight)];
        bgView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | 
                    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        bgView.backgroundColor = [UIColor blackColor];
        bgView.alpha = 0.8;
        bgView.tag = kLoadingIndicatorBgViewTag;
        [parentView addSubview:bgView];
        [parentView bringSubviewToFront:bgView];
        parentView.userInteractionEnabled = NO;
        
        //set to round conrner
        bgView.layer.cornerRadius = 10;
        bgView.layer.masksToBounds = YES;
        bgView.opaque = NO;
        
        //indicator view
        indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        left = (bgViewWidth - indictorWidth) / 2;
        top = (bgViewHeight - indictorHeight) / 2;
        indicatorView.tag = kLoadingIndicatorViewTag;
        indicatorView.frame = CGRectMake(left, top - top / 3, indictorWidth, indictorHeight);
        [bgView addSubview:indicatorView];
        [indicatorView startAnimating];
        [indicatorView release];
        
        //label
        CGFloat labelHeight = 50;
        VerticallyAlignedLabel *textLabel = [[VerticallyAlignedLabel alloc] initWithFrame:CGRectMake(0, top + top / 3, bgViewWidth, labelHeight)];
        textLabel.tag = kLoadingIndicatorTextLabelTag;
        textLabel.text = @"正在加载...";
        textLabel.font = [UIFont fontWithName:@"Arial" size:17];
        textLabel.textColor = [UIColor whiteColor];
        textLabel.textAlignment = UITextAlignmentCenter;
        textLabel.verticalAlignment = VerticalAlignmentMiddle;
        textLabel.backgroundColor = [UIColor clearColor];
        [bgView addSubview:textLabel];
        [textLabel release];
        
        //bgView release
        [bgView release]; 
    } else {
        bgView = (UIView*)[parentView viewWithTag:kLoadingIndicatorBgViewTag];
        if (bgView != nil) {
            indicatorView = (UIActivityIndicatorView*)[bgView viewWithTag:kLoadingIndicatorViewTag];
            if (indicatorView != nil) {
                [indicatorView stopAnimating];
                [indicatorView removeFromSuperview];
            }
            UILabel *label = (UILabel*)[bgView viewWithTag:kLoadingIndicatorTextLabelTag];
            if (label != nil) {
                [label removeFromSuperview];
            }
            [bgView removeFromSuperview];
        }
        parentView.userInteractionEnabled = YES;
    }
    return bgView;
}

+ (void)showEmptyRecordTip:(UIView*)parentView
{
    [self showTipMessage:@"记录为空" inView:parentView];
}

+ (void)showTipMessage:(NSString*)msg inView:(UIView*)parentView
{
    NSAssert(parentView != nil, @"parent view is nil!");
    
    CGRect frame = parentView.frame;
    const NSInteger labelWidth = 150;
    const NSInteger labelHeight = 80;
    CGRect labelFrame = CGRectMake((frame.size.width - labelWidth) / 2, (frame.size.height - labelHeight) / 2, labelWidth, labelHeight);
    UILabel *tipLabel = [[UILabel alloc] initWithFrame:labelFrame];
    tipLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | 
                UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    tipLabel.text = msg;
    tipLabel.font = [UIFont fontWithName:@"Arial" size:15];
    tipLabel.textAlignment = UITextAlignmentCenter;
    tipLabel.textColor = [UIColor whiteColor];
    tipLabel.backgroundColor = [UIColor darkGrayColor];
    tipLabel.alpha = 0.0f;
    [parentView addSubview:tipLabel];
	[parentView bringSubviewToFront:tipLabel];
    [tipLabel release];
    
    //set to round conrner
    tipLabel.layer.cornerRadius = 10;
    tipLabel.layer.masksToBounds = YES;
    tipLabel.opaque = NO;
    
    //animation
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:1.0f];
	tipLabel.alpha = 1.0f;
	[UIView commitAnimations];
    
    [UIView animateWithDuration:2.0f animations:^{tipLabel.alpha = 0.0f;} completion:^(BOOL finished){if (finished) [tipLabel removeFromSuperview];}];

}

+ (BOOL)isPhoneNoValid:(NSString*)phoneNo
{
    //length is 11 and the first character is 1
    return ([phoneNo length] == 11 && [[phoneNo substringToIndex:1] compare:@"1"] == NSOrderedSame);
}

@end
