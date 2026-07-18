package com.sweetalert

import android.app.Activity
import android.app.Dialog
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.view.Window
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

/** Custom alert dialog rendering the `success`/`error`/`warning`/`normal`/`progress` styles. */
internal class SweetAlertDialog(
  activity: Activity,
  private val options: SweetAlertOptions,
  private val onResult: (confirmed: Boolean) -> Unit,
) : Dialog(activity, android.R.style.Theme_Black_NoTitleBar) {

  private val iconView = SweetAlertIconView(context)
  private var resolved = false

  init {
    requestWindowFeature(Window.FEATURE_NO_TITLE)
    window?.setBackgroundDrawableResource(android.R.color.transparent)
    setCancelable(options.cancellable)
    setCanceledOnTouchOutside(options.cancellable)
    setContentView(buildContentView())
    setOnDismissListener { resolveOnce(false) }
  }

  fun updateProgress(progress: Double) {
    iconView.progress = progress
  }

  private fun resolveOnce(confirmed: Boolean) {
    if (resolved) return
    resolved = true
    onResult(confirmed)
  }

  private val isDarkMode: Boolean
    get() = (context.resources.configuration.uiMode and
      Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

  private fun dp(value: Number): Int = TypedValue.applyDimension(
    TypedValue.COMPLEX_UNIT_DIP,
    value.toFloat(),
    context.resources.displayMetrics,
  ).toInt()

  private fun parseColor(hex: String?, fallback: Int): Int = try {
    if (hex != null) Color.parseColor(hex) else fallback
  } catch (error: IllegalArgumentException) {
    fallback
  }

  private fun buildContentView(): ViewGroup {
    val cardBackground = if (isDarkMode) Color.parseColor("#2C2C2E") else Color.WHITE
    val titleColor = if (isDarkMode) Color.parseColor("#F2F2F7") else Color.parseColor("#575757")
    val subTitleColor = if (isDarkMode) Color.parseColor("#AEAEB2") else Color.parseColor("#797979")

    val card = LinearLayout(context).apply {
      orientation = LinearLayout.VERTICAL
      gravity = Gravity.CENTER_HORIZONTAL
      setPadding(dp(24), dp(24), dp(24), dp(16))
      background = GradientDrawable().apply {
        cornerRadius = dp(12).toFloat()
        setColor(cardBackground)
      }
    }

    iconView.style = options.style
    iconView.progress = options.progress
    options.progressBarColor?.let { iconView.strokeColor = parseColor(it, Color.BLACK) }
    options.progressBarWidth?.let { iconView.strokeWidthPx = dp(it).toFloat() }
    val iconSize = options.progressCircleRadius?.let { dp(it * 2) } ?: dp(64)
    card.addView(
      iconView,
      LinearLayout.LayoutParams(iconSize, iconSize).apply { bottomMargin = dp(16) },
    )

    if (!options.title.isNullOrEmpty()) {
      card.addView(TextView(context).apply {
        text = options.title
        textSize = 20f
        gravity = Gravity.CENTER
        setTextColor(titleColor)
      })
    }

    if (!options.subTitle.isNullOrEmpty()) {
      card.addView(TextView(context).apply {
        text = options.subTitle
        textSize = 14f
        gravity = Gravity.CENTER
        setTextColor(subTitleColor)
        setPadding(0, dp(8), 0, 0)
      })
    }

    val buttonRow = LinearLayout(context).apply {
      orientation = LinearLayout.HORIZONTAL
      gravity = Gravity.CENTER_HORIZONTAL
      setPadding(0, dp(20), 0, 0)
    }

    if (!options.otherButtonTitle.isNullOrEmpty()) {
      buttonRow.addView(
        makeButton(options.otherButtonTitle, parseColor(options.otherButtonColor, Color.parseColor("#F27474"))) {
          resolveOnce(false)
          dismiss()
        },
        LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply { marginEnd = dp(8) },
      )
    }

    if (!options.confirmButtonTitle.isNullOrEmpty()) {
      buttonRow.addView(
        makeButton(options.confirmButtonTitle, parseColor(options.confirmButtonColor, Color.parseColor("#8CC152"))) {
          resolveOnce(true)
          dismiss()
        },
        LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f),
      )
    }

    if (buttonRow.childCount > 0) {
      card.addView(buttonRow)
    }

    return FrameLayout(context).apply {
      addView(
        card,
        FrameLayout.LayoutParams(dp(280), ViewGroup.LayoutParams.WRAP_CONTENT).apply { gravity = Gravity.CENTER },
      )
    }
  }

  private fun makeButton(title: String, color: Int, onClick: () -> Unit): Button = Button(context).apply {
    text = title
    isAllCaps = false
    setTextColor(Color.WHITE)
    background = GradientDrawable().apply {
      cornerRadius = dp(6).toFloat()
      setColor(color)
    }
    setOnClickListener { onClick() }
  }
}
