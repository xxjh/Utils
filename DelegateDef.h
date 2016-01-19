//
//  DelegateDef.h
//  All delegate definition file
//
//  Created by sing on 11-5-23.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//


@protocol DownloadProcessorDelegate
@optional
-(void)didReceiveResponse:(NSURLResponse *)response tag:(NSUInteger)aTag;
-(void)didReceiveData:(NSData *)data tag:(NSUInteger)aTag;
-(void)didFailWithError:(NSError *)error tag:(NSUInteger)aTag;
-(void)didFinishLoading:(NSURLConnection *)connection data:(NSData *)responseData tag:(NSUInteger)aTag;
@end


@protocol ItemClickDelegate
-(void)itemClick:(id)item index:(NSInteger)aIndex tag:(NSInteger)aTag;
@end
