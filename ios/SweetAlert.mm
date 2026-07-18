#import "SweetAlert.h"
#import "SweetAlert-Swift.h"

@implementation SweetAlert

RCT_EXPORT_MODULE(SweetAlert)

- (void)showAlert:(JS::NativeSweetAlert::AlertOptions &)options
          resolve:(RCTPromiseResolveBlock)resolve
           reject:(RCTPromiseRejectBlock)reject
{
    // TurboModule methods run on a background queue by default, but
    // SweetAlertBridge/SweetAlertView touch UIKit (addSubview, layout).
    // Extract the C++ struct's fields synchronously here — `options` is a
    // reference into caller-owned stack memory, not valid once we return —
    // then hop to the main queue for the actual UI work.
    NSString *title = options.title();
    NSString *subTitle = options.subTitle();
    NSString *style = options.style();
    NSString *confirmButtonTitle = options.confirmButtonTitle();
    NSString *confirmButtonColor = options.confirmButtonColor();
    NSString *otherButtonTitle = options.otherButtonTitle();
    NSString *otherButtonColor = options.otherButtonColor();
    BOOL cancellable = options.cancellable() ? *options.cancellable() : NO;
    NSNumber *progress = options.progress() ? @(*options.progress()) : nil;
    NSString *progressBarColor = options.progressBarColor();
    NSNumber *progressBarWidth = options.progressBarWidth() ? @(*options.progressBarWidth()) : nil;

    dispatch_async(dispatch_get_main_queue(), ^{
        [SweetAlertBridge presentWithTitle:title
                                  subTitle:subTitle
                                     style:style
                        confirmButtonTitle:confirmButtonTitle
                        confirmButtonColor:confirmButtonColor
                          otherButtonTitle:otherButtonTitle
                          otherButtonColor:otherButtonColor
                               cancellable:cancellable
                                  progress:progress
                          progressBarColor:progressBarColor
                          progressBarWidth:progressBarWidth
                                completion:^(BOOL confirmed) {
            resolve(@{ @"confirmed": @(confirmed) });
        }];
    });
}

- (void)dismissAlert
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [SweetAlertBridge dismiss];
    });
}

- (void)setProgress:(double)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [SweetAlertBridge setProgress:progress];
    });
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeSweetAlertSpecJSI>(params);
}

@end
