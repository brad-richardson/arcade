## AudioEffectSpectrumAnalyzer <- AudioEffect

Calculates a Fourier Transform of the audio signal. This effect does not alter the audio. Can be used for creating real-time audio visualizations, like a spectrogram. This resource configures an AudioEffectSpectrumAnalyzerInstance, which performs the actual analysis at runtime. An instance should be obtained with `AudioServer.get_bus_effect_instance` to make use of this effect.

**Props:**
- buffer_length: float = 2.0
- fft_size: int (AudioEffectSpectrumAnalyzer.FFTSize) = 2

**Enums:**
**FFTSize:** FFT_SIZE_256=0, FFT_SIZE_512=1, FFT_SIZE_1024=2, FFT_SIZE_2048=3, FFT_SIZE_4096=4, FFT_SIZE_MAX=5

