#import "SweetAlert.h"
#import "SweetAlert-Swift.h"

@implementation SweetAlert

RCT_EXPORT_MODULE(SweetAlert)

- (void)showAlert:(JS::NativeSweetAlert::AlertOptions &)options
          resolve:(RCTPromiseResolveBlock)resolve
           reject:(RCTPromiseRejectBlock)reject
{
    NSNumber *progress = options.progress() ? @(*options.progress()) : nil;
    NSNumber *progressBarWidth = options.progressBarWidth() ? @(*options.progressBarWidth()) : nil;

    [SweetAlertBridge presentWithTitle:options.title()
                              subTitle:options.subTitle()
                                 style:options.style()
                    confirmButtonTitle:options.confirmButtonTitle()
                    confirmButtonColor:options.confirmButtonColor()
                       otherButtonTitle:options.otherButtonTitle()
                       otherButtonColor:options.otherButtonColor()
                           cancellable:options.cancellable() ? *options.cancellable() : NO
                              progress:progress
                      progressBarColor:options.progressBarColor()
                      progressBarWidth:progressBarWidth
                            completion:^(BOOL confirmed) {
        resolve(@{ @"confirmed": @(confirmed) });
    }];
}

- (void)dismissAlert
{
    [SweetAlertBridge dismiss];
}

- (void)setProgress:(double)progress
{
    [SweetAlertBridge setProgress:progress];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeSweetAlertSpecJSI>(params);
}

@end
