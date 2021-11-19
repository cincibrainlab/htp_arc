%% Get Stage Information from CSV
%
%%% Usage
%    
% obj = getStageCSV( obj, stage, basePath )
%
% The input parameters are stage which is a string representing the stage 
% (i.e. 'postcomps'),basePath which is a string representing the base 
% output path for the generated CSV file, and a third optional parameter if 
% the function is not self-invoked obj that is the htpPreprocessMaster 
% object.  The output, if the function is not self-invoked, obj is the htpPreprocessMaster object with the updated stage
% information regarding steps completed and upcoming steps along with updated paths
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

%% getStageCSV
% Provide the essential information regarding subject datasets for the stage
% based on the stage id.
% By setting the filter and stage information such as
% last stage and next stage to be performed, the accurate csv
% dataset details are included in the resulting output for the Analysis Master
% to be utilized later in preprocessing.
function obj  = getStageCSV( obj, stage, basePath )

    configObject = eegDataClass( );
    configObject.updatePaths( basePath );
    pathdb = configObject.pathdb;

    switch stage

        case 'raw'
            filter = '';
            caption = 'Stage 1 Raw Import';
            stage_last = 'raw';
            stage_next = 'import';

        case 'import'
            filter = {'*Stage1*.csv;*_in_progress_Stage2*.csv'};
            caption = 'Select Stage 1 (Import) or Stage 2 (Partial) Subject Log';
            stage_last = 'import';
            stage_next = 'preica';

        case 'preica'
            filter = '*_Default_Stage2*.csv';
            caption = 'Select Stage 2 (Preica) or Stage 3 (Partial) Subject Log';
            stage_last = 'preica';
            stage_next = 'postica';
        case 'postica'

            filter = {'*Stage3*.csv;*_in_progress_Stage4*.csv'};
            caption = 'Select Stage 3 (PostICA) or Stage 4 (Partial) Subject Log';
            stage_last = 'postica';
            stage_next = 'postcomps';

        case 'postcomps'
            filter = {'*_Default_Stage4*.csv';'*Stage5*.csv'};
            caption = 'Select Stage 4 (PostComps) or Stage 5 (Partial) Subject Log';
            stage_last = 'postcomps';
            stage_next = 'level1';

        case 'preanalysis'
            filter = '*Stage*.csv';
            caption = 'Select Stage 5 (Level1) Subject Log to Finalize';
             stage_last = 'postcomps';
            stage_next = 'preanalysis';                   
        case 'level1'
            filter = '*Stage*.csv';
            caption = 'Select Stage 5 (Level1) or Stage 6 (Partial) Subject Log';
            stage_last = 'postcomps';
            stage_next = 'group';                    
        case 'group'
            filter = '*Stage*.csv';
            caption = 'Select Stage 6 (Partial) Subject Log';
            stage_last = 'level1';
            stage_next = 'group';                    
        otherwise
            filter = '*Stage*.csv';
            caption = 'Select Any Stage Subject Log';
            stage_last = 'placeholder';
            stage_next = 'placeholder';   
    end

    try
        Stage2_CleanMode = obj.htpcfg.optnow.Stage2_CleanMode;
    catch
        Stage2_CleanMode = 'Unavailable';
    end

    if strcmp(Stage2_CleanMode, 'FullAuto')
        try
            obj.htpcfg.csvfile = obj.htpcfg.fullauto.csvfile;
            obj.htpcfg.matfile = obj.htpcfg.fullauto.matfile;
        catch

            try
                [file,path] = uigetfile( filter, caption, fullfile(pathdb.analysis));
            catch
                obj.msgout('Cancelled opening CSV file.');
            end

            obj.htpcfg.csvfile = fullfile(path,file);
            obj.htpcfg.matfile = [path file(1:end-length('.csv')) '.mat'];

        end
    else
        try
            [file,path] = uigetfile( filter, caption, fullfile(pathdb.analysis));
        catch
            obj.msgout('Cancelled opening CSV file.');
        end

        obj.htpcfg.csvfile = fullfile(path,file);
        obj.htpcfg.matfile = [path file(1:end-length('.csv')) '.mat'];

    end

    obj.htpcfg.objStageStatus = find(obj.selectObjects(stage_last, obj.htpcfg.csvfile)); % current stage
    obj.htpcfg.objStageIndex = obj.selectObjects(stage_last, obj.htpcfg.csvfile);
    obj.htpcfg.objStageDesc = obj.getCsvState(obj.htpcfg.csvfile);
    obj.htpcfg.objStageStatus_completed = find(obj.selectObjects(stage_next, obj.htpcfg.csvfile)); % completed
    obj.htpcfg.pathdb = pathdb;

end