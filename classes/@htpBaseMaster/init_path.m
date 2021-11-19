%% Initialize Path
%%% Usage
% obj = init_path( obj )
%
%%% Parameters
%
% * INPUTS: obj
%
% * OUTPUTS: obj
%
% The optional input parameter if the function is not self-invoked obj is 
% the htpPreprocessMaster object.  The output, if the function is not self-invoked, is the 
% htpPreprocessMaster object that was passed in with the path updated to
% reflect inclusion of the necessary directories for preprocessing and
% analysis to proceed.
%
%%% Copyright and Contact Information
% Copyright © 2020  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% init_path
% For the htpPreprocessMaster object the general pipeline directories 
% (and sub-directories, if necessary) are added to the MATLAB path to have 
% access to necessary preprocessing and analysis class files and related 
% functions and scripts.
% The path success attribute is set depending upon if there is an error in
% the path initialization process, and if there is the attribute is set
% accordingly as it could impact the preprocessing experience.

function obj = init_path( obj )

obj.htpcfg.pathsuccess = 0;
try
    
    agp = @(x) addpath(genpath(x),'-end');
    
    
    ap = @(x) addpath(x,'-end');
    
    %     % experiment of choice, change path to experiment file
    %     rmpath(genpath('experiments'));
    %
    %     switch htp_mode
    %         case 'default'
    %             currentExperiment = 'experiments/template';
    %             agp(currentExperiment);
    %     end
    
    %     obj.msgout(sprintf('Current Experiment Path: %s', currentExperiment), 'step_complete');
    %     notify( obj, 'step_complete' );
    
    agp('config');
    agp('chanfiles');
    agp('analysis');
    %agp('functions');
    %agp('subclasses');
    agp('classes');
    agp('docs');
    %agp('templates');
    %agp('external\eegdb');
    ap('external');
    ap('import');
    ap('gui');
    agp('local');
    
    obj.htpcfg.pathsuccess = 1;
    
catch
    obj.htpcfg.pathsuccess = 0;
end

end


