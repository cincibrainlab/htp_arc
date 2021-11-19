%% Set Frequency Table
%%% Usage
% obj = setFreqTable(obj, newFreqMat) 
%
%%% Parameters
% 
% * INPUTS: obj, newFreqMat
%
% * OUTPUTS: obj
%
% The input is newFreqMat which is a powerband matrix to determine
% the obtain the necessary frequency table and the second optional input 
% parameter if the function is not self-invoked obj is the RestEegDataClass 
% object.  The function can be called and passed no input, in which case the default
% frequency table will be set.  The output, if the function is not 
% self-invoked, is the original RestEegDataClass object passed in with 
% the frequency table attribute updated.  
%
%%% Copyright and Contact Information
%
% Copyright © 2020  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP) 
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% setFreqTable 
% Prepare frequency table based on user input, if no user input
% set the default frequency table for later operations such as
% points retrieval.
% Before the frequency table is officially assigned, 
% verification that max frequency is not above nyquist frequency.
% Returns an error if max above nyquist frequency.
% The frequency table attribute is assigned for the object to be utilized in
% further operations such as points retrieval and various analysis methods.
function obj = setFreqTable( obj, newFreqMat ) 

    if nargin<2
        newFreqMat = [1,3; 4,7; 8,10; 10,12; 13,30; 30,80]; % human default P2
%                 newFreqMat = [1,4; 4,10; 10,13; 13,30; 30,55; 65,100]; %
%                 human modulation index
%                 newFreqMat = [1,4; 4,8; 8,13; 13,30; 30,55; 65,100]; % mice
    end



    EEG = obj.EEG;
    if newFreqMat(end,2) <= EEG.srate/2
        obj.freqTable = newFreqMat;
        obj.msgout('Frequency Table set', 'proc_msg');
%                 disp(obj.freqTable);
    else
        cprintf('err', '\n\nERROR: Highest possible frequency lower than selected frequency band.\n');
        return

    end
end