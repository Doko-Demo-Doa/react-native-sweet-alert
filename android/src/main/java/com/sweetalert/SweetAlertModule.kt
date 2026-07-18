package com.sweetalert

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap

class SweetAlertModule(reactContext: ReactApplicationContext) :
  NativeSweetAlertSpec(reactContext) {

  override fun showAlert(options: ReadableMap, promise: Promise) {
    // TODO: render the native alert dialog and resolve once dismissed.
    promise.reject("not_implemented", "showAlert is not yet implemented")
  }

  override fun dismissAlert() {
    // TODO: dismiss the currently shown alert, if any.
  }

  override fun setProgress(progress: Double) {
    // TODO: update the progress indicator of a 'progress' style alert.
  }

  companion object {
    const val NAME = NativeSweetAlertSpec.NAME
  }
}
