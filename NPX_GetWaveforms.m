% LOAD_SPK_FROM_DAT     and detrend
%
% CALL                  SPK = LOAD_SPK_FROM_DAT( FILEBASE, SHANKNUM, CLUNUM )
%
% GETS                  FILEBASE    dat file assumed to be FILEBASE.dat
%                       SHAKNUM     
%                       CLUNUM      clu number/list of spike times/empty (all spikes in res file)
%                       SPKSUFFIX   {'spr'}, 'spk'; if empty - saves temporarily to PWD and deletes upon exist
%                       CLUSUFFIX   {'clu'}
%
% REQUIRES              dat, xml file
%                       res file/list of spike times
%                       for loading spikes of a specific cluster - clu file
%
% DOES                  -determines the parameters from the xml file;
%                       -determines the spike times from the res/clu files
%                       or from the list given in CLUNUM (at the data
%                       sampling frequency);
%                       -loads the spikes at these times
%                       -removes DC and trends
%                       -(optional) saves the spikes to an spk/spr file (spikes-raw)
%                       -(optional) loads those spikes
%
% CALLS                 LOADXML, READBIN, MYDETREND
%
% NOTES                 1. uses a procesing buffer of 1000 spikes
%                       2. channel order is kept as in xml file


% 11-feb-20 subsample option added (default = 1000 samples)
% 28-apr-11 ES, 10-june-2015 Adrien Peyrache. change nSample and nPeak
% options

% revisions
% 02-may-11 case of zero spikes handled


function wavef = NPX_GetWaveforms(filebase, NSAMPLES,PEAKSAMPLE)

% arguments
nargs = nargin;
if nargs < 2, nsamples = 96; end % 'spk'
if nargs < 3, peaksample = 24; end % 'clc' 

% constants
source = 'int16'; 
target = 'single';
blocksize = 100000;   % spikes; e.g. 10 x 32 x 100000 x 4 bytes = 12.5 MB
subsize = 1000; % size of sub-sample if subsample is set to 1
totchans = 385; % should be read from META file...

chanIx = [-8:9]; %Index relative to position of peak waveform
nchans = length(chanIx); %number of channels around peak waveform

% file names
datfname = sprintf( '%s.dat', filebase );
if ~exist(datfname,'file')
    datfname = sprintf( '%s.bin', filebase );
end
if ~exist(datfname,'file')
    error('No dat/bin file!')
end

spk_samp = readNPY('spike_times.npy');
spk_clusters = readNPY('spike_clusters.npy');
spk_info = tdfread('cluster_info.tsv');

spk_cluIx = spk_info.id;
spk_label = spk_info.group;

meanWaveF = {};

for s=2:length(spk_cluIx) %skip the first value, table description
    if strcmp(spk_label(s,:),'good ') || strcmp(spk_label(s,:),'     ')
        tim = spk_samp(spk_clusters == spk_cluIx(s));
        tim = double(tim);
        depth = spk_info.depth(s);
        
        % output
        wavef = [];
        
        nspikes = length(tim);
        
        %We select 1000 random spikes
        if length(tim) > subsize
            tim = randsample(tim,subsize);
            tim = sort(tim);
            nspikesSub = size(tim,1); 
        else
            nspikesSub = nspikes;
        end   
        
        % We determine the channels around the peak waveform
        % We assume 2 channels at same depth ber row on the NPX probe
        % And 20um separation
        % We keep 18 channels, that is 4 rows above and below the cell's
        % depth (2 channels per row);
        
        chans = chanIx+(depth/10-1);
        
        if chans(1)<1
            chans = chans - chans(1) + 1;
        elseif chans(end)>totchans
            chans = chans - (chans(end) - totchans);
        end
        
        periods = tim * [ 1 1 ] + ones( nspikesSub, 1 ) * [ -peaksample + 1 nsamples - peaksample ];

        % work in blocks
        t0 = clock;
        fprintf( 1, 'cluster %d: %d spikes out of %d spikes', s, nspikesSub, nspikes )
        nperiods = size( periods, 1 );
        nblocks = ceil( nperiods / blocksize );

        for i = 1 : nblocks
            fprintf( 1, '.' )
            bidx = ( ( i - 1 ) * blocksize + 1 )  : min( i * blocksize, nperiods );
            nspikesb = length( bidx );
            % load spikes
            if i == 1 && periods( bidx( 1 ) ) < 0 % first spike
                spk1 = readbin( datfname, chans, totchans, [ 1 periods( bidx( 1 ), 2 ) ], source, target );
                spk1 = [ zeros( nchans, 1 - periods( bidx( 1 ), 1 ), target ) spk1 ];
                spk = readbin( datfname, chans, totchans, periods( bidx( 2 : end ), : ), source, target );
                spk = reshape( spk, [ nchans nsamples nspikesb - 1 ] );
                wavef = cat( 3, spk1, spk );
        %    elseif % last spike
            else % any other spike
                spk = readbin( datfname, chans, totchans, periods( bidx, : ), source, target );
                spk = reshape( spk, [ nchans nsamples nspikesb ] );
                wavef = cat(3,wavef,spk);
            end

        end

        % Detrend
        for ci = 1 : nchans
            wavef( ci, :, : ) = mydetrend( squeeze( wavef( ci, :, : ) ) );
        end

        wavef = squeeze(mean(wavef,3));
        meanWaveF{end+1} = wavef;
        
        fprintf( 1, 'done (%0.3g sec)\n', etime( clock, t0 ) )
        
    end
end

SaveAnalysis(pwd,'Waveforms',{meanWaveF},{'meanWaveforms'});
