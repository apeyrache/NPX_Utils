% Transform Kilosort output (in samples) in seconds
%
%  USAGE
%
%    NPX_NPY2Seconds()
%
%    Dependencies:  NPY-matlab and NPX_ReadMeta


% Copyright (C) 2021 Adrien Peyrache
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.

function NPX_NPY2Seconds(fbasename)

[dir,fname,~] = fileparts(fbasename);
if isempty(dir)
    dir =pwd;
end
if ~exist(fullfile(dir,[fname, '.meta']),'file')
    error([dir filesep fname, '.meta does not exist'])
end

meta = NPX_ReadMeta(fbasename,pwd);
fs = meta.imSampRate;
fs = str2num(fs);
spk_samp = readNPY('spike_times.npy');
spk_sec = double(spk_samp)/fs;
writeNPY(spk_sec,'spike_seconds.npy');



