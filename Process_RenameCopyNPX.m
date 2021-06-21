function recList = Process_RenameCopyNPX(fbasename,varargin)

% Preprocess raw SpikeGLX data file and folders. Multiple folders are renamed
% with number (instead of _g*) and *imec* are remoed. Assuming only one
% NeuroPix probe
%
%  USAGE
%
%    recList = Process_RenameCopyNPX(fbasename,<optional> newfbasename)
%
%    INPUT:
%    fbasename      the base name of the Intan recording (everything until
%                   the last '_g*', e.g. 'MouseXXX-YYMMDD')
%    newfbsaneme    change the file base name
%
%    OUTPUT:
%    recList        a cell array containing the names of the new folders
%
%    Dependencies:  none

% Copyright (C) 2021 Adrien Peyrache
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.

processName = [];

%Parameters:
eraseDir    = 1; %Remove original directories
%cpVideo     = 1; %Move and rename video files from original folders
%videoExt    = {'avi';'mpg';'mov'};

if ~isempty(varargin)
    newfbasename = varargin{1};
    if length(varargin)>1
        cpVideo = varargin{2};
    end
else
    newfbasename = fbasename;
end

%To access NPX_ReadMeta
addpath('/home/adrien/Toolbox/Neuropixel/SpikeGLX_Datafile_Tools/')

try
    
folders = dir([fbasename '_g*']);
nRec = 0;
recName = [];
for ii=1:length(folders)
    if folders(ii).isdir
        recName = [recName;{folders(ii).name}];
    end
end
nRec = length(recName);

if nRec == 0
    error('No data fodlers detected')
end

processName = 'listing folders';

recList = cell(nRec,1);
durations = [];

for ii=1:nRec
    disp(ii)
    nber = num2str(ii-1);
    
    newFbase = [newfbasename '-' nber];
    recList{ii} = newFbase;
    
    processName = 'creating destination folder';
    if ~exist(newFbase,'dir')
        mkdir(newFbase)
    end
    
    keyboard
    processName = 'create Epoch_TS.csv';
    dataDir = fullfile(recName{ii},[recName{ii} '_imec0']);
    fname = [recName{ii} '_t0.imec0.ap.bin'];
    if exist(fullfile(dataDir,fname), 'file')
        meta = NPX_ReadMeta(fname,dataDir);
        durations = [durations;str2num(meta.fileTimeSecs)];
    else
        error(['Bin file ' fname ' does not exist in ' dataDir]);
    end
    
    fprintf([newFbase '.bin\n'])
    processName = 'moving Spike Data';
    movefile(fullfile(dataDir,fname),[newFbase '.bin'],'f')
    
    fname = [recName{ii} '_t0.imec0.ap.meta'];
    if exist(fullfile(dataDir,fname),'file')
        movefile(fullfile(dataDir,fname),[newFbase '.meta'],'f')
    else
        warning(['Meta file ' fname ' does not exist'])
    end
    
%     processName = 'moving csv file';
%     csvFile = dir(fullfile(recName{ii}, '*.csv'));
%     if ~isempty(csvFile)
%         fname = fullfile(recName{ii},csvFile.name);
%         targetFile = fullfile(pwd, [newFbase, '.csv']);
%         movefile(fname,targetFile,'f');
%     else
%         warning(['Found no csv file for ' recName{ii}]);
%     end
%     
%     if eraseDir
%         dirContent = dir(fullfile(recName{ii},'*'));
%         if ~isempty(dirContent)
%             answer = input('Original directory not empty, are you sure you want to remove it? [Y/N]','s');
%             if strcmpi(answer,'y')
%                 try
%                     rmdir(recName{ii},'s')
%                 catch
%                     keyboard
%                 end
%             end
%         end
%     end

end

%% Writing epochs.csv
epochs = zeros(nRec, 2);
start = 0;
%if length(durations) == nRec
for ii=1:nRec
    epochs(ii,1) = start;
    start = start + durations(ii);
    epochs(ii,2) = start;
end
dlmwrite('Epoch_TS.csv',epochs,'precision','%.6f');

%end

catch
    warning(lasterr)
    warning(['Error while ' processName ])
 
end