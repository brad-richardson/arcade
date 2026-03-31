## AudioEffectFilter <- AudioEffect

A "filter" controls the gain of frequencies, using `cutoff_hz` as a frequency threshold. Filters can help to give room for each sound, and create interesting effects. There are different types of filter that inherit this class: Shelf filters: AudioEffectLowShelfFilter and AudioEffectHighShelfFilter Band-pass and notch filters: AudioEffectBandPassFilter, AudioEffectBandLimitFilter, and AudioEffectNotchFilter Low/high-pass filters: AudioEffectLowPassFilter and AudioEffectHighPassFilter

**Props:**
- cutoff_hz: float = 2000.0
- db: int (AudioEffectFilter.FilterDB) = 0
- gain: float = 1.0
- resonance: float = 0.5

**Enums:**
**FilterDB:** FILTER_6DB=0, FILTER_12DB=1, FILTER_18DB=2, FILTER_24DB=3

