classdef htpBaseMaster < handle & matlab.mixin.SetGet & htpBst
    %HTPBASEMODULE Summary of this class goes here
    %   Detailed explanation goes here
    properties (SetAccess = public)


        % files: configuration
        xmlfile_options;
        xmlfile_elec;
        xmlfile_presets;
        xmlfile_exclude;
        xmlfile_power;
        xml_power;

        % config
        noeeglabpath;

        xml_opt; % stage options imported from external file
        xml_elec; % electrode systems imported from external file
        xml_presets;
        xml_exclude;

        % files
        targetPath; % overall data directory for files
        basePath; % root directory of folder containing S00_RAW folder
        dirlist; % directory + files of raw files for import
        fnlist; % fully formed filelist
        subfolderlist;

        % stage processing
        analysisMode;
        current_stage;
        user;
        stage_info;
        study_title;

        autoproc;

        optnow_s1;

        % data
        dataTable;

        % group data
        grp;
        grp_title;
        grp_filename;
        grp_outdir;
        grp_tmp1;
        grp_tmp2;

        % output & messaging
        logfile; % unique logfile for each run
        logfile_id; % unique logfile id for each run;

        msglog; % logging of all messages
        logger;
    end

    properties (SetAccess = public)

        msg;
        msgtype;
        outStr;
        
        configObject; % example single object as template


        htpcfg;
        sub; % data objects for subjects

        clindata;

    end

    events

        step_complete;
        step_warning;
        step_error;
        step_msg;

    end


    methods (Static)

        results = turnOffWarnings();

        str = countStrings(cellArrIn);


    end

    methods
        %% htpBaseMaster
        %
        % *Usage*
        %
        % obj = htpBaseMaster();
        %
        % *PARAMETERS*
        % 
        % * INPUTS:
        %
        % * OUTPUTS: obj
        %
        % Due to the function being the default constructor for the
        % htpBaseMaster instance, there is no input.  The output,
        % obj, is the newly constructed htpBaseMaster instance.
        %
        % *Description*
        % Construct htpBaseMaster instance for preprocessing
        % setup regarding configuration of file paths and settings to be 
        % used in the ensuing stages.
        %
        % The base path for scripts and logs to be kept are initialized
        % with path and datetime to be uniquely identifiable 
        % to be utilized for later stages and preprocessing.
        %
        % Along with logs and file paths, the htpcfg configuration structure
        % is initialized with host, version, user, screensize information
        % along with creating and populating various fields such as 
        % study title and so on.
        %
        % Also instantiates an htpbst object to interact with brainstorm
        % interface for later functionality with regards to analysis
        % techniques.
        function obj = htpBaseMaster()
            obj@htpBst;
            
            agp = @(x) addpath(genpath(x), '-end');
            
            ap = @(x) addpath(x, '-end');
       
            
            obj.msg = '';
            
            
            obj.reset_msg_log;

            
            [obj.htpcfg.scriptPath, ~, ~] = fileparts(which('htp_contents'));

            
            datetime.setDefaultFormats('default', 'MMddyyhhmm');
            obj.htpcfg.logfile = sprintf('htp_Log_%s_%s.txt', obj.getHostName, datetime);
            %obj.htpcfg.logfile_id = fopen(fullfile(obj.htpcfg.scriptPath, 'local/logfiles/', obj.htpcfg.logfile),'a');
            obj.htpcfg.v = version;
            obj.htpcfg.hostname = obj.getHostName();
            obj.htpcfg.title_string = 'DemoData';
            obj.htpcfg.user = 'UnknownUser';
            obj.htpcfg.timetag2 = datestr(now, 'yymmddHHMM');
            obj.htpcfg.screensize = get(0, 'screensize');
            obj.htpcfg.chanNow = 'init';
            obj.htpcfg.saveSettingFile = ['local/', 'settings_', obj.htpcfg.hostname, '.mat'];

            obj.htpcfg.completed = struct();
            obj.htpcfg.completed.NetTypeDropDown = 0;
            obj.htpcfg.completed.FilenameEditField = 0;
            obj.htpcfg.completed.TargetFolderEditField = 0;
            obj.htpcfg.completed.OutputFolderEditField = 0;
            obj.htpcfg.completed.PrepareStageButton = 0;

            obj.htpcfg.autoprocflag = 0;


            obj.htpcfg.rawsubfolder = 'single_file';

            obj.set_user('');
            obj.set_study_title('');
            obj.htpcfg.logger = log4m.getLogger(fullfile(obj.htpcfg.scriptPath, 'local/logfiles/', obj.htpcfg.logfile)); 
            obj.start_EegLab_If_Needed;
            obj.msgout('Extended by Brainstorm Function (htpBst Class)');

            

        end

        obj = msgout(obj, str, varargin);
        obj = lm(obj, inputStr);

        %% GetSize
        %
        % *Usage*
        %
        % getSize(this)
        %
        % * INPUTS: this
        %
        % * OUTPUTS: 
        %
        % The optional input, this if the function is not self-invoked, is 
        % an htpBaseMaster instance.
        %
        % *Description*
        %
        % Obtain current memory footprint for htpBaseMaster object
        % in terms of MB and GB for user to inspect
        function GetSize(this)
            props = properties(this);
            totSize = 0;
            
            for ii=1:length(props)
                currentProperty = getfield(this, char(props(ii)));
                s = whos('currentProperty');
                totSize = totSize + s.bytes;
            end
            
            str = sprintf('%d bytes or %1.3f megabytes or %1.3f gigabytes\n', totSize,totSize/1e6, totSize/1e9);
            this.msgout(str, 'proc_complete');
        end
        
        %% assignChanInfoToSubjects
        %
        % *Usage*
        %
        % o = assignChanInfoToSubjects(o, chantype)
        %
        % * INPUTS: this
        %
        % * OUTPUTS: 
        %
        % The optional input, this if the function is not self-invoked, is 
        % an htpBaseMaster instance.
        %
        % *Description*
        %Assign the channel info for each subject in the group being
        %preprocessed via the pertinent fields associated with the given
        %net type and electrode system.
        function o = assignChanInfoToSubjects( o, chantype )
            
            chanInfoIndex = strcmp(chantype, {o.htpcfg.chaninfo.net_name});
            chanInfo = o.htpcfg.chaninfo(chanInfoIndex);
            
            for iSub = 1 : numel( o.sub )
                s = o.sub(iSub);
                s.setElectrodeSystem( chanInfo );
                o.sub(iSub) = s;
            end
            
            o.htpcfg.chanNow = chanInfo;
            
        end
        
        %Clear all associated RestingAnalysis object variables for each
        %subject to free up memory
        function o = clearRestAnalysisVariables( o )
            fieldnames = {'freqTable','pntsTable','rest_rel_power','rest_rel_hz',...
                'rest_rel_power_band_average_trials','rest_peakloc', 'rest_abs_power', ...
                'rest_abs_hz', 'rest_abs_power_band_average_trials'};
            for iSub = 1 : numel( o.sub )
                for iField = 1 : numel(fieldnames)
                    o.sub(iSub).(fieldnames{iField}) = ...
                        [];
                end
            end
        end
        
        %Attempt to retrieve subject's name of net used in data collection,
        %and alert the user to load subjects to obtain net upon error
        function netname = getSubjectNetName( o ) 
            try    
            netname = o.sub(1).net_name;
            catch e
                disp('No subjects loaded');
                throw e;
            end
        end
        
        %Sets the electrode system upon selection of net by user in the net
        %type dropdown and assigns necessary channel info.
        %If there are not subjects, nothing needs to be done, but with
        %subjects established the configuration must be updated for them.
        function obj = setElecNow( obj, code )
            
            chaninfo = obj.htpcfg.chaninfo;
            codeIdx = strcmp(code, {chaninfo.net_name});
            obj.htpcfg.chanNow = chaninfo(codeIdx);
            obj.htpcfg.completed.NetTypeDropDown = true;
            obj.msgout(sprintf('Net Selected: %s', code), 'step_complete');
            
            if isempty(obj.sub)
            else
                arrayfun(@( s ) obj.update_htpcfg( s ), obj.sub, 'UniformOutput',false );
            end
            
        end
        
        %Getter and setter functions for the  current user of pipeline
        function set_user(obj, user), obj.user = user; end
        function user = get_user(obj), user = obj.user; end
        
        %Getter and setter functions for the study title of the current
        %batch of group preprocessing
        function set_study_title(obj, title), obj.study_title = title; end
        function study_title = get_study_title(obj), study_title = obj.study_title; end

        %Retrieve the power bands set by the pipeline XML options based
        %upon the study presets for the study selected by the user
        function list = listPowBands( obj )
            list = obj.xml_power(:,1);
        
