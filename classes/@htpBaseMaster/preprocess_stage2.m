%% Preprocess Stage 2
%%% Usage
%   
% obj = preprocess_stage2( obj )
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
% status and details of stage 2 completion.
%
%%% Copyright and Contact Information
% Copyright (C) 2020  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% preprocess_stage2
% Preprocesses artifacts subject by subject by computing spectrum for 
% channels and presenting the series of data for the user to mark channels 
% to be rejected via manual selection along with the automatically rejected 
% channels outside of threshold and frequency limits.
%
% Missing channels will be interpolated and upon continuation the data will
% be split into epochs with overlap.  The user can select the segments to 
% reject and segments will be removed and true data rank calculated again.  
%
% The third and final step will generate epochs from the .set file with 0% 
% overlap of length set by the user in the stage 2 pipeline options.  Any 
% discontinuous trial data, or unreferenced events, will be removed 
% automatically.  Upon trial rejection completion, the user can save the 
% dataset and continue or redo the stage 2 process as they wish. 
%
% If merging is allowed via the pipeline user defined option, the user will
% be prompted accordingly to merge existing data files on a subejct by
% subject basis.
%
% Verification of cleaning process and outcome such as files processed, 
% those skipped, those that had been previously completed, and other errors 
% that occurred during the stage can be done by user via the
% pipeline output window or the command console
function obj = preprocess_stage2(obj)

[mc, mm, mw] = obj.tools_log;

mm('Starting Stage 2: Preprocessing Artifacts...');

stage_last = 'import';
stage_next = 'preica';

obj.sub = obj.loadSub(stage_last);

opt = obj.formatOptions;

arrayfun(@(s) s.setopt(opt), obj.sub, 'uni', 0);


objStageStatus = obj.htpcfg.objStageStatus;
objStageStatus_completed = obj.htpcfg.objStageStatus_completed;

