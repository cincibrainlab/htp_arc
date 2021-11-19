%% Format Preprocessing Options
%
%%% Usage
%    
% obj = formatOptions( obj )
%
%%% Parameters
%
% * Inputs: obj
%
% * Outputs: obj
%
% The optional input parameter if the function is not self-invoked obj is 
% is the htpPreprocessMaster object.  The output
% is the newly updated options object with the options now reflecting
% correct settings.
%
%%% Copyright and Contact Information
%
% Copyright (C) 2020  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% formatOptions
% The options set by the user in the preprocessing gui are now written to
% a specifically created options object that is utilized and referenced
% throughout the various stages of preprocessing
function opt = formatOptions( obj )

opt.netdowngrade    = char(obj.htpcfg.optnow.Stage1_NetDowngrade);
opt.ChanCleanThreshold   = obj.htpcfg.optnow.Stage2_ChanCleanThreshold;
opt.cleanmode       = char(obj.htpcfg.optnow.Stage2_CleanMode);
opt.epoch_length    = str2double(obj.htpcfg.optnow.Stage2_EpochLength);
opt.epoch_limits    = obj.calc_cont_EpochLimits;
opt.epoch_type      = char(obj.htpcfg.optnow.Stage2_EpochType);
opt.mergemode       = char(obj.htpcfg.optnow.Stage2_MergeFiles);
opt.lowcutoff       = str2double(obj.htpcfg.optnow.Stage1_FilterLow) ;
opt.highcutoff      = str2double(obj.htpcfg.optnow.Stage1_FilterHigh);
opt.notch           = str2num(obj.htpcfg.optnow.Stage1_Notch1{1});
opt.cleanline       = obj.htpcfg.optnow.Stage1_Cleanline{1};
opt.srate           = str2double(obj.htpcfg.optnow.Stage1_Resample);
opt.parforS1        = str2double(obj.htpcfg.optnow.Stage1_ParforS1);
opt.dipfitcalc      = char(obj.htpcfg.optnow.Stage3_DipfitCalc);

opt.event_limits    = cell2mat(obj.htpcfg.optnow.Stage2_EventLimits);
opt.event_baseline  = obj.htpcfg.optnow.Stage2_EventBaseline;
opt.always_recalc   = char(obj.htpcfg.optnow.Stage3_AlwaysRecalc);
opt.pca_rank        = char(obj.htpcfg.optnow.Stage3_PCA);
opt.comp_select     = obj.htpcfg.optnow.Stage3_CompSelect;
opt.icatype         = obj.htpcfg.optnow.Stage3_IcaType{1};

end
