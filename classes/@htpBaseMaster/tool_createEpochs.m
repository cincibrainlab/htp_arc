%% Tool to Create Epochs
%%% Usage
%    
% s = tool_createEpochs( obj, s )
%
%%% Parameters
%
% The input parameter s is a subject object (RestEegDataClass object) and
% the second optional input paramter if the function is self-invoked obj is 
% the htpPreprocessMaster object.  The output is the subject object with 
% the newly created epochs stored in the EEG_preica struct of the updated 
% output. 
%
% Copyright (C) 2020  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% tool_createEpochs
% Utilized to create the epochs for the EEG data.
% Length and limits are configured, and once configuration is done, epoch 
% creation proceeds and the creation process depends on if the data 
% is rest data or event related data with the epochs being outputted into 
% the EEG_preica struct.  The epochs are created to be used 
% throughout the future preprocessing steps to allow for accurate processing
% and component analysis.
function s = tool_createEpochs( obj, s )

opt     = obj.formatOptions;

s.proc_contEpochLength = opt.epoch_length;
s.proc_contEpochLimits = opt.epoch_limits;

switch opt.epoch_type
    
    case 'Rest'
        s.createEpochs;
    case 'Event'  
        s.createEpochsERP
end


% see snagit picture
% time window of interest is t = 0 is the user response
% or the maximum 2000 ms, always 600 ms afterwards
% ERP window: -1000 + 1000 of trigger 9 (positive), 10 (no press), 11
% (reversal)
% bands: theta, alpha ( < 30 hz filter) keep background gamma
% run it both ways with or without high pass
% amplitude measures and latency of P300 P3A, P3B
% N100 data
% leads: 68 and regions, Fz (11, 12, 5,6) Cz (6, 7,107, 129), Pz
% (62,61,70,67,73,78,68)

% datasets: see onedrive link

% DIN11 - DIN9 amplitude / latency
% table
% time frequency / amplitude
% rows: FXS, CONTROL
% columns: feedback column reversal (negative) versus non-reversal
% (positive) within that you amplitudes, latencies

% blinded epochs
% all epochs look the same

end