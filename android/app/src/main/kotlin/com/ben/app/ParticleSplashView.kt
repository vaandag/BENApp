package com.ben.app

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.os.SystemClock
import android.view.View
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.min
import kotlin.math.sin
import kotlin.random.Random

/**
 * BEN V160 splash.
 *
 * The splash does NOT load or draw a logo bitmap. The pin is constructed from
 * mathematical target points so the first visible logo is genuinely formed
 * from particles. After formation the particle logo spins like a top and
 * drops onto a glowing location target.
 */
class ParticleSplashView(
    context: Context,
    private val onFinished: () -> Unit
) : View(context) {

    private data class Particle(
        val sx: Float,
        val sy: Float,
        val tx: Float,
        val ty: Float,
        val size: Float,
        val phase: Float,
        val drift: Float
    )

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val glow = Paint(Paint.ANTI_ALIAS_FLAG)
    private val particles = ArrayList<Particle>(1500)
    private val random = Random(29071993)
    private var start = 0L
    private var built = false
    private var finished = false

    private val total = 5600L
    private val formationEnd = 3200L
    private val spinEnd = 4850L

    init {
        setLayerType(View.LAYER_TYPE_HARDWARE, null)
        post { buildParticles() }
    }

    private fun buildParticles() {
        if (built || width <= 0 || height <= 0) return
        built = true

        val cx = width / 2f
        val logoW = min(width * 0.54f, 420f)
        val radius = logoW * 0.36f
        val topCy = height * 0.34f
        val tipY = topCy + radius * 2.15f

        val targets = ArrayList<Pair<Float, Float>>(1500)

        // Dense but airy particle fill of the pin body. The upper body is a
        // circle; the lower part tapers into the location-pin tip.
        val rows = 72
        for (row in 0..rows) {
            val y = topCy - radius + (tipY - (topCy - radius)) * row / rows
            val dy = y - topCy
            val half: Float
            if (dy <= 0f) {
                val inside = radius * radius - dy * dy
                half = if (inside > 0f) kotlin.math.sqrt(inside) else 0f
            } else {
                val t = ((y - topCy) / (tipY - topCy)).coerceIn(0f, 1f)
                half = radius * (1f - t).coerceIn(0f, 1f)
            }
            val spacing = 7.5f
            var x = cx - half
            while (x <= cx + half) {
                val edge = half > 0f && kotlin.math.abs(x - cx) > half * 0.80f
                if (random.nextFloat() < if (edge) 0.82f else 0.55f) {
                    // Hollow center: the real logo has a dark circular opening.
                    val innerDx = x - cx
                    val innerDy = y - topCy
                    val innerR = radius * 0.57f
                    val insideHole = innerDx * innerDx + innerDy * innerDy < innerR * innerR
                    if (!insideHole || innerDy > radius * 0.25f) {
                        targets.add(x to y)
                    }
                }
                x += spacing
            }
        }

        // Crisp outer contour.
        val contourCount = 360
        for (i in 0 until contourCount) {
            val a = Math.PI * 0.10 + Math.PI * 1.80 * i / (contourCount - 1)
            targets.add(
                (cx + radius * cos(a).toFloat()) to
                    (topCy + radius * sin(a).toFloat())
            )
        }
        // Two straight-ish sides converging to the tip.
        for (i in 0..140) {
            val t = i / 140f
            val y = topCy + radius * 0.72f + (tipY - topCy - radius * 0.72f) * t
            val half = radius * (1f - t)
            targets.add((cx - half) to y)
            targets.add((cx + half) to y)
        }
        // Inner circular ring.
        val innerR = radius * 0.55f
        for (i in 0 until 260) {
            val a = (Math.PI * 2.0 * i / 260.0)
            targets.add(
                (cx + innerR * cos(a).toFloat()) to
                    (topCy + innerR * sin(a).toFloat())
            )
        }

        // Cap count for older devices.
        val selected = if (targets.size > 1450) targets.shuffled(random).take(1450) else targets
        val cloudCx = cx
        val cloudCy = height * 0.48f
        for ((tx, ty) in selected) {
            val angle = random.nextDouble() * Math.PI * 2.0
            val dist = 80f + random.nextFloat() * min(width, height) * 0.34f
            val sx = cloudCx + cos(angle).toFloat() * dist
            val sy = cloudCy + sin(angle).toFloat() * dist
            particles.add(
                Particle(
                    sx = sx,
                    sy = sy,
                    tx = tx,
                    ty = ty,
                    size = 1.3f + random.nextFloat() * 3.4f,
                    phase = random.nextFloat() * 6.28f,
                    drift = 5f + random.nextFloat() * 18f
                )
            )
        }

        start = SystemClock.uptimeMillis()
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawColor(Color.rgb(7, 9, 12))
        if (!built) return

        val elapsed = SystemClock.uptimeMillis() - start
        val p = (elapsed.toFloat() / total).coerceIn(0f, 1f)

        drawAmbient(canvas, p)
        drawParticles(canvas, elapsed)
        drawTarget(canvas, elapsed, p)

        if (elapsed < total) {
            postInvalidateOnAnimation()
        } else if (!finished) {
            finished = true
            postDelayed({ onFinished() }, 80L)
        }
    }

    private fun drawParticles(canvas: Canvas, elapsed: Long) {
        val t = elapsed.toFloat()
        val formation = easeInOut((elapsed / formationEnd.toFloat()).coerceIn(0f, 1f))
        val spin = if (elapsed <= formationEnd) 0f else {
            easeInOut(((elapsed - formationEnd) / (spinEnd - formationEnd).toFloat()).coerceIn(0f, 1f))
        }
        val settle = if (elapsed <= spinEnd) 0f else easeOut(((elapsed - spinEnd) / (total - spinEnd).toFloat()).coerceIn(0f, 1f))

        val logoCx = width / 2f
        val startCy = height * 0.34f
        val targetCy = height * 0.61f
        val drop = targetCy - startCy

        for (part in particles) {
            var x = lerp(part.sx, part.tx, formation)
            var y = lerp(part.sy, part.ty, formation)

            if (elapsed > formationEnd) {
                val a = (spin * Math.PI * 2.35).toFloat()
                val dx = x - logoCx
                val dy = y - startCy
                val rx = dx * cos(a) - dy * sin(a)
                val ry = dx * sin(a) + dy * cos(a)
                x = logoCx + rx
                y = startCy + ry
            }

            if (elapsed > formationEnd) {
                y += drop * spin
            }
            if (elapsed > spinEnd) {
                // Settle exactly on the glowing target after the spin.
                y = lerp(y, y - drop * 0.0f, settle)
            }

            val alpha = when {
                elapsed < 500L -> (elapsed / 500f).coerceIn(0f, 1f)
                else -> 1f
            }
            val pulse = 0.78f + 0.22f * sin(t / 115f + part.phase).toFloat()
            paint.color = Color.argb((alpha * 255 * pulse).toInt().coerceIn(0, 255), 255, 215, 35)
            paint.style = Paint.Style.FILL
            canvas.drawCircle(x, y, part.size, paint)
        }
    }

    private fun drawTarget(canvas: Canvas, elapsed: Long, p: Float) {
        if (elapsed < formationEnd + 450L) return
        val q = ((elapsed - formationEnd) / (total - formationEnd).toFloat()).coerceIn(0f, 1f)
        val cy = height * 0.61f
        val cx = width / 2f
        val pulse = 1f + 0.18f * sin(elapsed / 130f).toFloat()
        glow.color = Color.argb((100 * (0.25f + q * 0.75f)).toInt(), 255, 215, 35)
        glow.style = Paint.Style.STROKE
        glow.strokeWidth = 3f
        canvas.drawOval(cx - 65f * pulse, cy + 135f, cx + 65f * pulse, cy + 162f, glow)
        glow.strokeWidth = 1.5f
        canvas.drawOval(cx - 38f * pulse, cy + 141f, cx + 38f * pulse, cy + 156f, glow)
    }

    private fun drawAmbient(canvas: Canvas, p: Float) {
        val cx = width / 2f
        val cy = height * 0.44f
        glow.style = Paint.Style.FILL
        glow.color = Color.argb((25 + p * 18).toInt(), 255, 210, 20)
        canvas.drawCircle(cx, cy, 95f + p * 35f, glow)
    }

    private fun easeInOut(x: Float): Float = x * x * (3f - 2f * x)
    private fun easeOut(x: Float): Float = 1f - (1f - x) * (1f - x)
    private fun lerp(a: Float, b: Float, t: Float): Float = a + (b - a) * t
}
