package com.sweetalert

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap

class SweetAlertModule(reactContext: ReactApplicationContext) :
  NativeSweetAlertSpec(reactContext) {

  private var currentDialog: SweetAlertDialog? = null

  override fun showAlert(options: ReadableMap, promise: Promise) {
    val activity = reactApplicationContext.currentActivity
    if (activity == null) {
      promise.reject("no_activity", "No current activity to show the alert on")
      return
    }

    activity.runOnUiThread {
      currentDialog?.dismiss()
      val dialog = SweetAlertDialog(activity, SweetAlertOptions.from(options)) { confirmed ->
        currentDialog = null
        val result = Arguments.createMap()
        result.putBoolean("confirmed", confirmed)
        promise.resolve(result)
      }
      currentDialog = dialog
      dialog.show()
    }
  }

  override fun dismissAlert() {
    reactApplicationContext.currentActivity?.runOnUiThread {
      currentDialog?.dismiss()
    }
  }

  override fun setProgress(progress: Double) {
    reactApplicationContext.currentActivity?.runOnUiThread {
      currentDialog?.updateProgress(progress)
    }
  }

  companion object {
    const val NAME = NativeSweetAlertSpec.NAME
  }
}
