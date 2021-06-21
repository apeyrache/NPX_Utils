% Load Phy results and create save spikes with TSToolbox. 
%
%  USAGE
%
%    NPX_MakeSpike(filebasename)
%
%    filebasename   self-explanatory
%
%    Dependencies:  TSToolbox

% Copyright (C) 2021 Adrien Peyrache
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.

%% Parameters


function NPX_MakeSpike(mergename)

%Add to path.
addpath(genpath('~/Toolbox/Neuropixel/npy-matlab'));

spikeSecF = 'spike_seconds.npy';

if ~exist(spikeSecF,'file')
    NPX_NPY2Seconds(mergename);
end

spk_t = readNPY(spikeSecF);
spk_clusters = readNPY('spike_clusters.npy');
spk_info = tdfread('cluster_info.tsv');

spk_cluIx = spk_info.id;
spk_label = spk_info.group;

S = {};
cellIx = [];
depth = [];

for s=2:length(spk_cluIx) %skip the first value, table description
    if strcmp(spk_label(s,:),'good ') || strcmp(spk_label(s,:),'     ')
        t = spk_t(spk_clusters == spk_cluIx(s));
        S = [S;{ts(double(t))}];
        cellIx = [cellIx;s];
        depth = [depth;spk_info.depth(s)];
    end
end

S = tsdArray(S);

if ~exist('Analysis','dir')
    mkdir('Analysis')
end

save(fullfile('Analysis','SpikeData.mat'),'S','cellIx','depth');


