function obj = preprocess_stage2_auto( obj )

[mc, mm, mw] = obj.tools_log;

mm('Starting Stage 2 (Auto): Refilter and Apply Preprocess of Artifacts...');

stage_last = 'import';
stage_next = 'preica'; 

obj.sub = obj.loadSub( stage_last );

opt     = obj.formatOptions;

arrayfun(@( s ) s.setopt( opt ), obj.sub, 'uni', 0);


objStageStatus = obj.htpcfg.objStageStatus;
objStageStatus_completed = obj.htpcfg.objStageStatus_completed;

mm(sprintf('\nCurrent Data Directory: %s\n\n', obj.htpcfg.basePath'));

if strcmp( opt.mergemode, 'Yes') && obj.sub(1).proc_merge.status ~= 1
    
    uihandle = mergeDialogApp( obj );    
    uiwait(uihandle.UIFigure);
    
    if obj.htpcfg.mergesuccess == true
        mm('Successful merge dialog.');        
        obj.sub = mergeSubjects(obj.sub);
    else
        mm('Please turn off merge mode or try again to continue.');
        return;
    end
    arrayfun(@( s ) s.setopt( opt ), obj.sub, 'uni', 0);
    arrayfun(@( s ) s.storeDataset( s.EEG, obj.htpcfg.pathdb.import, s.subj_subfolder, s.filename.import), obj.sub, 'uni', 0 );
    arrayfun(@( s ) s.unloadDataset, obj.sub, 'uni', 0);
    arrayfun(@( s ) s.outputRow( stage_last ), obj.sub, 'uni', 0);
    
    obj.createResultsCsv(obj.sub, 'import','Merge');
      
end

mm(sprintf('Current Data Directory: %s', obj.htpcfg.basePath));
mm('\nManual Cleaning Operations\n');

prev_files = 0; skip_files = 0; errorchk = 0; i = 1;

obj.htpcfg.objStageStatus = find(obj.selectObjects(stage_last, obj.htpcfg.csvfile)); % current stage
obj.htpcfg.objStageStatus_completed = find(obj.selectObjects(stage_next, obj.htpcfg.csvfile)); % completed
 
while i <= length(obj.sub)
    
    s = obj.sub(i); % allows for parallel loops and temporary changes

    
    s.setUser( obj.htpcfg.user );
    
    if ismember(i, objStageStatus) % processes only files specified by the spreadsheet
        
        if obj.htpcfg.autoprocflag == 1
            s.htpcfg = obj.htpcfg;
            s.htpcfg.autoproc = obj.htpcfg.autoproc(strcmp(s.subj_basename, {obj.htpcfg.autoproc.basename}));
            autostatus = sprintf('\nFile Found. Reprocessing %s\n', s.subj_basename);

            s.proc_tmprej_chans = s.htpcfg.autoproc.tmprej_chans;

            
            mm(autostatus);
        end
        
        str_status = sprintf('\nOpening dataset (%d of %d): %s', i, length(obj.sub), s.subj_basename);
        mc(str_status);
        s.str_plottitle = str_status;
        mm(sprintf('\nFolder: %s\n', s.subj_subfolder));
        
        % load dataset
        s.openDataset(obj.htpcfg.pathdb.import, s.subj_subfolder, s.filename.import);       
        
        s = obj.tool_manualChanClean( s );
        
        if strcmp(opt.epoch_type, 'Rest') == 1
            
            s = obj.tool_createEpochs( s );
            
            s = obj.tool_cleanEpochs( s );
            
        end
        
        s.EEG.filename = s.filename.( stage_next );
        obj.tool_saveSubject( s, stage_next);
        
        % unload data & decrease memory footprint
        s.unloadDataset;
        
        %[flag, errorchk] = obj.redoOrContinue( s );
        
        flag = 0;
        errorchk = 0;

        
        if errorchk == 0
        
            s.outputRow( stage_next );
            
        else
            if flag ~= 1
                s.outputRow('error');
            end
        end
        
    else  % if object is not at correct stage, push through only as saved
        if ismember(i, objStageStatus_completed)
            % unload data & decrease memory footprint
            s.unloadDataset;
            s.outputRow(stage_next);
            prev_files = prev_files + 1;
        else
            % unload data & decrease memory footprint
            s.unloadDataset;
            s.outputRow('error');
            skip_files = skip_files + 1;
        end
    end  
    
    % Code to verify or redo subject
    if flag == 1  % do not increment "i" counter if redo
        
    else
        obj.sub(i) = s;  % apply changes to persistant object
        i = i + 1;   % increment counter
    end
    
end

mc(sprintf('\nSummary'));
mm(sprintf('\nFiles Processed: %d', length(objStageStatus)));
mm(sprintf('Previously Completed Files: %d', prev_files));
mm(sprintf('Skipped Files: %d', skip_files));
mm(sprintf('Other Errors: %d', errorchk));

obj.createResultsCsv(obj.sub, stage_next, 'reprocess');

end