%             for i = 1 : size( obj.xml_power(:,3:end), 1 )
%                 tmprow = obj.xml_power(i,3:end);
%                 vals{i} = sprintf('%s ', tmprow{:})                
%             end
         
        end
        
        %Get the detail of the specified power band and show to user
        function str = getPowBandDetail( obj, idx )
            tmprow = obj.xml_power(idx,3:end);
            str = sprintf('%s ', tmprow{:});
        end
        
        %Get the applicable index for the specified power band
        function idx = getPowBandIdx( obj, key )
           idx = find(strcmpi( key, obj.xml_power(:,1))); 
           if isempty(idx)
               idx = 2;
           end
        end
        
        %CURRENTLY UNUTILIZED
        function obj = editPowBands( obj )
           % edit power band config file           
        end
        
        
        function [label, mat] = createPowBandMat( obj, idx )
            tmprow = obj.xml_power(idx,3:end);
            
            powband_label = {};
            powband_mat = [];
            
            coin = true;
            label_cnt = 1;
            mat_cnt = 1;
            for i = 1 : length(tmprow)
                if mod(length(tmprow),2) ~= 0
                    o.msgout('Error: check powerband XML file');
                end
                if coin
                    if  ~isempty(tmprow{i})
                        powband_label{label_cnt} = tmprow{i};
                        coin = false;
                        label_cnt = label_cnt + 1;
                    end
                else
                    if  ~isempty(tmprow{i})
                        powband_mat(mat_cnt, :) = str2num(tmprow{i});
                        coin = true;
                        mat_cnt = mat_cnt + 1;
                    end
                end
            end
            
            label = powband_label;
            mat = powband_mat;
            
            obj.htpcfg.powband.label = powband_label;
            obj.htpcfg.powband.mat = powband_mat;
            
        end
        
        %Check if the user has added EEGLAB directory to the MATLAB path as
        %it is essential for the pipeline to function as intended.
        %If it is not added, alert the user via command console and
        %pipeline output window to add it to the path before preprocessing
        %can begin.
        %If already added, the applicable configuration attributes for the
        %path are set for the user.
        function obj = checkEegLab(obj)
            % add to path without subdirectories
            ap = @(x) addpath(x, '-end');

            try
                eeglabpath = which('eeglab.m');


                if isempty(eeglabpath)
                    obj.htpcfg.noeeglabpath = 0;
                    obj.msgout('Critical: EEGLAB not found. Please add to MATLAB path, restart HTP.', 'step_error');

                else
                    eeglabpath = eeglabpath(1:end-length('eeglab.m'));
                    obj.msgout(sprintf('EEGLAB Found. Path: %s', which('eeglab.m')), 'step_complete');
                    ap(eeglabpath);
                    obj.htpcfg.eeglabpath = eeglabpath;
                    obj.htpcfg.noeeglabpath = 1;
                end
            catch
                obj.htpcfg.noeeglabpath = 0;
            end
        end

        %Checks if EEGLAB has been started prior to pipeline initiation
        %If so, begin eeglab as pipeline initiation is occurring for key
        %stage function execution later on (filtering, ICA/PCA, artifact
        %rejection, and so on).
        %If eeglab not found, error is thrown and alerts the user to add
        %eeglab to the MATLAB path and restart the pipeline to correctly 
        %utilize the pipeline
        function obj = start_EegLab_If_Needed(obj)
            
            ap = @(x) addpath(x, '-end');

            try
                eeglabpath = which('eeglab.m');
                [eeglabpath, ~, ~] = fileparts(eeglabpath);

                if ~isempty(eeglabpath)
                    obj.msgout(sprintf('EEGLAB Found. Path: %s', which('eeglab.m')), 'step_complete');
                else
                    %   error('');
                end
                try
                    is_sccn();
                catch
                    if isempty(eeglabpath)
                        str = 'Missing.';
                    else
                        str = which('eeglab.m');
                    end
                    obj.msgout(sprintf('EEGLAB Loading. Path: %s', str), 'step_warning');
                    eeglab;
                    %eeglab nogui;
                    close gcf;
                end
                if isempty(eeglabpath)
                    eeglab;
                    %eeglab nogui;
                    close gcf;
                end
            catch
                obj.htpcfg.noeeglabpath = 0;
                obj.msg = 'Critical: EEGLAB not found. Please add to MATLAB path, restart HTP.';
                obj.msgout(obj.msg, 'step_error');
            end
            evalin('base', 'eeglab');
            %evalin('base','eeglab nogui');
            evalin('base', 'close gcf');
        end
        
        %Update htpcfg structure with potentially newly updated fields for
        %modified preprocessing options and or path related attributes
        function s = update_htpcfg(obj, s)

            s.htpcfg = obj.htpcfg;

        end

        %CURRENTLY UNUTILIZED
        function result = check_user(obj)
            if strcmp(obj.get_user, '')
                result = 0;
            else
                result = 1;
            end
        end


        %CURRENTLY UNUTILIZED
        function result = check_study_title(obj)
            if strcmp(obj.get_study_title, '')
                result = 0;
            else
                result = 1;
            end
        end


        %Create file to save settings for local user of the pipeline
        %Each device can have its own settings to generate options of the 
        %pipeline tailored to the user based on previous session and needs
        function obj = generateSaveFileName(obj)

            obj.htpcfg.saveSettingFile = ['local/', 'settings_', obj.htpcfg.hostname, '.mat'];
            obj.msgout(sprintf('Generating Save Filename: %s', obj.htpcfg.saveSettingFile), 'step_complete');
        end


        %CURRENTLY UNUTILIZED
        function obj = setAnalysisMode(obj, value)

            obj.htpcfg.analysisMode = value;
            obj.msgout(sprintf('Set Analysis Mode (htpcfg.analysisMode): %s', value), 'step_complete');

        end

        %CURRENTLY UNUTILIZED
        function value = getAnalysisMode(obj)

            value = obj.htpcfg.analysisMode;

        end

        %Seek the target directory specified by the user and 
        %validate that it does exist to bet set as the base output 
        %directory. If it exists, the path provided is selected as the 
        %target path for all future preprocessing stage output and the 
        %configuration structure are updated with the path for 
        %preprocessing to accurately occur. If it does not exist, the user 
        %is prompted to select a currently existing directory for the 
        %preprocessing directory structure to be created in due to there 
        %needing to be a certain directory structure for stage outputs.
        function obj = setTargetPath(obj, srcpath)

            % validate path
            if 7 == exist(srcpath, 'dir')
                obj.htpcfg.targetPath = srcpath;
                obj.targetPath = srcpath;
                obj.htpcfg.completed.TargetFolderEditField = 1;
                obj.msgout(sprintf('Target directory selected: %s.', srcpath), 'step_complete');

                %obj.saveLastSettings;
            else
                obj.msgout(sprintf('%s\nAssigned Target Directory Not Found. Check Path.\n', srcpath), 'step_error');
                return;

            end
        end
        
        
        %Seek the base path provided by the user and validate that it 
        %does exist.  If it exists, the base path for location of datasets
        %is set to this directory as the datasets and stage input files
        %are sought out in this base path for each stage of preprocessing.
        %If it does not exist, alert the user and notify them to select
        %an existing directory to be used as the base pth for pipeline
        %input files.
        function obj = setBasePath(obj, srcpath)

            % validate path
            if 7 == exist(srcpath, 'dir')
                obj.htpcfg.basePath = srcpath;
                obj.basePath = srcpath;
                obj.htpcfg.completed.OutputFolderEditField = 1;
                obj.msgout(sprintf('Base directory for Dataset selected: %s', srcpath), 'step_complete');

            else
                obj.msgout(sprintf('%s\nAssigned Base Directory Not Found. Check Path.\n', srcpath), 'step_error');
                return;

            end
        end
        
        %CURRENTLY UNUTILIZED
        function obj = setDataObjectListeners(obj, eegdataclass)

            events_of_interest = {proc_complete, proc_warning, proc_error, proc_msg};

            % addlistener( eegdataobj, event_of_interest{i}, @

        end
        
        
        %Starts EEGLAB, if necessary, and uses the basepath, or creates it
        %if necessary, and populates the directory with the configuration
        %structure necessary for the outputs from the stages of
        %preprocessing.  The target path is then set to this base path for
        %all future outputs to be placed in the corresponding
        %subdirectories.  All corresponding configuration attributes are
        %accurately updated to reflect the target path being set and output
        %directories being generated for the user.
        function obj = targetpath2basepath(obj, targetpath, fileroot)

            obj.start_EegLab_If_Needed;

            % take general dataout directory and make basePath which
            % contains S00_RAW

            basepath = fullfile(targetpath, fileroot);
            if 7 == exist(basepath, 'dir')
                obj.msgout(sprintf('Using existing Basepath at %s', basepath), 'step_completed');

            else
                [status, msg, msgID] = mkdir(basepath);
                if status == 1
                    obj.msgout(sprintf('Basepath Directory Created at %s', basepath), 'step_completed');
                else
                    obj.msgout(sprintf('Using existing Basepath at %s', basepath), 'step_completed');
                end
            end

            obj.setBasePath(basepath);

            % create example object from configuration data to test file paths
            obj.generateConfigObject;

            obj.configObject.assignRawFile('singleFile', obj.htpcfg.rawfile)
            obj.configObject.setSubfolderAsSubjname;

            obj.htpcfg.rawsubfolder = obj.configObject.subj_subfolder;

        end

        %CURRENTLY UNUTILIZED
        function tbl_result = getDataColumn(obj, searchstr)
            try
                tbl = obj.dataTable;
                tbl_fields = fields(tbl);

                %strcmp(searchstr, tbl_fields);

                idx = cellfun(@(x) find(strcmp(x, tbl.Properties.VariableNames)), searchstr, 'UniformOutput', 0);
                idx = cell2mat(idx);
                tbl_result = tbl(:, idx);

            catch
                obj.msgout('Check Search Column Names.', 'msg_error');
            end
        end

        %Toggles the inclusion flag for each subject depending upon
        %function input.  The flag being checked at various stages of
        %preprocessing to see if the subject should be included in the
        %current processing step.
        function obj = include_all_subjects(obj, toggle)
            switch toggle
                case 'yes'
                    arrayfun(@(x) x.exclude_subject('no'), obj.sub, 'UniformOutput', false);

                case 'no'
                    arrayfun(@(x) x.exclude_subject('yes'), obj.sub, 'UniformOutput', false);
            end
        end

        %CURRENTLY UNUTILIZED
        function results = is_savefile_valid(obj)

            mode = obj.getAnalysisMode;

            switch mode

                case 'Single'

                    % check if last button is valid
                    try
                        saved = load(fullfile(obj.htpcfg.scriptPath, obj.htpcfg.saveSettingFile));

                        if ...
                                isfield(saved.localSettings.single, 'net') && ...
                                isfield(saved.localSettings.single, 'file') && ...
                                isfield(saved.localSettings.single, 'targetPath') && ...
                                isfield(saved.localSettings.single, 'basePath') && ...
                                isfield(saved.localSettings.single, 'subfolder')
                            % obj.msgout(sprintf('Save file is valid.\n'), 'step_complete');
                            results = 1;
                        else
                            obj.msgout(sprintf('Load %s file is invalid with missing fields.', obj.htpcfg.saveSettingFile), 'step_complete');
                            results = 0;
                        end
                        %disp(saved.localSettings.single);

                    catch
                        obj.msgout(sprintf('No saved single file *.mat file found.'), 'step_warning');
                        results = 0;
                    end

                case 'Group'


                    % check if last button is valid
                    try
                        saved = load(fullfile(obj.htpcfg.scriptPath, obj.htpcfg.saveSettingFile));

                        if ...
                                isfield(saved.localSettings.group, 'net') && ...
                                isfield(saved.localSettings.group, 'file') && ...
                                isfield(saved.localSettings.group, 'targetPath') && ...
                                isfield(saved.localSettings.group, 'basePath') && ...
                                isfield(saved.localSettings.group, 'subfolder')
                            % obj.msgout(sprintf('Save file is valid.\n'), 'step_complete');
                            results = 1;
                        else
                            obj.msgout(sprintf('Load %s file is invalid with missing fields.', obj.htpcfg.saveSettingFile), 'step_complete');
                            results = 0;
                        end
                        %disp(saved.localSettings.single);

                    catch
                        obj.msgout(sprintf('No saved group *.mat file found.'), 'step_warning');
                        results = 0;
                    end


                otherwise

            end

        end

        %CURRENTLY UNUTILIZED
        function obj = assignConfig2Subjects(obj)

            for i = 1:length(obj.sub)

                obj.sub(i).assigncfg(obj.htpcfg);

            end


        end

        %Creates configuration object and uses the basepath provided by the
        %user to create the specific paths utilized throughout
        %preprocessing and updates the path database for various file paths
        %to be referenced during each stage.
        function obj = generateConfigObject(obj)
            try
                obj.configObject = eegDataClass();
            catch
                eeglab;
                clear gcf;
                obj.configObject = eegDataClass();
            end


            obj.configObject.createPaths(obj.htpcfg.basePath);
            obj.htpcfg.pathdb = obj.configObject.pathdb;

        end

        %CURRENTLY UNUTILIZED
        function obj = saveLastSettings(obj)

            % check mode
            mode = obj.getAnalysisMode;

            % local savefile
            savefile = obj.htpcfg.saveSettingFile;

            %             check that all prereqs are met
            %             all "blanks" are filled in
            completed = obj.htpcfg.completed;

            %             NetTypeDropDown: 1
            %             FilenameEditField: 1
            %             OutputFolderEditField: 1
            %             PrepareStageButton: 1
            %             TargetFolderEditField: 1
            try
                localSettings = load(savefile);
                localSettings = localSettings.localSettings;
            catch
                localSettings = struct;
            end
            % check if ready for save
            switch mode
                case 'Single'

                    if completed.NetTypeDropDown && completed.FilenameEditField && completed.TargetFolderEditField && completed.OutputFolderEditField
                        ready_for_save = true;
                        obj.msgout('Valid inputs for saving "Last" settings.', 'step_complete');
                    else
                        ready_for_save = false;
                        obj.msgout('Missing Inputs for "Last"', 'step_warning');

                        completed_fields = fields(completed);

                        str = sprintf('\nCompleted Fields\n');

                        for i = 1:length(completed_fields)

                            str = sprintf('%s\t%s %d\n', str, completed_fields{i}, completed.(completed_fields{i}));

                        end

                        obj.msgout(sprintf('Input Missing: %s', str), 'step_warning');
                    end

                    if ready_for_save == true

                        %localSettings = struct();
                        localSettings.single.net = obj.htpcfg.chanNow.net_name;
                        localSettings.single.file = obj.htpcfg.rawfile;
                        localSettings.single.targetPath = obj.htpcfg.targetPath;
                        localSettings.single.basePath = obj.htpcfg.basePath;
                        localSettings.single.subfolder = obj.htpcfg.rawsubfolder;

                        save(fullfile(obj.htpcfg.scriptPath, obj.htpcfg.saveSettingFile), 'localSettings');

                        obj.msgout(sprintf('Last inputs saved in %s', obj.htpcfg.saveSettingFile), 'step_completed');

                        disp(table(fields(localSettings.single), struct2cell(localSettings.single)));

                    end

                case 'Group'
                    if completed.NetTypeDropDown && completed.FilenameEditField && completed.TargetFolderEditField
                        ready_for_save = true;

                    else
                        ready_for_save = false;
                    end

                    if ready_for_save == true

                        %localSettings = struct();
                        localSettings.group.net = obj.htpcfg.chanNow.net_name;
                        localSettings.group.file = obj.htpcfg.basePath;
                        localSettings.group.basePath = obj.htpcfg.basePath;
                        localSettings.group.targetPath = obj.htpcfg.basePath;
                        localSettings.group.subfolder = 'N/A';

                        save(fullfile(obj.htpcfg.scriptPath, obj.htpcfg.saveSettingFile), 'localSettings');
                        obj.msgout('Last inputs saved.', 'step_completed');
                        disp(localSettings);

                    end

            end


        end

        %CURRENTLY UNUTILIZED
        function obj = loadLastSettings(obj)

            mode = obj.getAnalysisMode;

            switch mode

                case 'Single'

                    tmp = load(fullfile(obj.htpcfg.scriptPath, obj.htpcfg.saveSettingFile));

                    obj.htpcfg.localSettings = tmp.localSettings;

                    obj.setElecNow(obj.htpcfg.localSettings.single.net);
                    obj.setSingleRawFile(obj.htpcfg.localSettings.single.file);
                    obj.setTargetPath(obj.htpcfg.localSettings.single.targetPath);
                    obj.setBasePath(obj.htpcfg.single.basePath);
                    obj.htpcfg.rawsubfolder = obj.htpcfg.single.subfolder;
                    %obj.setBasePath( obj.htpcfg.localSettings.single.basePath);


                case 'Group'


                    tmp = load(fullfile(obj.htpcfg.scriptPath, obj.htpcfg.saveSettingFile));

                    obj.htpcfg.localSettings = tmp.localSettings;

                    obj.htpcfg.localSettings = tmp.localSettings;

                    obj.setElecNow(obj.htpcfg.localSettings.group.net);
                    obj.setSingleRawFile(obj.htpcfg.localSettings.group.file);
                    obj.setTargetPath(obj.htpcfg.localSettings.group.targetPath);
                    obj.setBasePath(obj.htpcfg.localSettings.group.basePath);
                    obj.htpcfg.rawsubfolder = obj.htpcfg.localSettings.group.subfolder;

            end
        end

        %CURRENTLY UNUTILZED
        function openFolderInExplorer(obj, foldername)
            try
                if any(strfind(computer, 'WIN')) == 1

                    winopen(fullfile(foldername));

                else
                    system(['open ', foldername]);

                end

                obj.msgout(sprintf('Opening output directory: %s.', fullfile(foldername)), 'step_complete');

            catch
                errorMsg = lasterror;
                obj.msgout(sprintf('Error: %s', errorMsg.message), 'step_warning');

            end
        end

        %Checks the excluded flag for each subject to obtain the number of
        %subjects to be excluded froma certain stage of preprocessing
        %(currently performed in stage 4 for Component selection)
        function [n, idx] = countExcluded(o)
            validvec = zeros(1, length(o.sub));
            for i = 1:length(o.sub)

                validvec(1, i) = o.sub(i).get_exclude_switch;

            end
            idx = find(validvec);
            n = sum(validvec(1, :));
        end

        %CURRENTLY UNUTILIZED
        function o = assignStudyId(o)

            for i = 1:length(o.sub)
                o.sub(i).study_id = i;
            end

        end

        %Obtain the group information for the batch of datasets being 
        %preprocessed and display to the user.  This information contains 
        %the subfolders for each group and how many subjects are found for 
        %each subfolder (possibly condition if the subfolders represent 
        %various conditions of the study)
        function grpInfo = getGroupInfo(o)

            if length(o.sub) >= 1
                subfolders = {o.sub.subj_subfolder};
                grpInfo.names = unique(subfolders, 'stable');
                grpInfo.cnt = length(grpInfo.names);
                
                % TODO: Add conditions
            else
                o.htpcfg.grp.cnt = 0;
            end

            o.htpcfg.grp.nbgroups = grpInfo.cnt;
            o.htpcfg.grp.grouplabels = grpInfo.names;
            for i = 1 : length( o.htpcfg.grp.grouplabels )
                o.htpcfg.grp.idx(i,:) = strcmp( o.htpcfg.grp.grouplabels{i}, subfolders );
            end
            
            grpInfo = o.htpcfg.grp;
        end

        %CURRENTLY UNUTILIZED
        function o = grp_cfg_htp_precompute(o)

            sub = o.sub;

            parfor i = 1:length(sub)

                tmp_s = sub(i);

                tmp_s = evp_setfile(tmp_s);

                sub(i) = tmp_s;

            end

            o.sub = sub;


        end
        
        %CURRENTLY UNUTILIZED
        function o = grp_cfg_htp_powercalc( o, varargin )
            % requires o.htpcfg.powband.label and o.htpcfg.powband.mat can be created from XML file
            % using [powband_label, powband_mat] = o.createPowBandMat( powband )
            % where powband is the index of the powerband from XML or
            % o.xmlpower structure
            
            if nargin < 2
                runInSerial = true;
            else
                if varargin{1}
                    runInSerial = false;
                end
            end
            
            powband_label = o.htpcfg.powband.label;
            powband_mat = o.htpcfg.powband.mat;
            
            tmpsub = o.sub;
            sub_n = length(tmpsub);
            
            if runInSerial
                parforArg = 0;
            else
                parforArg = Inf;
            end
            
            parfor (i = 1:sub_n, parforArg)
                
                s = tmpsub(i);
                s.loadDataset('postcomps');
                s.setFreqTable( powband_mat );
                s.getPntsTable;
                s.generateStoreRoom;
                s.bandAverageTrials;
                s.subj_trials = s.EEG.trials;
                s.unloadDataset;
                tmpsub(i)=s;
                
            end
            
            o.sub = tmpsub;
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = grp_cfg_setGrpTitle(o, str)

            str(strfind(str, ' ')) = '_';

            o.grp.StudyStruct.cfg.name = str;
            o.grp_cfg_createFilename;
        end

        %CURRENTLY UNUTILIZED
        function str = grp_cfg_getGrpTitle(o)
            % move to non-static methods
            str = o.grp.StudyStruct.cfg.name;

        end

        %CURRENTLY UNUTILIZED
        function o = grp_cfg_createFilename(o)

            % get grp or study title
            try
                % create filename and store
                o.grp.StudyStruct.cfg.filename = ['grp_', o.grp.StudyStruct.cfg.name, '.study'];
            catch
                o.grp.StudyStruct.cfg.filename = ['grp_err_no_grp_title.study'];

            end
            try
                o.grp.StudyStruct.cfg.filepath = o.htpcfg.pathdb.group;
            catch
                disp('Error: Check if Data has been loaded');
            end

            try
                o.grp.StudyStruct.cfg.task = o.htpcfg.optnow;
            catch
                o.grp.StudyStruct.cfg.task = 'NA';
                disp('Error: No optnow defined');
            end

        end

        %CURRENTLY UNUTILIZED
        function [path, fname] = grp_cfg_getFilename(o)

            path = o.grp.StudyStruct.cfg.filepath;
            fname = o.grp.StudyStruct.cfg.filename;

        end

        %CURRENTLY UNUTILIZED
        function o = grp_cfg_setTask(o, str)

            if strcmpi(str, 'Default')

                o.grp.StudyStruct.cfg.task = char(o.htpcfg.optnow.Stage2_EpochType);

            else
                str(strfind(str, ' ')) = '_';
                o.grp.StudyStruct.cfg.task = str;
            end
            try
                o.grp.StudyStruct.cfg.condition = o.htpcfg.optnow.Stage2_EpochType{1};
            catch
                disp('Warning: Condition set as NA');
                o.grp.StudyStruct.cfg.condition = 'NA';
            end
        end

        %CURRENTLY UNUTILIZED
        function o = importSub(o, sub, basePath, csvfile, matfile)

            % creates a htpBaseMaster object with subjects only for combiner
            % update basePath for each subject
            for i = 1:length(sub), sub(i).updatePaths(basePath); end

            o.htpcfg = sub(1).htpcfg;
            o.htpcfg.pathdb = sub(1).pathdb;
            o.setBasePath(basePath);
            arrayfun(@(s) o.update_htpcfg(s), sub, 'UniformOutput', false);

            pathdb = o.htpcfg.pathdb;

            o.htpcfg.csvfile = fullfile(pathdb.analysis, csvfile);
            o.htpcfg.matfile = fullfile(pathdb.analysis, matfile);

            arrayfun(@(s) s.updateScriptPath(o.htpcfg.scriptPath), sub, 'UniformOutput', false);
            arrayfun(@(s) s.setCsv(o.htpcfg.csvfile), sub, 'UniformOutput', false);
            arrayfun(@(s) s.setMat(o.htpcfg.matfile), sub, 'UniformOutput', false);

            o.sub = sub;

        end

        %CURRENTLY UNUTILIZED
        function [res, var] = getClinicalVarAverage(o, csvcol, idkey)
            res = true;
            var = true;
            % get all ids
            ids = {o.sub.subj_basename};
            grp = categorical({o.sub.subj_subfolder});
            bad = logical(cell2mat({o.sub.exclude_switch}));

            sub.total = length(ids);
            sub.excluded = length(ids(~bad));
            sub.bad = length(ids(bad));
            group.names = unique(grp);
            group.no = countcats(grp);

            included_ids = ids(~bad);
            included_grp = grp(~bad);

            summary(grp);
            summary(included_grp);

            group.members = arrayfun(@(x) included_ids(ismember(included_grp, x)), unique(included_grp), 'uni', 0);

            count = 1;
            value = [];
            valid = [];

            for i = 1:length(group.members)

                tmparr = group.members{i};

                for j = 1:length(tmparr)

                    %[valid(i,j), calcarr(i,j)] =
                    [valid(count), value(count)] = o.getClinicalVar(csvcol, idkey, tmparr{j});

                    count = count + 1;

                end

            end

            if strcmp(class(value), 'double')
                missingvalues = length(find(~valid));
                fprintf('Variable: %s\n', csvcol);

                [a, b, c, d, e, f] = grpstats(value, grp, {'mean', 'std', 'numel', 'min', 'max', 'range'}, 0.05);
                valuetable = table(a, b, c, d, e, f);
                valuetable.Properties.VariableNames = {'mean', 'std', 'numel', 'min', 'max', 'range'};
                valuetable.Properties.RowNames = cellstr(group.names);
                disp(valuetable);
                [p, tbl] = anova1(value, grp, 'off');
                fprintf('ANOVA sig: %2.3f\n', p);
                fprintf('Missing Values: %d\n\n', missingvalues);
            end

        end

        %CURRENTLY UNUTILIZED
        function [res, var] = getClinicalVar(o, csvcol, idkey, subid)
            % get id col
            dat = o.clindata;
            try
                idcol = dat.(idkey);
            catch
                fprintf('Invalid ID Key column %s.\n\n', idkey);
                return;
            end
            % match id or no match
            match = strcmp(subid, idcol);
            ismatch = any(match);

            % get firld of interest or missing
            if ismatch == 0
                res = 0;
                var = missing();
                fprintf('No match found for ID %s.\n\n', subid);
            else
                if ismatch == 1
                    res = 1;
                    var = dat.(csvcol)(match);
                end
            end

        end

        %CURRENTLY UNUTILIZED
        function o = loadClinicalData(o, csvfile)
            o.clindata = readtable(csvfile);
        end

        %CURRENTLY UNUTILIZED
        function res = grp_cfg_Valid(o)

            % TODO check grp structure before enabling create
            % STUDY file

            o.grp.StudyStruct.cfg.name = o.study_title;
            o.grp.StudyStruct.cfg.task = o.htpcfg.optnow.Stage2_EpochType{1};
            o.grp.StudyStruct.cfg.condition = o.htpcfg.optnow.Stage2_EpochType{1};
            o.grp.StudyStruct.cfg.filename = ['grp_', o.grp.StudyStruct.cfg.name, '.study'];
            o.grp.StudyStruct.cfg.filepath = o.htpcfg.pathdb.group;
            o.grp.StudyStruct.cfg.task = char(o.htpcfg.optnow.Stage2_EpochType);

        end

        %CURRENTLY UNUTILIZED
        function o = grp_cfg_createStudyStructFromGui(o)
            try
                [mc, mm, mw] = o.tools_log; % output log
                opt = o.formatOptions; % get GUI options
            catch
                disp('Error: OptNow Missing');
            end

            % load subject list
            sub_valid = o.sub;

            % key options one set in memory
            pop_editoptions('option_storedisk', 1, ...
                'option_savetwofiles', 1);

            o.grp_cfg_setTask('rest'); % set task = epochtype from optnow (i.e. rest)

            o.grp.StudyStruct.STUDY = [];

            commands = {};
            count = 1;

            for i = 1:length(sub_valid)

                s = sub_valid(i);

                setfile = fullfile(o.htpcfg.pathdb.postcomps, s.subj_subfolder, s.filename.postcomps);
                commands = {commands{:}, ...
                    {'index', count, 'load', setfile, 'subject', s.subj_basename, 'session', 1, 'condition', 'GrpMode', ...
                    'group', s.subj_subfolder, 'dipselect', 0.15},};
                count = count + 1;

                sub_valid(i) = s;

            end


            [STUDY, ALLEEG] = std_editset(o.grp.StudyStruct.STUDY, [], 'name', o.grp.StudyStruct.cfg.name, ...
                'task', o.grp.StudyStruct.cfg.task, ...
                'filename', o.grp.StudyStruct.cfg.filename, 'filepath', o.grp.StudyStruct.cfg.filepath, ...
                'notes', 'htpBaseMaster->grp_cfg_createStudyStructFromGui', 'commands', commands);


            [STUDY, EEG] = pop_savestudy(STUDY, [], 'filename', o.grp.StudyStruct.cfg.filename, 'filepath', o.grp.StudyStruct.cfg.filepath);
            o.msgout(sprintf('Study Definition Saved: %s', fullfile(o.grp.StudyStruct.cfg.filepath, o.grp.StudyStruct.cfg.filename)), 'step_complete');

            % TODO Add where file was saved
            o.sub = sub_valid;

        end

        %CURRENTLY UNUTILIZED
        function o = grp_cfg_openStudyStructFile(o)

            [path, fname] = o.grp_cfg_getFilename;
            cmd = ...
                sprintf('[STUDY ALLEEG] = pop_loadstudy(''filename'', ''%s'', ''filepath'', ''%s'');', ...
                fname, path);
            evalin('base', '[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;')
            evalin('base', cmd);
            evalin('base', 'CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];');
            evalin('base', 'eeglab redraw');

        end

        %CURRENTLY UNUTILIZED
        function res = areSubsPresent(o)

            try
                if length(o.sub) >= 1
                    res = true;
                    o.msgout('Subjects loaded.', 'msg_step');
                else
                    res = false;
                    o.msgout('No subjects loaded.', 'msg_warning');
                end
            catch
                disp('Error: AreSubsPresent');
                res = false;
            end

        end

        %CURRENTLY UNUTILIZED
        function o = updateBasePaths(o, basePath)
            if o.areSubsPresent
                sub = o.sub;
                arrayfun(@(sub) sub.setBasepath(basePath), sub, 'UniformOutput', false);
                arrayfun(@(sub) sub.updatePaths(basePath), sub, 'UniformOutput', false);
                o.htpcfg.pathdb = o.sub(1).pathdb;
                o.sub = sub;
            end
        end
        
        %CURRENTLY UNUTILIZED
        function o = grp_cfg_createStudyStructFile(o)
            % init
            [mc, mm, mw] = o.tools_log; % output log
            opt = o.formatOptions; % get GUI options

            o.getStageCSV('postcomps', o.htpcfg.basePath);

            validObjects = o.htpcfg.objStageStatus;
            unusedObjexts = o.htpcfg.objStageStatus_completed;

            % marked bad
            load(o.htpcfg.matfile, 'sub');
            arrayfun(@(sub) sub.setCsv(o.htpcfg.csvfile), sub, 'UniformOutput', false);
            arrayfun(@(sub) sub.setMat(o.htpcfg.matfile), sub, 'UniformOutput', false);
            arrayfun(@(sub) sub.updatePaths(o.htpcfg.basePath), sub, 'UniformOutput', false);
            arrayfun(@(sub) sub.updateScriptPath(o.htpcfg.scriptPath), sub, 'UniformOutput', false); % added 08.15

            o.sub = sub;
            o.display_excluded(validObjects);
            sub_valid = sub(o.htpcfg.objStageIndex);

            o.htpcfg.objStageIndex = o.htpcfg.objStageIndex(validObjects);
            % am.htpcfg.objStageStatus = am.htpcfg.objStageStatus( validObjects );
            o.htpcfg.objStageDesc = o.htpcfg.objStageDesc(validObjects);

            %             o.sub = o.loadSub( 'postcomps' );  % retreive subs from spreadsheet
            %             arrayfun(@( s ) s.setopt( opt ), o.sub, 'uni', 0);  % assign current options to each sub
            %             objStageStatus              = o.htpcfg.objStageStatus;
            %
            %             excludedStatus = ones(length(o.sub),1);
            %             excludedStatus(objStageStatus) = false;
            %             % new code to identify and print out subjects that are excluded
            %             % and reason why
            %             total_excluded_subjects = length(o.sub(find(excludedStatus)));
            %             ex.name = {o.sub(find(excludedStatus)).subj_basename};
            %             ex.switch = {o.sub(find(excludedStatus)).exclude_switch};
            %             ex.comment = {o.sub(find(excludedStatus)).exclude_comment};
            %             ex.category = {o.sub(find(excludedStatus)).exclude_category};
            %             table(ex.name', ex.switch', cellfun( @(x) char(x), ex.category, 'uni', 0)', ...
            %                 ex.comment', 'VariableNames', {'BaseName', 'Status', 'Category', 'Comment'})
            %             o.msgout(sprintf('Number of Subjects: %d', length(o.sub(objStageStatus))));
            %             o.msgout(['' o.countStrings({o.sub(objStageStatus).subj_subfolder})]);
            %             objStageStatus_completed    = o.htpcfg.objStageStatus_completed;

            % initalize loops
            prev_files = 0;
            skip_files = 0;
            errorchk = 0;
            uniquei = 1;
            flg = 0;


            % key options one set in memory
            pop_editoptions('option_storedisk', 1, ...
                'option_savetwofiles', 1);

            o.grp_cfg_setTask(o, 'default'); % set task = epochtype from optnow (i.e. rest)

            o.grp.StudyStruct.STUDY = [];

            commands = {};
            count = 1;

            for i = 1:length(sub_valid)

                s = sub_valid(i);

                setfile = fullfile(o.htpcfg.pathdb.preanalysis, s.subj_subfolder, s.filename.postcomps);
                commands = {commands{:}, ...
                    {'index', count, 'load', setfile, 'subject', s.subj_basename, 'session', 1, 'condition', 'GrpMode', ...
                    'group', s.subj_subfolder, 'dipselect', 0.15},};
                count = count + 1;

                sub_valid(i) = s;
            end


            [STUDY, ALLEEG] = std_editset(o.grp.StudyStruct.STUDY, [], 'name', o.grp.StudyStruct.cfg.name, ...
                'task', o.grp.StudyStruct.cfg.task, ...
                'filename', o.grp.StudyStruct.cfg.filename, 'filepath', o.grp.StudyStruct.cfg.filepath, ...
                'notes', 'htpBaseMaster->grp_cfg_createStudyStructFromGui', 'commands', commands);


            [STUDY, EEG] = pop_savestudy(STUDY, [], 'filename', o.grp.StudyStruct.cfg.filename, 'filepath', o.grp.StudyStruct.cfg.filepath);
            o.msgout(sprintf('Study Definition Saved: %s', fullfile(o.grp.StudyStruct.cfg.filepath, o.grp.StudyStruct.cfg.filename)), 'step_complete');
            % TODO Add where file was saved

            o.sub = sub_valid;

        end

        %CURRENTLY UNUTILIZED
        function o = grp_cfg_loadStudyStruct(o)
            o.grp.StudyStruct.STUDY
            o.grp.StudyStruct.ALLEEG
        end

        %CURRENTLY UNUTILIZED
        function o = grp_cfg_openEEGLAB(o)
            o.start_EegLab_If_Needed;
            % load last STUDY file
            if isempty(o.grp.StudyStruct.STUDY) || isempty(o.grp.StudyStruct.ALLEEG)
                [o.grp.StudyStruct.STUDY, o.grp.StudyStruct.ALLEEG] = pop_loadstudy('filename', o.grp.StudyStruct.cfg.filename, ...
                    'filepath', o.grp.StudyStruct.cfg.filepath);
            else

            end

            assignin('base', 'ALLEEG', o.grp.StudyStruct.ALLEEG);
            assignin('base', 'STUDY', o.grp.StudyStruct.STUDY);
            eeglab redraw;

            [EEG, ALLEEG, CURRENTSET] = eeg_retrieve(ALLEEG, 1);

            [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'retrieve', [1:length(ALLEEG)], 'study', 1);
            CURRENTSTUDY = 1;

            STUDY = std_makedesign(STUDY, ALLEEG, ...
                1, 'variable1', '', 'variable2', 'group', 'name', 'STUDY.design 1', 'pairing1', 'on', 'pairing2', 'off', ...
                'delfiles', 'off', 'defaultdesign', 'off', 'values2', {'Group2', 'Group3'}, ...
                'subjselect', STUDY.subject);
            [STUDY, EEG] = pop_savestudy(STUDY, ALLEEG, 'savemode', 'resave');
        end

        %CURRENTLY UNUTILIZED
        function o = grp_cfg_precompute(o, mode)
            pop_editoptions('option_storedisk', 1, ...
                'option_savetwofiles', 1);

            % load last STUDY file
            [STUDY, ALLEEG] = pop_loadstudy('filename', o.grp.StudyStruct.cfg.filename, ...
                'filepath', o.grp.StudyStruct.cfg.filepath);

            switch mode
                case 'chan'
                    STUDY = std_makedesign(STUDY, ALLEEG, ...
                        1, 'variable1', '', 'variable2', 'group', 'name', 'STUDY.design 1', 'pairing1', 'on', 'pairing2', 'off', ...
                        'delfiles', 'off', 'defaultdesign', 'off', 'values2', {'Group2', 'Group3'}, ...
                        'subjselect', STUDY.subject);
                    [STUDY, EEG] = pop_savestudy(STUDY, ALLEEG, 'savemode', 'resave');

                    [STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, {}, 'interp', 'on', ...
                        'recompute', 'on', 'spec', 'on', 'specparams', {'specmode', 'fft', 'logtrials', 'off'});

            end

            o.grp.StudyStruct.STUDY = STUDY;
            o.grp.StudyStruct.ALLEEG = ALLEEG;


        end

        %CURRENTLY UNUTILIZED
        function o = grp_cfg_prepareContDatasets(o)
            
            % replaced with bst_prepareContinuousData

        end

        %CURRENTLY UNUTILIZED
        function o = grp_cfg_loadbrainstorm(o)

            %              sub = o.sub;
            %
            %             for i = 1 : length( sub )
            %
            %                 s = sub(i);
            %
            %                 RawFiles{i} = fullfile(s.pathdb.source, ...
            %                     s.subj_subfolder, s.filename.source);
            %                 SubjectNames{i} = sprintf('%s_N%d_%s', s.subj_subfolder, i, s.subj_basename);
            %
            %                 sub(i) = s;
            %             end
            %             sFiles = [];
            %
            %             blank = {''};


            % init
            [mc, mm, mw] = o.tools_log; % output log
            try
                opt = o.formatOptions; % get GUI options
            catch
                o.msgout('Not in Preprocessing Gui', 'msg_warning');
                opt = o.sub(1).htpcfg.opt;
                %      optnow = o.sub(1).htpcfg.optnow;
            end
            % create into continuous and place in source directory
            %o.preprocess_stage5_brainstorm;

            o.sub = o.loadSub('postcomps'); % retreive subs from spreadsheet
            arrayfun(@(s) s.setopt(opt), o.sub, 'uni', 0); % assign current options to each sub
            objStageStatus = o.htpcfg.objStageStatus;
            objStageStatus_completed = o.htpcfg.objStageStatus_completed;

            o.display_excluded(objStageStatus);
            sub = o.sub(objStageStatus);
            % initalize loops
            prev_files = 0;
            skip_files = 0;
            errorchk = 0;
            uniquei = 1;
            flg = 0;


            % key options one set in memory
            pop_editoptions('option_storedisk', 1, ...
                'option_savetwofiles', 1);

            %o.grp_cfg_setTask( o, 'default' ); % set task = epochtype from optnow (i.e. rest)

            %o.grp.StudyStruct.STUDY = [];

            commands = {};
            count = 1;
            RawFiles = {};
            sFiles = [];
            SubjectNames = {};

            for i = 1:length(sub)
                s = sub(i);

                % if ismember(i, objStageStatus)

                RawFiles{count} = fullfile(s.pathdb.source, ...
                    s.subj_subfolder, sprintf('G%s-N%s', s.subj_subfolder, s.filename.('postcomps')));
                SubjectNames{count} = [s.subj_subfolder, '_', s.subj_basename];
                count = count + 1;

                %    end
            end

            blank = {''};

            % Start a new report
            bst_report('Start', sFiles);


            % Process: Create link to raw file
            for i = 1:length(RawFiles)

                sFiles = bst_process('CallProcess', 'process_import_data_raw', sFiles, [], ...
                    'subjectname', ['G4_', SubjectNames{i}], ...
                    'datafile', {RawFiles{i}, 'EEG-EEGLAB'}, ...
                    'channelreplace', 71, ...
                    'channelalign', 1, ...
                    'evtmode', 'value');
            end

            % Process: Create link to raw file
            %                         for i = 1:length( RawFiles )
            %
            %                             % Process: Set channels type
            %                             sFiles = bst_process('CallProcess', 'process_channel_settype', sFiles, [], ...
            %                                 'subjectname',    ['G4_' SubjectNames{i}], ...
            %                                 'sensortypes', '17,38,43:44, 48:49,56,73,81,88,107,113:114,119:121,125:128', ...
            %                                 'newtype',     'EEG');
            %
            %                         end


            % Process: Set channel file
            sFiles = bst_process('CallProcess', 'process_import_channel', sFiles, [], ...
                'usedefault', 71, ... % ICBM152: GSN HydroCel 128 E1
                'channelalign', 1, ...
                'fixunits', 1, ...
                'vox2ras', 1);




            % Save and display report
            ReportFile = bst_report('Save', sFiles);
            bst_report('Open', ReportFile);

            %bst_report('Open', ReportFile);
            % bst_report('Export', ReportFile, ExportDir);


        end
        
        %CURRENTLY UNUTILIZED
        function o = grp_cfg_bst_set_chan( o )
            
            sFiles = bst_process('CallProcess', 'process_select_files_data', [], []);
            
            
            for i = 1 : length(sFiles)
                
                s = sFiles(i);
                
                sFiles = bst_process('CallProcess', 'process_import_channel', sFiles, [], ...
                    'usedefault',   71, ...  % ICBM152: GSN HydroCel 128 E1
                    'channelalign', 1, ...
                    'fixunits',     1, ...
                    'vox2ras',      1);
                sFiles(i) = s;
            end
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = grp_cfg_bst_headmodel_sources( o )
            
            ProtocolInfo = bst_get('ProtocolInfo');
            
            sFiles = bst_process('CallProcess', 'process_select_files_data', [], []);
            %sStudy = bst_get('Study', sAvgData(1).iStudy);
            %%SubjectNames = {sAvgData(:).SubjectName};
           % Condition = {sAvgData(:).Condition};
            
          %  Condition(contains(SubjectNames, 'Group2')) = {'FXS'};
            
          %  Condition(contains(SubjectNames, 'Group3'))=  {'TDC'};
            
           % sFiles = [];
            %Process: Compute head model
            sFiles = bst_process('CallProcess', 'process_headmodel', sFiles, [], ...
                'Comment',     '', ...
                'sourcespace', 1, ...  % Cortex surface
                'volumegrid',  struct(...
                'Method',        'isotropic', ...
                'nLayers',       17, ...
                'Reduction',     3, ...
                'nVerticesInit', 4000, ...
                'Resolution',    0.005, ...
                'FileName',      ''), ...
                'meg',         3, ...  % Overlapping spheres
                'eeg',         3, ...  % OpenMEEG BEM
                'ecog',        2, ...  % OpenMEEG BEM
                'seeg',        2, ...  % OpenMEEG BEM
                'openmeeg',    struct(...
                'BemSelect',    [1, 1, 1], ...
                'BemCond',      [1, 0.0125, 1], ...
                'BemNames',     {{'Scalp', 'Skull', 'Brain'}}, ...
                'BemFiles',     {{}}, ...
                'isAdjoint',    0, ...
                'isAdaptative', 1, ...
                'isSplit',      0, ...
                'SplitLength',  4000));

sFiles = bst_process('CallProcess', 'process_select_files_data', [], []);

           
            % Process: Compute covariance (noise or data)
            sFiles = bst_process('CallProcess', 'process_noisecov', sFiles, [], ...
                'baseline',       [-500, -0.001], ...
                'datatimewindow', [0, 500], ...
                'sensortypes',    'MEG, EEG, SEEG, ECOG', ...
                'target',         1, ...  % Noise covariance     (covariance over baseline time window)
                'dcoffset',       1, ...  % Block by block, to avoid effects of slow shifts in data
                'identity',       1, ...
                'copycond',       0, ...
                'copysubj',       0, ...
                'copymatch',      0, ...
                'replacefile',    1);  % Replace
            
            % Process: Compute sources [2018]
            sFiles = bst_process('CallProcess', 'process_inverse_2018', sFiles, [], ...
                'output',  1, ...  % Kernel only: shared
                'inverse', struct(...
                'Comment',        'MN: EEG', ...
                'InverseMethod',  'minnorm', ...
                'InverseMeasure', 'amplitude', ...
                'SourceOrient',   {{'fixed'}}, ...
                'Loose',          0.2, ...
                'UseDepth',       1, ...
                'WeightExp',      0.5, ...
                'WeightLimit',    10, ...
                'NoiseMethod',    'none', ...
                'NoiseReg',       0.1, ...
                'SnrMethod',      'fixed', ...
                'SnrRms',         1e-06, ...
                'SnrFixed',       3, ...
                'ComputeKernel',  1, ...
                'DataTypes',      {{'EEG'}}));
            
            
           
            
            % Save and display report
            ReportFile = bst_report('Save', sFiles);
            bst_report('Open', ReportFile);
            
            
            
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = grp_calc_pac( o )
           
            % get all sources (no tag filtering)
            sFiles = o.bst_getSources;
            
            grp1 = 'group2';
            grp2 = 'group3';
            
            sFilesNames = {sFiles(:).SubjectName};
            
            grp1_idx = contains(sFilesNames, grp1, 'IgnoreCase',true);
            grp2_idx = contains(sFilesNames, grp2, 'IgnoreCase',true);
            
            groupidx = {grp1_idx, grp2_idx};
            
            grp_sFile = sFiles(grp2_idx);
            
            for i = 1 : length( groupidx )
%                bstobj = o.bst_scoutTimeSeries( grp_sFile(1), ... 
%                    [1 80], ... 
%                    %{'Mindboggle', );
                grp_sFile = sFiles( groupidx{i} );
                
                % call direct PAC
                % bst_dpac( s, timew, scouts, nesting, nested, numfreqs, parallel)
                % bst_dpac( s, [10,40], {'Mindboggle', {'lateraloccipital
                % L', 'lateraloccipital R'}}, [3,12], [20,80], 4, 1)
            
                grp_sFile = o.bst_dpac( grp_sFile, [10,40], {'Mindboggle', {'lateraloccipital L', 'lateraloccipital R'}}, ... 
                    [3,5], [30,40], 0, 0 );                
                    grp_sFile1 = o.bst_dpac( grp_sFile(1), [10,40], {'Mindboggle', {'lateraloccipital L', 'lateraloccipital R'}}, ... 
                    [3,5], [30,40], 0, 0 );                
            
      
                
                ReportFile = bst_report('Save', grp_sFile);
                bst_report('Open', ReportFile);
                
            end
            ProtocolInfo = bst_get('ProtocolInfo');
            %
%             N = length(grp_sFile);
%             for i = 1 : N
%                 s = grp_sFile(i);
%                 
%                 
%                 
%                 grp_sFile(i) = s;
%                 o.msgout(sprintf('Progress: subject %d/%d\n', i, N));
%             end
            

        end
        
        %CURRENTLY UNUTILIZED
        function s = bst_dpac( o, s, timew, scouts, nesting, nested, numfreqs, parallel)
            % Process: Phase-amplitude coupling
            s = bst_process('CallProcess', 'process_pac', s, [], ...
                'timewindow',     timew, ...
                'scouts',         scouts, ...
                'scoutfunc',      1, ...  % Mean
                'scouttime',      1, ...  % Before
                'nesting',        nesting, ...
                'nested',         nested, ...
                'numfreqs',       numfreqs, ...
                'parallel',       parallel, ...
                'ismex',          1, ...
                'max_block_size', 6, ...
                'avgoutput',      0, ...
                'savemax',        0);
            
            scout_ts = bst_process('in_bst_matrix', bstobj.FileName);
            
        end    

        %CURRENTLY UNUTILIZED
        function o = exportRawSignal( o )
            
            o.updateBasePaths(o.htpcfg.basePath);
            resultTable = {};
            % loop
            for i = 1 : length( o.sub )
            
                s = o.sub(i);
                
                % load subject & dataset
               % s.loadDataset('postcomps');
                
              %  s.modifySignal('removeEpochs');

                % [header, row] = s.storeSignal;
                [header, row] = s.signalRow;
               % resultTable = resultTable
                resultTable = [resultTable;row];
                % save files
            
            % close dataset
            
            % add info to htpcfg
           
            end
            
            resultTable = cell2table(resultTable);
            resultTable.Properties.VariableNames = header;
            
            csvfile = fullfile(o.htpcfg.pathdb.signal, ['A' o.htpcfg.timetag2 '_signal_key.csv']);
            writetable( resultTable, csvfile);
        end

        %CURRENTLY UNUTILIZED
        function o = update_excluded(o)

            % get excluded true
            excludeIdx = logical(cell2mat({o.sub(:).exclude_switch}));

            csvExcludedSubs_names = {o.sub(excludeIdx).subj_basename}';
            csvExcludedSubs_group = categorical({o.sub(excludeIdx).subj_subfolder}');
            csvExcludedSubs_desc = categorical(o.htpcfg.objStageDesc(excludeIdx));

            % accouting table for excluded subjects
            cnt = []; % init structure

            % count all subjects in sub array
            cnt.orig = countcats(categorical({o.sub(:).subj_subfolder}))'; % original

            % count sujects not excluded
            cnt.remain = countcats(categorical({o.sub(~excludeIdx).subj_subfolder}))'; % bad data

            % count excluded
            cnt.excluded = countcats(categorical({o.sub(excludeIdx).subj_subfolder}))'; % bad data


            cnt.table = table(cnt.orig, cnt.remain, cnt.excluded);
            cnt.table.Properties.RowNames = unique({o.sub(:).subj_subfolder});
            cnt.table.Properties.VariableNames = {'Orig', 'Remain', 'Excluded'};

            if isempty(cnt.excluded), cnt.excluded = zeros(size(cnt.orig)); end

            if cnt.excluded == 0
                o.clear_excluded_from_gui();
            end

            detail.table = table(csvExcludedSubs_names, csvExcludedSubs_group, csvExcludedSubs_desc);
            detail.table.Properties.VariableNames = {'BaseName', 'Category', 'Comment'};
            disp(detail.table);
            disp(cnt.table);

            o.htpcfg.excluded.detail = detail;
            o.htpcfg.excluded.cnt = cnt;

        end

        %CURRENTLY UNUTILIZED
        function o = clear_excluded_from_gui(o)

            csvExcludedSubs_names = {'No excluded subjects'};
            csvExcludedSubs_group = {'NA'};
            csvExcludedSubs_desc = {'NA'};

        end

        %Compile the excluded subjects' information such as subject name,
        %group, and description to compose a table of all the excluded
        %subjects for the user to see and use to determine bad data, etc.
        function o = display_excluded(o, objStageStatus)

            csvExcludedSubs_names = {o.sub(~o.htpcfg.objStageIndex).subj_basename}';
            csvExcludedSubs_group = categorical({o.sub(~o.htpcfg.objStageIndex).subj_subfolder}');
            csvExcludedSubs_desc = categorical(o.htpcfg.objStageDesc(~o.htpcfg.objStageIndex));

            for i = 1:length(o.sub), o.sub(i).exclude_switch = ~o.htpcfg.objStageIndex(i); ...
                    o.sub(i).exclude_comment = o.htpcfg.objStageDesc{i}; ...
                    o.sub(i).exclude_category = o.htpcfg.objStageDesc(i); ...
            end


        cnt = [];
        cnt.orig = countcats(categorical({o.sub(:).subj_subfolder}))'; % original
        cnt.remain = countcats(categorical({o.sub(o.htpcfg.objStageIndex).subj_subfolder}))'; % bad data
        cnt.excluded = countcats(categorical({o.sub(~o.htpcfg.objStageIndex).subj_subfolder}))'; % bad data
        if isempty(cnt.excluded), cnt.excluded = zeros(size(cnt.orig)); end
        cnt.table = table(cnt.orig, cnt.remain, cnt.excluded);
        cnt.table.Properties.RowNames = unique({o.sub(:).subj_subfolder});
        cnt.table.Properties.VariableNames = {'Orig', 'Remain', 'Excluded'};

        excludedStatus = ones(length(o.sub), 1);
        excludedStatus(objStageStatus) = false;

        %             total_excluded_subjects = length(o.sub(find(excludedStatus)));
        %             ex.name = {o.sub(find(excludedStatus)).subj_basename};
        %             ex.switch = {o.sub(find(excludedStatus)).exclude_switch};
        %             ex.comment = {o.sub(find(excludedStatus)).exclude_comment};
        %             ex.category = {o.sub(find(excludedStatus)).exclude_category};
        %             table(ex.name', ex.switch', cellfun( @(x) char(x), ex.category, 'uni', 0)', ...
        %                 ex.comment', 'VariableNames', {'BaseName', 'Status', 'Category', 'Comment'})
        %             %  o.msgout(sprintf('Number of Subjects: %d', length(o.sub(objStageStatus))));
        %             %  o.msgout(['' o.countStrings({o.sub(objStageStatus).subj_subfolder})]);
        %
        %
        %

        if cnt.excluded == 0
            csvExcludedSubs_names = {'No excluded subjects'};
            csvExcludedSubs_group = {'NA'};
            csvExcludedSubs_desc = {'NA'};
        end

        detail.table = table(csvExcludedSubs_names, csvExcludedSubs_group, csvExcludedSubs_desc);
        detail.table.Properties.VariableNames = {'BaseName', 'Category', 'Comment'};
        disp(detail.table);
        disp(cnt.table);

        o.htpcfg.excluded.detail = detail;
        o.htpcfg.excluded.cnt = cnt;


        end

        %Obtain list of options for the Quick Analysis dropdown in the
        %Subject-Level analysis fields to present to the user for selection
        function items = getSingleSubjectAnalysisItems(o)

            items = {'quickSpect', 'EEG Browser', 'EEGPlot', 'EEGLAB'};

        end

        %Upon selection of the quickspect option for subject-level analysis
        %the quickspect function is run for the selected subject 
        function o = quickAnalysisHandler(o, action, index)

            items = o.getSingleSubjectAnalysisItems;

            s = o.sub(index);

            switch action

                case items{1}
                    s.quickSpect;
                case items{2}
                case items{3}
                case items{4}

            end

        end

        %CURRENTLY UNUTILIZED
        function o = prepareMRA(o, s)

            o.spectSeriesPlot(s);


        end

        %CURRENTLY UNUTILIZED
        function o = updateMraStatusCounts(o)

            for i = 1:4

                status{i} = find(i == [o.sub.exclude_status]);

            end

            for i = 1:4

                status_names{i} = {o.sub(status{i}).subj_basename};

            end

            o.htpcfg.mra.status = status;
            o.htpcfg.mra.status_names = status_names;


        end

        %CURRENTLY UNUTILIZED  
        function o = spectSeriesPlot(o, s)

            % s = o.sub(idx);

            o.check_stages(s);

            stageidx = find(cell2mat(o.stage_info(2, :)));


            for i = 1:length(stageidx)

                testfile = fullfile(s.pathdb.(o.stage_info{1, stageidx(i)}), s.subj_subfolder, ...
                    s.filename.(o.stage_info{1, stageidx(i)}));


                if isfile(testfile)

                    current_stage = o.stage_info{1, stageidx(i)};
                    s.loadDataset(current_stage);
                    s.quickSpect;

                    % figfile{i} = fullfile(o.htpcfg.pathdb.figs, [s.subj_basename '_' current_stage '_topospect.tiff']);
                    figfile = fullfile(o.htpcfg.pathdb.figs, [s.subj_basename, '_topospect.tiff']);
                    d = get(gcf, 'Position');
                    set(gcf, 'Position', [d(1), d(2), d(3) * 2, d(4) * 2]);
                    s.unloadDataset;
                    F = getframe(gcf);
                    [X, Map] = frame2im(F);
                    fntsize = 24;
                    % X = imcapture( gcf )
                    %saveas(gcf,figfile{i}, 'png')
                    str = [s.subj_basename, ': ', current_stage];


                    if strcmp('import', current_stage)
                        str_exclude = sprintf('Group: %s Excluded: %s', s.subj_subfolder, mat2str(s.exclude_switch));
                        X = insertText(X, [0, 0], [str, ' ', str_exclude], 'FontSize', fntsize);
                    end

                    if strcmp('preica', current_stage)
                        str_chanremove = sprintf('(%d): %s', length(s.proc_ipchans), num2str(s.proc_ipchans));
                        X = insertText(X, [0, 0], [str, ' ', str_chanremove], 'FontSize', fntsize);
                    end

                    if strcmp('postica', current_stage)
                        str_time = sprintf('%.2f%% (%.0f secs)', (s.proc_xmax_epoch / s.proc_xmax_raw)*100, s.proc_xmax_epoch);
                        X = insertText(X, [0, 0], [str, ' ', str_time], 'FontSize', fntsize);
                    end

                    if strcmp('postcomps', current_stage)
                        str_compremove = sprintf('(%d): %s', length((s.proc_removeComps)), num2str(s.proc_removeComps));
                        X = insertText(X, [0, 0], [str, ' ', str_compremove], 'FontSize', fntsize);
                    end

                    %imshow(X);
                    imshow(X);

                    imwrite(X, figfile, 'writemode', 'append');

                    close(gcf);

                end
            end


            info = imfinfo(figfile);
            n = length(info);

            if n > 1

                sub_cols = 2;
                sub_rows = n / sub_cols;
                sub_rows = sub_rows + mod(n, 2);

            else
                sub_cols = 1;
                sub_rows = 1;
            end

            figure;
            for i = 1:n

                o.subplottight(sub_rows, sub_cols, i);
                imshow(imread(figfile, i), 'border', 'tight');

            end

            d = get(gcf, 'Position');
            set(gcf, 'Position', [d(1), d(2), d(3) * 3, d(4) * 3]);

            figfile_all = fullfile(o.htpcfg.pathdb.figs, o.create_filename_spectfig(s));

            s.mra.filename.spectfig = o.create_filename_spectfig(s);

            F = getframe(gcf);
            [X, Map] = frame2im(F);

            imwrite(X, figfile_all);
            close(gcf);
            delete(figfile);


        end

        %Create filename for a location to save the spectral figure 
        %generated for the selected subject in the subject-level analysis 
        %menu
        function str = create_filename_spectfig(o, s)
            try
                str = s.mra.filename.spectfig;
            catch
                str = [s.subj_basename, '_topospect_sum.png'];
            end
        end

        %CURRENTLY UNUTILIZED
        function arr = mra_getBaseNames(o)

            arr = {o.sub.subj_basename};

        end

        %CURRENTLY UNUTILIZED
        function tbl = getFilenameTable(o)

            tbl = table(o.fnlist, 'VariableNames', {'FileNames'});

        end

        % clinical csv assignment functions
        function res = assign_auxcsv_other(o, varargin)

   
               
            if nargin < 2

                str = sprintf('%s\t%s\t%s\n', o.htpcfg.auxcsv.colnames{:});
                o.msgout(['Available Columns:', str]);
                res = false(1, length(o.sub(o.htpcfg.objStageIndex)));
                o.msgout(sprintf('Total Fields: %d', length(o.htpcfg.auxcsv.colnames)));
                o.msgout(sprintf('Valid Subjects: %d', length(o.sub(o.htpcfg.objStageIndex))));
                o.msgout('No field name input for assignment.');
            else
                            varargin = varargin{1};
            end
            for j = 1 : length( varargin )
                
                var = varargin{j};
                
                % validate field name
                subidx = o.htpcfg.auxcsv.subidx;
                varidx = validate_auxcsv_field(o, var);
                subtable = o.htpcfg.auxcsv.tbl;
                celltable = table2cell(o.htpcfg.auxcsv.tbl);
                
                validsub = o.sub;
                validsub_n = length(validsub);
                
                basename_catalog = celltable(:, subidx);
                validname = zeros(1, validsub_n);
                preexist_missing(j) = 0;
                
                for i = 1:length(validsub)
                    
                    basename = validsub(i).subj_basename;
                    test = strcmp(basename, basename_catalog);
                    
                    if any(test)
                        tblidx = find(test);
                        tmpvalue = table2array(subtable(tblidx, var));
                        % sex = table2array(subtable(tblidx, var2));
                        validsub(i).meas.(var) = tmpvalue;
                        
                        tmpclass = class(tmpvalue);
                        
                        switch tmpclass
                            case {'class', 'cell'}
                            if strcmp(tmpvalue{1}, 'NA'), preexist_missing(j) = preexist_missing(j) + 1; end    
                            str = sprintf('%d: %s (%s: %s)', i, basename, var, tmpvalue{1});
                            case 'double'
                                str = sprintf('%d: %s (%s: %.2f)', i, basename, var, tmpvalue);    
                            case 'datetime'
                                str = sprintf('%d: %s (%s: %s)', i, basename, var, tmpvalue);
                            otherwise
                                        str = sprintf('%d: %s (%s: %s)', i, basename, var, 'Unknown Type');
                        end
                        
                        % validsub(i).subj_gender = sex{1};
                        %tmpstr = o.variable2string(tmpvalue);

                        o.msgout(str);
                        validname(i) = true;
                    else
                        tmpvalue = missing;
                      %  sex = missing;
                        validsub(i).meas.(var) = tmpvalue;
                       % validsub(i).subj_gender = sex;
                        str = sprintf('%d: %s (missing)', i, basename);
                        o.msgout(str);
                        validname(i) = false;
                    end
                    
                end
                
                res = any(~validname);
                if res == true
                    str = sprintf('Missing Subject Names. Check files.\n');
                    o.msgout(str, 'step_warning');
                else
                    str = sprintf('%s: All subjects matched, though pre-existing missing data might be present.\nData stored in sub.meas.(fieldname)', var);
                    o.msgout(str, 'step_complete');
                end
  
            end
            
            for i = 1 : length( varargin )
                var = varargin{i};
                str = sprintf('Field: %s, Pre-existing Missing (NA): %d', var, preexist_missing(i));
                o.msgout(str, 'step_complete');
            end

            
        end

        %Field name to be used as a key lookup field in a
        %auxillary clinical csv is assigned
        function res = assign_auxcsv_subid(o, var)
            
            varname = 'SubjectID';

            if nargin < 2
                sprintf('Warning: No %s field named.\n', var);
                o.msgout(str, 'step_warning');
                res = false;
            end

            o.htpcfg.auxcsv.subidx = validate_auxcsv_field(o, var);

        end

        %Ensure that the assigned key lookup field exists and alert the user
        %upon whether it the field can be found
        function idx = validate_auxcsv_field(o, var)

            % validate field name
            if any(strcmp(var, o.htpcfg.auxcsv.colnames))
                idx = find(strcmp(var, o.htpcfg.auxcsv.colnames));
                str = sprintf('Validation: Field [%s] assigned (index: %d)\n', var, idx);
                o.msgout(str);
            else
                str = sprintf('Validation: Field [%s] not found.\n', var);
                idx = 0;
                o.msgout(str, 'step error');
            end


        end

        
        function res = assign_auxcsv_age_sex(o, var, var2)
            varname = 'Age';

            if nargin < 2
                o.msgout(sprintf('Warning: No Age field named.\n'), 'step_warning');
                res = false;
            end

            % validate field name
            subidx = o.htpcfg.auxcsv.subidx;
            varidx = validate_auxcsv_field(o, var);
            subtable = o.htpcfg.auxcsv.tbl;
            celltable = table2cell(o.htpcfg.auxcsv.tbl);

            validsub = o.sub;
            validsub_n = length(validsub);

            basename_catalog = celltable(:, subidx);
            validname = zeros(1, validsub_n);

            for i = 1:length(validsub)

                basename = validsub(i).subj_basename;
                test = strcmp(basename, basename_catalog);

                if any(test)
                    tblidx = find(test);
                    age = table2array(subtable(tblidx, var));
                    sex = table2array(subtable(tblidx, var2));
                    validsub(i).subj_age = age;
                    validsub(i).subj_gender = sex{1};
                    str = sprintf('%d: %s (Sex: %s Age: %2.1f)', i, basename, sex{1}, age);
                    o.msgout(str);
                    validname(i) = true;
                else
                    age = missing;
                    sex = missing;
                    validsub(i).subj_age = age;
                    validsub(i).subj_gender = sex;
                    str = sprintf('%d: %s (Sex: %s Age: %s)', i, basename, 'missing', 'missing');
                    o.msgout(str);
                    validname(i) = false;
                end

            end

            res = any(~validname);
            if res == true
                str = sprintf('Missing Subject Names. Check files.\n');
                o.msgout(str, 'step_warning');
            else
                str = sprintf('%s: All subjects matched.\n', varname);
                o.msgout(str, 'step_complete');
            end

        end

        %CURRENTLY UNUTILIZED
        function res = assign_auxcsv_sex(o, var)
            varname = 'Sex';
            if nargin < 2
                o.msgout(sprintf('Warning: No Sex field named.\n'), 'step_warning');
                res = false;
            end


        end

    end


    methods (Static)
        
        %CURRENTLY UNUTILIZED
        function str = variable2string( tmparr, varargin )
            
            if nargin < 2
                no_elements = 1;
            else
                no_elements = varargin{1};
            end
            
            showExItemsStr = @(x) sprintf('%s,',x{1:no_elements});
            showExItemsNum = @(x) sprintf('%.1f,',x(1:no_elements));
            showExItemsDateTime = @(x) sprintf('%s, ', string(x(1:no_elements)'));
            
            switch class( tmparr )
                case 'double'
                    str = showExItemsNum( tmparr );
                case 'cell'
                    str = showExItemsStr( tmparr );
                case 'datetime'
                    str = showExItemsDateTime( tmparr );
                otherwise
                    str = 'no preview';
            end
        end
        
        %CURRENTLY UNUTILIZED
        function res = showTimeStamp(), datetime.setDefaultFormats('default','hh:mm:ss'); res = datetime; end
        %CURRENTLY UNUTILIZED
        function res = showTimeDateStamp(), datetime.setDefaultFormats('default','MMddyy hh:mm'); res = datetime; end
  
        %Composes a csv and mat file name for output based upon datetime 
        %string
        function [csvfile, matfile] = createCsvFileName()

            timetag2 = datestr(now, 'yymmddHHMM');
            basename = ['A', timetag2, '_subjTable_combined'];
            csvfile = [basename, '.csv'];
            matfile = [basename, '.mat'];

        end

        %CURRENTLY UNUTILIZED
        function h = subplottight(n, m, i)
            [c, r] = ind2sub([m, n], i);
            ax = subplot('Position', [(c - 1) / m, 1 - (r) / n, 1 / m, 1 / n]);
            if (nargout > 0)
                h = ax;
            end

        end

        %CURRENTLY UNUTILIZED
        function hname = getHostName()
            [~, hname] = system('hostname');
            hname = strtrim(hname);
        end

        %Check the specified EEGLAB plugin for existence within the EEGLAB
        %base directory to ensure it exists since it may be utilized
        %throughout the preprocessing that may occur
        function result = checkEegPlugin(strplugin, strpath)
           
            d = dir(strpath);
            isub = [d(:).isdir];
            subfolder = {d(isub).name};
            subfolder(ismember(subfolder, {'.', '..'})) = [];

            results = strfind(lower(subfolder), lower(strplugin));
            results = cell2mat(results);

            if any(results) == 1
                result = 1;
            else
                result = 0;
            end
        end

        %Retrieve list of files that contain study related data that will
        %be preprocessed in the following stages.  The raw directory of the 
        %base path set by the user is searched for the files that will be
        %named in the list, subdirectories will be accounted for and 
        %searched as well.
        function [filelist, out] = getFileList(filter, strpath)
            % gets file list of study related data files
            % needs config dummy class object
            v = version;
            if isstruct(filter)
                filter = filter.filter;

            end
            % retrieves study specific files for processing
            tmpfolders = {};
            tmpfiles = {};
            tmpsfolders = {};

            % get folder names
            d = dir(strpath);
            isub = [d(:).isdir];
            subfolder = {d(isub).name};
            subfolder(ismember(subfolder, {'.', '..'})) = [];

            cellcat = @(x, y) [x, y];

            % if no subdirectories, make subfolder empty string.
            if isempty(subfolder), subfolder = {''}; end

            for i = 1:length(subfolder)

                % create list of filename (could pre-process here with filter)
                rawFileList = dir([strpath, char(subfolder{i}), filesep(), filter]);

                [sfolders{1:length(rawFileList)}] = deal(subfolder{i});

                if strcmp(v, '9.0.0.370719 (R2016a)')
                    tmpfolders = cellcat(tmpfolders, subfolder{i});
                else
                    tmpfolders = cellcat(tmpfolders, {rawFileList(:).folder});
                end

                tmpfiles = cellcat(tmpfiles, {rawFileList(:).name});
                tmpsfolders = cellcat(tmpsfolders, sfolders);

                sfolders = {};
                rawFileList = {};


            end

            tmppath = cell(1, length(tmpsfolders));
            [tmppath{:}] = deal(strpath);

            try

                tmppath = cellfun(@(c, d) [c, d], tmppath, tmpsfolders, 'uni', false);
                tmpfull = cellfun(@(c, d) [c, filesep(), d], tmppath, tmpfiles, 'uni', false);
                tmpsubfolder = cellfun(@(c, d) c, tmpsfolders, 'uni', false);
                tmpname = cellfun(@(d) d, tmpfiles, 'uni', false);

                %subfoldernames = cellfun(@(x) split(x,'\'), tmpsubfolder, 'uni',false);

                filelist.full = tmpfull;
                filelist.path = tmpsubfolder;
                filelist.name = tmpname;
                filelist.subfolder = tmpsfolders;

            catch
                disp('** CHECK IF CONFIGURATION FILE IF PATH CORRECT, FILE EXT, OR IF FILES ARE IN DIRECTORY');

                filelist.full = {'No File'};
                filelist.path = {strpath};
                filelist.name = {'No File'};
                filelist.subfolder = {'No subfolders'};

            end


            out = '';

        end

        
        %Initialize parameters related to filtering procedures taken during
        %preprocessing.  The parameters include low cutoff and highcutoff
        %specified by the user in the gui, flag for plotting
        %frequencies, flag for reverse filtering,
        %and minimum phase frequency flag.
        function param = filtInitParam()
   
            param.locutoff = [];
            param.hicutoff = [];
            param.filtorder = [];
            param.revfilt = 0;
            param.plotfreqz = 0;
            param.minphase = false;

        end

        %Assign the frequency filtering related values to variables that
        %are then passed to the EEGLAB filtering function to perform
        %appropriate filtering of the data during preprocessing (Stage 1).
        function [EEG, com, b] = filtData(EEG, param)
  
            locutoff = param.locutoff;
            hicutoff = param.hicutoff;
            filtorder = param.filtorder;
            revfilt = param.revfilt;
            plotfreqz = param.plotfreqz;
            minphase = param.minphase;

            [EEG, com, b] = pop_eegfiltnew(EEG, locutoff, hicutoff, filtorder, revfilt, plotfreqz, minphase);

            EEG = eeg_checkset(EEG);

        end

        %Presents dialog for user to choose continuation, redo, or saving
        %and exiting after each subject completion of stage 2
        %preprocessing.  Depending upon user choice, the respective redo 
        %flag for each subject is set and factored into whether the subject
        %must undergo stage 2 again.
        function [flg, errorchk] = redoOrContinue(s)
     
            opts.Default = 'Continue';
            opts.Interpreter = 'none';
            quest = sprintf('Do you want to verify %s as complete or redo?', s.subj_basename);
            answer = questdlg(quest, 'Verify Processing', ...
                'Continue', 'Redo', 'Save', opts);

            switch answer
                case 'Redo'
                    flg = 1;
                    errorchk = 1;
                case 'Continue'
                    flg = 0;
                    errorchk = 0;
                case 'Save'
                    flg = 2;
                    errorchk = 0;
            end

            %if strcmp(answer, 'Redo'), flg = 1; errorchk = 1;  else, flg = 0; errorchk = 0; end

        end

        %Selects the indices of the subject objects from the specified csv 
        %file that are in the specified preprocessing state.  Logical
        %indices are used instead of numerical for accuracy and
        %functionality
        function objectIdx = selectObjects(stage, csvfile)

            if nargin < 2
                fprintf('\n\nFunction: objectIdx = selectObjects( stage, csvfile)\n');
                fprintf('Output: Logical array meeting stage criteria\n');
                fprintf('Input 1: desired stage\n');
                fprintf('Input 2: CSV file created by scripts\n\n');
                fprintf('Desc: Select Objects using CSV file criteria.\n');
                fprintf('Desc: Edit the CSV file to put any file to repeat a stage.\n');
                fprintf('\nStage Options:\n');
                fprintf('''raw'': N/A (filelist created by directory)\n');
                fprintf('''import'': ready for stage 2\n');
                fprintf('''preica'': ready for stage 3\n');
                fprintf('''postica'': ready for stage 4\n');
                fprintf('''postcomps'': ready for stage 5\n');

                fprintf('\n');

                return;
            end

            switch stage


                case 'import'
                    searchStr = 'Import';

                case 'preica'
                    searchStr = 'PreICA';

                case 'postica'
                    searchStr = 'PostICA';

                case 'postcomps'
                    searchStr = 'postcomps';

                case 'preanalysis'
                    searchStr = 'preanalysis';

                case 'level1'
                    searchStr = 'Level1';

                otherwise
                    searchStr = 'None';

            end

            T = readtable(csvfile, 'Delimiter', ',');
            TC = table2cell(T);
            TC_Header = T.Properties.VariableNames;

            idxState = find(strcmp(TC_Header(1, :), 'proc_state'));
            
            % numerical index, not used
            objectIdx2 = find(strcmp(TC(:, idxState), searchStr));

            % logical index (can be inverted)
            objectIdx = strcmp(TC(:, idxState), searchStr);

        end

        %CURRENTLY UNUTILIZED
        function results = copyRawFileToRawFolder(rawfile, targetDir)

            [status, msg, msgID] = copyfile(rawfile, targetDir);
            if status == 1
                results = 1;

            else
                results = 0;
            end
        end

        %Gets the processing state for every object in the specified csv
        %file to use for preprocessing stage procedures
        function arr = getCsvState(csvfile)

            T = readtable(csvfile, 'Delimiter', ',');
            arr = T.('proc_state');

        end


    end


end
