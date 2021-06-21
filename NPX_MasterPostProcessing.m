% This scripts reads output of Kilosort after manual curation with Phy

% Note: Position file should be mergename_X.csv where mergename is the
% session name (better if the name of the folder as wee) and X is the
% recording number in base 0! I.ee. if explo is 2nd recording, X='1';


[~,mergename,~ ] = fileparts(pwd);

% Create a npy file with spike_seconds.npy with spikes in seconds
NPX_NPY2Seconds(mergename)

% Create a TSToolbox spike array
NPX_MakeSpike(mergename)

% Extract waveforms and save them in Waveforms.mat
NPX_GetWaveforms(mergename)

% Extract position
exploEp = input('which exploration recording (starting at 0!!)', 's');
NPX_MakePos(mergename,str2num(exploEp))
