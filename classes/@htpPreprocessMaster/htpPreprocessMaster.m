

classdef htpPreprocessMaster < handle & htpBaseMaster
    
    
    methods
        %% htpPreprocessMaster
        % *Usage*
        % 
        % obj = htpPreprocessMaster();
        %
        % *Parameters*
        %
        % Due to the function being the default constructor for the
        % htpPreprocessMaster instance, there is no input.  The output,
        % obj, is the newly constructed htpPreprocessMaster instance.
        %
        % *Description*
        % 
        % Constructor to create htpPreprocessMaster object 
        % which in turn calls the superclass constructor from the 
        % htpBaseMaster subclass so the overarching htpPreprocessMaster 
        % object will handle not only preprocessing settings but file paths 
        % and configuration deemed appropriate for preprocessing needs and 
        % in turn provide storage for subject objects
        function obj = htpPreprocessMaster(  )
            obj@htpBaseMaster;
            obj.outStr = 'Constructing htpPreprocessMaster ...'; % initialize messages
        end
       
        
        %% firstRun
        %
        % *Usage*
        %
        % o = firstRun(o)
        %   
        % *Parameters*
        %
        % * INPUTS: o
        %
        % * OUTPUTS: o
        %
        % The optional input, o if the function is not self-invoked, is 
        % the htpPreprocessMaster object.  The output,o if the function
        % is not self-invoked, is the htpPreprocessMaster with updated
        % path,environment, and save information related attributes.
        % 
        %
        % *Description*
        %
        % Need to initialize path and environment which include  for preprocessing
        % pipeline upon startup and ensure EEGLAB is on the path for the
        % pipeline to function correctly
        function o = firstRun( o )
            o.checkEegLab;
            o.init_path;
            o.init_environment;
            o.generateSaveFileName;

            
        end
        
        %% getNetDisplayNames
        %
        % *Usage*
        %       
        % arr = getNetDisplayNames(o)
        %  
        % *Parameters*
        %
        % * INPUTS: o
        %
        % * OUTPUTS: arr
        %
        %  The optional input, o if the function is not self-invoked, is 
        %  the htpPreprocessMaster object.  The output, arr, is the cell 
        %  array of the names of the display net names available for 
        %  selection in the GUI
        %  (EGI Hydrocel 32, EGI Hydrocel 128, etc.) and set in 
        %  cfg_htpEegSystems.xml.
        % 
        %
        % *Description*
        % 
        % Provides the EEG cap display name used to collect data 
        % which is information needed to know how to go about setting 
        % preprocessing options and preprocessing
        function arr = getNetDisplayNames( o )
           
            arr = {o.xml_elec.net_displayname};
            
        end
        
        %% Get Electrode Net Names
        % *Usage* 
        % 
        % arr = getNetNames(o)
        %   
        % *Parameters*
        %
        % * INPUTS: o
        %
        % * OUTPUTS: arr
        %
        % The optional input, o if the function is not self-invoked, is 
        % the htpPreprocessMaster object.  The output, arr, is the cell 
        % array of the names of the configured net names
        % (EGI32, EGI128, etc) in cfg_htpEegSystems.xml.
        % 
        %
        % *Description*
        %
        % Provides the EEG net system (EGI32, EGI 128, etc.) name
        % used to collect data which is the information needed to know 
        % how to go about setting preprocessing options and preprocessing 
        % events for it.
        function arr = getNetNames( o )
                    
            arr = {o.xml_elec.net_name};
            
        end
       
        %% NetName2NetDisplay
        %
        % *Usage*
        % str = NetNameName2NetDisplay(o, dispName)
        %   
        % *Parameters*
        %
        % * INPUTS: o, dispName
        %
        % * OUTPUTS: str
        %
        % The first optional input, o if the function is not self-invoked, is 
        % the htpPreprocessMaster object and the other input, dispName, 
        % is the net name supplied to be converted to net display name 
        % with both attributes set in cfg_htpEegSystems.xml.  The output, 
        % str, is the converted net display name from the initial
        % supplied net name.
        %
        % *Description*
        % 
        % Obtain the net display name for the current net being used during
        % preprocessing
        function str = NetNameName2NetDisplay( o, dispName )
            
            idx = strcmp(dispName, {o.xml_elec.net_name});
            tmparr = {o.xml_elec.net_displayname};
            str = tmparr{ idx };
            
        end
        
        %% NetNameDisplay2NetName
        %
        % *Usage*
        %
        % str = NetNameDisplay2NetName(o, dispName)
        %   
        % *Parameters*
        %
        % * INPUTS: o, dispName
        %
        % * OUTPUTS: str
        %
        %  The first optional input, o if the function is not self-invoked, is 
        %  the htpPreprocessMaster object and the other input, dispName, 
        %  is the net display name supplied to be converted to net name with 
        %  both attributes set in cfg_htpEegSystems.xml.  The output, str,
        %  is the converted net name from the initial
        %  supplied net display name.
        % 
        %
        % *Description*
        %
        % Obtain the net name for the current net display name being used
        % during preprocessing
        function str = NetNameDisplay2NetName( o, dispName )
            
            idx = strcmp(dispName, {o.xml_elec.net_displayname});
            tmparr = {o.xml_elec.net_name};
            str = tmparr{ idx };
            
        end
        
        %CURRENTLY UNUTILIZED
        function tbl = getFileListTable( o )
           
            [s,f,e] = cellfun( @(x) fileparts(x), o.fnlist,'uni', 0);

            subfolders = o.subfolderlist;
            
            tbl = table(subfolders, f, e);
            tbl.Properties.VariableNames = {'Subfolder', 'File', 'Ext'};
        end
        
    end
    
    methods (Static)
    end
    
    methods
        
        %CURRENTLY UNUTILIZED
        function obj = setOpt_Stage1( obj, mat )
            %             lowcutoff: {'0.5'  '1'  '1.5'  '2'}
            %             highcutoff: {'30'  '40'  '80'  '100'  '120'}
            %             notch: {'57 63 3330'}
            %             resample: {'250'  '500'  '100'  '1000'}
            %             epochlength: {'2'  '1'  'Custom'}
            %             cleanmode: {'Manual'  'ASR'}
            %             pcacomps: {'Data Rank'  'K-Number'  '24'}
            %             brainonly: {'Manual'  'Brain Only'  'Muscle Only'  'Eye Movement'  'Cardiac'}
            %             plots: {'Off'  'Minimal'  'Maximum'}
            
            obj.htpcfg.optnow_s1.mat = mat;
            
        end
        
        %% copyRawfile2Basepath
        %
        % *Usage*
        % 
        % obj = copyRawfile2Basepath(obj)
        %   
        % *Parameters*
        %
        % * INPUTS: obj
        %
        % * OUTPUTS: obj
        %
        % The first optional input, obj if the function is not self-invoked, is 
        % the htpPreprocessMaster object.  The output, obj if the 
        % function is not self-invoked,
        % is the htpPreprocessMaster object after the raw file has been 
        % copied to the RAW base directory.
        % 
        %
        % *Description*
        %
        % Copies the RAW file to the configured data directory base path
        % (Only utilized in single analysis mode, current pipeline in
        % constant group analysis mode)
        function obj = copyRawfile2Basepath( obj )
            rawfile = obj.htpcfg.rawfile;
            subfolder = obj.htpcfg.rawsubfolder;
            rawdir = fullfile( obj.htpcfg.pathdb.raw, subfolder );
            
            
            
            [status,msg,msgID] = mkdir(rawdir);
            if status == 1
                
                obj.msgout(sprintf('Created New Base Dir: %s', obj.htpcfg.basePath), 'step_complete');
                
            else
                
                obj.msgout(sprintf('Failed Creating New Output Dir: %s', obj.htpcfg.basePath), 'step_error');
                
            end
            
            [status,msg,msgID] = copyfile( rawfile, rawdir);
            
            if status == 1, obj.msgout(sprintf('Copying file %s to base directory.', rawfile),  'step_complete'); ...
            else, obj.msgout('Error Copying file to base directory.', 'step_error');
            end
            
            
            
            if strcmp(obj.htpcfg.chanNow.net_name, 'BV64')
                
                [a,b,~] = fileparts(rawfile);
                
                [status,msg,msgID] = copyfile(fullfile(a,[b '.vhdr']), rawdir);
                [status,msg,msgID] = copyfile(fullfile(a,[b '.vmrk']), rawdir);
                
                
            end
            
        end
        
        
        

        %CURRENTLY UNUTILIZED
        function obj = setFileList( obj, subfolderlist, fnlist )
            
            if iscell(fnlist) && iscell(subfolderlist)
                obj.fnlist = fnlist;
                obj.subfolderlist = subfolderlist;
            else
                obj.msgout('Critical: Invalid File or Subfolder List.', 'step_error');
            end
        end
        
        
        
        %CURRENTLY UNUTILIZED
        function obj = htp_cfg( obj )
            
            obj.init_path;
            obj.init_environment;
            
        end
        
        %% setSingleRawFile
        %
        % *Usage*
        % obj = setSingleRawFile(obj, rawfile)
        %   
        % *Parameters*
        %
        % * INPUTS: obj, rawfile
        %
        % * OUTPUTS: obj
        %
        % The first optional input, obj if the function is not self-invoked, is 
        % the htpPreprocessMaster object and the other input, rawfile, 
        % is the file name for the supplied single raw file.  The output,
        % str, is the net display name which was converted to from the initial
        % supplied net name.
        % 
        % *Description*
        %
        % Setting base path for data directory and updating all related path
        % attributes for the configuration object for later usage of data files during the
        % various stages of preprocessing
        function obj = setSingleRawFile( obj, rawfile )
            
            mode = obj.htpcfg.analysisMode;
            
            switch mode
                
                case 'Single'
                    
                    obj.htpcfg.rawfile = rawfile;
                    
                    obj.htpcfg.completed.FilenameEditField = true;
                    
                    obj.msgout(sprintf('File Selected (Single File Mode): %s', rawfile), 'step_completed');
                    
                    
                case 'Group'
                    obj.setBasePath( rawfile );
                    
                    obj.generateConfigObject;
                    
                    obj.htpcfg.completed.FilenameEditField = true;
                    obj.htpcfg.completed.OutputFolderEditField = true;
                    obj.htpcfg.completed.TargetFolderEditField = true;
                    
                    obj.msgout(sprintf('Folder Selected (Folder Group Mode): %s', rawfile), 'step_completed');
                    
            end
            
        end
        
        %CURRENTLY UNUTILIZED
        function obj = setOptionsStage1( obj, choices )
            %             lowcutoff: {'0.5'  '1'  '1.5'  '2'}
            %             highcutoff: {'30'  '40'  '80'  '100'  '120'}
            %             notch: {'57 63 3330'}
            %             resample: {'250'  '500'  '100'  '1000'}
            %             epochlength: {'2'  '1' }
            %             cleanmode: {'Manual'  'ASR'}
            %             pcacomps: {'Data Rank'  'K-Number'  '24'}
            %             brainonly: {'Manual'  'Brain Only'  'Muscle Only'  'Eye Movement'  'Cardiac'}
            %             plots: {'Off'  'Minimal'  'Maximum'}
            %
            optlist = obj.htpcfg.opt;
            %     choices = [4,3,1,1,1,1,3,1,1,1];
            
            optnames = fields(optlist);
            
            cfg = struct();
            
            for i = 1 : length(optnames)
                
                if ismember(optnames{i}, {'lowcutoff', 'highcutoff', 'notch', 'resample', 'epochlength'})
                    
                    cfg.(optnames{i}) = str2num(optlist.(optnames{i}){choices(i)});
                else
                    cfg.(optnames{i}) = str2num(optlist.(optnames{i}){choices(i)});
                end
            end
            
            obj.htpcfg.optnow_s1 = cfg;
            
        end
        
        %CURRENTLY UNUTILIZED
        function obj = setOptionsStage2( obj, choices )
            %             lowcutoff: {'0.5'  '1'  '1.5'  '2'}
            %             highcutoff: {'30'  '40'  '80'  '100'  '120'}
            %             notch: {'57 63 3330'}
            %             resample: {'250'  '500'  '100'  '1000'}
            %             epochlength: {'2'  '1' }
            %             cleanmode: {'Manual'  'ASR'}
            %             pcacomps: {'Data Rank'  'K-Number'  '24'}
            %             brainonly: {'Manual'  'Brain Only'  'Muscle Only'  'Eye Movement'  'Cardiac'}
            %             plots: {'Off'  'Minimal'  'Maximum'}
            %
            optlist = obj.htpcfg.opt;
            %     choices = [4,3,1,1,1,1,3,1,1,1];
            
            optnames = fields(optlist);
            
            cfg = struct();
            
            for i = 1 : length(optnames)
                
                if ismember(optnames{i}, {'lowcutoff', 'highcutoff', 'notch', 'resample', 'epochlength'})
                    
                    cfg.(optnames{i}) = str2num(optlist.(optnames{i}){choices(i)});
                else
                    cfg.(optnames{i}) = str2num(optlist.(optnames{i}){choices(i)});
                end
            end
            
            obj.htpcfg.optnow_s2 = cfg;
            
        end
        
    end
    
end
