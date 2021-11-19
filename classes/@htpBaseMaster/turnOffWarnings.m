%% Turn Off Warnings
%%% Usage
% results = turnOffWarnings() 
%
%%% Parameters
%
% * INPUTS: 
%
% * OUTPUTS: results
%
% The function is self-invoked by an htpPreprocessMaster object thus there 
% there are not input parameters.  The output is a boolean indicating 
% success in terms of turning off the unnecessary messages. 
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

%% turnOffWarnings
% Deactivation of the warnings that might overfill the command console and
% pipeline output window.
% Warnings may not lead to fatal error therefore it is necessary
% to keep the pipeline console clean for primarily preprocessing related messages only.
function results = turnOffWarnings()
warning( 'off', 'MATLAB:printf:BadEscapeSequenceInFormat');
warning( 'off', 'MATLAB:MKDIR:DirectoryExists');
warning( 'off', 'MATLAB:xlswrite:AddSheet');
warning( 'off', 'MATLAB:table:ModifiedAndSavedVarnames');
warning( 'off', 'MATLAB:subscripting:noSubscriptsSpecified');
warning( 'off', 'MATLAB:rmpath:DirNotFound');
warning( 'off', 'MATLAB:printf:BadEscapeSequenceInFormat');

results = 1;

end