% =========================================================================
% Part 1: Smartphone-Based Heart Rate Monitoring
% =========================================================================

clear; clc; close all;

%% Step 1: Read video, convert to grayscale, extract mean color value
videoFile = 'heart_rate_video.mov'; % Ensure your video filename matches
videoObj = VideoReader(videoFile);

frameRate = videoObj.FrameRate; % Typically ~30 Hz
numFrames = floor(videoObj.Duration * frameRate);
meanIntensities = zeros(1, numFrames);

frameCount = 0;
while hasFrame(videoObj)
    frameCount = frameCount + 1;
    frame = readFrame(videoObj);
    
    % Checkpoint 1: rgb2gray and mean intensity
    grayFrame = rgb2gray(frame);
    meanIntensities(frameCount) = mean(grayFrame(:));
end

meanIntensities = meanIntensities(1:frameCount);
sampleVector = 1:length(meanIntensities); % Sample indices (# samples)

%% Step 2: Subtract DC component and apply zero-phase highpass filter
% Checkpoint 2: DC removal
dcRemoved = meanIntensities - mean(meanIntensities);

% Highpass filter with cutoff at ~0.7 Hz (42 bpm baseline cutoff)
cutoffFreq = 0.7; 
[b, a] = butter(3, cutoffFreq / (frameRate / 2), 'high');
filteredSignal = filtfilt(b, a, dcRemoved);

%% Step 3: Apply FFT & search range 60-100 bpm (1.0 Hz - 1.67 Hz)
% Checkpoint 3: FFT Analysis
N = length(filteredSignal);
fftResult = abs(fft(filteredSignal));
fftResult = fftResult(1:floor(N/2)+1); % Single-sided spectrum

freqBins = (0:floor(N/2)) * (frameRate / N); % Frequency vector (Hz)

% Bin range corresponding to normal heart rate: 60 - 100 bpm (1.0 Hz to 1.67 Hz)
minHz = 60 / 60;   % 1.00 Hz (60 bpm)
maxHz = 100 / 60;  % 1.67 Hz (100 bpm)

validIndices = find(freqBins >= minHz & freqBins <= maxHz);
searchFFT = fftResult(validIndices);
searchFreqs = freqBins(validIndices);

% Find true maximum peak within valid 60-100 bpm search range
[maxVal, maxIdx] = max(searchFFT);
peakFreqHz = searchFreqs(maxIdx);

% Estimated heart rate in BPM from FFT peak
estimatedBpm = peakFreqHz * 60;

fprintf('FFT Estimated HR: %.2f Hz (%.2f BPM)\n', peakFreqHz, estimatedBpm);

%% Step 4: Peak finding with MinPeakDistance heuristic & Prominence
% Checkpoint 4: MinPeakDistance in samples = frameRate / peakFreqHz
minPeakDistanceSamples = round(frameRate / peakFreqHz);
fprintf('MinPeakDistance: %d samples\n', minPeakDistanceSamples);

% Detect heartbeat peaks using MinPeakDistance + Prominence filter to ignore noise
[peaks, peakLocs] = findpeaks(filteredSignal, ...
    'MinPeakDistance', round(minPeakDistanceSamples * 0.85), ...
    'MinPeakProminence', 0.4 * std(filteredSignal));

% Compute time-domain heart rate from inter-peak intervals (IBI)
if length(peakLocs) > 1
    sampleIntervals = diff(peakLocs);
    timeIntervals = sampleIntervals / frameRate;
    computedBpm = 60 / mean(timeIntervals);
else
    computedBpm = estimatedBpm;
end

fprintf('Computed Time-Domain HR: %.2f BPM\n', computedBpm);

%% Step 5: Deliverables Plotting
% Checkpoint 5: Generate required assignment plots

% Deliverable 1: Plot of FFT with estimated heart rate in Hz
figure('Name', 'FFT Spectrum', 'NumberTitle', 'off');
plot(freqBins, fftResult, 'b-', 'LineWidth', 1.5);
hold on;
plot(peakFreqHz, maxVal, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
grid on;
xlim([0.5 2.5]);
xlabel('Frequency (Hz)');
ylabel('Amplitude / Magnitude');
title(sprintf('FFT Spectrum of PPG Signal (Estimated HR: %.2f Hz)', peakFreqHz));
legend('FFT Spectrum', sprintf('Peak Frequency (%.2f Hz)', peakFreqHz), 'Location', 'northeast');

% Deliverable 2: Plot of time-domain signal (# samples on X-axis) with selected peaks & HR title
figure('Name', 'Time-Domain Signal & Heartbeat Peaks', 'NumberTitle', 'off');
plot(sampleVector, filteredSignal, 'b-', 'LineWidth', 1.2);
hold on;
plot(peakLocs, peaks, 'r^', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
grid on;
xlabel('# samples');
ylabel('Amplitude');
title(sprintf('HR:%.0fbpm', computedBpm));
legend('Filtered PPG Signal', 'Detected Heartbeat Peaks', 'Location', 'northeast');