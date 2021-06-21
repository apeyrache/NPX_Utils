% This scripts preprocesses Neuropixel data acquired with SpikeGLX and
% runs Kilosort 2.

function NPX_MasterPreProcessing(fbasename,mergename)

[~,mergename,~] = fileparts(pwd);
destDir = '/mnt/Savitar/Neuropixel/';

Process_NPX2ConcatenateDat(mergename,varargin)

rootZ = fullfile(destDir,mergename); % the raw data binary file is in this folder
rootH = '/mnt/SpeedyGonzales/tmp/'; % path to temporary binary file (same size as data, should be on fast SSD)

addpath(genpath('~/Toolbox/
