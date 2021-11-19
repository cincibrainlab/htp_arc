%% Preprocess Stage 3
%
%%% Usage
%   
% obj = preprocess_stage3( obj )
%
%%% Parameters
%
% * INPUTS: obj
%
% * OUTPUTS: obj
%
% The optional input if the function is not self-invoked obj is the 
% htpPreprocessMaster object.  The output is the updated 
% htpPreprocessMaster object with information updated regarding the 
% status and details of stage 3 completion.
%
%%% Copyright and Contact Information
% Copyright (C) 2020 Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org
%
% Revision 8/27 for better memory handling for large datasets


%% preprocess_stage3
% Performing principal component analysis to reduce the dimension and thus
% reduce amount of data and computation time.  PCA allows the data rank to
% be set and perform pre-reduction to hand off results to ICA computation.  
% ICA is performed to seperate various activity of sources and cortical areas
% through reduction of mutual information of channels.  
% The components produced by the PCA and ICA performance are then used for 
% preprocessing to locate the primary brain components and remove artifacts
% in later stages. 
%
% If the subject is on the incorrect stage, then that subject will be
% skipped in this stage of preprocessing.
%
% The user can specify which ICA algorithm to run for their computation of
% component analysis.  It is recommended to use the 'BINICA' option if the 
% user has the BINICA executable on their MATLAB path as this method is the 
% fastest computational route of those available in the pipeline.
function obj = preprocess_stage3( obj )

[mc, mm, mw] = obj.tools_log;

mm('Starting Stage 3: PCA and ICA...');

icadefs;  % from EEGLAB, must point to correct binica
mm(sprintf('ICA Processor: %s', ICABINARY));
mm(sprintf('Current Data Directory: %s', obj.htpcfg.basePath));

stage_last = 'preica';
stage_next = 'postica';

obj.sub = obj.loadSub( stage_last );

opt     = obj.formatOptions;

arrayfun(@( s ) s.setopt( opt ), obj.sub, 'uni', 0);

objStageStatus = obj.htpcfg.objStageStatus;
objStageStatus_completed = obj.htpcfg.objStageStatus_completed;

prev_files = 0; skip_files = 0; errorchk = 0;

sub = obj.sub;
     
savesub = @(x) obj.tool_saveSubject(x, stage_next);
for i = 1 : length(obj.sub)
    s=sub(i);

    if ismember(i, objStageStatus) % processes only files specified by the spreadsheet

        if strcmp('No', opt.always_recalc)
            try
                s.loadDataset( stage_next );
                s.proc_state = 'PostICA';
            catch
            end
        end

        s.EEG.filename = s.filename.(stage_next);
        s.proc_icaweights = 'Yes';
        s.proc_state = 'PostICA';
        s.outputRow('postica');
        prev_files = prev_files + 1;


        % save cleaned dataset into the postica directory
        %obj.tool_saveSubject( s, stage_next);
        savesub(s);
        %  s.storeDataset( s.EEG, pathdb.postica, s.subj_subfolder, s.filename.postica);

        % unload data & decrease memory footprint
        s.unloadDataset;


    else  % if object is not at correct stage, push through only as saved

        if ismember(i, objStageStatus_completed)
            % unload data & decrease memory footprint
            s.unloadDataset;
            s.outputRow('postica');
            prev_files = prev_files + 1;
        else
            % unload data & decrease memory footprint
            s.unloadDataset;
            s.proc_state = 'ICA_Error';
            s.outputRow('error');
            skip_files = skip_files + 1;
        end
    end

    %obj.sub(i) = s;
    sub(i)=s;

end
    
obj.sub = sub;
sub=[];

% creates results spreadsheet
obj.msgout(sprintf('\nSummary'), 'step_complete');
obj.msgout(sprintf('\nFiles Processed: %d', length(objStageStatus)), 'step_msg');
obj.msgout(sprintf('Previously Completed Files: %d', prev_files), 'step_msg');
obj.msgout(sprintf('Skipped Files: %d', skip_files), 'step_msg');
obj.msgout(sprintf('Other Errors: %d', errorchk), 'step_msg');


obj.createResultsCsv(obj.sub, 'postica', 'Default');

end