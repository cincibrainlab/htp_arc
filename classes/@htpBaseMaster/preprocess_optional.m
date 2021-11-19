%% Preprocess Optional
%
%%% Usage
%    
% obj = preprocess_optional( obj, action )
%
%%% Parameters
%
% * INPUTS: obj, action
%
% * OUTPUTS: obj
%
% The input parameter action is the plotting action to be taken
% for the user to utilize in the manual review process and the second 
% optional parameter if the function is not self-invoked obj is the 
% htpPreprocessMaster object.  The output, if the function is not 
% self-invoked, is the htpPreprocessMaster that invoked the function or 
% was passed in as the first input since the images generated themselves will be 
% displayed to the user.
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

%% preprocess_optional
% Perform post-ica artifact detection via loading each subject from the stage
% and setting up options for subject and prepopulated status 
% to perform the necessary manual reviewal. Finally, produce the
% figures for the user to review and the generation of images is based upon
% the action dictating the method for manual review the user seeks to perform.
function obj = preprocess_optional( obj, action )

stage_last = 'postcomps';
stage_next = 'level1';

% init
[mc, mm, mw] = obj.tools_log;       
opt     = obj.formatOptions;        


dipfitcalc = opt.dipfitcalc;

disp_welcome(mm);


obj.sub = obj.loadSub( stage_last );  

arrayfun(@( s ) s.setopt( opt ), obj.sub, 'uni', 0);  

objStageStatus              = obj.htpcfg.objStageStatus;
objStageStatus_completed    = obj.htpcfg.objStageStatus_completed;

prev_files = 0; skip_files = 0; errorchk = 0; uniquei = 1; flg = 0;


sub = obj.sub;

for i = 1 : length(sub)
    s = sub(i);
    
    if s.exclude_switch
        s.exclude_status = randi([1 4]);
    else
        s.exclude_status = randi([1 4]);
    end
    
    s.mra.filename.spectfig = obj.create_filename_spectfig(s);
    
    s.mra.reviewed = false;
    
    if ismember(i, objStageStatus)
        
        switch action
            
            case 'spectSeriesPlot'
                
                %     obj.spectSeriesPlot( s );
                
            otherwise
                
        end
        
        
    end
    
    sub(i) = s;
end

obj.sub = sub;

obj.createResultsCsv(obj.sub, 'postcomps', 'mra');

%  [csvfile, matfile] = o.createCsvFileName;

mm( sprintf('CSV & mat file: %s\n', obj.htpcfg.csvfile));

end

%% disp_welcome
% Displays message to user via GUI output console and command console that
% stage 4 optional preprocessing has begun
function disp_welcome(mm)
mm('Starting Stage 4: Optional Functions');
end