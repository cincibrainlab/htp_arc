%% Check Stages
%
%%% Usage
%
% obj = check_stages( obj, sub )
%
%%% Parameters
%
% * INPUTS: obj, sub
%
% * OUTPUTS: obj
%
% The input parameter sub is the array of subjects (RestEEGDataClass objects) 
% passed in and the second optional input parameter if the function is not 
% self_invoked obj is the htpPreprocessMaster object.  The output obj is 
% the updated htpPreprocessMaster object with the stage information for 
% each subject updated.
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

%% check_stages
% Need to check the stage information for each available subject and ensure that it
% accurately reflects the latest stage of the preprocessing complete and the
% next stage to be performed.
function obj = check_stages( obj, sub )

try

    for i = 1:length(sub)
       sub(i).checkAvailableDatasets;        
    end

catch
    
end

if length(obj.sub) < 1
   
    obj.msgout('ERROR: No data objects available for testing.', 'step_error');
    
end

try
    
    test_subject = obj.sub( 1 ).resultTbl;
    avail_idx = {test_subject.available};
    avail_stages = {test_subject.stage};
    obj.stage_info =  [avail_stages; avail_idx ];
        
catch

    obj.msgout('ERROR: unable to create stage_info.', 'step_error');
end


end