mm(sprintf('\nCurrent Data Directory: %s\n\n', obj.htpcfg.basePath'));

if strcmp(opt.mergemode, 'Yes') && obj.sub(1).proc_merge.status ~= 1

    uihandle = mergeDialogApp(obj);
    uiwait(uihandle.UIFigure);

    if obj.htpcfg.mergesuccess == true
        mm('Successful merge dialog.');
        obj.sub = mergeSubjects(obj.sub);
    else
        mm('Please turn off merge mode or try again to continue.');
        return;
    end
    arrayfun(@(s) s.setopt(opt), obj.sub, 'uni', 0);
    arrayfun(@(s) s.storeDataset(s.EEG, obj.htpcfg.pathdb.import, s.subj_subfolder, s.filename.import), obj.sub, 'uni', 0);
    arrayfun(@(s) s.unloadDataset, obj.sub, 'uni', 0);
    arrayfun(@(s) s.outputRow(stage_last), obj.sub, 'uni', 0);

    arrayfun(@(s) s.outputRow(stage_last), obj.sub, 'uni', 0);

    obj.createResultsCsv(obj.sub, 'import', 'Merge');

end

mm(sprintf('Current Data Directory: %s', obj.htpcfg.basePath));


prev_files = 0;
skip_files = 0;
errorchk = 0;
i = 1;
flag = 0;

obj.htpcfg.objStageStatus = find(obj.selectObjects(stage_last, obj.htpcfg.csvfile)); % current stage
obj.htpcfg.objStageStatus_completed = find(obj.selectObjects(stage_next, obj.htpcfg.csvfile)); % completed

user = obj.htpcfg.user;
%objStageStatus = objStageStatus(63:end);

if strcmp(obj.htpcfg.optnow.Stage2_CleanMode, 'FullAuto')
    mm('\nFull Auto Cleaning Operations\n');
    totalsubs = length(obj.sub);
    sub = obj.sub;
    importdir = obj.htpcfg.pathdb.import;

    for i = 1:totalsubs

        s = sub(i);

        s.setUser(user);

        [QI_pass, QI_msg] = qualityCheck(obj, s);

        if QI_pass && ismember(i, objStageStatus)

            str_status = sprintf('\nOpening dataset (%d of %d): %s', i, totalsubs, s.subj_basename);
            mc(str_status);
            s.str_plottitle = str_status;
            mm(sprintf('\nFolder: %s\n', s.subj_subfolder));

            
            s.openDataset(importdir, s.subj_subfolder, s.filename.import);

            s.trim_edges(10);

            s.autoclean;

            s = obj.tool_createEpochs(s);

            s.EEG.filename = s.filename.(stage_next);

            obj.tool_saveSubject(s, stage_next);

            s.unloadDataset;

            errorchk = 0;

            s.outputRow(stage_next);

            flag = 0;

            sub(i) = s;

        else

            s.proc_state = QI_msg;
        end

    end

    obj.sub = sub;
end


if strcmp(obj.htpcfg.optnow.Stage2_CleanMode, 'Manual') || strcmp(obj.htpcfg.optnow.Stage2_CleanMode, 'ASR')
    mm('\nManual Cleaning Operations\n');
    while i <= length(obj.sub)

        s = obj.sub(i); 

        s.setUser(obj.htpcfg.user);

        [QI_pass, QI_msg] = qualityCheck(obj, s);

        if QI_pass

            if ismember(i, objStageStatus) % processes only files specified by the spreadsheet


                str_status = sprintf('\nOpening dataset (%d of %d): %s', i, length(obj.sub), s.subj_basename);
                mc(str_status);
                s.str_plottitle = str_status;
                mm(sprintf('\nFolder: %s\n', s.subj_subfolder));

                
                s.openDataset(obj.htpcfg.pathdb.import, s.subj_subfolder, s.filename.import);

                s.trim_edges(10); 

                
                if strcmp(obj.htpcfg.optnow.Stage2_CleanMode, 'FullAuto')
                    s.autoclean;

                    s = obj.tool_createEpochs(s);

                    s.EEG.filename = s.filename.(stage_next);

                    obj.tool_saveSubject(s, stage_next);

                    s.unloadDataset;

                    errorchk = 0;

                    flag = 0;

                else
                    s = obj.tool_manualChanClean(s);

                    if strcmp(opt.epoch_type, 'Rest') == 1

                        s = obj.tool_createEpochs(s);

                        s = obj.tool_cleanEpochs(s);

                    end
                    s.EEG.filename = s.filename.(stage_next);
                    obj.tool_saveSubject(s, stage_next);

                    
                    s.unloadDataset;

                    [flag, errorchk] = obj.redoOrContinue(s);

                end


                if errorchk == 0

                    s.outputRow(stage_next);

                else
                    if flag ~= 1
                        s.outputRow('error');
                    end
                end

            else 
                if ismember(i, objStageStatus_completed)
                    
                    s.unloadDataset;
                    s.outputRow(stage_next);
                    prev_files = prev_files + 1;
                else
                    
                    s.unloadDataset;
                    s.outputRow('error');
                    skip_files = skip_files + 1;
                end
            end

        else

            s.proc_state = QI_msg;

        end

        
        switch flag
            case 0
                obj.sub(i) = s; 
                i = i + 1; 
            case 1
                
                obj.msgout('Redo subject selected.');
                s = [];
            case 2 

                mm('Save work in progress...');
                break;
        end

        % Code to verify or redo subject
        %         if flag == 1  % do not increment "i" counter if redo
        %
        %         else
        %             obj.sub(i) = s;  % apply changes to persistant object
        %             i = i + 1;   % increment counter
        %         end

    end

end


if strcmp(obj.htpcfg.optnow.Stage2_CleanMode, 'ContCleanOnly')

    mm('\nManual Cleaning Operations\n');
    while i <= length(obj.sub)

        s = obj.sub(i); 

        s.setUser(obj.htpcfg.user);

        [QI_pass, QI_msg] = qualityCheck(obj, s);

        if QI_pass

            if ismember(i, objStageStatus) 


                str_status = sprintf('\nOpening dataset (%d of %d): %s', i, length(obj.sub), s.subj_basename);
                mc(str_status);
                s.str_plottitle = str_status;
                mm(sprintf('\nFolder: %s\n', s.subj_subfolder));

                
                s.openDataset(obj.htpcfg.pathdb.import, s.subj_subfolder, s.filename.import);

                %   s.trim_edges( 10 ); 

                s = obj.tool_manualChanClean(s);

                if strcmp(opt.epoch_type, 'Rest') == 1

                    s = obj.tool_createEpochs(s);

                    s = obj.tool_cleanEpochs(s);


                end
                s.EEG.filename = s.filename.(stage_next);
                obj.tool_saveSubject(s, stage_next);

                
                s.unloadDataset;

                [flag, errorchk] = obj.redoOrContinue(s);

            end


            if errorchk == 0

                s.outputRow(stage_next);

            else
                if flag ~= 1
                    s.outputRow('error');
                end
            end

        else 
            if ismember(i, objStageStatus_completed)
                
                s.unloadDataset;
                s.outputRow(stage_next);
                prev_files = prev_files + 1;
            else
                
                s.unloadDataset;
                s.outputRow('error');
                skip_files = skip_files + 1;
            end
        end


        
        switch flag
            case 0
                obj.sub(i) = s; 
                i = i + 1; 
            case 1
                
                obj.msgout('Redo subject selected.');
                s = [];
            case 2 

                mm('Save work in progress...');
                break;
        end

        %         if flag == 1  % do not increment "i" counter if redo
        %
        %         else
        %             obj.sub(i) = s;  % apply changes to persistant object
        %             i = i + 1;   % increment counter
        %         end
    end
end


mc(sprintf('\nSummary'));
mm(sprintf('\nFiles Processed: %d', length(objStageStatus)));
mm(sprintf('Previously Completed Files: %d', prev_files));
mm(sprintf('Skipped Files: %d', skip_files));
mm(sprintf('Other Errors: %d', errorchk));

if flag == 2, save_desc = 'in_progress'; else, save_desc = 'Default'; end

%obj.createResultsCsv(obj.sub, stage_next, 'Default');
obj.createResultsCsv(obj.sub, stage_next, save_desc);

end

%% qualityCheck
% Check that the duration of the data meets the duration criteria (in seconds) specified for 
% allowed preprocessing to take place.
function [QI_pass, QI_msg] = qualityCheck(o, s)

QI_msg = {'SHORT', 'EMPTY'};
QI_pass = true;

minimum_duration = 100; 

if s.getDuration < minimum_duration
    QI_pass = false;
    QI_msg = QI_msg{1};
    o.msgout(sprintf('%s: Did not meet minimum duration (%d s).', s.subj_basename, minimum_duration));
elseif s.proc_contains_all_nans
    QI_pass = false;
    QI_msg = QI_msg{2};
    o.msgout(sprintf('%s: Did not contain any valid data.', s.subj_basename));
end

end
