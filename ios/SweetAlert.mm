#import "SweetAlert.h"

@implementation SweetAlert
- (void)showAlert:(JS::NativeSweetAlert::AlertOptions &)options
          resolve:(RCTPromiseResolveBlock)resolve
           reject:(RCTPromiseRejectBlock)reject
{
    // TODO: render the native alert dialog and resolve once dismissed.
    reject(@"not_implemented", @"showAlert is not yet implemented", nil);
}

- (void)dismissAlert
{
    // TODO: dismiss the currently shown alert, if any.
}

- (void)setProgress:(double)progress
{
    // TODO: update the progress indicator of a 'progress' style alert.
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeSweetAlertSpecJSI>(params);
}

+ (NSString *)moduleName
{
  return @"SweetAlert";
}

@end
