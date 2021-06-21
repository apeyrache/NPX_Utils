function Process_NPX2ConcatenateDat(fbasename,varargin)

% Processes raw data from SpikeGLX, renames files and folders, concatenates
% dat files (if multiple). Must be called from the folder where all
% recording folders are stored (indexed by _g1,2, and assumes only t0)
%
%  USAGE
%
%    Process_NPX2ConcatenateDat(filebasename,<optional>mergename)
%
%    filebasename   a cell array of filebasenames (with or without '.dat' extenstion)
%    mergename      final concatenated file and folder name (if omitted,
%                   mergename will be the name of the current folder.


% Copyright (C) 2021 Adrien Peyrache
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.

%% Parameters


if isempty(varargin)
    [~,mergename,~] = fileparts(pwd);
else
    mergename = varargin{1};
    if length(varargin)>1
        destDir = varargin{2};
    else
        destDir = pwd;
    end
end

fprintf('Processing %s...\n',mergename);

%%Create destination folder
if ~exist(destDir,'dir')
    error(['destination folder ' destDir ' does not exist'])
end
destDir = fullfile(destDir,mergename);

if ~exist(destDir,'dir')
    mkdir(destDir)
end

%% Check folders, compute duration
folders = dir([fbasename '_g*']);

recName = [];
for ii=1:length(folders)
    if folders(ii).isdir
        recName = [recName;{folders(ii).name}];
    end
end


fprintf('Creating Epoch_TS.csv\n',mergename);
nRec = length(recName);
epochs = zeros(nRec, 2);
start = 0;

for ii=1:nRec

    fname = [recName{ii} '_t0.imec0.ap.bin'];
    if exist(fullfile(recName{ii},fname), 'file')
        meta = NPX_ReadMeta(fname,recName{ii});
        recDuration = str2num(meta.fileTimeSecs);
    else
        error(['Bin file ' fname ' does not exist in ' dataDir]);
    end
    epochs(ii,1) = start;
    start = start + recDuration;
    epochs(ii,2) = start;
end
dlmwrite(fullfile(destDir,'Epoch_TS.csv'),epochs,'precision','%.6f');

%% Concatenate Data for Kilosort (or others)

% Concatenating NPX bin files
fprintf('Concatening NPX bin files\n',mergename);

if nRec>1
    cmdline = 'cat ';
    for ii=1:nRec-1
        cmdline = [cmdline fullfile(recName{ii}, [recName{ii} '_t0.imec0.ap.bin '])];
    end
    cmdline = [cmdline fullfile(recName{ii+1},[recName{ii+1} '_t0.imec0.ap.bin']) ' > ' fullfile(destDir,[mergename '.dat'])];
else    
    cmdline = ['mv ' fullfile(recName{ii},[recName{ii} '_t0.imec0.ap.bin ']) fullfile(destDir,[mergename '.dat'])];
end
fprintf('Launch command %s\n\n',cmdline)
system(cmdline);

%% Concatenating NIDQ bin files
fprintf('Concatening NIDQ bin files\n',mergename);

if nRec>1
    cmdline = 'cat ';
    for ii=1:nRec-1
        cmdline = [cmdline fullfile(recName{ii}, [recName{ii} '_t0.nidq.bin '])];
    end
    cmdline = [cmdline fullfile(recName{ii+1},[recName{ii+1} '_t0.nidq.bin']) ' > ' fullfile(destDir,[mergename '.nidq.dat'])];
else    
    cmdline = ['mv ' fullfile(recName{ii},[recName{ii} '_t0.nidq.bin ']) fullfile(destDir,[mergename '.nidq.dat'])];
end
fprintf('Launch command %s\n\n',cmdline)
system(cmdline);

%% Copy files to new final directory
%mkdir(mergename);

%% Moving xml and dat file
%movefile([mergename '.bin'],mergename,'f')
%copyfile([recList{1} '.meta'],[mergename '.meta'],'f')
%movefile([mergename '.meta'],mergename,'f')

% %% Moving position csv file if any exists and renaming it for python (starting at 0)
% nRec = length(recList);
% for ii=1:nRec
%     fname = [recList{ii} '.csv'];
%     if exist(fname, 'file')
%         targetFile = fullfile(pwd, mergename, [mergename '_' num2str(ii-1) '.csv']);
%         movefile(fname, targetFile);
%     end
% end




        


