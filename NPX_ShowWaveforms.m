load Analysis/Waveforms

cellIx = 50; %or whatever else

wave = meanWaveforms{cellIx};
waveL = wave(1:2:end,:);
waveR = wave(2:2:end,:);
t = size(waveR,2);
figure(1),clf
imagesc([waveL waveR])

colormap bone