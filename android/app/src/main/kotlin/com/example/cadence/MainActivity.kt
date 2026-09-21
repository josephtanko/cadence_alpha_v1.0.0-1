package com.example.cadence

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.nio.ByteOrder

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.cadence/bpm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "analyzeBpm" || call.method == "calculateBpm") {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    try {
                        val bpm = decodeAndCalculateBpm(filePath)
                        result.success(bpm)
                    } catch (e: Exception) {
                        result.error("AUDIO_ERROR", e.localizedMessage, null)
                    }
                } else {
                    result.error("INVALID_PATH", "File path was null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun decodeAndCalculateBpm(filePath: String): Double {
        val extractor = MediaExtractor()
        var codec: MediaCodec? = null

        try {
            extractor.setDataSource(filePath)
            var trackIndex = -1
            var format: MediaFormat? = null

            for (i in 0 until extractor.trackCount) {
                val trackFormat = extractor.getTrackFormat(i)
                val mime = trackFormat.getString(MediaFormat.KEY_MIME)
                if (mime != null && mime.startsWith("audio/")) {
                    trackIndex = i
                    format = trackFormat
                    break
                }
            }

            if (trackIndex < 0 || format == null) return 0.0

            extractor.selectTrack(trackIndex)
            val mime = format.getString(MediaFormat.KEY_MIME) ?: return 0.0
            val sampleRate = if (format.containsKey(MediaFormat.KEY_SAMPLE_RATE)) format.getInteger(MediaFormat.KEY_SAMPLE_RATE) else 44100
            val channelCount = if (format.containsKey(MediaFormat.KEY_CHANNEL_COUNT)) format.getInteger(MediaFormat.KEY_CHANNEL_COUNT) else 2

            codec = MediaCodec.createDecoderByType(mime)
            codec.configure(format, null, null, 0)
            codec.start()

            val info = MediaCodec.BufferInfo()
            var isEOS = false

            val downsampleFactor = (sampleRate / 11025).coerceAtLeast(1)
            val energyList = ArrayList<Float>()

            var sampleCounter = 0
            var currentChunkEnergy = 0f
            var samplesInChunk = 0

            while (!isEOS) {
                val inIndex = codec.dequeueInputBuffer(10000)
                if (inIndex >= 0) {
                    val buffer = codec.getInputBuffer(inIndex)
                    if (buffer != null) {
                        val sampleSize = extractor.readSampleData(buffer, 0)
                        if (sampleSize < 0) {
                            codec.queueInputBuffer(inIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            isEOS = true
                        } else {
                            codec.queueInputBuffer(inIndex, 0, sampleSize, extractor.sampleTime, 0)
                            extractor.advance()
                        }
                    }
                }

                val outIndex = codec.dequeueOutputBuffer(info, 10000)
                if (outIndex >= 0) {
                    val outBuffer = codec.getOutputBuffer(outIndex)
                    if (outBuffer != null && info.size > 0) {
                        outBuffer.position(info.offset)
                        outBuffer.limit(info.offset + info.size)

                        val shortBuffer = outBuffer.asShortBuffer()
                        while (shortBuffer.hasRemaining()) {
                            val sample = shortBuffer.get().toFloat() / 32768.0f
                            sampleCounter++

                            if (sampleCounter % (channelCount * downsampleFactor) == 0) {
                                currentChunkEnergy += sample * sample
                                samplesInChunk++

                                if (samplesInChunk >= 512) {
                                    energyList.add(currentChunkEnergy / samplesInChunk)
                                    currentChunkEnergy = 0f
                                    samplesInChunk = 0
                                }
                            }
                        }
                    }
                    codec.releaseOutputBuffer(outIndex, false)
                }
            }

            return computeBpmFromEnergy(energyList, 11025.0 / 512.0)
        } finally {
            try {
                codec?.stop()
                codec?.release()
            } catch (_: Exception) {}
            extractor.release()
        }
    }

    private fun computeBpmFromEnergy(energyList: List<Float>, framesPerSecond: Double): Double {
        if (energyList.isEmpty()) return 0.0

        val minLag = (framesPerSecond * 60.0 / 180.0).toInt().coerceAtLeast(1)
        val maxLag = (framesPerSecond * 60.0 / 60.0).toInt().coerceAtMost(energyList.size - 1)

        var maxCorr = 0.0
        var bestLag = minLag

        for (lag in minLag..maxLag) {
            var corr = 0.0
            for (i in 0 until energyList.size - lag) {
                corr += energyList[i] * energyList[i + lag]
            }
            if (corr > maxCorr) {
                maxCorr = corr
                bestLag = lag
            }
        }

        return if (bestLag > 0) (60.0 * framesPerSecond) / bestLag else 0.0
    }
}