% Processes data from SpikeGLX & Motive, and create a position file (csv)
% in the same time base as the ephys rec. 
% It assumes that extracted Motive files are called filebasename_xx.csv where xx
% corrresponds to the epoch number in Epoch_TS.csv.
%
% !!!CAUTION!!! xx is in base 0, for max compatibility with Python scripts
%
%  USAGE
%
%    NPX_MakePos(filebasename,exploEp)
%
%    filebasename   self-explanatory
%    exploEp        the recording sessions (i.e. bin / g* files in
%                   SpikeGLX) to consider for motion tracking !!IN BASE 0!!
%
%    Dependencies:  ProcessMotiveData

% Copyright (C) 2021 Adrien Peyrache
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.

%% Parameters


function NPX_MakePos(mergename,exploEp)

%Add to path.
addpath('~/Toolbox/ProcessMotiveData');

%Before going further, check that there are Motive position files,
%othewise, the rest is pointless

motiveFiles = dir([mergename '_*.csv']);

if isempty(motiveFiles)
    error('No Motive tracking files can be found')
end

% Load NIDQ dat file
fid = fopen([mergename '.nidq.dat']);
nidqDat = fread(fid,[2 Inf],'uint8');
fclose(fid);

% Load NIDQ meta file
metaF = [mergename '.nidq.meta'];
if ~exist(metaF,'file')
    warning('No NIDQ meta file, assumes FS=25kHz');
    fs = 25000;
else
    meta = NPX_ReadMeta(metaF, pwd);
    fs = str2num(meta.niSampRate);
end

%looking for TTL pulses
idx = find(nidqDat(1,:)>60);

%keep only rise time
dIdx = diff(idx);
jumpidx = [1 find(dIdx>1)+1];

% Define times
t = [0:size(nidqDat,2)-1]/fs;

% Restrict it to TTL rise times
motiveTimes = t(idx(jumpidx));

% Now we proceed epoch by epoch, as defined in Epoch_TS.csv and exploEp
% in argument

% first, check whether 'Epoch_TS.csv' exists or not
epochF = 'Epoch_TS.csv';
if ~exist(epochF,'file')
    warning(['No ' epochF ' file, consider the whole recording']);
    epochT = [t(0) t(end)];
else
    epochT = csvread(epochF);
end

% Easier to separate start and end times.
stEp = epochT(:,1);
enEp = epochT(:,2);

%Declare variables
ang = [];
X = [];
Y = [];

for ii=1:length(exploEp)

    motiveF = [mergename '_' num2str(exploEp(ii)) '.csv'];
    if ~exist(motiveF,'file')
        error(['No Motive file ' motiveF ', make sure you use a base 0'])
    end
    
    motiveDat = csvread(motiveF,7,0);

    %Restrict NIDQ to epoch
    timeIx = motiveTimes > stEp(exploEp(ii)+1) & motiveTimes < enEp(exploEp(ii)+1);
    motiveT = motiveTimes(timeIx);
    
    lD = size(motiveDat,1);
    lT = length(motiveT);
    if lD<lT
        fprintf('Skipping last Motive TTLs\n')
        motiveT(lD+1:end) = [];
    elseif lD>lT
        fprintf('More Motive data than TTLs??? Unusual!')
        keyboard
    end
    
    ang_tmp = [motiveT(:),motiveDat(:,5)];
    
    ang = [ang;ang_tmp];
    X = [X;motiveDat(:,6)];
    Y = [Y;motiveDat(:,7)];
    
end

t = ang(:,1);

angClean = CleanMotiveAng(t, deg2rad(ang(:,2)));
ix = ~isnan(angClean);
goodTrackingEp = thresholdIntervals(tsd(t,double(ix)),0.5,'Direction','Above');

if ~exist('Analysis','dir')
    mkdir('Analysis')
end

%For Linux users
csvwrite(fullfile('Analysis','AnglePosition.csv'),[t angClean X Y])
csvwrite(fullfile('Analysis','GoodTracking.csv'),[Start(goodTrackingEp) End(goodTrackingEp)])

%For Matlab users
ang = tsd(t,angClean);
X = tsd(t,X);
Y = tsd(t,Y);
save(fullfile('Analysis','Angle.mat'),'ang','goodTrackingEp');
save(fullfile('Analysis','Position.mat'),'X','Y','goodTrackingEp');

