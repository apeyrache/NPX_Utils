A% A Matlab pipeline for Neuropixel data acquired with SpikeGLX
% It assumes one probe per recording for now.
%
% create a folder whose name is typically Animal-YYMMDD
% This folder should contain the successive Intan recordings of the day.
% Make sure sure the first recording of the day (at least) contains a
% proper xml file.
% Launch MasterPreProcessing_Intan
% You should get data ready to be manually spike sorted soon!
%
% USAGE: MasterPreProcessing_Intan(fbasename)
% where fbasename is the base name of the Intan recording (everything until
% the last '_', e.g. 'MouseXXX_YYMMDD')


function NPX_LaunchKS(basename,mergename,destDir)

%Parameters
%oneFilePerProbe = 0;
launchCatGT = 0;

%mergename = Process_NPX2ConcatenateDat(fbasename);


[~,mergename,~] = fileparts(pwd);

dataDir = pwd;
destDir = '/mnt/Savitar/Neuropixel';

if launchCatGT
    %cmd_line = ['CatGT -dir=D:/data -run=demo -prb_fld ']
    cmd_line = ['CatGT -dir=' dataDir ' -run=' mergename ' ']; %add  -prb_fld for one fodler per probe
    cmd_line = [cmd_line '-g=0-4 -t=0,0 '];
    cmd_line = [cmd_line '-ap -prb=0 -ni '];
    cmd_line = [cmd_line '-aphipass=300 -aplopass=9000 -gbldmx '];
    cmd_line = [cmd_line '-SY=0,384,6,500 '];
    cmd_line = [cmd_line '-XD=1,6,0 ']; % Optitrack
    cmd_line = [cmd_line '-XD=1,4,500 ']; %Sync chan on NIDQ
    cmd_line = [cmd_line ' -dest=' destDir ' '];
    system(cmd_line)
end

rootZ = fullfile(pwd,mergename);
main_kilosort;

destDir= '/mnt/SpeedyGonzales/Neuropixel/CGT_OUT/A8602-210514';
catDir = ['catgt_' mergename '_g0'];
%catName = ['catgt_' mergename '_g0_tcat.'];
catName = [mergename '_g0_tcat.'];
catName = [destDir filesep catDir filesep catName];

cmd_line = ['TPrime -syncperiod=1.0 '];
cmd_line = [cmd_line '-tostream=' catName 'imec0.ap.SY_384_6_500.txt '];
cmd_line = [cmd_line '-fromstream=1,' catName 'nidq.XD_0_4_500.txt '];
cmd_line = [cmd_line '-events=1,' destDir filesep catDir filesep 'spike_seconds.npy,' destDir filesep catDir filesep 'spike_seconds_adj.npy '];
cmd_line = [cmd_line '-events=2,' catName 'nidq.XD_0_6_0.txt,' destDir filesep catDir '_MotivePulses.txt'];
