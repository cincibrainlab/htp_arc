%% Set Preprocessing Options for User Selection
%
%%% Usage
% 
% obj = setOptNow( obj, selection_arr )
%
%%% Parameters
%
% * INPUTS: obj, selection_arr
%
% * OUTPUTS: obj
%
% The input parameter selection_arr is the xml of options for the 
% pipeline preprocessing gui fields and the second optional input 
% parameter if the function is not self-invoked is the 
% htpPreprocessMaster object.  The output is the htpPreprocessMaster
% with the corresponding preprocessing option attributes updated.
%
%%% Copyright and Contact Information
%
% Copyright (C) 2020 Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% setOptNow
% Populate the various dropdowns in the options section of the preprocessing
% pipeline for the user to select desired settings when needed.
% Need to check length of options to populate to ensure correct assignment of
% settings options and throw error for mismatch since the settings are not
% correct
function obj = setOptNow( obj, selection_arr )

opt = obj.htpcfg.opt;
optnow = opt;

fieldname_of_options = fields(opt);

number_of_options = length(fieldname_of_options);

if length(selection_arr) == number_of_options
    for i = 1 : number_of_options
        
        opt.(fieldname_of_options{i})(selection_arr(i));
        optnow.(fieldname_of_options{i}) = opt.(fieldname_of_options{i})(selection_arr(i));
      %  obj.msgout(sprintf('%25.25s: (%10s)(%2d) [%s]', fieldname_of_options{i}, opt.(fieldname_of_options{i}){selection_arr(i)}, selection_arr(i), strjoin(opt.(fieldname_of_options{i}))), 'step_msg');
        
    end
else
    
    obj.msgout('Selection mismatch with available options.', 'step_error');
    
end

obj.htpcfg.optnow = optnow;

end
