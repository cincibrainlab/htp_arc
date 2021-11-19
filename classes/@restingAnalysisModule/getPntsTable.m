%% Get Points Table
%%% Usage
% obj = getPntsTable(obj) 
%
%%% Parameters
%
% * INPUTS: obj
%
% * OUTPUTS: obj
%
% The optional input parameter if the function is not self-invoked obj
% is the RestEegDataClass object.  The output, if the function is not self-invoked, is the 
% RestEegDataClass object with the pntstable attribute updated.  
%
%
%%% Copyright and Contact Information
% Copyright © 2020 Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP) 
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% getPntsTable
% Proceed to get the points table for the object's structured 
% frequency table to use for future calculations.
function obj = getPntsTable( obj )

epoch_length = obj.proc_contEpochLength; 
freq = obj.freqTable;

for iband = 1:length(freq)
    for j = 1:size(freq,2)
        pnt(iband, j) = epoch_length * freq(iband, j) + 1;
    end
end

obj.pntsTable = pnt;

%% hz2pnts
% Construct points table based on frequency & 
% segment length in seconds
function pnts = hz2pnts(hz, epoch_length)
    pnts = epoch_length * hz + 1;
end

end