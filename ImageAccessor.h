//
//  ImageAccessor.h
//  FilmPicker
//
//  Created by sing on 11-6-9.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadProcessor.h"

#pragma mark - ImageItem class

enum _imageStatus {
    status_succeed = 0,
    status_failed = 1
    };
typedef enum _imageStatus ImageStatus;

@interface ImageItem : NSObject {
    UIImage *image;
    NSString *imageUrl;
    NSString *imageLocalPath;
@private
    NSInteger _retryCount;
    ImageStatus _status;
}

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, copy) NSString *imageLocalPath;
@property (nonatomic, assign) NSInteger retryCount;
@property (nonatomic, assign) ImageStatus status;

- (id)initWithImageUrl:(NSString*)url;

@end


#pragma mark - ImageAccessorDelegate

@protocol ImageAccessorDelegate

-(void)updateWhenImageFinishDownload:(ImageItem*)imageItem;

@end

#pragma mark - imageacessor class

enum _lockFlag {
    sync_lock = 0,
    sync_unLock = 1
};
typedef enum _lockFlag SyncLockFlag;

@interface ImageAccessor : NSObject <DownloadProcessorDelegate> {
    NSMutableArray *imageTaskList;      //the task list of image which to be download
    NSCondition *imageProcessorLock;
    NSThread *workThread;
    DownloadProcessor *httpProcessor;
    UIImage *defaultImage;
    NSObject<ImageAccessorDelegate> *delegate;
@private
    BOOL _exitThread;
    BOOL _nextTask;
    ImageItem *_currentTaskImageItem;
}

@property (nonatomic, retain) NSMutableArray *imageTaskList;
@property (nonatomic, retain) NSCondition *imageProcessorLock;
@property (nonatomic, retain) NSThread *workThread;
@property (nonatomic, assign) BOOL exitThread;
@property (nonatomic, retain) DownloadProcessor *httpProcessor;
@property (nonatomic, retain) UIImage *defaultImage;
@property (nonatomic, assign) NSObject<ImageAccessorDelegate> *delegate;

- (NSMutableArray*)imageTaskList;
- (void)threadSync:(SyncLockFlag)flag;
- (UIImage*)imageFromPath:(NSString*)imagePath;
- (NSInteger)addToImageTaskList:(ImageItem*)imageItem;
- (ImageItem*)getFromImageTaskList;
- (BOOL)writeImageToDisk:(NSData*)imageData filePath:(NSString*)path;
- (UIImage*)readImageFromDisk:(NSString*)imageUrl;
- (UIImage*)readImageFromDisk:(NSString*)imageUrl clearTask:(BOOL)clear;
- (NSInteger)removeTaskFromList:(ImageItem*)item;
-(void)clearImageTaskList;

-(void)run;
-(void)startDownload:(NSString*)url;
-(void)setLoopFlag:(BOOL)flag;

+ (NSString*)getFileNameFromUrl:(NSString*)url;
+ (NSString*)converUrlToLocalPath:(NSString*)url;

@end
