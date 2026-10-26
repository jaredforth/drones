package dev.jaredforth.drones

import android.app.Activity
import android.content.res.ColorStateList
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Bundle
import android.widget.Button
import android.widget.GridLayout
import kotlin.math.PI
import kotlin.math.pow
import kotlin.math.sin

// Calibration knob: reference pitch for A4.
const val A4 = 440.0
const val RATE = 48000
val IDLE: ColorStateList = ColorStateList.valueOf(0xFF555555.toInt())
val ACTIVE: ColorStateList = ColorStateList.valueOf(0xFFFF9800.toInt())
val KEYS = listOf("C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B")

// Semitone 0 = C. Octave 2 (C2 ≈ 65 Hz .. B2 ≈ 123 Hz).
fun droneFreq(semitone: Int) = A4 * 2.0.pow((semitone - 9) / 12.0 - 2)

class MainActivity : Activity() {
    private val drone = Drone().apply { start() }
    private var selected: Button? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val grid = GridLayout(this).apply { columnCount = 3; fitsSystemWindows = true }
        KEYS.forEachIndexed { i, name ->
            val b = Button(this).apply { text = name; textSize = 28f; backgroundTintList = IDLE }
            b.setOnClickListener { toggle(b, i) }
            val fill = GridLayout.spec(GridLayout.UNDEFINED, 1f)
            grid.addView(b, GridLayout.LayoutParams(fill, fill).apply { width = 0; height = 0 })
        }
        setContentView(grid)
    }

    private fun toggle(b: Button, semitone: Int) {
        selected?.backgroundTintList = IDLE
        if (selected == b) {
            selected = null
            drone.silence()
            return
        }
        selected = b
        b.backgroundTintList = ACTIVE
        drone.play(droneFreq(semitone))
    }

    override fun onDestroy() {
        drone.running = false
        super.onDestroy()
    }
}

// Streams a sine + 2 harmonics (so phone speakers can reproduce the low fundamental).
// Amplitude is smoothed per sample so start/stop doesn't click.
class Drone : Thread() {
    @Volatile private var freq = 0.0
    @Volatile private var targetAmp = 0.0
    @Volatile var running = true

    fun play(f: Double) { freq = f; targetAmp = 0.5 }
    fun silence() { targetAmp = 0.0 }

    override fun run() {
        val track = AudioTrack.Builder()
            .setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build())
            .setAudioFormat(AudioFormat.Builder()
                .setSampleRate(RATE)
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                .build())
            // Generous buffer: latency doesn't matter for a drone, underruns do.
            .setBufferSizeInBytes(4 * AudioTrack.getMinBufferSize(RATE, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT))
            .build()
        track.play()
        val buf = ShortArray(1024)
        var phase = 0.0
        var amp = 0.0
        while (running) {
            for (i in buf.indices) {
                amp += (targetAmp - amp) * 0.0005
                phase = (phase + freq / RATE) % 1.0
                val x = 2 * PI * phase
                val s = (sin(x) + 0.5 * sin(2 * x) + 0.25 * sin(3 * x)) / 1.75
                buf[i] = (amp * s * Short.MAX_VALUE).toInt().toShort()
            }
            track.write(buf, 0, buf.size)
        }
        track.release()
    }
}
