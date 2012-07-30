//
//  UIImageView+UNNetworking.h
//  UNNetworkingExample
//
//  Created by Alexander Bukov on 7/28/12.
//  Copyright (c) 2012 Company. All rights reserved.
//


#import <UIKit/UIKit.h>

//! Image cache policy
typedef enum {
    UNImageCachePolicyIgnoreCache,
    UNImageCachePolicyMemoryCache,
    UNImageCachePolicyMemoryAndFileCache
} UNImageCachePolicy;

//! Image resize/scale policy
typedef enum {
    UNImageSizePolicyOriginalSize,
    UNImageSizePolicyResizeToRect,
    UNImageSizePolicyScaleAspectFill,
    UNImageSizePolicyScaleAspectFit
} UNImageSizePolicy;



@interface UIImageView (UNNetworking)

//! Base method
- (void)setImageWithURLRequest:(NSURLRequest *)urlRequest 
              placeholderImage:(UIImage *)placeholderImage
                  failureImage:(UIImage *)failureImage
              progressViewSize:(CGSize)size
             progressViewStile:(UIProgressViewStyle)stile
             progressTintColor:(UIColor*)progressTintColor
                trackTintColor:(UIColor*)trackTintColor
                    sizePolicy:(UNImageSizePolicy)sizePolicy
                   cachePolicy:(UNImageCachePolicy)cachePolicy
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
                      progress:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, float progress))progress;

//! Without progress
- (void)setImageWithURLRequest:(NSURLRequest *)urlRequest 
              placeholderImage:(UIImage *)placeholderImage
                  failureImage:(UIImage *)failureImage
                    sizePolicy:(UNImageSizePolicy)sizePolicy
                   cachePolicy:(UNImageCachePolicy)cachePolicy
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
                      progress:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, float progress))progress;

//! Method remove progress view from supper view
- (void)removeProgressView;

//! Call this method if you need clear memory cache
+ (void)clearMemoryImageCache;

//! Call this method if you need clear file cache
+ (void)clearFileImageCache;

@end
