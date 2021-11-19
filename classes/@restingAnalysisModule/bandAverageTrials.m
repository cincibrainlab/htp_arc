%% Band Average Trials
%%% Usage
% obj = bandAverageTrials(obj) 
%
%%% Parameters
%
% * INPUTS: obj
%
% * OUTPUTS: obj
% 
% The optional input if the function is not self-invoked obj is the 
% RestEegDataClass.  The output, if the function is not self-invoked, is 
% the original RestEegDataClass object passed in with the relative and 
% absolute power banded average trials attributes updated.  
%
%%% Copyright and Contact Information
% Copyright © 2020 Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org 

%% bandAverageTrials
% Use of the rectangular-rule within each frequency band
% to obtain the mean sum of absolute and relative power
% from the input arrays of dimensions freq*trial*chan.
function obj = bandAverageTrials( obj )   

    nbchan = obj.EEG.nbchan;
    abs_power = obj.rest_abs_power; 
    rel_power = obj.rest_rel_power;
    pnt = obj.pntsTable; n = size(pnt,1);

    msum_abs_power_band = NaN(n, nbchan);
    for k = 1:n
        interval = pnt(k,1):pnt(k,2);
        msum_abs_power_band(k,:) = mean(squeeze(0.5*sum(abs_power(interval, :, :))));
    end

    sum_rel_power_band = NaN(n, nbchan);
    for k = 1:n
        interval = pnt(k,1):pnt(k,2);
        sum_rel_power_band(k,:) = mean(squeeze(sum(rel_power(interval, :, :))));
    end

    obj.rest_rel_power_band_average_trials = sum_rel_power_band;
    obj.rest_abs_power_band_average_trials = msum_abs_power_band;

end