%% calc_cont_EpochLimits
%%% Usage
% limits = calc_cont_EpochLimits( obj )
%
%%% Parameters
% The optional input parameter if the function is not self-invoked obj is the htpPreprocessMaster object that is passed in if the function
% is not self-invoked.  The output are the calculated limits for the 
% epochs of the data. 
%
% Copyright (C) 2020 Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% calc_cont_EpochLimits
% Calculate the epoch lengths to be used for the EEG data for each subject
% based upon preprocessing designated options.  Based upon the epoch limit
% option, various calculation paths for the epochs are taken.
function limits = calc_cont_EpochLimits( obj )

epochLength = str2double(obj.htpcfg.optnow.('Stage2_EpochLength'));
epochLimits = obj.htpcfg.optnow.('Stage2_EpochLimits');

switch char(epochLimits)
    
    case '- to + length'
        
        limitmin = epochLength / 2 * -1;
        limitmax = epochLength / 2;
        
    case '- to 0 length'
        
        limitmin = epochLength * -1;
        limitmax = 0;
        
    case '0 to + length'
                
        limitmin = 0;
        limitmax = epochLength * -1;
        
end 
        
        limits = [limitmin limitmax];
        
        
end