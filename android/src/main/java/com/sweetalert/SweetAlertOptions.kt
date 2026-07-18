package com.sweetalert

import com.facebook.react.bridge.ReadableMap

internal data class SweetAlertOptions(
  val style: String,
  val title: String?,
  val subTitle: String?,
  val confirmButtonTitle: String?,
  val confirmButtonColor: String?,
  val otherButtonTitle: String?,
  val otherButtonColor: String?,
  val cancellable: Boolean,
  val progress: Double?,
  val progressBarColor: String?,
  val progressCircleRadius: Double?,
  val progressBarWidth: Double?,
  val progressRimWidth: Double?,
  val progressSpinSpeed: Double?,
) {
  companion object {
    fun from(map: ReadableMap): SweetAlertOptions = SweetAlertOptions(
      style = if (map.hasKey("style")) map.getString("style") ?: "normal" else "normal",
      title = if (map.hasKey("title")) map.getString("title") else null,
      subTitle = if (map.hasKey("subTitle")) map.getString("subTitle") else null,
      confirmButtonTitle = if (map.hasKey("confirmButtonTitle")) map.getString("confirmButtonTitle") else null,
      confirmButtonColor = if (map.hasKey("confirmButtonColor")) map.getString("confirmButtonColor") else null,
      otherButtonTitle = if (map.hasKey("otherButtonTitle")) map.getString("otherButtonTitle") else null,
      otherButtonColor = if (map.hasKey("otherButtonColor")) map.getString("otherButtonColor") else null,
      cancellable = map.hasKey("cancellable") && map.getBoolean("cancellable"),
      progress = if (map.hasKey("progress")) map.getDouble("progress") else null,
      progressBarColor = if (map.hasKey("progressBarColor")) map.getString("progressBarColor") else null,
      progressCircleRadius = if (map.hasKey("progressCircleRadius")) map.getDouble("progressCircleRadius") else null,
      progressBarWidth = if (map.hasKey("progressBarWidth")) map.getDouble("progressBarWidth") else null,
      progressRimWidth = if (map.hasKey("progressRimWidth")) map.getDouble("progressRimWidth") else null,
      progressSpinSpeed = if (map.hasKey("progressSpinSpeed")) map.getDouble("progressSpinSpeed") else null,
    )
  }
}
