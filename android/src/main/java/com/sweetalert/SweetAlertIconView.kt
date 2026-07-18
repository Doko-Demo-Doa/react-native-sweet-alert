package com.sweetalert

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.view.View
import android.view.animation.DecelerateInterpolator
import android.view.animation.LinearInterpolator

/** Draws the success / error / warning glyph or progress arc shown above the alert title. */
internal class SweetAlertIconView(context: Context) : View(context) {
  var style: String = "success"
    set(value) {
      field = value
      startAnimation()
    }

  var progress: Double? = null
    set(value) {
      field = value
      invalidate()
    }

  var strokeColor: Int? = null
    set(value) {
      field = value
      invalidate()
    }

  var strokeWidthPx: Float = 8f
    set(value) {
      field = value
      invalidate()
    }

  private var drawFraction = 0f
  private var animator: ValueAnimator? = null

  private val arcPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
    style = Paint.Style.STROKE
    strokeCap = Paint.Cap.ROUND
  }
  private val glyphPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
    style = Paint.Style.STROKE
    strokeCap = Paint.Cap.ROUND
  }

  private fun defaultColorFor(style: String): Int = when (style) {
    "error" -> Color.parseColor("#F27474")
    "warning" -> Color.parseColor("#F8BB86")
    "progress" -> Color.parseColor("#8CC152")
    else -> Color.parseColor("#A5DC86")
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    startAnimation()
  }

  override fun onDetachedFromWindow() {
    super.onDetachedFromWindow()
    animator?.cancel()
  }

  private fun startAnimation() {
    animator?.cancel()
    drawFraction = if (style == "progress") 0f else 0f

    if (style == "progress" && progress == null) {
      animator = ValueAnimator.ofFloat(0f, 1f).apply {
        duration = 1200
        repeatCount = ValueAnimator.INFINITE
        interpolator = LinearInterpolator()
        addUpdateListener {
          drawFraction = it.animatedValue as Float
          invalidate()
        }
        start()
      }
      return
    }

    animator = ValueAnimator.ofFloat(0f, 1f).apply {
      duration = 400
      interpolator = DecelerateInterpolator()
      addUpdateListener {
        drawFraction = it.animatedValue as Float
        invalidate()
      }
      start()
    }
  }

  override fun onDraw(canvas: Canvas) {
    super.onDraw(canvas)
    val inset = strokeWidthPx
    val rect = RectF(inset, inset, width - inset, height - inset)
    val color = strokeColor ?: defaultColorFor(style)
    arcPaint.strokeWidth = strokeWidthPx
    arcPaint.color = color
    glyphPaint.strokeWidth = strokeWidthPx
    glyphPaint.color = color

    when (style) {
      "progress" -> drawProgress(canvas, rect)
      else -> {
        canvas.drawArc(rect, -90f, 360f * drawFraction, false, arcPaint)
        if (drawFraction >= 1f) drawGlyph(canvas, rect)
      }
    }
  }

  private fun drawProgress(canvas: Canvas, rect: RectF) {
    val current = progress
    if (current != null) {
      canvas.drawArc(rect, -90f, (current.coerceIn(0.0, 100.0) / 100.0 * 360.0).toFloat(), false, arcPaint)
    } else {
      canvas.drawArc(rect, drawFraction * 360f - 90f, 90f, false, arcPaint)
    }
  }

  private fun drawGlyph(canvas: Canvas, rect: RectF) {
    val cx = rect.centerX()
    val cy = rect.centerY()
    val r = rect.width() / 2f
    val path = Path()
    when (style) {
      "success" -> {
        path.moveTo(cx - r * 0.5f, cy)
        path.lineTo(cx - r * 0.15f, cy + r * 0.35f)
        path.lineTo(cx + r * 0.5f, cy - r * 0.35f)
        canvas.drawPath(path, glyphPaint)
      }
      "error" -> {
        path.moveTo(cx - r * 0.4f, cy - r * 0.4f)
        path.lineTo(cx + r * 0.4f, cy + r * 0.4f)
        path.moveTo(cx + r * 0.4f, cy - r * 0.4f)
        path.lineTo(cx - r * 0.4f, cy + r * 0.4f)
        canvas.drawPath(path, glyphPaint)
      }
      "warning" -> {
        path.moveTo(cx, cy - r * 0.45f)
        path.lineTo(cx, cy + r * 0.1f)
        canvas.drawPath(path, glyphPaint)
        val dotPaint = Paint(glyphPaint).apply { style = Paint.Style.FILL }
        canvas.drawCircle(cx, cy + r * 0.35f, strokeWidthPx / 2f, dotPaint)
      }
    }
  }
}
