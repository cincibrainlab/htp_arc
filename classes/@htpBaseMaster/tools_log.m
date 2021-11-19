%% Tools Log 
%%% Usage
% [ mc, mm, mw ] = tools_log( obj )
%
%%% Parameters
%
% * INPUTS: obj
%
% * OUTPUTS: mc, mm, mw
%
% The optional input parameter if the function is not self-invoked obj is 
% an htpPreprocessMaster object  The mc output is the function handle 
% to signify step completion, the mm output is the function handle to 
% signify a message about the process during a step, and the mw output is 
% the function handle to signify a warning about a potential issue in the 
% step.
%
%%% Copyright and Contact Information
% Copyright © 2019  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% tools_log
% Set up variables with the function handles to alert users throughout the use of the pipeline 
% via step completion, step related messages, and step related warnings.
function [mc, mm, mw] = tools_log(obj)

mc = @( str ) obj.msgout( str , 'step_complete');
mm = @( str ) obj.msgout( str , 'step_msg');
mw = @( str ) obj.msgout( str , 'step_warning');

end