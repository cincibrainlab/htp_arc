%% Tool to Clean Epochs
%
%%% Usage
%
% s = tool_cleanEpochs( obj, s )
%
%%% Parameters
%
% * INPUTS: obj, s
%
% * OUTPUTS: s
%
% The input parameters are s which is a subject object (RestEegDataClass object) and
% the second optional input parameter if the function is not self-invoked 
% obj is the htpPreprocessMaster object.  The output is the subject object with the cleaned 
% epochs stored within their respective struct. 
%
% Copyright (C) 2020 Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% tool_cleanEpochs
% Determine mode of cleaning, epoch length, and epoch limits, and proceed
% to clean the epochs to be correctly utilized for later preprocessing steps.
% The cleaned epochs are stored for the subject and returned upon
% completion.
function  s = tool_cleanEpochs( obj, s )

htpcfg = obj.htpcfg;
opt = htpcfg.optnow;


% Interpolation = opt.Stage2_Interpolation;
CleanMode = char(opt.Stage2_CleanMode);
EpochLength = str2double(opt.Stage2_EpochLength);
EpochLimits = obj.calc_cont_EpochLimits;
 
s.cleanEpochs;

end