## AudioEffectLimiter <- AudioEffect

A "limiter" is an audio effect designed to stop audio signals from exceeding a specified volume threshold level, and usually works by decreasing the volume or soft-clipping the audio. Adding one in the Master bus is always recommended to prevent clipping when the volume goes above 0 dB. Soft clipping starts to decrease the peaks a little below the volume threshold level and progressively increases its effect as the input volume increases such that the threshold level is never exceeded. If hard clipping is desired, consider `AudioEffectDistortion.MODE_CLIP`.

**Props:**
- ceiling_db: float = -0.1
- soft_clip_db: float = 2.0
- soft_clip_ratio: float = 10.0
- threshold_db: float = 0.0

