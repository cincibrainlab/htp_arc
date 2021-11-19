classdef (ConstructOnLoad = true) eegDataClass < handle  & restingAnalysisModule & eegDataMethods.freq
    % eegDataClass: Generic EEG data superclass
    % extend with subclasses 
    
    properties (Abstract)
        
    end
    
    events
        proc_complete;
        proc_warning;
        proc_error;
        proc_msg;
    end
    
    properties
        
        % File system variables keep file and directory structures equal
        filename = struct(...
            'analysis','', ...
            'raw','',   ...
            'import','',...
            'preica','',...
            'postica','',...
            'level1','',...
            'postcomps','',...
            'preanalysis','',...
            'group','',...
            'figs','',...
            'icaweights','',...
            'do','', ...
            'eventdata','',...
            'ft','', ...
            'signal','');
        
        pathdb = struct(...
            'analysis','', ...
            'raw','',   ...
            'import','',...
            'preica','',...
            'postica','',...
            'level1','',...
            'postcomps','',...
            'preanalysis','',...
            'group','',...
            'figs','',...
            'icaweights','',...
            'do','',...
            'eventdata','',...
            'ft','', ...
            'signal', '');
        
        pathCellArr;
        
        % study configutation
        htpcfg;
        msg;
        outStr;
        msgtype;
        mra; %manual review
        
        % GUI variables
        includeInStudyList;
        includeInStudyType;
        resultTbl;
        
        % Study Specific Information
        study_id    = 0;
        study_title = 'Assign Study Title';
        study_desc  = 'Assign Study Description';
        study_type = '';
        study_user = ''; % initials of the user processing
        study_csv = '';
        study_mat = '';
        
        % Subject Specific Information
        subj_id;           % consequtive subject id by process order
        subj_basename;     % generate unique prefix for subject
        subj_basepath;     % root path to datafiles
        subj_subfolder;    % subfolder/group of patient
        subj_condition;
        subj_group;
        subj_timept;
        
        % Electrode configuration
        net_name;           % idenfier for net
        net_file;           % assign EEG channel file
        net_nbchan_orig;    % original number of channels
        net_nbchan_post;    % number of channels following pre-processing
        net_filter;         % file ext of recording system format (i.e. '*.raw')
        net_ref;            % reference electrode number
        net_regions;        % define subgroups of electrodes
        net_other;
        % Processing Parameters
        proc_merge;
        proc_timetag                 % time of dataset creation
        proc_clearEpochs;            % remove epochs following raw import
        proc_deleteMissingChans;     % remove raw channels without locations
        proc_dataRank;               % indenpendent data ranks following preprocessing
        proc_srate0;                 % original sampling rate 1;
        proc_sRate1;                 % final sampling rate 1
        proc_sRate2;                 % final sampling rate 2 (i.e. for phase analysis)
        proc_sRate_raw;              % original sampling rate
        proc_contEpochLength;        % epochs for resting data
        proc_contEpochLimits;        % epoch limits including baseline
        proc_xmax_raw;               % original length before pre-procssing
        proc_xmax_post;              % length post cleaning
        proc_xmax_percent;           % length percentage due to cleaning
        proc_xmax_epoch;             % length following epoching
        proc_contains_all_nans;
        proc_removed_regions;
        proc_tmprej_chans;
        proc_tmprej_cont;
        proc_tmprej_epochs;
        proc_state;                  % what stage file is in
        proc_removeComps;            % vector of components to be removed
        proc_comments;               % additional comments
        proc_fileStatus;             % current state of each directory
        proc_badchans;               % chans removed and interpolated
        proc_ipchans;                % number of interpolated channels
        proc_compstatus;             % added 9/26/2019 to show status artifact comps were removed
                                     % present = 1, removed = 0
        proc_autobadchannel;         % place for automatic bad chan id
        proc_autobadsegment;         % place for automatic bad segment id
        
        proc_filt_bandlow;           % filter settings
        proc_filt_bandhigh;
        proc_filt_lowcutoff;
        proc_filt_highcutoff;
        
        proc_icaweights;
        
        
        sig;
        
        
        epoch_length;
        epoch_limits;
        epoch_trials;
        epoch_badtrials;
        epoch_badid;
        epoch_percent;
        
        eventcfg;
        
        % data structures
        EEG;
        EEG_raw;
        EEG_prefilt;
        EEG_prechan;
        EEG_import;
        EEG_preica;
        EEG_postica;
        EEG_postcomps;
        EEG_preanalysis;
        EEG_level1;
        
        % event data
        events_event;               % import from data channel in EEGLAB format
        events_urevent;               % import from data channel in EEGLAB format
        events_pnts;                 % num of pts in event file for QI
        events_filenames;
        events_dins;
        
        % analysis variables
        sigPairs;       % unique channel pairs for connectivity analysis
        
        % manual clean variables
        man_chanRemove;
        
        % display strings
        str_plottitle;
        
        % logging functions
        log_subjRow = {};
        log_subjHeader = {};
        log_signal = {};
        
        % dipfit configuration
        dipfit;
        
        % fieldtrip calculations
        ft;
        
        % spectral power
        powTable1;
        powTable2;
        powTable3;
        
        % analysis options
        exclude_switch;
        exclude_comment;
        exclude_category;
        exclude_status;
        
        % source module
        atlas;
        
        % clinical variables
        meas;
        
        %
        opt; % formatted options from GUI for easy access
        
    end
    
    methods (Abstract)
    end
    
    methods (Static = true)
        
        %Use as:
        %       [ param ] = o.filtInitParam()
        %
        %   Due to the function being the self-invoked initialization for the
        %   filter parameters via an eegDataClass object, there is no input.  The output,
        %   param, is the newly initalized parameter structure with 
        %   filter-related attributes.
        %
        %Initialize filtering related attributes such as low cutoff, hight 
        %cutoff, filtering order, reverse filtering flag, and minimum phase 
        %flag that are utilized throughout preprocessing, primarily in 
        %stage 1 
        function param = filtInitParam()
            
            param.locutoff = [];
            param.hicutoff = [];
            param.filtorder = [];
            param.revfilt = 0;
            param.plotfreqz = 0;
            param.minphase = false;
            
        end
        
        %Use as:
        %       [ index ] = o.find_zeroed_chans(dat)
        %
        %   The input, dat, is the data attribute of an EEG structure to 
        %   search through in the function.  The output,
        %   index, is the vector of the indices that are zeroed out 
        %   channels within the supplied data input.
        %
        %Find any channel that contains completely zeroed data
        %Necessary for locating either dead channels or verification of
        %errors within channels that should contain real data
        function index = find_zeroed_chans( dat )
            
            chans_median = zeros( size( dat, 1 ),1 );
            
            for i = 1 : size( dat, 1 )
                
                chans_median(i) = median( dat(i, :));
                
            end
            
            allchannels = round(chans_median(:),8);
            index =  find(allchannels == 0);
            
        end
        
        %Use as:
        %       [ chanmap ] = o.getChanMapEGI128to32()
        %
        %   There is no input for the self-invoked function.  The output,
        %   chanmap, is the cell array of the electrode labels of the newly 
        %   downsized channel map.
        %
        %Downsize channel map from EGI 128 channel net to EGI 32 channel
        %net.  Necessary for when the user selects the net downgrade option 
        %within the pipeline gui.
        function chanmap = getChanMapEGI128to32()
            
            chanmap = { ...
                'E127', 'E29'; ...
                'E17', 'E18'; ...
                'E126', 'E30'; ...
                'E128', 'E31'; ...
                'E22', 'E1'; ...
                'E15', 'E27'; ...
                'E9', 'E2'; ...
                'E125', 'E32'; ...
                'E43', 'E21'; ...
                'E33', 'E11'; ...
                'E24', 'E3'; ...
                'E11', 'E17'; ...
                'E124', 'E4'; ...
                'E122', 'E12'; ...
                'E120', 'E22'; ...
                'E45', 'E13'; ...
                'E36', 'E5'; ...
                'E104', 'E6'; ...
                'E52', 'E7'; ...
                'E62', 'E19'; ...
                'E92', 'E8'; ...
                'E108', 'E14'; ...
                'E100', 'E24'; ...
                'E96', 'E16'; ...
                'E94', 'E26'; ...
                'E68', 'E25'; ...
                'E83', 'E10'; ...
                'E75', 'E20'; ...
                'E70', 'E9'; ...
                'E56', 'E23'; ...
                'E6', 'E28'; ...
                'E58', 'E15'; ...
                };
            
        end

    end
    
    methods
        
        %Use as:
        %       [ o ] = eegDataClass()
        %
        %   Due to the function being the default constructor for the
        %   eegDataClass instance, there is no input.  The output,
        %   o, is the newly constructed eegDataClass instance.
        %
        %Superclass Constructor to instantiate eegDataClass instance with default
        %settings.  Object is vital and utilized throughout almost all 
        %preprocessing steps and further analysis steps due to being superclass of 
        %RestEegDataClass object.
        function o = eegDataClass()
            %  if isempty(o.subj_basename)
            %  o.subj_basename =[];
            o.exclude_switch = false;
            o.exclude_comment = '';
            o.exclude_category = {'xml_placeholder'};
            
            o.proc_merge = struct();
            o.proc_merge.subjectid = 0;
            o.proc_merge.partid = 0;
            o.proc_merge.status = 0; 
            
            o.classInit;
            
            o.meas = struct();
            %        end
        end
        
        %Use as:
        %       [ o ] = classInit(o)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The output is the initialized and updated
        %   eegDataClass object with the necessary fields initalized and
        %   populated.
        %
        %Further initiation for eegDataClass object and attributes
        %corresponding to the study and processing attributes/parameters.
        function o = classInit( o )
            o.study_id        = 1;
            o.study_title     = 'Undefined';
            o.study_desc      = 'Undefined';
            o.proc_sRate1             = 500;
            o.proc_clearEpochs        = 1;            % remove epochs following raw import
            o.proc_deleteMissingChans = 1;     % remove raw channels without locations
            o.proc_contEpochLength    = 2;     % duration in seconds
            o.proc_contEpochLimits    = [-1 1];
            
            o.includeInStudyList = true;
            o.includeInStudyType = 'eeg';
            
        end
        
        %Use as:
        %       [ o ] = setElectrodeSystem(o, chaninfo)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object and the other input, chaninfo, is an 
        %   electrodeConfigClass instance.  The output is the
        %   eegDataClass object with the necessary net fields updated.
        %
        %Set the electrode system utilized in the collection of the data to
        %be preprocessed.  Various attributes such as name, configuration
        %file, regions, and channel info are assigned to the output
        %structure to allow accurate preprocessing.
        function o = setElectrodeSystem( o, chaninfo )
            
            fieldname = fields(chaninfo);
            
            for iChanInfo = 1 : numel(fieldname)
                f = fieldname{ iChanInfo };
                o.net_other.(f) = chaninfo.(f);
                
            end
            
            o.net_name      = chaninfo.net_name;
            o.net_file      = chaninfo.net_file;
            o.net_filter    = chaninfo.net_filter;
            o.net_regions   = chaninfo.net_regions;
            
            
            
        end
        
        %Use as:
        %       [ o ] = changeStudyTitle(o, string)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object and the other input, string, is the string 
        %   to update the study title with 
        %   The output is the
        %   eegDataClass object with the study title updated.
        %
        %Need to change the study title if dataset changes to correctly
        %output associated study data.
        function o = changeStudyTitle( o, string )
            
            o.study_title     = string;
            
        end
        
        function o = convertBipolarMontage( o )
            %o.loadDataset('import');
            EEG = o.EEG;
            nonOriginalElectrodes = find(ismember({EEG.chanlocs.labels},...
                {'EEG F3','EEG F4','EEG F7','EEG F8','EEG Fz','EEG P3','EEG P4',...
                'EEG Pz','EEG T5','EEG T6','EOG L-EOG','EOG R-EOG'}));
            EEG = pop_select(EEG,'nochannel', nonOriginalElectrodes);
  
            % create pairs
            bipolarMontage = containers.Map({'Fp1','T3','C3','Cz','C4','O1'},...
                {'Fp2','C3','Cz','C4','T4','O2'});
            bipolarMontageKeys = keys(bipolarMontage);
            bipolarMontageValues = values(bipolarMontage);
            for i=1:length(bipolarMontageKeys)
                currentChannelLabel = bipolarMontageKeys{i};
                adjustmentChannelLabel = bipolarMontageValues{i};
                currentChannelIndex = find(ismember({EEG.chanlocs.labels},currentChannelLabel));
                adjustmentChannelIndex = find(ismember({EEG.chanlocs.labels},adjustmentChannelLabel));
                EEG.data(i+EEG.nbchan,:) = EEG.data(currentChannelIndex,:)-EEG.data(adjustmentChannelIndex,:);
            end
            
            for i=1:length(bipolarMontageKeys)
                currentChannelLabel = bipolarMontageKeys{i};
                currentChannelIndex = find(ismember({EEG.chanlocs.labels},currentChannelLabel));
                EEG.chanlocs(i+EEG.nbchan) = EEG.chanlocs(currentChannelIndex);
                EEG.chanlocs(i+EEG.nbchan).labels = sprintf('%s - %s',currentChannelLabel, bipolarMontageValues{i});
            end
            
            EEG = eeg_checkset(EEG);
            
            nonOriginalElectrodesSecondSet = find(ismember({EEG.chanlocs.labels},...
                {'Fp1','C3','O1','Fp2','C4','O2','T3','T4','Cz','ECGL-ECGR'}));
            EEG = pop_select(EEG,'nochannel', nonOriginalElectrodesSecondSet);
            EEG = eeg_checkset(EEG);
            clear bipolarMontageKeys;
            clear bipolarMontage;
            clear bipolarMontageValues;
        end
        
        %Use as:
        %       [ o ] = getMeaDataRHD(o)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The output is the
        %   eegDataClass object with the MEARHD data imported and the 
        %   appropriate corresponding fields updated.
        %
        %Need to change the study title if dataset changes to correctly
        %output associated study data.
        %Import function for raw MEARHD datasets that is utilized to 
        %correctly import and parse necessary data found within the 
        %original raw file.  Utilized when the user has selected their net 
        %to be 'MEARHD 32'.
        function o = getMeaDataRHD( o )
            
            datafile =  o.filename.raw;
            subfolder = o.subj_subfolder;
            folder = o.pathdb.raw;
            filename = fullfile(folder, subfolder, datafile);


            % initialize empty eeglab set
            EEG = eeg_emptyset;
            EEG = eeg_checkchanlocs(EEG);
            
            
            
            EEG.filename = filename;
            
            [sample_rate, amplifier_data, amplifier_channels, spike_triggers] = read_Intan_RHD2000_file(filename);
            
            EEG.srate = sample_rate;
            EEG.data = amplifier_data(33:end, :);
            
            EEG = eeg_checkset( EEG );
            
            tmpchaninfo = amplifier_channels(33:end);
            EEG = eeg_checkchanlocs(EEG);


            for i = 1 : numel(tmpchaninfo)
                tmpstr = strsplit(tmpchaninfo(i).native_channel_name,'-');
                abbreviated_name = abbreviated_name;
                EEG.chanlocs( i ).labels = tmpchaninfo( i ).native_channel_name;
                EEG.chanlocs( i ).type = 'EEG';
                EEG.chanlocs( i ).urchan = tmpchaninfo( i ).native_order;
                
            end
            
            % assign 3d layout
            
            try
                load(o.net_file, 'chanlocs');
            catch e
                o.msgout('mea3d.mat file missing', 'proc_error');
                throw(e);
            end
            
            for i = 1 : numel(chanlocs)
                
                EEG.chanlocs(i).theta       = chanlocs(i).theta;
                EEG.chanlocs(i).radius      = chanlocs(i).radius;
                EEG.chanlocs(i).X           = chanlocs(i).X;
                EEG.chanlocs(i).Y           = chanlocs(i).Y; 
                EEG.chanlocs(i).Z           = chanlocs(i).Z;
                EEG.chanlocs(i).sph_theta   = chanlocs(i).sph_theta;
                EEG.chanlocs(i).sph_phi     = chanlocs(i).sph_phi;
                EEG.chanlocs(i).sph_radius  = chanlocs(i).sph_radius;               
           
            end
                
            o.EEG = eeg_checkset( EEG );
            
            o.net_nbchan_orig = o.EEG.nbchan;
            o.proc_sRate_raw = o.EEG.srate;
            o.proc_xmax_raw = o.EEG.xmax;
            
        end
        
        %Use as:
        %       [ o ] = getRawEDF(o)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The output is the
        %   eegDataClass object with the EDF data imported and the 
        %   appropriate corresponding fields updated.
        %
        %Import function for raw EDF datasets that is utilized to 
        %correctly import and parse necessary data found within the 
        %original raw file. Utilized when the user has selected their net 
        %to be 'EDFGENERIC'. 
        function o = getRawEDF( o )
            
            datafile =  o.filename.raw;
            subfolder = o.subj_subfolder;
            folder = o.pathdb.raw;
            file = fullfile(folder, subfolder, datafile);
            
            o.EEG = eeg_emptyset;
            o.EEG.filename = file;
            [ headerOutput, recordOutput ]=import_edf(file);
            o.EEG.data = recordOutput;
            o.EEG.pnts = size(o.EEG.data,2);
            o.EEG.nbchan = length(headerOutput.labels);
            o.net_nbchan_orig =  o.EEG.nbchan;
            o.EEG.srate = headerOutput.samplingRate(1);
            clear recordOutput;                        
            o.EEG = eeg_checkset(o.EEG);
            o.EEG = eeg_checkchanlocs(o.EEG);
            try
                chanlocs = readlocs(o.net_file);
            catch e
                o.msgout('standard_1020.elc file missing', 'proc_error');
                throw(e);
            end
            
            for i = 1 : o.EEG.nbchan                
                o.EEG.chanlocs(i).labels = headerOutput.labels{i};
                index = find(strcmp({chanlocs.labels},o.EEG.chanlocs(i).labels));
                if ~isempty(index)
                    o.EEG.chanlocs(i).theta       = chanlocs(index).theta;
                    o.EEG.chanlocs(i).radius      = chanlocs(index).radius;
                    o.EEG.chanlocs(i).X           = chanlocs(index).X;
                    o.EEG.chanlocs(i).Y           = chanlocs(index).Y; 
                    o.EEG.chanlocs(i).Z           = chanlocs(index).Z;
                    o.EEG.chanlocs(i).sph_theta   = chanlocs(index).sph_theta;
                    o.EEG.chanlocs(i).sph_phi     = chanlocs(index).sph_phi;  
                    o.EEG.chanlocs(i).type = 'EEG';
                end
            end
            o.EEG.chaninfo.nosedir='+Y';
            o.EEG = pop_select(o.EEG,'nochannel', find(cellfun(@isempty,{o.EEG.chanlocs.radius})));
            nonOriginalElectrodes = find(ismember({o.EEG.chanlocs.labels},{'F3','F4','F7','F8','Fz','P3','P4','Pz','T5','T6','Fpz'}));
            o.EEG = pop_select(o.EEG,'nochannel', nonOriginalElectrodes);
            o.EEG = eeg_checkset(o.EEG);
            o.EEG = eeg_checkchanlocs(o.EEG);
%             data_SegmentSize = 300000;
%             recording_MinuteSegments = find(mod(o.EEG.times,data_SegmentSize)==0);
%             temp_times = NaN(1,size(o.EEG.times,2));
%             temp_times(1:recording_MinuteSegments(3)) = o.EEG.times(1,1:recording_MinuteSegments(3));
%             temp_times(recording_MinuteSegments(round(size(recording_MinuteSegments,2)/2)):recording_MinuteSegments(round(size(recording_MinuteSegments,2)/2)+2)) ...
%                 = o.EEG.times(1,recording_MinuteSegments(round(size(recording_MinuteSegments,2)/2)):recording_MinuteSegments(round(size(recording_MinuteSegments,2)/2)+2));
%             temp_times(recording_MinuteSegments(end-2):recording_MinuteSegments(end)) = o.EEG.times(1,recording_MinuteSegments(end-2):recording_MinuteSegments(end));
%             o.EEG.data = o.EEG.data(:,~isnan(temp_times));
%             o.EEG.times = o.EEG.times(~isnan(temp_times));
%             clear temp_times;
%             clear recording_MinuteSegments;
            o.EEG.data = double(o.EEG.data);
            o.EEG.pnts = size(o.EEG.data,2);
            o.net_nbchan_orig =  o.EEG.nbchan;
            o.proc_sRate_raw = o.EEG.srate;
            o.EEG = eeg_checkset(o.EEG);
            o.EEG = eeg_checkchanlocs(o.EEG);
            %o.proc_xmax_raw = o.EEG.xmax/3;
            o.net_nbchan_orig =  o.EEG.nbchan;
            o.proc_sRate_raw = o.EEG.srate;
            o.proc_xmax_raw = o.EEG.xmax;
            
        end
        
        function o = getRawArcEDF( o )
            
            datafile =  o.filename.raw;
            subfolder = o.subj_subfolder;
            folder = o.pathdb.raw;
            file = fullfile(folder, subfolder, datafile);
            
%             o.EEG = eeg_emptyset;
            
            o.EEG = pop_loadset('filename',datafile,'filepath',fullfile(folder,subfolder));
            %o.EEG = pop_loadset(file);
            o.EEG.filename = file;   
            o.EEG = eeg_checkset(o.EEG);
            o.EEG = eeg_checkchanlocs(o.EEG);
            try
                chanlocs = readlocs(o.net_file);
            catch e
                o.msgout('standard_1020.elc file missing', 'proc_error');
                throw(e);
            end
            
            for i = 1 : o.EEG.nbchan                
                if contains(o.EEG.chanlocs(i).labels,'EEG');
                    o.EEG.chanlocs(i).labels = strip(regexprep(o.EEG.chanlocs(i).labels,'\EEG',''));
                elseif contains(o.EEG.chanlocs(i).labels,'EOG');
                    o.EEG.chanlocs(i).labels = strip(regexprep(o.EEG.chanlocs(i).labels,'\EOG',''));
                elseif contains(o.EEG.chanlocs(i).labels,'ECG');
                    o.EEG.chanlocs(i).labels = strip(regexprep(o.EEG.chanlocs(i).labels,'\ECG',''));
                end
                index = find(strcmp({chanlocs.labels},o.EEG.chanlocs(i).labels));
                if ~isempty(index)
                    o.EEG.chanlocs(i).theta       = chanlocs(index).theta;
                    o.EEG.chanlocs(i).radius      = chanlocs(index).radius;
                    o.EEG.chanlocs(i).X           = chanlocs(index).X;
                    o.EEG.chanlocs(i).Y           = chanlocs(index).Y; 
                    o.EEG.chanlocs(i).Z           = chanlocs(index).Z;
                    o.EEG.chanlocs(i).sph_theta   = chanlocs(index).sph_theta;
                    o.EEG.chanlocs(i).sph_phi     = chanlocs(index).sph_phi;  
                    o.EEG.chanlocs(i).type = 'EEG';
                end
            end
            o.EEG.chaninfo.nosedir='+Y';
            o.EEG = pop_select(o.EEG,'nochannel', find(cellfun(@isempty,{o.EEG.chanlocs.radius})));
            nonOriginalElectrodes = find(ismember({o.EEG.chanlocs.labels},{'F3','F4','F7','F8','Fz','P3','P4','Pz','T5','T6','Fpz'}));
            o.EEG = pop_select(o.EEG,'nochannel', nonOriginalElectrodes);
            o.EEG = eeg_checkset(o.EEG);
            o.EEG = eeg_checkchanlocs(o.EEG);
            data_SegmentSize = (o.EEG.srate*60*60)*o.EEG.etc.hourSegmentation;
            timesToUse = 1:data_SegmentSize:size(o.EEG.times,2);
            temp_times = NaN(1,size(o.EEG.times,2));
            temp_times(1:timesToUse(2)-1) = o.EEG.times(1,1:timesToUse(2)-1);
            temp_times(timesToUse(2):timesToUse(3)-1) ...
                = o.EEG.times(1,timesToUse(2):timesToUse(3)-1);
            temp_times(timesToUse(3):timesToUse(4)-1) = o.EEG.times(1,timesToUse(3):timesToUse(4)-1);
            temp_times(timesToUse(4):size(o.EEG.times,2)) = o.EEG.times(1,timesToUse(3):timesToUse(4)-1);
            o.EEG.data = o.EEG.data(:,~isnan(temp_times));
            o.EEG.times = o.EEG.times(~isnan(temp_times));
            clear temp_times;
            clear recording_MinuteSegments;
            o.EEG.data = double(o.EEG.data);
            o.EEG.pnts = size(o.EEG.data,2);
            o.net_nbchan_orig =  o.EEG.nbchan;
            o.proc_sRate_raw = o.EEG.srate;
            o.EEG = eeg_checkset(o.EEG);
            o.EEG = eeg_checkchanlocs(o.EEG);
            %o.proc_xmax_raw = o.EEG.xmax/3;
            o.net_nbchan_orig =  o.EEG.nbchan;
            o.proc_sRate_raw = o.EEG.srate;
            o.proc_xmax_raw = o.EEG.xmax;
            
        end
        
        %Use as:
        %       [ o ] = getRawData(o)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The output is the
        %   eegDataClass object with the specific net system EEG data 
        %   imported and the 
        %   appropriate corresponding fields updated.
        % 
        %Obtain the raw data recorded based on the net name specified by
        %the user in the pipeline gui 'Net Type' option that was then set 
        %in setElectrodeSystem method.
        function o = getRawData ( o )
            
            net_name = o.net_name;
            
            switch net_name
                
                case 'EGI32'
                    
                    o.getRawEGI;
                    
                case 'EGI128'
                    
                    o.getRawEGI;
                    
                case 'MEA30'
                    
                    o.getRawMEA;
                    
                case 'BV64'
                    
                    o.getRawBV64;
                    
                case 'MEARHD32'
                    o.getMeaDataRHD;
                    
                case 'EDFGENERIC'
                    o.getRawEDF;
                    
                case 'ARCEDF'
                    o.getRawArcEDF
                    
                case 'MEAXDAT'
                    o.getRawMEAXDAT;
                    
            end
            
        end
        
        %Use as:
        %       [ o ] = getRawBV64(o)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The output is the
        %   eegDataClass object with the BV64 data imported and the 
        %   appropriate corresponding fields updated.
        %
        %Import function for raw BV64 datasets that is utilized to 
        %correctly import and parse necessary data found within the 
        %original raw file. Utilized when the user has selected their net 
        %to be 'Brainvision 64'. 
        function o = getRawBV64( o )
            % added 3/5/2019
            % biosig import toolbox must be installed
            try
                
                srcfile = fullfile(o.pathdb.raw, o.subj_subfolder, o.filename.raw);
                o.EEG = pop_biosig(srcfile);
                o.EEG = eeg_checkset( o.EEG );
                
                %o.EEG = pop_chanedit(o.EEG, 'load',{o.net_file 'filetype' 'besa'});
                chanlocs = loadbvef('chanfiles/AS-64-X5_noREF.bvef');
                chanlocs(find(strcmp('53',{chanlocs.labels}))) = [];
                chanlocs(find(strcmp('GND',{chanlocs.labels}))) = [];
                o.EEG.chanlocs = chanlocs;
                
                o.EEG = pop_chanedit(o.EEG, 'load',{o.net_file 'filetype' 'besa'});
                o.EEG = eeg_checkset( o.EEG );
                
                o.net_nbchan_orig = o.EEG.nbchan;
                o.proc_sRate_raw = o.EEG.srate;
                o.proc_xmax_raw = o.EEG.xmax;

                
            catch
                cprintf('red', '\n\nERROR: Check if data files are located in "Main Folder"\\S00_RAW\\"Subfolder"\n\n');
                return;
                
            end
            
            
        end
        
        %Use as:
        %       [ o ] = getRawEGI(o)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The output is the
        %   eegDataClass object with the EGI data imported and the 
        %   appropriate corresponding fields updated.
        %
        %Import function for raw EGI datasets that is utilized to 
        %correctly import and parse necessary data found within the 
        %original raw file as well as loading accurate 3d locations. 
        %Utilized when the user has selected their net to be 
        %'EGI Hydrocel 32', 'EGI Hydrocel 64', or 'EGI Hydrocel 128'. 
        function o = getRawEGI( o )
            
            try
                
                o.EEG = pop_readegi(fullfile(o.pathdb.raw, o.subj_subfolder, o.filename.raw));
                o.EEG = eeg_checkset( o.EEG );
                
               
                o.EEG = readegilocs2(o.EEG,o.net_file);
                o.net_nbchan_orig = o.EEG.nbchan;
                o.proc_sRate_raw = o.EEG.srate;
                o.proc_xmax_raw = o.EEG.xmax;
                
                o.EEG = eeg_checkset( o.EEG );
                
                
            catch
                o.msgout('\n\nERROR: Check if data files are located in "Main Folder"\\S00_RAW\\"Subfolder"\n\n', 'step_error');
                return;
                
            end
            
            
            
        end
        
        %Use as:
        %       [ o ] = assignDataset(o, EEG)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object and the other input, EEG, is the EEG data
        %   structure to assign.  The output, o if the function is not 
        %   self-invoked, is the eegDataClass object with the dataset 
        %   assigned.
        %
        %Assign eegDataClass object attributes to htpBaseMaster object 
        %fields corresponding to subject information for accuracy
        %throughout preprocessing
        function o = assignDataset( o, EEG )
           
            o.subj_basename     = EEG.subject;
            o.subj_subfolder    = EEG.group;
            o.atlas = EEG.etc.atlas;
            o.EEG = EEG;
            o.study_title = EEG.comments;
            
        end
        
        %Use as:
        %       [ o ] = getRawMEA(o)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.   The output, o if the function is not 
        %   self-invoked, is the eegDataClass object with the MEA data 
        %   imported and the appropriate corresponding fields updated.
        %
        %Import function for raw MEA datasets that is utilized to 
        %correctly import and parse necessary data found within the 
        %original raw file. Utilized when the user has selected their net 
        %to be 'MEA 30'. 
        function o = getRawMEA( o )
            
            try
                
                datafile =  o.filename.raw;
                subfolder = o.subj_subfolder;
                folder = o.pathdb.raw;
                
                edfFile = fullfile(folder, subfolder, datafile);
                
                EEG = pop_biosig( edfFile );
                EEG = pop_select( EEG, 'nochannel', [2,32,33]);
                
                try
                load(o.net_file, 'chanlocs');
                catch
                   o.msgout('mea3d.mat file missing', 'proc_error'); 
                end
                
                chanlocs(31) = [];
                EEG.chanlocs = chanlocs;
                EEG = eeg_checkset( EEG );
                
                % clear chanlocs;
                
                %EEG = pop_select( EEG,'channel',{'17' '16' '15' '14' '19' '18' '13' '12' '21' '20' '11' ...
                %    '10' '24' '23' '22' '9' '8' '7' '27' '26' '25' '6' '5' '4' '30' '29' '28' '3' '2' '1'});
                
                % based on the revised NN remap provided by Carrie Jonak
                % (Channel remap.jpg)
                
                %EEG = pop_select( EEG,'channel',{'1','3','4','5','6','7','8','9','10', ...
                %                     '11','12','13','14','15','16','17','18','19','20','21','22','23','24', ...
                %                     '25','26','27','28','29','30','31'});
                %
                %
                %                 '17' '16' '15' '14' '19' '18' '13' '12' '21' '20' '11' ...
                %                     '10' '24' '23' '22' '9' '8' '7' '27' '26' '25' '6' '5' '4' '30' '29' '28' '3' '2' '1'});
                %
                %
                swCHANNEL = 0;
                swRESAMPLE  = 0;
                EEG.filename = datafile;
                EEG.chaninfo.filename = 'meachanlocs.mat';
                o.EEG = eeg_checkset(EEG);
                o.net_nbchan_orig = o.EEG.nbchan;
                o.proc_sRate_raw = o.EEG.srate;
                o.proc_xmax_raw = o.EEG.xmax;
           
            catch e
                throw(e);
            end
            
            
        end
        
        
        function o = getRawMEAXDAT( o )
            
            try
                
                datafile =  o.filename.raw;
                subfolder = o.subj_subfolder;
                folder = o.pathdb.raw;
                
                xdatfile = fullfile(folder, subfolder, datafile);
                EEG = eeg_emptyset;
                EEG.filename = xdatfile;
                [signalStruct,timeRange,jsonData] = xdatImport(extractBefore(xdatfile,'_data'));
                
                            
                %EEG.data = double(signalStruct.PriSigs.signals);
                EEG.data = signalStruct.PriSigs.signals;
                EEG.pnts = size(EEG.data,2);
                EEG.nbchan = size(EEG.data,1);
                EEG.srate = jsonData.status.samp_freq;
                EEG.x_min = timeRange(1);
                EEG.x_max = timeRange(2);
                clear signalStruct;
                clear timeRange;
                
                EEG = eeg_checkset(EEG);
                %EEG = eeg_checkchanlocs(EEG);
                EEG = pop_select( EEG, 'nochannel', [2,32]);
                for i = 1 : EEG.nbchan
                    
                    EEG.chanlocs( i ).labels = jsonData.sapiens_base.biointerface_map.ntv_chan_name(i);
                    EEG.chanlocs( i ).type = 'EEG';
                    EEG.chanlocs( i ).urchan = jsonData.sapiens_base.biointerface_map.ntv_chan_idx(i);
                
                end
                EEG = eeg_checkchanlocs(EEG);
                try
                load(o.net_file, 'chanlocs');
                catch
                   o.msgout('mea3d.mat file missing', 'proc_error'); 
                end
                clear jsonData;
                chanlocs(31) = [];
                %EEG = pop_select( EEG, 'nochannel', [2,32]);
                for i = 1 : numel(chanlocs)
                
                    EEG.chanlocs(i).theta       = chanlocs(i).theta;
                    EEG.chanlocs(i).radius      = chanlocs(i).radius;
                    EEG.chanlocs(i).X           = chanlocs(i).X;
                    EEG.chanlocs(i).Y           = chanlocs(i).Y; 
                    EEG.chanlocs(i).Z           = chanlocs(i).Z;
                    EEG.chanlocs(i).sph_theta   = chanlocs(i).sph_theta;
                    EEG.chanlocs(i).sph_phi     = chanlocs(i).sph_phi;
                    EEG.chanlocs(i).sph_radius  = chanlocs(i).sph_radius;               
           
                end
                
                o.EEG = eeg_checkset( EEG );
                o.EEG = eeg_checkchanlocs(EEG);
                
                               
                o.EEG.filename = datafile;
                o.EEG.chaninfo.filename = 'meachanlocs.mat';
                o.EEG = eeg_checkset(o.EEG);
                o.net_nbchan_orig = o.EEG.nbchan;
                o.proc_sRate_raw = o.EEG.srate;
                o.proc_xmax_raw = o.EEG.xmax;
           
            catch e
                throw(e);
            end
            
            
        end
        
        %Use as:
        %       GetSize(this)
        %
        %   The input, this, is the
        %   eegDataClass object.  There is no output as the size is printed
        %   to the command console.
        %
        %Presents the total size of the input object and presents to the
        %user to visualize the size for possible memory management decision
        %based on the calulated byte size
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
        
        %             % import raw data into eeglab format
        %             % main import function for human data
        %
        %
        %
        %
        %             %chanLocsTemplate = loadbvef(o.net_file);
        %             %o.EEG = assignChanLocs( o.EEG, chanLocsTemplate, ...
        %             %    o.proc_deleteMissingChans );
        %
        %             % create backup of original data
        %             obj.EEG_raw = obj.EEG;
        %
        %             % -------- LOG -----------
        %             % original channel number prior to cleaning
        %             obj.net_nbchan_orig = obj.EEG.nbchan;
        %             obj.proc_sRate_raw = obj.EEG.srate;
        %             obj.proc_xmax_raw = obj.EEG.xmax;
        %
        %             if strcmp(obj.study_type,'chirp')
        %
        %                 if  obj.EEG.pnts == obj.events_pnts
        %
        %                     disp('EEG ERROR: Event DIG file is not same length as MEA Datafile');
        %                     disp(['Data file: ' obj.filename.raw]);
        %                     disp(['Event file: ' obj.filename.eventdata]);
        %
        %                     obj.EEG.event = obj.events_event;
        %                     obj.EEG.uurevent = obj.events_urevent;
        %
        %                 end
        %
        %
        %             end
        
        %         end
        
        %         function obj = getChanEvents( obj )
        %
        %             % identify raw basename
        %             [sub,basefile,~] = fileparts(obj.filename.raw);
        %
        %             % add 'dig.edf'
        %             eventfile = fullfile(sub, [basefile ' dig.edf']);
        %
        %             % load data
        %             EEG = pop_biosig(eventfile, 'channels',3,'importevent','off','importannot','off');
        %
        %             % extract events
        %             EEG = pop_chanevent(EEG, 1,'edge','leading','edgelen',5, 'delchan', 'off');
        %
        %             % store data size
        %             obj.events_pnts = EEG.pnts;
        %
        %             % store events in temp structure
        %             obj.events_event = EEG.event;
        %             obj.events_urevent = EEG.urevent;
        %             % print basics
        %             uniqueEvents = unique({EEG.event(:).type});
        %             disp(['Unique Events:' uniqueEvents]);
        %             % return
        %
        %         end
        
        %Use as:
        %       [ o ] = eeglab128to32(o)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.   The output, o if the function is not 
        %   self-invoked, is the eegDataClass object with the EEG data
        %   structure downsized from 128 channels to 32 channels 
        %   imported and the appropriate corresponding fields updated.
        %
         %Downsize 128 electrode system to 32 via a mapping array, 
         %generated from the 3d locations of the original system, to retain
         %the necessary channels based on the mapping array's channel names.
         %The downsized electrode data is validated to ensure proper
         %retention so that the future preprocessing steps will produce
         %expected results.
         function o = eeglab128to32( o )
             
             EEG = o.EEG;
             
             EEG2 = readegilocs2(EEG, o.net_file);
             chanfile = EEG2.chanlocs;
             EEG2 = [];
             
             searchChanFile = @(x) find(strcmpi(x, {chanfile.labels}));
             
             chanmap = o.getChanMapEGI128to32;
             
             EEG = pop_select( EEG, 'channel',chanmap(:,1));
             
             EEG = eeg_checkset( EEG );
             
             renameArr = {EEG.chanlocs.labels};
             
             for i = 1 : length(renameArr)
                 renameIdx = find(strcmpi(renameArr(i) , chanmap(:,1)));
                 fileIdx = searchChanFile(chanmap{renameIdx, 2});
                 tmpchanlocs(i) =  chanfile(fileIdx);
                 
             end
           
             EEG.chanlocs = [];
             EEG.chanlocs = tmpchanlocs;
             
             o.EEG = eeg_checkset( EEG );
             
         
         end
        
        %Use as:
        %       [ o ] = filtHandler(o,filttype,hz)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The next input, filttype, is the type of 
        %   filter to perform ('lowcutoff, 'highcutoff',etc.).  The final 
        %   input, hz, is the frequency to use for the specified filter.
        %   The output, o if the function is not 
        %   self-invoked, is the eegDataClass object with the EEG data
        %   structure downsized from 128 channels to 32 channels 
        %   imported and the appropriate corresponding fields updated.
        %
        %Function to set filter related attributes such as order, hi and lo
        %cutoff, etc. and the function to perform for filtering data based
        %on user needs for current dataset and then perform said filtering 
        %for stage 1 of preprocessing pipeline
        function o = filtHandler( o, filttype, hz )
            
            filt_InitParam = @o.filtInitParam;
            filt_eegfiltnew = @o.filt_eegfiltnew;
            filt_bandpass = @o.filt_bandpass;
            filt_cleanline = @o.filt_cleanline;
            
            try
                
                EEG = eeg_checkset( o.EEG );
                filtConfig = filt_InitParam();
                
                switch filttype
                    
                    case 'lowcutoff'  


                        filtConfig.filtorder = 6600;
                        filtConfig.hicutoff = [];
                        filtConfig.locutoff = hz;
                        filtConfig.revfilt = 0;
                        filtConfig.plotfreqz = 0;
                        
                        filterFunction = filt_eegfiltnew;
                        
                        o.proc_filt_lowcutoff = hz;
                        
                    case 'highcutoff'
                        if ~isnan(hz)
                            
                            filtConfig.filtorder = 3300;
                            filtConfig.hicutoff = hz;
                            filtConfig.locutoff = [];
                            filtConfig.revfilt = 0;
                            filtConfig.plotfreqz = 0;
                            
                            filterFunction = filt_eegfiltnew;
                            
                        else
                            hz = 'None';
                            o.msgout('Low Pass (High cutoff) filter disabled.', 'proc_warning');
                        end
                        o.proc_filt_highcutoff = hz;
                        
                    case 'notch'
                        
                        hz1 = hz(1);
                        hz2 = hz(2);
                        filtConfig.locutoff = hz1;
                        filtConfig.hicutoff = hz2;

                            filtConfig.filtorder = 3300;
                        filtConfig.revfilt = 1;
                        filtConfig.plotfreqz = 0;
                        
                        filterFunction = filt_eegfiltnew;
                        
                        
                        o.proc_filt_bandlow = hz1;
                        o.proc_filt_bandhigh = hz2;
                        
                    case 'bandpass'
                        
                        filtConfig = hz;
                        filterFunction = filt_bandpass;
                        
                    case 'cleanline'
                        
                        filterFunction = filt_cleanline;
                        
                    otherwise
                end
                try
                    o.msgout(sprintf('Filter Data: %s PassBand: %s Order: %s\n',  filttype, num2str(hz), num2str(filtConfig.filtorder)), 'proc_msg');
                catch
                end
                EEG = filterFunction( EEG, filtConfig);
                
                o.EEG = EEG;
                
            catch
                
            end
            
        end
        
        %Use as:
        %       [ EEG ] = filt_Cleanline(o,EEG,param)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The next input, EEG, is the EEG data 
        %   structure.  The final input, param, is a currently unused input.
        %   The output, EEG, is the EEG data
        %   structure and appropriate corresponding fields to filtering 
        %   updated.
        %
        %Perform a cleanline filter on the supplied EEG parameter
        %via the EEGLAB cleanline filter function for mainly stage 1 of 
        %preprocessing.
        function EEG = filt_cleanline( o, EEG, param )
            
            EEG2 = pop_cleanline(EEG, 'bandwidth', 2,'chanlist', [1:EEG.nbchan], 'computepower', 0, 'linefreqs', [60 120 180 240 300],...
                'normSpectrum', 0, 'p', 0.01, 'pad', 2, 'PlotFigures', 0, 'scanforlines', 1, 'sigtype', 'Channels', 'tau', 100,...
                'verb', 1, 'winsize', 4, 'winstep', 4);
            EEG = eeg_checkset( EEG );
        end
        
        %Use as:
        %       [ EEG ] = filt_eegfiltnew(o,EEG,param)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The next input, EEG, is the EEG data 
        %   structure.  The final input, param, is a configuration structure 
        %   for filtering with different filtering parameters.
        %   The output, EEG, is the EEG data
        %   structure and appropriate corresponding fields to filtering 
        %   updated.
        %
        %Perform Hamming based filtering on the supplied EEG parameter
        %utilizing the pop_eegfiltnew EEGLAB function with specified
        %optional inputs from the param input for stage 1 of preprocessing.
        function EEG = filt_eegfiltnew( o, EEG, param )            
            
            locutoff    = param.locutoff;
            hicutoff    = param.hicutoff;
            filtorder   = param.filtorder;
            revfilt     = param.revfilt;
            plotfreqz   = param.plotfreqz;
            minphase    = param.minphase;
            usefft      = 0;
            
            %               try
            %                   if locutoff <= 2
            %                       locutoff = locutoff / 2;
            %                       filtorder = 1650;
            %                   end
            %               catch
            %               end
            %
            %EEG = pop_eegfiltnew(EEG, configStr);
            %             EEG  =  pop_eegfiltnew( EEG, locutoff ,hicutoff ,filtorder, revfilt, [], plotfreqz );
            %EEG = ;
            %EEG = pop_eegfiltnew(EEG,  locutoff,  hicutoff, filtorder,  revfilt, [], plotfreqz);
            try
                switch revfilt  % correctly set reverse filtering for notch filter
                    case 0
                        EEG = pop_eegfiltnew(EEG,  locutoff,  hicutoff, filtorder);
                    case 1
                        linenoise = floor((locutoff + hicutoff) / 2);
                        harmonics = floor((EEG.srate/2) / linenoise);
                        if EEG.srate < 2000
                            for i = 1 : harmonics
                                EEG = pop_eegfiltnew(EEG, 'locutoff', (linenoise * i)-2, 'hicutoff', (linenoise * i)+2, 'filtorder', filtorder, 'revfilt', revfilt, 'plotfreqz',plotfreqz);
                            end
                        end
                end
            
            catch e
                o.msgout('filt_eegfiltnew: filter error','proc_error');
                throw(e);
            end
            
            EEG = eeg_checkset( EEG );
            
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = openInEEGLAB( o, EEG )
            
            %EEG = o.EEG;
            eeglab;
            assignin('base', 'EEG', EEG);
            eeglab redraw;
            
        end
        
        %Use as:
        %       [ EEG ] = filt_bandpass(o,EEG,filtbound)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The next input, EEG, is the EEG data 
        %   structure.  The final input, filtbound, is a vector of the 
        %   bounds for the filter to be performed.
        %   The output, EEG, is the EEG data
        %   structure and appropriate corresponding fields to filtering 
        %   updated.
        %
        %Perform bandpass filtering on the supplied EEG input after going
        %through various necessary steps such as definition of nyquist
        %frequency, transition width, filter order, shape of the filter,
        %and the filter weights.  Proceed with pre-filter and post-filter
        %plots to display to user to ensure filter is appropriately
        %applied.
        function EEG = filt_bandpass( o, EEG, filtbound )
            
            plots = 1;
            
            o.proc_filt_bandlow = filtbound(1);              % filter settings
            o.proc_filt_bandhigh = filtbound(2);              % filter settings
            
            %EEG = o.EEG;
            
            nyquist = EEG.srate / 2; 
            
            
            trans_width = 0.15; % fraction of 1, thus 20%.
            
           
            filt_order = round(3 * ( EEG.srate / filtbound(1) ));
            
            
            ffrequencies  = [ 0 (1-trans_width)*filtbound(1) filtbound (1+trans_width)*filtbound(2) nyquist ]/nyquist;
            
            
            idealresponse = [ 0 0 1 1 0 0 ];
            
            
            filterweights = firls(filt_order,ffrequencies,idealresponse);
            
            if plots == 1
                
                figure(1), clf
                subplot(211)
                plot(ffrequencies*nyquist,idealresponse,'k--o','markerface','m')
                set(gca,'ylim',[-.1 1.1],'xlim',[-2 nyquist+2])
                xlabel('Frequencies (Hz)'), ylabel('Response amplitude')
                
                subplot(212)
                plot((0:filt_order)*(1000/EEG.srate),filterweights)
                xlabel('Time (ms)'), ylabel('Amplitude')
            end
            
            
            
            filtered_data = zeros(EEG.nbchan,EEG.pnts);
            for chani=1:EEG.nbchan
                filtered_data(chani,:) = filtfilt(filterweights,1,double(EEG.data(chani,:,1)));
            end
            
            if plots == 1
                chani = 3;
                figure(2), clf
                plot(EEG.times,squeeze(EEG.data(chani,:,1)))
                hold on
                plot(EEG.times,squeeze(filtered_data(chani,:)),'r','linew',2)
                xlabel('Time (ms)'), ylabel('Voltage (\muV)')
                legend({'raw data';'filtered'})
                
            end
            
        end
        
        %Use as:
        %       [ obj ] = resampleData(obj,varargin)
        %
        %   The input, obj if the function is not self-invoked, is the
        %   eegDataClass object.  The next input, varargin, is the new 
        %   sampling rate to use in sampling the data.
        %   The output, obj, is the eegDataClass object
        %   with the appropriate fields corresponding to sample rate 
        %   updated.
        %
        %Perform resampling of data with specified sampling rate input if 
        %necessary and update subject related sampling rate attribute for 
        %accurate preprocessing
        function obj = resampleData( obj, varargin )
            
            if nargin > 1
                srate = varargin{1};
                obj.proc_sRate_raw = srate;
            else
                srate = obj.proc_sRate1;
            end
            
            obj.EEG             = pop_resample( obj.EEG, srate);
            obj.EEG             = eeg_checkset( obj.EEG );
            
        end
        
        %Use as:
        %       [ obj ] = setResampleRate(obj,srate)
        %
        %   The input, obj if the function is not self-invoked, is the
        %   eegDataClass object.  The next input, srate, is the new 
        %   sampling rate.
        %   The output, obj, is the eegDataClass object
        %   with the appropriate fields corresponding to sample rate 
        %   updated.
        %
        %Setter function for the given object input to set the resampling
        %rate related attribute  
        function obj = setResampleRate( obj, srate )
            
            obj.proc_sRate1 = srate;
            
        end
        
        %CURRENTLY UNUTILIZED
        function obj = interpolateData( obj )
            
            obj.EEG = pop_interp(obj.EEG, obj.EEG_prechan.chanlocs, 'spherical');
            
        end
        
        %Use as:
        %       [ obj ] = asrData(obj,param)
        %
        %   The input, obj if the function is not self-invoked, is the
        %   eegDataClass object.  The next input, param, is the 
        %   configuration structure of the cleaning parameters 
        %   (arg_highpass, arg_flatline, etc.).
        %   The output, obj, is the eegDataClass object
        %   with the data cleaned and corresponding attributes updated.
        %
        %Perform cleaning of raw data for given object input and revision
        %performed for channel numbers and data rank based on the cleaned
        %data.
        function obj = asrData( obj, param )
            
            obj.EEG = CleanRawDataClass.cleanRawData( obj.EEG, param );
            
            % revise channel number for log
            obj.net_nbchan_post = obj.EEG.nbchan;
            
            % calculate the independent rank
            if isfield(obj.EEG.etc, 'clean_channel_mask')
                obj.proc_dataRank = min([rank(double(obj.EEG.data')) sum(obj.EEG.etc.clean_channel_mask)]);
            else
                obj.proc_dataRank = rank(double(obj.EEG.data'));
            end
            obj.EEG.etc.dataRank = obj.proc_dataRank;
        end
        
        %Use as:
        %       [ obj ] = averageRefData(obj)
        %
        %   The input, obj if the function is not self-invoked, is the
        %   eegDataClass object.  The output, obj, is the eegDataClass object
        %   with the data rereferenced and corresponding attributes updated.
        %
        %Rereference data to average referencing after import
        %Certain, special rereferencing steps may need to be taken for
        %certain net types such as 'EDFGENERIC' which may need further
        %rereferincing to linked mastoid, etc.
        %Independent data rank will need to be recalculated after
        %rereferencing
        function obj = averageRefData( obj )
            
            obj.EEG.nbchan = obj.EEG.nbchan+1;
            obj.EEG.data(end+1,:) = zeros(1, obj.EEG.pnts);
            %obj.EEG.chanlocs(1,obj.EEG.nbchan).labels = 'initialReference';
            obj.EEG.chanlocs(obj.EEG.nbchan,1).labels = 'initialReference';
            is_edf = strcmp(obj.net_name, 'EDFGENERIC');
            
            if ~(is_edf)
                obj.EEG = pop_reref(obj.EEG, []);
                obj.EEG = pop_select( obj.EEG,'nochannel',{'initialReference'});
            else
                
                try 
                    original_reference = find(ismember({obj.EEG.chanlocs.labels},{'Cz'}));
                    new_references = find(ismember({obj.EEG.chanlocs.labels},{'A1','A2'}));
                    obj.EEG = pop_reref(obj.EEG, [],'keepref','on');
                    obj.EEG = pop_reref(obj.EEG, [new_references(1),new_references(2)]);
                    obj.EEG = pop_select( obj.EEG,'nochannel',{'initialReference'});
                    obj.EEG.nbchan = obj.EEG.nbchan+1;
                    obj.EEG.data(end+1,:) = zeros(1, obj.EEG.pnts);
                    obj.EEG.chanlocs(obj.EEG.nbchan,1).labels = 'initialReference';
                    obj.EEG = pop_reref(obj.EEG, []);
                    obj.EEG = pop_select( obj.EEG,'nochannel',{'initialReference'});
                catch
                    obj.EEG = pop_reref(obj.EEG, []);
                    obj.EEG = pop_select( obj.EEG,'nochannel',{'initialReference'});
                end
            end
            
            if isfield(obj.EEG.etc, 'clean_channel_mask')
                obj.proc_dataRank = min([rank(double(obj.EEG.data')) sum(obj.EEG.etc.clean_channel_mask)]);
            else
                obj.proc_dataRank = rank(double(obj.EEG.data'));
            end
            
            obj.EEG  = eeg_checkset( obj.EEG );
        end
        
        function obj = epochData( obj )
            % old function
            switch obj.study_type
                case 'rest'
                    
                    arg_recurrence = obj.proc_contEpochLength;
                    arg_limits = obj.proc_contEpochLimits;
                    obj.EEG = eeg_regepochs(obj.EEG,'recurrence',arg_recurrence,'limits',arg_limits,'rmbase',NaN);
                    obj.EEG  = eeg_checkset( obj.EEG );
                    
                case 'chirp'
                    s={obj.EEG.event.type};
                    eventTypes=unique(s,'sorted');
                    obj.EEG = pop_epoch( obj.EEG, eventTypes,  obj.proc_contEpochLimits );
                    %EEG = pop_epoch( EEG, All_STIM, vEPOCHERP, 'newname', 'Epochs', 'epochinfo', 'yes');
                    obj.EEG                         = eeg_checkset( obj.EEG );
                    
                    
            end
        end
        
        %Use as:
        %       [ obj ] = outputrow(obj, stage)
        %
        %   The input, obj if the function is not self-invoked, is the
        %   eegDataClass object.  The next input, stage, is the stage 
        %   corresponding to the output generated for the object's data and 
        %   attributes. The output, obj, is the eegDataClass object
        %   with the information dealing with stage attributes and output 
        %   filepaths updated.
        %
        %Generation of excel/csv output for each dataset object
        %Various steps are taken such as assigning the proper stage based 
        %on the input stage, creation of arrays for all 
        %attributes for the input object, and selection of structure 
        %specific attributes for the output object.  The specific structure
        %attributes that are selected can be modified upon the user's needs
        %for the preprocessing occurring
        function obj = outputRow ( obj, stage )
            
            % >> stage 1
            % proc_state
            % subj_basename
            % subj_subfolder
            % study_title
            % filenameimport
  
            propArr = properties(obj);
            
            if strcmpi(stage,'import') || strcmp(stage,'import_trim'), obj.proc_state = 'Import'; end
            if strcmpi(stage,'preica'), obj.proc_state = 'PreICA'; end
            if strcmpi(stage,'level1'), obj.proc_state = 'level1'; end
            
            
            if strcmp(stage, 'error'), obj.proc_state = ['Error-' obj.proc_state]; end
            
            %if strcmp(stage, 'postica'),obj.proc_state = 'PostICA';end
            
            propArr = properties(obj);
            
            customArr = {};
            if strcmp(stage,'import_trim')
                obj.filename.import = [obj.EEG.setname '.set'];
            end
            
            fnArr = fields(obj.filename);
            pathArr = fields(obj.pathdb);
            if strcmp(obj.EEG, '')
                obj.EEG = eeg_emptyset;
            end
            eegArr = fields(obj.EEG);
            fnArr = cellfun(@(x) strcat('filename.', x), fnArr, 'UniformOutput', false);
            pathArr  = cellfun(@(x) strcat('pathdb.', x), pathArr, 'UniformOutput', false);
            eegArr  = cellfun(@(x) strcat('EEG.', x), eegArr, 'UniformOutput', false);
            propArr = [customArr; propArr; fnArr; pathArr; eegArr];
            
            propArr = [[num2cell(1:length(propArr))]' propArr];
            
            fidx = @(x) find(strcmp([propArr(:,2)], x));
            
            if obj.is_event_EEG && strcmp(stage, 'postcomps') && ~obj.exclude_switch
                
                
                fn = obj.eventcfg.event_fn;
                
                str = '';
                
                for i = 1 : length( fn )
                    str = sprintf('%s|%s', str, fn{i});
                end
                
                obj.events_filenames = str;
                obj.filename.eventdata = str;
                
                
                str = '';
                for i = 1 : length( obj.eventcfg.nowTrigger )
                    str = sprintf('%s|%s', str, obj.eventcfg.nowTrigger{i});
                    
                end
                obj.events_dins = str;
                
            end
            
            
            selColumns = [ ...
                fidx('proc_timetag') ...
                fidx('study_user') ...
                fidx('proc_state') ...
                fidx('subj_basename') ...
                fidx('subj_id') ...
                fidx('subj_subfolder') ...
                fidx('study_type') ...
                fidx('study_title') ...
                fidx('net_nbchan_orig') ...
                fidx('net_nbchan_post') ...
                fidx('proc_badchans') ...
                fidx('proc_filt_bandlow') ...
                fidx('proc_filt_bandhigh') ...
                fidx('proc_filt_lowcutoff') ...
                fidx('proc_filt_highcutoff') ...
                fidx('proc_sRate_raw') ...
                fidx('proc_sRate1') ...
                fidx('proc_xmax_raw') ...
                fidx('proc_xmax_post') ...
                fidx('proc_xmax_percent') ...
                fidx('proc_xmax_epoch') ...
                fidx('epoch_length') ...
                fidx('epoch_limits') ...
                fidx('epoch_trials') ...
                fidx('epoch_badtrials') ...
                fidx('epoch_percent') ...
                fidx('epoch_badid') ...
                fidx('proc_removed_regions') ...
                fidx('proc_dataRank') ...
                fidx('proc_ipchans') ...
                fidx('proc_icaweights') ...
                fidx('proc_removeComps') ...
                fidx('exclude_switch') ...
                fidx('events_filenames') ...
                fidx('events_dins') ...
                fidx('exclude_category')
                ];
            
            
            obj.log_subjHeader = propArr(selColumns,2)';
            
            tmpArr = {};
            
            
            
            
            tmpArr = {};
            
            for i = 1 : length(selColumns)
                rowidx = selColumns(i);
                
                
                
                if rowidx == 0
                    tmpArr{end+1} = ' ';
                else
                    str = ['obj.' propArr{selColumns(i),2}];
                    if iscell(eval(str))
                        
                        if rowidx == fidx('exclude_category')
                            str = ['obj.' propArr{selColumns(i),2}];
                            
                            tmp = eval(str);
                            if ~isempty(tmp)
                                tmpstr = '';
                                for j = 1 : length(tmp')
                                    tmpstr = sprintf('%s|%s', tmpstr, tmp{j});
                                end
                                str = tmpstr;
                            else
                                str = 'Included';
                            end
                        end
                        tmpArr{end+1} = str;
                        
                    else
                        
                        tmpArr{end+1} = num2str(eval(str));
                        
                    end
                    
                end
                
                if rowidx == fidx('exclude_category')
                    str = ['obj.' propArr{selColumns(i),2}];
                    
                    tmp = eval(str);
                    if ~isempty(tmp)
                        tmpstr = '';
                        for j = 1 : length(tmp')
                            tmpstr = sprintf('%s|%s', tmpstr, tmp{j});
                        end
                        tmpArr{i} = tmpstr;
                    else
                        tmpArr{i} = 'Included';
                    end
                end
                
                if rowidx == fidx('proc_timetag')
                    tmpArr{i} = strcat('D',num2str(tmpArr{i}));
                    %tmpArr{i} = num2str(tmpArr{i});
                    
                end
                
                if rowidx == fidx('exclude_switch')
                    try
                        tmpArr{i} = logical(str2double(tmpArr{i}));
                    catch
                        tmpArr{i} = logical(0);
                    end
                    %tmpArr{i} = num2str(tmpArr{i});
                end
                
            end
            
            obj.log_subjRow = tmpArr;
            
            if ~obj.exclude_switch
                if obj.is_event_EEG && strcmp(stage, 'postcomps')
                    
                    eventArr        = obj.eventcfg.details;
                    
                    %log_subjHeader  = obj.log_subjHeader;
                    
                    for i = 2:size(eventArr,1)
                        
                        obj.log_subjHeader = [obj.log_subjHeader cellfun(@(x) sprintf('%s_%d', x,i-1), eventArr(1, 1:end), 'uni',0)];
                        obj.log_subjRow = [obj.log_subjRow eventArr(i, 1:end)];
                        
                    end
                end
                
            end
            
            
        end
        
        %CURRENTLY UNUTILIZED
        function obj = lapData( obj )
            
            obj = lap( obj );
        end
        
        %CURRENTLY UNUTILIZED
        function o = sigPowTable( o )
            
            % load dataset
            o.loadDataset('import');
            
            %% What are the limits for each power band?
            frq.maxfreq               = 80;
            
            frq.delta.title           = 'Delta';        frq.theta.title           = 'Theta';
            frq.delta.range           = [0 4];          frq.theta.range           = [4 8];
            
            frq.lo_alpha.title        = 'Low_Alpha';    frq.hi_alpha.title        = 'High_Alpha';
            frq.lo_alpha.range        = [8 10];         frq.hi_alpha.range        = [10 13];
            
            frq.beta.title            = 'Beta';         frq.gamma.title           = 'Gamma';
            frq.beta.range            = [13 30];        frq.gamma.range           = [30 frq.maxfreq];
            
            frq.total.title           = 'Total Range';
            frq.total.range           = [1  frq.maxfreq];
            
            frq.totalex.title         = 'Total Range (excluding gaps)';
            frq.totalex.range         = [frq.delta.range(1):frq.delta.range(end), ...
                frq.theta.range(1):frq.theta.range(end)];
            
            bandtitle = {'Delta','Theta', 'LowAlpha','HighAlpha','Beta','Gamma'};
            
            
            % Define freq. bands and result arrays
            maxfreq = frq.maxfreq;
            
            frq_delta    = [frq.delta.range(1)      frq.delta.range(2)];
            frq_theta    = [frq.theta.range(1)      frq.theta.range(2)];
            frq_lo_alpha = [frq.lo_alpha.range(1)   frq.lo_alpha.range(2)];
            frq_hi_alpha = [frq.hi_alpha.range(1)   frq.hi_alpha.range(2)];
            frq_beta     = [frq.beta.range(1)       frq.beta.range(2)];
            frq_gamma    = [frq.gamma.range(1)      frq.gamma.range(2)];
            frq_total    = [frq.delta.range(1)      maxfreq];
            frq_totalex  = frq.totalex.range;
            
            strdelta            = sprintf('%s %s', frq.delta.title, mat2str(frq_delta));
            strtheta            = sprintf('%s %s', frq.theta.title,mat2str(frq_theta));
            strloalpha          = sprintf('%s %s', frq.lo_alpha.title,mat2str(frq_lo_alpha));
            strhialpha          = sprintf('%s %s', frq.hi_alpha.title,mat2str(frq_hi_alpha));
            strbeta             = sprintf('%s %s', frq.beta.title,mat2str(frq_beta));
            strgamma            = sprintf('%s %s', frq.gamma.title,mat2str(frq_gamma));
            strtotal            = sprintf('%s %s', frq.total.title,mat2str(frq_total));
            strtotalex          = sprintf('%s %s', frq.total.title,mat2str(frq_totalex));
            
            strchanlabels = {strdelta, strtheta, strloalpha, strhialpha,strbeta,strgamma};
            
            
            % What is the results Excel template to use?
            %[~,subid,~] = fileparts(o.EEG.filename);
            subprefix = [o.subj_basename '_'];
            
            % define sampling rate
            srate        = o.EEG.srate;
            
            % define number of epochs
            nepochs      = length(o.EEG.data(1,1,:));
            
            % define number of channels
            nchans       = length(o.EEG.data(:,1,1));
            
            % define number of data points in epoch
            npnts        = length(o.EEG.data(1,:,1));
            
            % number of channels
            chanidx = linspace(1,nchans,nchans)';
            
            % define time (s) of data points in epoch
            time         = o.EEG.times;
            
            % define analysis frequencies
            hz              = linspace(0,srate/2,npnts/2);
            
            % data matrixes for pooled data to create averages
            mat_signal          = zeros(nepochs,npnts,nchans);
            mat_signal_dt       = zeros(nepochs,npnts,nchans);
            mat_signal_hn       = zeros(nepochs,npnts,nchans);
            mat_signalX         = zeros(nepochs,npnts,nchans);
            
            % data matrixes for freq data
            mat_amp             = zeros(nepochs,length(hz),nchans);
            mat_pow             = zeros(nepochs,length(hz),nchans);
            %mat_pow2            = zeros(nepochs, length(hz), nchans);
            
            % Optional tests
            mat_pow_nodt             = zeros(nepochs,length(hz),nchans);    % no detrend or window
            mat_pow_nohn             = zeros(nepochs,length(hz),nchans);    % no taper window (Hann)
            
            
            for chanid = 1:nchans
                for epochid = 1:nepochs
                    
                    % define data signal (per epoch)
                    signal      = o.EEG.data(chanid,:,epochid);
                    
                    % Detrend 2-second epochs for each channel
                    signal_dt   = detrend(signal);
                    
                    % Apply Hann window to detrended signal
                    signal_hn   = hann( length(signal) )' .* signal_dt ;
                    
                    %stitch_signal = [stitch_signal signal_hn];
                    
                    % Create Fourier co-efficients (0.5 Hz freq steps)
                    signalX         = fft( signal_hn, npnts ) ./ npnts;
                    
                    % Multiply positive-frequency coefficients by 2
                    posfrex  = 2:floor(npnts/2);
                    ampl = abs(signalX( 1:length(hz) ));
                    ampl(posfrex) = ampl(posfrex)*2;
                    
                    % Square amplitude to calculate Power
                    power = ampl .^ 2;
                    
                    % capture amplitude & power per epoch in matrix
                    mat_amp(epochid,:,chanid)             = ampl;
                    mat_pow(epochid,:,chanid)             = power;
                    
                    % calculate power band with matlab internal function
                    %mat_pow2(epochid,:,chanid)            = bandpower(signal_hn,256,[0 128]);
                    
                    % Consider effects of detrending and hann window
                    signalX_nodt            = fft( signal, npnts ) ./ npnts;
                    signalX_nohn            = fft( signal_dt, npnts ) ./ npnts;
                    
                    % power calculation without detrending or Hann window
                    power_nodt              = abs(signalX_nodt( 1:length(hz) ));
                    power_nodt(posfrex)     = power_nodt(posfrex)*2;
                    power_nodt              = power_nodt .^2;
                    mat_pow_nodt(epochid,:,chanid)             = power_nodt;
                    
                    % power calculation with detrending but NO Hann window
                    power_nohn              = abs(signalX_nohn( 1:length(hz) ));
                    power_nohn(posfrex)     = power_nohn(posfrex)*2;
                    power_nohn              = power_nohn .^2;
                    mat_pow_nohn(epochid,:,chanid) = power_nohn;
                    
                    
                    % matrix of raw amplitudes
                    % mat_signal(epochs, samples, channels)
                    mat_signal(epochid,:,chanid)          = signal;
                    mat_signal_dt(epochid,:,chanid)       = signal_dt;
                    mat_signal_hn(epochid,:,chanid)       = signal_hn;
                    mat_signalX(epochid,:,chanid)         = signalX;
                    
                end % epoch loop
            end % channel loop
            
            mean_signal             = zeros(nchans,size(mat_signal,2));
            mean_signal_dt          = zeros(nchans,size(mat_signal_dt,2));
            mean_signal_hn          = zeros(nchans,size(mat_signal_hn,2));
            
            mean_signalX            = zeros(nchans,size(mat_signalX,2));
            
            mean_amp                = zeros(nchans, length(hz)); %length(mat_amp));
            mean_pow                = zeros(nchans, length(hz)); %length(mat_pow));
            
            mean_pow_nodt          = zeros(nchans,size(mat_pow_nodt,2));
            mean_pow_nohn          = zeros(nchans,size(mat_pow_nohn,2));
            
            
            for chanid = 1:nchans
                
                mean_signal(chanid,:)                = squeeze(mean(mat_signal(:,:,chanid),1));
                mean_signal_dt(chanid,:)             = squeeze(mean(mat_signal_dt(:,:,chanid),1));
                mean_signal_hn(chanid,:)             = squeeze(mean(mat_signal_hn(:,:,chanid),1));
                
                mean_signalX(chanid,:)            = squeeze(mean(mat_signalX(:,:,chanid),1));
                mean_amp(chanid,:)                = squeeze(mean(mat_amp(:,:,chanid),1));
                mean_pow(chanid,:)                = squeeze(mean(mat_pow(:,:,chanid),1));
                
                mean_signal_nodt(chanid,:)             = squeeze(mean(mat_pow_nodt(:,:,chanid),1));
                mean_signal_nohn(chanid,:)             = squeeze(mean(mat_pow_nohn(:,:,chanid),1));
                
            end
            
            
            rel_mean_pow80      = zeros(nchans,maxfreq);
            
            % create rel power array
            for chanid = 1:nchans
                
                rel_mean_pow80(chanid,:) = mean_pow(chanid,[1:maxfreq]) / sum(mean_pow(chanid,[1:maxfreq]),2);
                
            end
            
            
            bandtitle = { frq.delta.title, frq.theta.title,  frq.lo_alpha.title, ...
                frq.hi_alpha.title, frq.beta.title, frq.gamma.title };
            
            % define result arrays
            res_delta    = zeros(nepochs,1,nchans);
            res_theta    = zeros(nepochs,1,nchans);
            res_lo_alpha = zeros(nepochs,1,nchans);
            res_hi_alpha = zeros(nepochs,1,nchans);
            res_beta     = zeros(nepochs,1,nchans);
            res_gamma    = zeros(nepochs,1,nchans);
            
            
            [ delta_sum, delta_avg ] = powband( frq_delta, mean_pow, hz, srate, npnts );
            [ theta_sum, theta_avg ] = powband( frq_theta, mean_pow, hz, srate, npnts );
            [ lo_alpha_sum, lo_alpha_avg ] = powband( frq_lo_alpha, mean_pow, hz, srate, npnts );
            [ hi_alpha_sum, hi_alpha_avg ] = powband( frq_hi_alpha, mean_pow, hz, srate, npnts );
            [ beta_sum, beta_avg ] = powband( frq_beta, mean_pow, hz, srate, npnts );
            [ gamma_sum, gamma_avg ] = powband( frq_gamma, mean_pow, hz, srate, npnts );
            [ total_sum_all, total_avg ] = powband( frq_total, mean_pow, hz, srate, npnts );
            
            % total sum of relative power based on true intervals
            total_sum = delta_sum + theta_sum + lo_alpha_sum + hi_alpha_sum + beta_sum + gamma_sum;
            
            % Calculate relative power for each of the channel channels:
            % (power at specific frequency) / (total power)
            [delta_rel]      = relpow( delta_sum, total_sum, nchans );
            [theta_rel]      = relpow( theta_sum, total_sum, nchans );
            [lo_alpha_rel]   = relpow( lo_alpha_sum, total_sum, nchans );
            [hi_alpha_rel]   = relpow( hi_alpha_sum, total_sum, nchans );
            [beta_rel]       = relpow( beta_sum, total_sum, nchans );
            [gamma_rel]      = relpow( gamma_sum, total_sum, nchans );
            
            
            % output result table to file
            % relative power
            rel_tb = table(chanidx,delta_rel,theta_rel, ...
                lo_alpha_rel,hi_alpha_rel,beta_rel,gamma_rel);
            
            % absolute power (sum)
            abs_tb = table(chanidx,delta_sum,theta_sum, ...
                lo_alpha_sum,hi_alpha_sum,beta_sum,gamma_sum);
            
            % absolute power (average)
            avg_tb = table(chanidx,delta_avg,theta_avg, ...
                lo_alpha_avg,hi_alpha_avg,beta_avg,gamma_avg);
            
            
            % write tables to file
            
            savefile = fullfile(o.pathdb.analysis,[subprefix '_s4_power.xls']);
            % copyfile( templatefile, savefile );
            
            writetable( abs_tb, savefile, 'sheet', 'abs_sum' );
            writetable( avg_tb, savefile, 'sheet', 'abs_avg' );
            writetable( rel_tb, savefile, 'sheet', 'abs_rel' );
            
            spsslong = zeros(nchans,9);
            
            savefile = fullfile(o.pathdb.analysis,[subprefix '_s4_pow_spss.csv']);
            fid = fopen( savefile, 'w' );
            
            fprintf(fid,'%s,%s,%s,%s, %s,%s,%s,%s,%s,%s,%s\n', ...
                'Subject', 'Group', 'Timepoint', 'Channel', 'Rel_Pow', ...
                frq.delta.title, frq.theta.title, frq.lo_alpha.title, ...
                frq.hi_alpha.title, frq.beta.title, frq.gamma.title);
            
            for chanid = 1:nchans
                fprintf(fid,'%s, %s, %s, %d,%s,%f,%f,%f,%f,%f,%f\n',subprefix, '','', chanid,'relpow', ...
                    rel_tb{1,2}, rel_tb{1,3}, rel_tb{1,4}, ...
                    rel_tb{1,5}, rel_tb{1,6}, rel_tb{1,7});
                fprintf(fid,'%s,%s, %s, %d,%s,%f,%f,%f,%f,%f,%f\n',subprefix, '','', chanid,'abspow', ...
                    abs_tb{1,2}, abs_tb{1,3}, abs_tb{1,4}, ...
                    abs_tb{1,5}, abs_tb{1,6}, abs_tb{1,7});
                fprintf(fid,'%s,%s, %s,%d,%s,%f,%f,%f,%f,%f,%f\n',subprefix, '','', chanid,'avgpow', ...
                    avg_tb{1,2}, avg_tb{1,3}, avg_tb{1,4}, ...
                    avg_tb{1,5}, avg_tb{1,6}, avg_tb{1,7});
            end
            
            fclose( fid );
            
            titlestr.pow_topo_rel = 'test';
            titlestr.pow_topo_fix = 'test';
            titlestr.pow_plot = 'test';
            
            savefile = fullfile(o.pathdb.analysis,[subprefix '_s4_pow_topo_rel.png']);
            htp_rest_power_plots(rel_tb, titlestr, o.pathdb.analysis, o.EEG.chanlocs, savefile, strchanlabels, 'relative');
            
            savefile = fullfile(o.pathdb.analysis,[subprefix '_s4_pow_topo_fixed.png']);
            htp_rest_power_plots(rel_tb, titlestr, o.pathdb.analysis, o.EEG.chanlocs, savefile, strchanlabels, 'fixed');
            
            savefile = fullfile(o.pathdb.analysis,[subprefix '_s4_plot.png']);
            powplot(mean_pow(1:o.EEG.nbchan,:), hz, 'relpow', savefile);
            
            
            for i = 1:length(o.net_regions)
                
                savefile = fullfile(o.pathdb.analysis,[subprefix '_s' num2str(i) '_plot.png']);
                powplot(mean_pow(o.net_regions{i,3},:), hz, o.net_regions{i,1}, savefile);
                
            end
            
            % unload data
            o.removeData;
            
            
            %
            % savefile = fullfile([subprefix '_s4_pow_topo.png']);
            % plot_stitch(subprefix, savefile, o.pathdb.analysis);
            
            
            
        end
        
        %Use as:
        %       [ o ] = setStudyType(o, str)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The next input, str, is the title 
        %   the study wil be set to after function completion.
        %   The output, o, is the eegDataClass object
        %   with the study title information and attributes updated.
        %
        %Setter function for the study type for the current preprocessing 
        %to the specified string input.
        %The study_type is set depending on if the preprocessing is for
        %rest or event epoch data.
        function o = setStudyType( o, str )
            
            o.study_type = str;
            
        end
        
        %Use as:
        %       [ str ] = getStudyType(o)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The output, str, is the study type of the 
        %   eegDataClass object.
        %
        %Getter function for the study type of the current preprocessing
        %occurring
        function str = getStudyType( o )
            
            str = o.study_type;
            
        end
        
        %Use as:
        %       [ o ] = setStudyType(o, timetag)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The next input, timetag, is the string of
        %   the timestamp to be set.
        %   The output, o, is the eegDataClass object
        %   with the timetag updated to the supplied timestamp.
        %
        %Setter function for the timetag of the subject object input
        %Sets the processing timetag to be used in various stages of
        %preprocessing for output means.
        function o = setTimeTag( o, timetag )
            
            try
                o.proc_timetag = timetag;
            catch
                o.proc_timetag = '0000';
            end
            
        end
        
        %Use as:
        %       [ o ] = setopt(o, opt)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The next input, opt, is an options 
        %   configuration structure.
        %   The output, o, is the eegDataClass object
        %   with the options related field set with the configuration 
        %   supplied options.
        %
        %Setter function for the options structure for an object
        function o = setopt( o, opt )
            
            o.opt = opt;
            
        end
        
        %Use as:
        %       [ o ] = setBasepath(o, pathstr)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The next input, pathstr, is the string to 
        %   be set as the basepath for the eegDataClass object.  The output, 
        %   o, is the eegDataClass object with the basepath updated and EEG
        %   data attribute initialized.
        %
        %Set the base path string for the subject object to the input
        %pathStr parameter and initialize the EEG attribute.
        function o = setBasepath( o, pathStr )
            o.subj_basepath = pathStr;
            o.EEG = eeg_emptyset; % (EEGLAB function)
            
        end
        
        %CURRENTLY UNUTILIZED
        function set_exclude( o, inputStruct )
            
            o.exclude_switch = inputStruct.switch;
            o.exclude_comment = inputStruct.comment;
            o.exclude_category = inputStruct.category;
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = setMraStatus( o, status_code )
            
            switch status_code
                case {'Reprocess',1} , code = 1;
                case {'Comps Only',2}, code = 2;
                case {'Exclude',3}, code = 3;
                case {'Approve',4}, code = 4;
                    
                otherwise
                    
            end
            
            o.exclude_status = code;
        end
        
        %CURRENTLY UNUTILIZED
        function o = set_gui_exclude_true( o )
            
            o.exclude_switch = true;
            o.exclude_comment = 'user selected exclude';
            o.exclude_category = 'GUI';
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = set_gui_exclude_false( o )
            
            o.exclude_switch = false;
            o.exclude_comment = '';
            o.exclude_category = '';
            
        end
        
        %Use as:
        %       [ exclude_switch ] = get_exclude_switch(o)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The output, 
        %   exclude_switch, is the flag value for if the eegDataClass 
        %   should be excluded from the stage of preprocessing.
        %
        %Getter function for the exclusion flag for the subject object.
        %The flag represents the exclusion of the subject from certain
        %preprocessing steps
        function exclude_switch = get_exclude_switch( o )
            
            exclude_switch = o.exclude_switch;
            
        end
        
        %Use as:
        %       [ exclude_switch ] = get_exclude_switch(o)
        %
        %   The input, o if the function is not self-invoked, is the
        %   eegDataClass object.  The output, 
        %   exclude_switch, is the flag value for if the eegDataClass 
        %   should be excluded from the stage of preprocessing.
        %
        %Setter function for the exclusion flag for the subject object
        %dependent upon the input toggle parameter.
        function exclude_subject( o, toggle )
            
            switch toggle
                case 'yes'
                    o.exclude_switch = true;
                case 'no'
                    o.exclude_switch = false;
            end
        end
        
        %Getter function for obtaining clinical field of interest based on
        %the fieldname input parameter
        function res = getMeasByFieldName( o, fieldname )
            
            res = o.meas.(fieldname);
        end
        
        %Setter function for setting the subject's specific subfolder as
        %the current basename attribute value for the subject
        function o = setSubfolderAsSubjname( o )
            o.subj_subfolder = o.subj_basename;
        end
        
        %Assign the input filename parameter as the associated dataset file
        %for the subject along with assigning a subfolder to which the
        %subject belongs.  A unique subject basename is generated for the
        %subject
        function o = assignRawFile( o, subfolder, filename )
            
            [~, o.filename.raw, tmpExt]  = fileparts(filename);
            o.filename.raw = [o.filename.raw tmpExt];
            
           
            o.subj_subfolder = subfolder;
            
            
            filename(strfind( filename, ' ' )) = '';
            
            [~, o.subj_basename, ~]  = fileparts(filename);
            
            o.subj_basename = ['D' o.subj_basename];
            
            rawfullfile = fullfile(o.pathdb.raw, o.subj_subfolder, o.filename.raw);
            
            if exist(rawfullfile, 'file') == 2
            else
                fprintf('%s\nFile does not exist, check filename and path.', rawfullfile);
                
            end
            
        end
        
        %Assign the htpcfg structure input parameter to the subject object 
        function obj = assigncfg( obj, htpcfg )
            
            obj.htpcfg = htpcfg;
            
        end
        
        %Getter function for the subfolder that the subject object belongs
        %to.  This usually indicating the group of a study to which a 
        %subject belongs.
        function result = get_subfolder( obj )
            
            result = obj.subj_subfolder;
        end
        
        %Load the event dataset for the specified file via the
        %idx input parameter, utilized in preprocessing stages, specifically in
        %stage 4.
        function o = loadDataset_Event( o, idx )
            
            fn = o.eventcfg.event_fn;
            setfile = fn{idx};
            path = fullfile(o.pathdb.postica,o.subj_subfolder);
            
            o.EEG = pop_loadset( 'filename', setfile, 'filepath', path);
            
            o.EEG  = eeg_checkset( o.EEG );
            
        end
        
        %Load the dataset for the specified stage via the stage input
        %parameter, and the setfile and path are used to load the dataset
        %to proceed with the current stage of preprocessing.
        function o = loadDataset(o, stage)
            if strcmp(stage, 'import') || strcmp(stage, 'import_trim')
                setfile = o.filename.import;
                path = fullfile(o.pathdb.import,o.subj_subfolder);
                
            elseif strcmp(stage, 'preica')
                setfile = o.filename.preica;
                path = fullfile(o.pathdb.preica,o.subj_subfolder);
                
            elseif strcmp(stage, 'postica')
                setfile = o.filename.postica;
                path = fullfile(o.pathdb.postica,o.subj_subfolder);
                
            elseif strcmp(stage, 'postcomps')
                setfile = o.filename.postcomps;
                path = fullfile(o.pathdb.postcomps,o.subj_subfolder);
                
            elseif strcmp(stage, 'preanalysis')
                setfile = o.filename.preanalysis;
                path = fullfile(o.pathdb.preanalysis,o.subj_subfolder);
                
            elseif strcmp(stage, 'level1')
                setfile = o.filename.level1;
                path = fullfile(o.pathdb.level1,o.subj_subfolder);
                
            elseif strcmp(stage, 'group')
                setfile = o.filename.group;
                path = fullfile(o.pathdb.group,o.subj_subfolder);
                
            elseif strcmp(stage, 'source')
                setfile = o.filename.postcomps;
                path = fullfile(o.pathdb.source,o.subj_subfolder);
                
            end
            
            o.EEG = pop_loadset( 'filename', setfile, 'filepath', path);
            
            o.EEG  = eeg_checkset( o.EEG );
            
            
        end
        
        %Opens the dataset using the various folder and file path related
        %input parameters supplied
        function o = openDataset(o, open_directory, open_subfolder, open_filename)
            
            openfile = fullfile(open_directory, open_subfolder, open_filename);
            
            o.EEG = pop_loadset( 'filename', openfile);
            
        end
        
        %CURRENTLY UNUTILIZED
        function obj = removeData ( obj )
            
            obj.EEG = eeg_emptyset;
            obj.EEG_raw = eeg_emptyset;
            obj.EEG_prefilt = eeg_emptyset;
            obj.EEG_prechan = eeg_emptyset;
            obj.EEG_postcomps = eeg_emptyset;
            obj.EEG_preanalysis = eeg_emptyset;
            obj.EEG_preica = eeg_emptyset;
            obj.EEG_postica = eeg_emptyset;
            obj.EEG_import = eeg_emptyset;
            obj.EEG_level1 = eeg_emptyset;
            
            
        end
        
        %Unloads data by emptying the EEG related dataset attributes for
        %the subject object.  Potential significant decrease in memory
        %usage during preprocessing.
        function obj = unloadDataset ( obj )
            
            obj.EEG = eeg_emptyset;
            obj.EEG_raw = eeg_emptyset;
            obj.EEG_prefilt = eeg_emptyset;
            obj.EEG_prechan = eeg_emptyset;
            obj.EEG_postcomps = eeg_emptyset;
            obj.EEG_preanalysis = eeg_emptyset;
            obj.EEG_preica = eeg_emptyset;
            obj.EEG_postica = eeg_emptyset;
            obj.EEG_import = eeg_emptyset;
            obj.EEG_level1 = eeg_emptyset;
            
        end
        
        %Create specified interval epochs for continuous Rest type dataset
        %via the EEGLAB eeg_regepochs function and updating the subject
        %epoch related attributes
        function o = createEpochs( o )
            o.proc_contEpochLength = o.opt.epoch_length;
            o.proc_contEpochLimits = o.opt.epoch_limits;
            
            arg_recurrence = o.proc_contEpochLength;
            arg_limits = o.proc_contEpochLimits;
            %o.EEG_preica = eeg_regepochs(o.EEG,'recurrence', ...
            %  arg_recurrence,'limits',arg_limits,'rmbase',NaN);
            o.EEG = eeg_regepochs( o.EEG, 'recurrence', arg_recurrence,'limits',arg_limits, 'extractepochs', 'on', 'rmbase', NaN );
            
            o.proc_xmax_epoch = o.EEG.trials * abs(o.EEG.xmax-o.EEG.xmin);
            
            for i = 1 : length( o.EEG.epoch )
                
                o.EEG.epoch( i ).trialno = i;
                
            end
            
            o.EEG  = eeg_checkset( o.EEG );
            
            o.epoch_length = arg_recurrence;
            o.epoch_limits = arg_limits;
            o.epoch_trials = o.EEG.trials;
            
        end
        
        %Create epochs for Event type dataset by tracking specified 
        %variables and utilizing target triggers while removing duplicate 
        %and proceeding to update the subject epoch related attributes
        function o = createEpochsERP( o )
            
            % tracked variables
            try
                det = o.eventcfg.details;
                detvars = {'DIN', 'xmax', 'limitA', 'limitB', 'ERPlimA', 'ERPlimB', 'baselineA', 'baselineB', 'removeBl', 'trials_og', 'trials_final', 'trials_remove', 'trials_per', 'filename'};
                if isempty(det)
                    det = {};
                    det(1,:) = detvars; % initialize results array
                end
            catch
                detvars = {'DIN', 'xmax', 'limitA', 'limitB', 'ERPlimA', 'ERPlimB', 'baselineA', 'baselineB', 'removeBl', 'trials_og', 'trials_final', 'trials_remove', 'trials_per', 'filename'};
                det(1,:) = detvars; % initialize results array
            end
            
            ecfg = o.eventcfg;
            if o.eventcfg.levelb ~= 1
                ecfg.nowInterval = char(o.htpcfg.optnow.Stage2_EventLimits);
            else
                %o.eventcfg.nowInterval_lvlB = o.eventcfg.nowInterval;
                ecfg.bLimits = char(o.htpcfg.optnow.Stage2_LevelBLimits);
            end
            
            % helper functions
            fidx = @(x) find(strcmp(x, detvars));
            cidx = @(x) find(strcmp(x, fields(ecfg)));
            
            try
                if strcmp(ecfg.stage, 'C')
                    nowTrigger      = ecfg.('din_code');
                else
                    nowTrigger      = ecfg.('nowTrigger');
                end
            catch
                nowTrigger      = ecfg.('nowTrigger');
            end
            
            nowRename       = ecfg.('nowRename');
            nowElectrodeSet = ecfg.('nowElectrodeSet');
            nowElectrodes   = ecfg.('nowElectrodes');
            o.eventcfg.removeBaseline = char(o.htpcfg.optnow.Stage2_EventRemoveBaseline);
            
            try
                tmp = strsplit(o.eventcfg.nowBaseline);
                o.eventcfg.nowBaseline     = [str2num(tmp{1}) str2num(tmp{2})];
                
                tmp = strsplit(ecfg.nowInterval);
                o.eventcfg.nowInterval     = [str2num(tmp{1}) str2num(tmp{2})] / 1000;
                
                tmp = strsplit(ecfg.bLimits);
                o.eventcfg.bLimits    = [str2num(tmp{1}) str2num(tmp{2})] / 1000;
                
            catch
                o.msgout('Variables already converted to matrixes.','proc_msg');
            end
            %tmp = strsplit(o.eventcfg.nowInterval);
            
            % remove duplicates
            if any(strcmp(nowTrigger, det(:,1)) == 1)
                delete_idx = strcmp(nowTrigger, det(:,1));
                det(delete_idx, :) = [];
            end
            
            det(end+1:end+length(nowTrigger'),1) = cell(nowTrigger');
            
            det(end, fidx('baselineA')) = deal({o.eventcfg.nowBaseline(1)});
            det(end, fidx('baselineB')) = deal({o.eventcfg.nowBaseline(2)});
            det(end, fidx('removeBl')) = deal({o.eventcfg.removeBaseline});
            det(end, fidx('limitA')) = deal({o.eventcfg.nowInterval(1)});
            det(end, fidx('limitB')) = deal({o.eventcfg.nowInterval(2)});
            
            if o.eventcfg.levelb == 1
                det(end, fidx('ERPlimA')) = deal({o.eventcfg.bLimits(1)});
                det(end, fidx('ERPlimB')) = deal({o.eventcfg.bLimits(2)});
            end
            % use target trigger, not code.
            nowTrigger      = ecfg.('nowTrigger');
            
            o.filename.event = {};
            
            for j = 1 : length(o.eventcfg.nowTrigger)
                % select dataset to cu
                
                if o.eventcfg.levelb == 1
                    if strcmp(o.eventcfg.stage, 'A')
                        o.loadDataset('postica');
                    else
                        if strcmp(o.eventcfg.stage, 'B')
                            str = ['Working dataset: ' o.EEG.setname];
                            o.msgout(str,'msg_complete');
                            %o.loadDataset_Event(1);
                        end
                    end
                    
                else
                    
                end
                
                EEGtemp = o.EEG;
                
                [basefolder, basefile,~] = fileparts(fullfile(o.filename.postica));
                eventname = o.eventcfg.nowTrigger{j};
                if strcmp(o.eventcfg.stage, 'C')
                    o.eventcfg.event_fn{end+1} = o.EEG.filename;
                else
                    o.EEG.filename = fullfile([basefile '_' sprintf('%s.set', eventname)]);
                    o.EEG.setname = o.EEG.filename;
                    o.eventcfg.event_fn{end+1} = o.EEG.filename;
                    
                end
                det{end, fidx('filename')} = o.eventcfg.event_fn{end} ;
                if o.eventcfg.levelb == 1 && strcmp(o.eventcfg.stage, 'B') || strcmp(o.eventcfg.stage, 'C')
                    EEGtemp = pop_epoch( EEGtemp,   nowTrigger(j)  , o.eventcfg.bLimits, 'epochinfo', 'yes', 'newname', o.EEG.filename);
                else
                    
                    EEGtemp = pop_epoch( EEGtemp,   nowTrigger(j)  , o.eventcfg.nowInterval, 'epochinfo', 'yes', 'newname', o.EEG.filename);
                end
                
                
                if strcmp(  o.eventcfg.nowBaseline, 'Yes' )
                    EEGtemp = pop_rmbase( EEGtemp,  o.eventcfg.nowBaseline );
                end
                
                EEGtemp = eeg_checkset( EEGtemp );
                %    EEGtemp = pop_selectevent( EEGtemp, 'type', eventname,'deleteepochs','on', 'deleteevents', 'on');
                %  EEGtemp = eeg_checkset( EEGtemp );
                o.storeDataset(EEGtemp, o.pathdb.postica, o.subj_subfolder, o.EEG.filename);
                
                o.filename.event{end+1} = o.EEG.filename;
                
                det{end, fidx('xmax')} = EEGtemp.trials * abs(EEGtemp.xmax-EEGtemp.xmin);
                det{end, fidx('trials_og')} = length(EEGtemp.epoch);
                
                %         sub(i) = s;
                %         sub(i).unloadDataset;
                %
                % s.createEpochsERP('FEEDBACK', [-0.2 0.75]);
                %EEG = pop_epoch( EEG, {  'DI11'  'DIN1'  'DIN5'  }, [-1  2], 'newname', 'D0401_RLEEG2_import.set epochs', 'epochinfo', 'yes');
                for i = 1 : length( o.EEG.epoch )
                    
                    o.EEG.epoch( i ).trialno = i;
                    
                end
                o.unloadDataset;
            end
            
            o.eventcfg.details = det;
            % det = cell2table(det);
            % det.Properties.VariableNames = detvars;
            
            o.epoch_length = 'Event';
            o.epoch_limits = 'Event';
            o.epoch_trials = 'Event';
            
        end
        
        %Conversion of eventless, resting data to singular, continuous epoch 
        function o = epoch2cont( o )
            
            EEG = o.EEG;
            EEG.data = reshape(EEG.data, size(EEG.data,1), size(EEG.data,2)*size(EEG.data,3));
            EEG.pnts   = size(EEG.data,2);
            EEG.trials = 1;
            EEG.event = [];
            EEG.epoch = [];
            EEG.urevent = [];
            
            o.EEG = eeg_checkset( EEG );
                       
        end
        
        %CURRENTLY UNUTILIZED
        function o = renameEvents( o )
            
            EEG2 = o.EEG;
            
            trigIdx = find(strcmp({EEG2.event.type}, 'DIN9'));
            og_DIN9 = find(strcmp({EEG2.event.type}, 'DIN9'));
            
            for i = 1 : length(trigIdx)
                
                EEG2.event(trigIdx(i)).type = 'FEEDBACK';
                
            end
            
            
            trigIdx = find(strcmp({EEG2.event.type}, 'DI11'));
            og_DIN11 = find(strcmp({EEG2.event.type}, 'DI11'));
            
            for i = 1 : length(trigIdx)
                
                EEG2.event(trigIdx(i)).type = 'FEEDBACK';
                
            end
            
            o.EEG = EEG2;
            
        end
        
        
        %Uses the current subject basename attribute and appends each stage
        %name with a set file extension to populate the filename fields
        %that are utilized throughout each stage of preprocessing when
        %saving and loading datasets.
        function o = createFileNames( o )
            
                        
            fn.raw    = o.filename.raw;
            fn.import = [o.subj_basename '_import.set'];
            fn.preica = [o.subj_basename '_preica.set'];
            fn.postica = [o.subj_basename '_postica.set'];
            fn.level1 = [o.subj_basename '_level1.set'];
            fn.postcomps = [o.subj_basename '_postcomp.set'];
            fn.preanalysis = [o.subj_basename '_preanalysis.set'];
            fn.ftdat = [o.subj_basename '_ft_dat.mat']; % large datasets only
            fn.ftoutput = [o.subj_basename '_ft_output.mat'];  % all other output
            fn.ftcfg = [o.subj_basename '_ft_cfg.mat'];  % ft config only
            fn.signal_info = [o.subj_basename '_postcomp_info.mat'] ;
            fn.signal_data = [o.subj_basename '_postcomp_signal.mat'] ;
            fn.signal_comps = [o.subj_basename '_postcomp_comps.mat'] ;

            o.filename = fn;
        end
        
        %CURRENTLY UNUTILIZED
        function o = updateSubfolder( o, folderstr )
            
            o.subj_subfolder = folderstr;
            
        end
        
        %Saves the EEG dataset for the subject to the path supplied by the
        %folder and path input parameters to be able to be loaded and 
        %stored throughout each stage.  If the save directory does not
        %exist, one will be made to save the dataset within.
        function o = storeDataset(o, EEG, save_directory, save_subfolder, save_filename)
            
            EEG.setname = save_filename;
            EEG.subject = o.subj_basename;
            EEG.group = o.subj_subfolder;
            EEG.condition = o.subj_subfolder;
            
            savefile = fullfile(save_directory, save_subfolder, save_filename);
            
            workingdir = fullfile(save_directory, save_subfolder);
            if 7~=exist(workingdir,'dir'), status = mkdir(workingdir); end
            
            
            EEG = pop_saveset( EEG, 'filename', savefile );
            
            o.msgout(sprintf('Storing Dataset: %s\n', savefile), 'proc_complete');
            
            o.EEG = EEG;
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = modifySignal( o, varargin )
            
            if nargin < 2
                o.msgout('No modification to signal');
            else
                opt = varargin;
            end
            
            
            if ~isempty(o.EEG)
               
                for i = 1 : length(opt)
                   
                    switch opt{i}
                        case 'removeEpochs'                       
                            if length(o.EEG.epoch) > 1
                            o.epoch2cont;
                            else
                                o.msgout('No epochs found.');
                            end
                    end
                    
                end
                
            else
                
                o.msgout('No EEG dataset loaded. No save performed.', 'proc_warning');
                
            end
            
            
        end
                
        %CURRENTLY UNUTILIZED
        function [header, row] = storeSignal( o )
            
            if ~isempty(o.EEG)
                o.generateIcaAct;
                                
                pnts = 1 : o.EEG.pnts;
                dat = [o.EEG.data; pnts; o.EEG.times ];
                comps = [o.EEG.icaact; pnts; o.EEG.times ];
                
                o.EEG.data = [];   
                o.EEG.icaact = [];
                
                o.EEG.datrows = {o.EEG.chanlocs.labels 'Pnts' 'Time'};
                o.EEG.compsrows = {num2cell(o.EEG.icachansind) 'Pnts' 'Time'};
                
                o.EEG.etc.datafile = fn_data; 
                o.EEG.etc.icaactfile = fn_comps;
                o.EEG.etc.infofile = fn_info;
                
                info.EEG = o.EEG;
                
                % o.EEG = [];
                
                o.unloadDataset;
                
                info.s = o;
               
            else                
                o.msgout('No EEG dataset loaded. No save performed.', 'proc_warning');                
            end
            
            workingdir = fullfile(o.pathdb.signal, o.subj_subfolder);
            if 7~=exist(workingdir,'dir'), status = mkdir(workingdir); end
            
            save(fn_info, 'info');
            save(fn_data, 'dat');
            save(fn_comps, 'comps');
            
        end
        
        %CURRENTLY UNUTILIZED
        function [header, row] = signalRow( o )
            try
                % create filenames
                o.createFileNames;
                
                % create full filenames
                fn_info = fullfile(o.pathdb.signal, o.subj_subfolder, o.filename.signal_info);
                fn_data = fullfile(o.pathdb.signal, o.subj_subfolder, o.filename.signal_data);
                fn_comps = fullfile(o.pathdb.signal, o.subj_subfolder, o.filename.signal_comps);
                
                % create signal csv table
                o.sig = [];
                o.sig.proc_timetag = sprintf('A%d', mat2str(o.proc_timetag));
                o.sig.proc_state = o.proc_state;
                o.sig.subj_basename = o.subj_basename;
                o.sig.subj_id = mat2str(o.subj_id);
                o.sig.subj_subfolder = o.subj_subfolder;
                o.sig.filename_signal_info = fn_info;
                o.sig.filename_signal_data = fn_data;
                o.sig.filename_signal_comps = fn_comps;
                o.sig.xmin = o.EEG.xmin;
                o.sig.xmax = o.EEG.xmax;
                o.sig.original_xmax = o.proc_xmax_raw;
                o.sig.srate = o.EEG.srate;
                o.sig.nbchan = o.EEG.nbchan;
                o.sig.pnts = o.EEG.pnts;
                o.sig.time_start = o.EEG.times(1);
                o.sig.time_end = o.EEG.times(end);
                o.sig.rank = o.proc_dataRank;
                
                t = {o.EEG.chanlocs.labels};
                o.sig.chanlabels = sprintf('%s|', t{:});
                o.sig.icachansind = sprintf('%d|', o.EEG.icachansind);
                o.sig.badchannels = sprintf('%d|', o.proc_badchans);
                o.sig.netfile = o.net_name;
                o.sig.removedcomps = sprintf('%d|', o.proc_removeComps);
                o.sig.excluded = o.exclude_status;
                
                o.log_signal = struct();
                
                o.log_signal.table = struct2table( o.sig, 'AsArray', true );
                o.log_signal.row = table2cell( o.log_signal.table );
                o.log_signal.header = o.log_signal.table.Properties.VariableNames;
                
                row = o.log_signal.row;
                header = o.log_signal.header;
            catch
                
                row = 'Error: SignalRow';
                
            end
        end
        
        %CURRENTLY UNUTILIZED
        function propArr = createFullPropertyArray( o )
            
            propArr = properties(o);
            
            customArr = {};
            try
            if strcmp(stage,'import_trim')
                o.filename.import = [o.EEG.setname '.set'];
            end
            catch
                o.msgout('Import_trim step omitted', 'proc_warning');
            end
            
            
            fnArr = fields(o.filename);
            pathArr = fields(o.pathdb);
%             if strcmp(o.EEG, '')
%                 o.EEG = eeg_emptyset;
%             end
            eegArr = fields(o.EEG);
            fnArr = cellfun(@(x) strcat('filename.', x), fnArr, 'UniformOutput', false);
            pathArr  = cellfun(@(x) strcat('pathdb.', x), pathArr, 'UniformOutput', false);
            eegArr  = cellfun(@(x) strcat('EEG.', x), eegArr, 'UniformOutput', false);
            propArr = [customArr; propArr; fnArr; pathArr; eegArr];
            
            propArr = [[num2cell(1:length(propArr))]' propArr];
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = fplot( o )
            fastplot(o.EEG);
        end
        
        %CURRENTLY UNUTILIZED
        function o = EEGBrowser( o )
            EEGBrowser(o.EEG);
        end
        
        %Create a spectrum for the specified percentage of EEG data and
        %frequencies, utilized in subject-level analysis specifically to 
        %give the user an in-depth look at subject-level data.
        function o = quickSpect( o )
            try
            EEG = o.EEG;
            figure; 
            pop_spectopo(EEG, 1, [EEG.xmin*1000   EEG.xmax*1000], ...
                'EEG' , 'percent', 15, 'freq', [5 10 30 80], 'freqrange',[1 80],'electrodes','off');
            catch
                
                disp('Error: QuickSpect, check if data loaded');
            end
            
        end
        
        %Sets the basepath at the subject level, usually based upon the 
        %basepath of head htpPreprocessMaster object to ensure correct 
        %placement of files and reference of configuration files.  Also 
        %performs definition of appropriate paths for the various stage 
        %files and outputs relating to the specific subject's data
        function o = createPaths( o, varargin )
            minArgs=0;
            maxArgs=2;
            
            narginchk(minArgs,maxArgs);
            
            if ~isempty(varargin)
                
                basepath = varargin{1};
                o.subj_basepath = basepath;
                
            else
                
                basepath = o.subj_basepath;
                
            end
            
            o.definePaths( basepath );
            
            o.pathCellArr = {};
            fns = fieldnames(o.pathdb);
            md = @(x) mkdir(x);
            
            for i = 1: length(fns)
                o.pathCellArr{i}=o.pathdb.(fns{i});
            end
           
            try
                
                for iPath = o.pathCellArr, md(iPath{1}); end
                
            catch
                str = sprintf('Please check data directory name.\n%s', basepath);
                o.msgout(str);
            end
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = makePathDirectories( o )
            try
                md = @(x) mkdir(x);
                
                % create directory
                for iPath = o.pathCellArr, md(iPath{1}); end
                
            catch
                disp('Please check directory name.');
            end
            
            
        end
        
        %Uses ICview plugin to classify and optionally remove artifactual 
        %components for creating a draft artifact free dataset.  If 
        %number of removed comps > 10% of total channels, exclude the file.
        %The extra input parameters represent the proportion of confidence
        %that the component is classified and the flag to remove or
        %recalculate components.  The number of components screened and
        %selected can be modified to suit user's needs, set at 50
        %currently.  This method is utilized for stage 4 of preprocessing.
        function o = removeComps_auto( o, threshold, remove )
            
            range = 1:50;       % only screen and select 1:n components
            
            get_ic = @(x) o.get_icview_comps(x, threshold, range);  % parse classification from plugin
            
            comps_artifact = [get_ic('Eye') get_ic('Heart') get_ic('Muscle') get_ic('Line Noise')];
            
            n_comps = length(comps_artifact);
            
            o.proc_removeComps = comps_artifact;
            
            o.proc_state = 'postcomps';
            
            if n_comps > round( 0.2 * o.EEG.nbchan)
                
                o.msgout(sprintf('ID: s: exceeded threshold comps (%n > %n)', o.subj_basename, n_comps, o.EEG.nbchan), 'proc_warning');
                o.exclude_subject( 'yes' );
                
            end
            
            if remove
                o.compRemove;
                
            end
            
            
        end
        
        %Sets the study user to the specified user of the pipeline during 
        %preprocessing configuration to be used in documentation of the
        %preprocessing tasks done for the subject.
        function o = setUser( o, username )
            
            o.study_user = username;
            
        end
        
        %Sets the Study Configuration for the specified subject object to
        %be utilized during each stage of preprocessing
        function o = setHtpCfg( o, htpcfg )
            
            o.htpcfg = htpcfg;
            
        end
        
        %Sets the csv output file name for the subject object for any stage
        %specific output files
        function o = setCsv( o, csvname )
            
            o.study_csv = csvname;
            
        end
        
        %Sets the mat data output file name for the subject object for any 
        %stage specific output files 
        function o = setMat( o, matname )
            
            o.study_mat = matname;
            
        end
        
        %Update the configuration script path for the subject object
        function o = updateScriptPath(o, scriptPath)
            
            o.htpcfg.scriptPath = scriptPath;
            
        end
        
        %Defines the default directories of the subject's path structure
        %for various stages of preprocessing and related directories
        %(RAW, stages 1-4 event data, ICA weights, etc.) using the 
        %specified base path input parameter.  The user should only ever 
        %add data files themself to the S00_RAW directory.
        function o = definePaths( o, basepath )
       
            o.pathdb.analysis        = fullfile(basepath, 'A00_ANALYSIS/');
            o.pathdb.raw             = fullfile(basepath, 'S00_RAW/');
            o.pathdb.import          = fullfile(basepath, 'S01_IMPORT/');
            o.pathdb.preica          = fullfile(basepath, 'S02_PREICA/');
            o.pathdb.postica         = fullfile(basepath, 'S03_POSTICA/');
            o.pathdb.postcomps       = fullfile(basepath, 'S04_POSTCOMP');
            o.pathdb.preanalysis     = fullfile(basepath, 'S04b_PREANALYSIS');
            o.pathdb.level1          = fullfile(basepath, 'S05_LEVEL1/');
            o.pathdb.group           = fullfile(basepath, 'S06_GROUP/');
            o.pathdb.figs            = fullfile(basepath, 'A01_FIGS/');
            o.pathdb.icaweights      = fullfile(basepath, 'ICAWEIGHTS');
            o.pathdb.do              = fullfile(basepath, 'dataobjects');
            o.pathdb.eventdata       = fullfile(basepath, 'eventdata');
            o.pathdb.pca             = fullfile(basepath, 'S04b_PCA');
            o.pathdb.ft                 = fullfile(basepath, 'ft');
            o.pathdb.signal         = fullfile(basepath, 'signal');
            o.pathdb.source          = fullfile(basepath, 'source');
            o.pathdb.chanfiles          = fullfile(basepath, 'chanfiles');
            o.pathdb.brainwave       = fullfile(basepath, 'brainwave');
            
        end
        
        %Definte the default directories and then update the subject
        %object's path cell array to contain the updated path structure
        %attribute values.
        function o = updatePaths( o, basepath )
            
            o.definePaths( basepath );
           
            o.pathCellArr = {};
            fns = fieldnames(o.pathdb);
            
            for i = 1:length(fns)               
                o.pathCellArr{end+1} = o.pathdb.(fns{i});                
            end
            
            dataPath = {o.pathdb.analysis, o.pathdb.raw, o.pathdb.import, o.pathdb.preica, ...
                o.pathdb.level1, o.pathdb.postcomps, o.pathdb.preanalysis, o.pathdb.group, o.pathdb.figs, o.pathdb.ft,  o.pathdb.icaweights};
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = findProcFiles( o )
            
            pathCellArr = {};
            fns = fieldnames(o.pathdb);
            
            for i = 1:length(fns)
                
                pathCellArr{end+1} = o.pathdb.(fns{i});
                
            end
            
            searchIdx = [];
            
            searchIdx(end+1) = find(contains(pathCellArr', 'RAW'));
            searchIdx(end+1) = find(contains(pathCellArr,'IMPORT'));
            searchIdx(end+1) = find(contains(pathCellArr,'PREICA'));
            searchIdx(end+1) = find(contains(pathCellArr,'POSTICA'));
            searchIdx(end+1) = find(contains(pathCellArr,'POSTCOMP'));
            searchIdx(end+1) = find(contains(pathCellArr,'PREANALYSIS'));
            searchIdx(end+1) = find(contains(pathCellArr,'LEVEL1'));
            
            dispIdx = {};
            
            for i = 1:length(searchIdx)
                
                
                fullfile(pathCellArr{searchIdx(i)}, ...
                    o.subj_subfolder, [o.subj_basename '.set']);
                
                endout=regexp(testFile,filesep,'split');
                
                stageName = regexp(pathCellArr{searchIdx(i)},filesep,'split');
                stageName = stageName{end-1};
                
                
                if  find(contains(endout,'S01_RAW')) > 0
                    
                    testFile = fullfile(pathCellArr{searchIdx(i)}, ...
                        o.subj_subfolder, o.filename.raw);
                    
                    if exist(testFile, 'file') == 2
                        file = dir(testFile);
                        dispIdx{end+1} = [stageName ': ' file.date ];
                        disp([testFile ' file exists']);
                    end
                    
                else
                    
                    
                    if exist(testFile, 'file') == 2
                        file = dir(testFile);
                        dispIdx{end+1} = [ stageName ': '  file.date  ];
                        disp([testFile ' file exists']);
                    else
                        dispIdx{end+1} = [ stageName ': Missing ' ];
                        disp([testFile ' does not exists']);
                    end
                    
                    
                    
                end
                
            end
            
            
            o.proc_fileStatus = dispIdx;
            
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = ica( o )
            
            o.EEG = pop_runica(o.EEG,'icatype','binica', 'extended',1,'interupt','on','pca', o.EEG.nbchan);
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = sigCreateUniqueChanPairs( o )
            
            pairArr1 = 1:o.EEG.nbchan;
            pairArr2 = pairArr1;
            
            nPairArr = length(pairArr1);
            
            [pairArr1, pairArr2] = meshgrid(pairArr1, pairArr2);
            
            mask   = triu(ones(nPairArr), 1) > 0.5; 
            
            tmpPairs  = [pairArr1(mask) pairArr2(mask)];
            
            for i = 1:length(tmpPairs)
                
                distArr(i) = getPairDist( num2str(tmpPairs(i,1)), num2str(tmpPairs(i,2)), o.EEG);
                
            end
            o.sigPairs = [tmpPairs distArr'];
        end
        
        %CURRENTLY UNUTILIZED
        function o = sigChirp( o )
            
            for i=1:400
                rcrits(i,1)=sqrt(-(1/i)*log(.5));
            end
            
            channel2plot = '23';
            
            sensoridx = find(strcmpi(channel2plot,{o.EEG.chanlocs.labels}));
            
            
            data            = o.EEG.data(sensoridx,:,:);
            %data = mean(EEG.data([28,24],:,:),1);
            %data = mean(EEG.data([120,3,117,118,4,111],:,:),1);
            
            frames          = o.EEG.pnts;
            epochlim        = [-500 2000];
            srate           =  o.EEG.srate;
            cycles          = [1 30];
            winsize         = 100;
            nfreqs          = 119;
            freqs           = [2 120];
            timesout        = 250;
            
            [ersp1,itc,n2,t_s,f_s]=newtimef( data, frames, epochlim, o.EEG.srate,[1 30],...
                'winsize',100,'nfreqs',119,'freqs',[2 120], ...
                'plotersp','on','plotitc','on','verbose','off',...
                'baseline',NaN,'timesout',250);
            
            %disp(n)
            
            ITC1=(abs(itc))-rcrits(length(o.EEG.data(1,1,:)));
            
            
            
            figure; imagesc(t_s,f_s,ersp1), axis xy;
            figure; imagesc(t_s,f_s,ITC1), axis xy;
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = plotBadChan( o )
            
            EEG = o.EEG;
            originalEEG = o.EEG_prechan;
            
            
            
            eegplot(EEG.data,'data2', originalEEG.data)
            
            
        end
        
        
        %Setup and performance of manual channel cleaning via eegplot of 
        %data in generated window for user to select channels to 
        %remove from dataset. Gui elements are utilized for
        %easy selection for removal, and if no channels are selected upon 
        %start an array of channels to remove is initiated for the channels 
        %chosen for removal to be added to upon selection.  
        %Dins are not obscured in the selection window.
        function o = manualChanClean( o )
            
            gui.position = [0.01 0.20 0.80 0.70];
            
            o.autobadchannel( 5 );
            
            cdef = {'g','b'};
            carr = repmat(cdef,1, size(o.EEG.data,1));
            carr = carr(1:size(o.EEG.data, 1));
            carr(o.proc_autobadchannel) = {'r'};
            
            
            eegplot(o.EEG.data,'srate',o.EEG.srate,'winlength',10, ...
                'plottitle', ['Mark and Interpolate Bad Channels ' o.str_plottitle], ...
                'events',o.EEG.event,'color',carr,'wincolor',[1 0.5 0.5], ...
                'eloc_file',o.EEG.chanlocs,  'butlabel', 'Close Window', 'submean', 'on', ...
                'command', 't = 1', 'position', [400 400 1024 768] ...
                );
            
            h = findobj('tag', 'eegplottitle');
            h.FontWeight = 'Bold'; h.FontSize = 16; h.Position = [0.5000 0.93 0];
            
            chanlist = {o.EEG.chanlocs.labels};
            
            
            o.proc_badchans = '';
            
            handle = gcf;
            handle.Units = 'normalized';
            handle.Position = gui.position;
            
            
            popup = uicontrol(handle,'Tag', 'chanselect', 'Style', 'listbox', ...
                'max',10,'min',1, ...
                'String', chanlist , 'Value', o.proc_autobadchannel,...
                'Units', 'normalized', ...
                'Position', [.05 0.15 0.035 .70], 'BackgroundColor', [0.94 0.94 0.94]);
            
            showBadDetail = uicontrol(handle,...
                'Tag', 'detailbutton', ...
                'Style', 'pushbutton', 'BackgroundColor', [0 1 1],...
                'Units', 'normalized', ...
                'Position', [0.7 0.08 0.10 0.05],...
                'String', 'Detail', 'Callback', @o.showChanDetail);
            
            toggleBadChannels = uicontrol(handle,...
                'Tag', 'savebutton', ...
                'Style', 'togglebutton', 'BackgroundColor', [0 1 0],...
                'Units', 'normalized', ...
                'Position', [0.8 0.08 0.14 0.05],...
                'String', 'Save', 'Callback', @o.selBadChan);
            
            textBadChannels = uicontrol(handle, 'Style', 'text', ...
                'String', 'Manual Bad Channel Rejection: no channels selected', 'Tag', 'badchantitle', ...
                'FontSize', 14,    'Units', 'normalized', 'Position', [0.1 0.89 0.3 0.03], 'HorizontalAlignment', 'left');
            
            waitfor(gcf);
            
            return;
            
        end
        
        %Callback function enacted upon selection of channel/channels and 
        %the detail button, and the user is then presented with the
        %details regarding that channel based upon the data.  The details
        %presented include electrode location, the activity power spectrum,
        %and a erp image for the data.
        function o = showChanDetail(o , src, event)
            
            EEG = o.EEG;
            
            
            ui_main = findobj(gcf,'Tag', 'EEGPLOT');
            h = findobj(gcf,'Style','togglebutton');
            hlist = findobj(gcf,'Style','listbox');
            htext = findobj(gcf,'Tag','badchantitle');
            
            ui_list = h.Value;
            ui_selection = hlist.Value;
            
            if ~isempty(ui_selection)
                
                pop_prop( EEG, 1, ui_selection, NaN, {'freqrange' [0.5 55] });
                
            end
            
        end
        
        %Callback function enacted when the user selects the
        %channel/channels they wish to remove and selects the save button.
        %The channels are added to the bad channels array and the user will
        %be shown the numbers of the channels that have been chosen to be
        %removed.  The user can continue to further remove channels as 
        %needed and they will be appended to the bad channels list.
        function o = selBadChan(o, src,event)
            
            o.EEG_prechan = o.EEG;
            
            ui_main = findobj(gcf,'Tag', 'EEGPLOT');
            h = findobj(gcf,'Style','togglebutton');
            hlist = findobj(gcf,'Style','listbox');
            htext = findobj(gcf,'Tag','badchantitle');
            
            ui_list = h.Value;
            ui_selection = hlist.Value;
            
            if ui_list == 1
                ui_main.UserData.delchans = ui_selection;
                htext.String = 'Manual Bad Channel Rejection: ';
                htext.String = [htext.String num2str(ui_selection)];
                %fprintf(htext.String);
                htext.BackgroundColor = [0 1 0];
                o.proc_badchans = ui_selection;
            else
                ui_main.UserData.delchans = '';
                htext.String = 'Manual Bad Channel Rejection: no channels selected';
                htext.BackgroundColor = [0.93 0.93 0.93];
                o.proc_badchans = '';
            end
            
            
            
            %display(boxBadChannels.String);
            
            %ui_obj = get(gcf, 'Children');
        end
        
        %Upon completion of channel cleaning, the bad channels, if any, are
        %interpolated via the EEGLAB pop_interp method and the data rank is 
        %adjusted to reflect this change and ensure that it is correct for 
        %future preprocessing steps.
        function o = removeInterpolateChans( o )
                      
            
            badchannels = o.proc_badchans;
            o.proc_tmprej_chans = badchannels;
            EEG = o.EEG;  
            EEG = eeg_checkset(EEG);
            
            EEGtemp = EEG;  
            
            if length(badchannels) >= 1
                
                
                %EEGtemp = pop_select( EEG, 'nochannel', badchannels);
                
                
                
                EEG = pop_interp(EEGtemp,badchannels,'spherical');
                EEG.etc.dataRank = size(double(EEG.data'),2) - length(badchannels);
                
                
                %EEG2 = pop_interp(EEGtemp,eeg_mergelocs(EEGtemp.chanlocs),'spherical');

                o.net_nbchan_post = EEG.etc.dataRank;
                o.proc_ipchans = badchannels;
            else
                
                EEG.etc.dataRank = EEG.nbchan;
                o.net_nbchan_post = EEG.etc.dataRank;
                
            end
            
            EEG = eeg_checkset(EEG);
            
            o.EEG = EEG;
            
        end
        
        %Removes boundary events and updates the proc_removed_regions
        %attribute of the subject's EEG dataset structure.
        function o = getBoundaryEvents( o, EEG )
           
            events = EEG.event;
            
            cutIndex = strcmp({events.type}, 'boundary');
            cutIndexNo = find(cutIndex);
            
            latencies = [events(cutIndexNo).latency];
            durations = [events(cutIndexNo).duration];
            
            tmpstr = '';
            finalstr = '';
            
            for i = 1 : length(cutIndexNo)
                
                tmpstr = sprintf('#%0d@%.0f(%.0f); ', cutIndexNo(i), latencies(i), durations(i));
                
                finalstr = [finalstr tmpstr];
            end
            
            o.proc_removed_regions = finalstr;
            
            
        end
        
        %CURRENTLY UNUTILIZED
        function autoprocAssign( o, autoproc )
            
            o.msgout('Subject found.');
            
            o.msgout('Subject missing');
            
            
        end
        
        %Automatic rejection of bad sample segments in continuous data 
        %and utilizes getBoundaryEvents class
        %method to update the EEG structure's removed regions related 
        %attributes
        function o = autoContClean( o )
            tmprej = o.htpcfg.autoproc.tmprej_cont;
            %gui.position = [0.01 0.20 0.95 0.70];
            srate_correction = o.htpcfg.autoproc.orig_srate / o.proc_sRate1;
            
            o.EEG = eeg_checkset(o.EEG);
            o.EEG_prechan = o.EEG;
            
            
            o.proc_removed_regions = [];
            
            %             eegplot(o.EEG.data,'srate',o.EEG.srate,'winlength',8, ...
            %                 'plottitle', ['Step 2/3: Continuous Artifact Rejection'  o.str_plottitle], ...
            %                 'events',o.EEG.event,'wincolor',[1 0.5 0.5], ...
            %                 'command','global rej,rej=TMPREJ',...
            %                 'eloc_file',o.EEG.chanlocs);
            
            
            %
            %             handle = gcf;
            %             handle.Units = 'normalized';
            %             handle.Position = gui.position;
            %
            %             % Formatting Main EEGPLOT
            %             h = findobj('tag', 'eegplottitle');
            %             h.FontWeight = 'Bold'; h.FontSize = 16; h.Position = [0.5000 0.93 0];
            %
            %
            %
            %             waitfor(gcf);
            
            try
                
                if ~isempty(tmprej)
                    
                    %tmprej = eegplot2event(rej, -1);
                    o.proc_tmprej_cont = tmprej;
                    [o.EEG,~] = eeg_eegrej( o.EEG,tmprej(:,[1 2]) ./ srate_correction );
                    
                    o.getBoundaryEvents(o.EEG); 
                    
                else
                    o.proc_removed_regions = '';
                end
                
            catch
                o.msgout('Error in Manual Cleaning.','proc_error');
                
            end
            
            
            
            o.proc_xmax_raw = o.EEG_prechan.trials * (o.EEG_prechan.xmax-o.EEG_prechan.xmin);
            o.proc_xmax_post = o.EEG.trials * (o.EEG.xmax-o.EEG.xmin);
            o.proc_xmax_percent =  (o.proc_xmax_post / o.proc_xmax_raw) * 100;
            %o.proc_xmax_epoch
            
            o.EEG = eeg_checkset(o.EEG);
            
            return;
            
        end
        
        %Manual rejection of bad sample segments in continuous data via
        %interactive eegplot window and utilizes getBoundaryEvents class
        %method to update the EEG structure's removed regions related 
        %attributes
        function o = manualContClean( o )
            
            gui.position = [0.01 0.20 0.95 0.70];
            
            o.EEG = eeg_checkset(o.EEG);
            o.EEG_prechan = o.EEG;
            
            
            
            global rej
            
            o.proc_removed_regions = [];
            try
            [OUTEEG, selectedregions, precompstruct, com] = pop_rejcont(o.EEG, 'elecrange',[1:o.EEG.nbchan] ,'freqlimit',[20 40] ...
                ,'threshold',10,'epochlength',0.5,'contiguous',4, ...
                'onlyreturnselection', 'on', 'addlength',0.25,'taper','hamming', 'verbose', 'on');
            OUTEEG = [];
            
            winrej = zeros(size(selectedregions,1), size(selectedregions,2) + 3 + size(o.EEG.data, 1));
            winrej(:, 1:2) = selectedregions(:,1:2);
            winrej(:, 3:5) = repmat([0 0.9 0],size(selectedregions,1),1);
            catch
               winrej = []; 
            end
            eegplot(o.EEG.data,'srate',o.EEG.srate,'winlength',8, ...
                'plottitle', ['Step 2/3: Continuous Artifact Rejection'  o.str_plottitle], ...
                'events',o.EEG.event,'wincolor',[1 0.5 0.5], 'winrej', winrej, ...
                'command','global rej,rej=TMPREJ',...
                'eloc_file',o.EEG.chanlocs);
            
            handle = gcf;
            handle.Units = 'normalized';
            handle.Position = gui.position;
            
            
            h = findobj('tag', 'eegplottitle');
            h.FontWeight = 'Bold'; h.FontSize = 16; h.Position = [0.5000 0.93 0];
            usrStr1 = 'GREEN REGIONS: Autorejected Regions based on on Spectrum Thresholding (pop_rejcont)';
            usrStr2 = 'RED REGIONS: User Selected Regions';
            h.String = sprintf('%s\n%s\n%s',  strjoin(h.String,'\n'), usrStr1, usrStr2);
            h.Position(2) = 0.93;
            
            
            waitfor(gcf);
            
            try
                
                if ~isempty(rej)
                    
                    tmprej = eegplot2event(rej, -1);
                    o.proc_tmprej_cont = tmprej;
                    [o.EEG,~] = eeg_eegrej(o.EEG,tmprej(:,[3 4]));
                    
                    o.getBoundaryEvents(o.EEG); 
                    
                else
                    o.proc_removed_regions = '';
                end
                
            catch
                
                o.msgout('\nError in Manual Cleaning\n', 'proc_warning');
                
            end
           
            
            o.proc_xmax_raw = o.EEG_prechan.trials * (o.EEG_prechan.xmax-o.EEG_prechan.xmin);
            o.proc_xmax_post = o.EEG.trials * (o.EEG.xmax-o.EEG.xmin);
            o.proc_xmax_percent =  (o.proc_xmax_post / o.proc_xmax_raw) * 100;
            %o.proc_xmax_epoch
            
            o.EEG = eeg_checkset(o.EEG);
            
            return;
            
        end
        
        %Perform cleaning of epochs for stage 2 of preprocessing to prepare
        %data for epoch rejection step of stage 2. The epochs are marked 
        %and appropriately labeled depending on the type of data whether 
        %the epoch is of a certain DIN or there are no DINs and need to be 
        %blinded for the dataset.  Different methods taken for 
        %event vs resting data.
        function o = cleanEpochs( o )
            global rej;
            
            EEG = o.EEG;
            
            EEG = eeg_checkset( EEG );
            
            
            if o.htpcfg.autoprocflag == 0
                
                
                gui.position = [0.07 0.35 0.4 0.55];
                
                
                if strcmp(o.htpcfg.optnow.Stage2_EpochType, 'Event')
                    
                    EEG.event
                    EEG.blinded = EEG.event;
                    noDINs = length({EEG.blinded.type});
                    
                    [type{1:noDINs}] = deal('DIN');
                    
                    for i = 1 : noDINs
                        EEG.blinded(i).type = type{i};
                    end
                    spevent = EEG.blinded;
                    try
                        spfilename = EEG.etc.din_code{1};
                        spfilename = o.subj_basename;
                        
                    catch
                        spfilename = o.subj_basename;
                    end
                    titlestr = sprintf('Epoch Rejection: %s (Subject %d of %d)', spfilename, o.subj_id(1), o.subj_id(2));
                    
                else
                    
                    spevent = EEG.event;
                    spfilename = EEG.filename;
                    titlestr = sprintf('Epoch Rejection: %s ', spfilename)
                end
                
                eegplot(EEG.data,'srate',EEG.srate,'winlength',8, ...
                    'events', spevent,'wincolor',[1 0.5 0.5], 'limits', [EEG.xmin EEG.xmax]*1000,...
                    'plottitle', titlestr, ...
                    'command','global rej,rej=TMPREJ',...
                    'eloc_file',EEG.chanlocs);
                
                
                h = findobj('tag', 'eegplottitle');
                h.FontWeight = 'Bold'; h.FontSize = 16; h.Position = [0.5000 0.93 0];
                
                
                handle = gcf;
                handle.Units = 'normalized';
                handle.Position = gui.position;
                
                
                waitfor(gcf);
            else
                
                tmprej = o.htpcfg.autoproc.tmprej_epochs;
                
            end
            
            
            if ~isempty(rej) && o.htpcfg.autoprocflag == 0
                
                tmprej = eegplot2trial(rej, EEG.pnts, EEG.trials);
                o.proc_tmprej_epochs = tmprej;
                EEG = eeg_checkset( EEG );
                
            else
                
                if o.htpcfg.autoprocflag == 1
                    tmprej = o.htpcfg.autoproc.tmprej_epochs;
                    o.proc_tmprej_epochs = tmprej;
                    tmprej = zeros(1, length(o.EEG.epoch));
                    tmprej(o.proc_tmprej_epochs) = 1;
                    
                    EEG = eeg_checkset( EEG );
                end
                
                o.epoch_badtrials = '';
                o.epoch_badid = '';
                o.epoch_percent = 100;
                
            end
            
            
            
            if o.is_event_EEG
                if ~strcmp( o.eventcfg.stage, 'C' )
                    if ~iscell(EEG.epoch(1).eventlatency(:))
                        correctIdx = 1;
                        correctEvent = EEG.epoch(1).eventtype;
                        
                    else
                        correctIdx = find(cell2mat(EEG.epoch(1).eventlatency(:)) == 0);
                        correctEvent = EEG.epoch(1).eventtype(correctIdx);
                        
                    end
                else
                    
                    correctEvent = EEG.etc.din_code;
                end
                
                
                fidx = @(x) find(strcmp(x,  o.eventcfg.details(1,:)));
                
                if ~exist('tmprej')
                    bad_notrials = 0;
                    bad_ids = 0;
                    tmprej = 0;
                else
                    bad_notrials    = length(find(tmprej));
                    bad_ids         = ['[' num2str(find(tmprej)) ']'];
                end
                
                idx = find(strcmp( o.eventcfg.details(:,1), correctEvent));  % EEG.event(1).type));
                
                idx_trials_final         = find(strcmp('trials_final',  o.eventcfg.details(1,:)));
                idx_trials_og   = find(strcmp('trials_og',  o.eventcfg.details(1,:)));
                idx_trials_remove = find(strcmp('trials_remove',  o.eventcfg.details(1,:)));
                idx_trials_per  = find(strcmp('trials_per',  o.eventcfg.details(1,:)));
                
                original_trials = cell2mat(o.eventcfg.details(idx,idx_trials_og));
                trials_to_remove = bad_notrials;
                final_trials = original_trials - trials_to_remove;
                
                bad_percent     = (final_trials / original_trials)*100;
                
                if ~isempty(idx)
                    
                    o.eventcfg.details{idx, idx_trials_final} = ['[' num2str( final_trials ) ']'];
                    o.eventcfg.details{idx, idx_trials_remove} = bad_ids;
                    o.eventcfg.details{idx, idx_trials_per} = bad_percent;
                    
                else
                    
                    o.eventcfg.details{idx, idx_trials_final} =  original_trials;
                    o.eventcfg.details{idx, idx_trials_remove} = 0;
                    o.eventcfg.details{idx, idx_trials_per} = 0;
                    
                end
                
                
            else
                if ~exist('tmprej')
                    
                    o.epoch_badtrials   = 0;
                    o.epoch_badid       = '[0]';
                    o.epoch_percent     = 100;
                    
                else
                    o.epoch_badtrials = length(find(tmprej));
                    o.epoch_badid = ['[' num2str(find(tmprej)) ']'];
                    o.epoch_percent = 100-(o.epoch_badtrials / o.epoch_trials)*100;
                    
                end
                
            end
            
            
            
            %EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);
            try
                EEG = pop_rejepoch( EEG, tmprej ,0);
                EEG = eeg_checkset(EEG);
                o.EEG = EEG;
                o.epoch_trials = o.EEG.trials;
            catch
                o.msgout('Reject trial Error','proc_warning');
            end
        end
        
        %Performs removal of components marked for removal and creating the
        %accurate EEG active array based on ICA weights for usage in later
        %preprocessing steps and alerting the user as to which components 
        %were removed to be checked for accuracy.
        function o = compRemove( o, varargin )
            
            % EEG.reject.gcompreject matrix
            
            try
                EEG = o.EEG;
                
                EEG = eeg_checkset( EEG );
                
                try
                    EEG.etc.clean_channel_mask = true(1,EEG.nbchan);
                    EEG.etc.clean_sample_mask = true(1,EEG.pnts * EEG.trials);
                catch
                    
                end
                
                if nargin > 1
                    
                    compIdx = varargin{1};
                else
                    compIdx = o.proc_removeComps;
                end
                
                try
                EEG.reject.gcompreject(1,compIdx) = 1;
                
                
                EEG = pop_subcomp( EEG, compIdx, 0);
                
                o.proc_compstatus = 0;
                
                catch
                    o.msg_out('Error during component removal and backprojection.','proc_err');
                end
                
                try
                    o.icview;
                catch
                    
                end
                
                
                EEG.icaact = eeg_getdatact(EEG, 'component', [1:size(EEG.icaweights,1)]);

                
                %o.msgout(sprintf('\nComponents Removed: %s\n', num2str(o.proc_removeComps)), 'proc_msg');
                
            catch
                
                %o.msgout(sprintf('\nError: Component Removal Incomplete.'), 'proc_msg');
                
            end
            
            EEG = eeg_checkset( EEG );
            
            o.EEG = EEG;
        end
        
        %CURRENTLY UNUTILIZED
        function o = generateIcaAct( o )
            
            if ~isempty(o.EEG)
                
                o.EEG.icaact = eeg_getdatact(o.EEG, 'component', [1:size(o.EEG.icaweights,1)]);
                
            else
                
                o.msgout('No EEG dataset loaded. No save performed.', 'proc_warning');
                
            end

        end
        
        %Compile list of components within range and if it belongs to 
        %artifact group dependent upon the confidence threshold value.
        function comps_artifact = get_icview_comps( o, var, threshold, range )
            
            % test = o.is_icview_valid();
            
            if isfield(o.EEG.etc, 'ic_classification')
            
            else
                o.icview;
            end
                
            getCompIdx = @(x) find(strcmpi( x, o.EEG.etc.ic_classification.ICLabel.classes));
            getComps = @(x, y) find(o.EEG.etc.ic_classification.ICLabel.classifications(range, getCompIdx(x)) > y)';
            
            %threshold = 0.75;
            comps_artifact = getComps(var, threshold);
            
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = sig_ispc( o )
            
            %o.loadDataset('import');
            
            o.sigCreateUniqueChanPairs;
            pairs = o.sigPairs;
            for iPair = 1:length(pairs)
                channel1 = num2str(pairs(iPair,1));
                channel2 = num2str(pairs(iPair,2));
                
                
                freqs2use  = logspace(log10(4),log10(30),15); % 4-30 Hz in 15 steps
                times2save = -400:10:1000;
                timewindow = linspace(1.5,3,length(freqs2use)); % number of cycles on either end of the center point (1.5 means a total of 3 cycles))
                baselinetm = [-400 -200];
                
                
                time          = -1:1/o.EEG.srate:1;
                half_wavelet  = (length(time)-1)/2;
                num_cycles    = logspace(log10(4),log10(8),length(freqs2use));
                n_wavelet     = length(time);
                n_data        = o.EEG.pnts*o.EEG.trials;
                n_convolution = n_wavelet+n_data-1;
                
               
                times2saveidx = dsearchn(o.EEG.times',times2save');
                baselineidxF  = dsearchn(o.EEG.times',baselinetm');  % for the full temporal resolution data (thanks to Daniel Roberts for finding/reporting this bug here!)
                baselineidx   = dsearchn(times2save',baselinetm'); % for the temporally downsampled data
                
                chanidx = zeros(1,2); % always initialize!
                chanidx(1) = find(strcmpi(channel1,{o.EEG.chanlocs.labels}));
                chanidx(2) = find(strcmpi(channel2,{o.EEG.chanlocs.labels}));
                
                
                data_fft1 = fft(reshape(o.EEG.data(chanidx(1),:,:),1,n_data),n_convolution);
                data_fft2 = fft(reshape(o.EEG.data(chanidx(2),:,:),1,n_data),n_convolution);
                
                
                ispc    = zeros(length(freqs2use),o.EEG.pnts);
                pli     = zeros(length(freqs2use),o.EEG.pnts);
                wpli    = zeros(length(freqs2use),o.EEG.pnts);
                dwpli   = zeros(length(freqs2use),o.EEG.pnts);
                dwpli_t = zeros(length(freqs2use),length(times2save));
                ispc_t  = zeros(length(freqs2use),length(times2save));
                
                for fi=1:length(freqs2use)
                    
                    
                    s = num_cycles(fi)/(2*pi*freqs2use(fi));
                    wavelet_fft = fft( exp(2*1i*pi*freqs2use(fi).*time) .* exp(-time.^2./(2*(s^2))) ,n_convolution);
                    
                    
                    convolution_result_fft = ifft(wavelet_fft.*data_fft1,n_convolution);
                    convolution_result_fft = convolution_result_fft(half_wavelet+1:end-half_wavelet);
                    sig1 = reshape(convolution_result_fft,o.EEG.pnts,o.EEG.trials);
                    
                    
                    convolution_result_fft = ifft(wavelet_fft.*data_fft2,n_convolution);
                    convolution_result_fft = convolution_result_fft(half_wavelet+1:end-half_wavelet);
                    sig2 = reshape(convolution_result_fft,o.EEG.pnts,o.EEG.trials);
                    
                    
                    cdd = sig1 .* conj(sig2);
                    
                    
                    ispc(fi,:) = abs(mean(exp(1i*angle(cdd)),2)); % note: equivalent to ispc(fi,:) = abs(mean(exp(1i*(angle(sig1)-angle(sig2))),2));
                    
                    
                    
                    cdi = imag(cdd);
                    
                    
                    pli(fi,:)  = abs(mean(sign(imag(cdd)),2));
                    
                    
                    wpli(fi,:) = abs( mean( abs(cdi).*sign(cdi) ,2) )./mean(abs(cdi),2);
                    
                    
                    imagsum      = sum(cdi,2);
                    imagsumW     = sum(abs(cdi),2);
                    debiasfactor = sum(cdi.^2,2);
                    dwpli(fi,:)  = (imagsum.^2 - debiasfactor)./(imagsumW.^2 - debiasfactor);
                    
                    
                    time_window_idx = round((1000/freqs2use(fi))*timewindow(fi)/(1000/o.EEG.srate));
                    
                    for ti=1:length(times2save)
                        imagsum        = sum(cdi(times2saveidx(ti)-time_window_idx:times2saveidx(ti)+time_window_idx,:),1);
                        imagsumW       = sum(abs(cdi(times2saveidx(ti)-time_window_idx:times2saveidx(ti)+time_window_idx,:)),1);
                        debiasfactor   = sum(cdi(times2saveidx(ti)-time_window_idx:times2saveidx(ti)+time_window_idx,:).^2,1);
                        dwpli_t(fi,ti) = mean((imagsum.^2 - debiasfactor)./(imagsumW.^2 - debiasfactor));
                        
                       
                        phasesynch     = abs(mean(exp(1i*angle(cdd(times2saveidx(ti)-time_window_idx:times2saveidx(ti)+time_window_idx,:))),1));
                        ispc_t(fi,ti)  = mean(phasesynch);
                    end
                end
                
               
                ispc    = bsxfun(@minus,ispc,mean(ispc(:,baselineidxF(1):baselineidxF(2)),2)); % not plotted in the book, but you can plot it for comparison with PLI
                ispc_t  = bsxfun(@minus,ispc_t,mean(ispc_t(:,baselineidx(1):baselineidx(2)),2));
                pli     = bsxfun(@minus,pli,mean(pli(:,baselineidxF(1):baselineidxF(2)),2));
                dwpli   = bsxfun(@minus,dwpli,mean(dwpli(:,baselineidxF(1):baselineidxF(2)),2));
                dwpli_t = bsxfun(@minus,dwpli_t,mean(dwpli_t(:,baselineidx(1):baselineidx(2)),2));
                
                tbl_dwpli_t = array2table(dwpli_t);
                
                frqpli(iPair,:) = mean(ispc_t,2);
                
                
                frqdwpli(iPair,:) = mean(dwpli_t,2);
            end
            figure
            subplot(221)
            contourf(times2save,freqs2use,pli(:,times2saveidx),40,'linecolor','none')
            set(gca,'clim',[-.3 .3],'yscale','log','ytick',round(logspace(log10(freqs2use(1)),log10(freqs2use(end)),8)))
            title('PLI over trials')
            
            subplot(222)
            contourf(times2save,freqs2use,dwpli(:,times2saveidx),40,'linecolor','none')
            set(gca,'clim',[-.2 .2],'yscale','log','ytick',round(logspace(log10(freqs2use(1)),log10(freqs2use(end)),8)))
            title('dWPLI over trials')
            
            subplot(223)
            contourf(times2save,freqs2use,ispc_t,40,'linecolor','none')
            set(gca,'clim',[-.1 .1],'yscale','log','ytick',round(logspace(log10(freqs2use(1)),log10(freqs2use(end)),8)))
            title('ICPS over time')
            
            subplot(224)
            contourf(times2save,freqs2use,dwpli_t,40,'linecolor','none')
            set(gca,'clim',[-.1 .1],'yscale','log','ytick',round(logspace(log10(freqs2use(1)),log10(freqs2use(end)),8)))
            title('dWPLI over time')
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = compsremove( o )
            
            s = o;
            
            h.tp = gcf;
            h.tp.Position = [100 50 700 460];
            
            p = uipanel(h.tp,'Title','Component Selection Tool',...
                'Position',[.40 .1 .55 .22]);
            
            %strStatus = sprintf('(%d of %d): %s', i, length(sub), s.subj_basename);
            
            title = uicontrol(p,'Style','text',...
                'String', strStatus,...
                'FontSize', 10,...
                'Units', 'normalized', ...
                'HorizontalAlignment', 'left', ...
                'BackgroundColor', [1 1 1], 'ForegroundColor', [0 0 0], ...
                'Position',[0.05 0.7 0.9 0.30]);
            
            b1 = uicontrol(p,'Style','pushbutton','String','Save Components',...
                'Units','normalized',...
                'UserData', s, ...
                'Callback',@o.b1_callback, ...
                'BackgroundColor', [0 1 0], ...
                'Position',[.6 0.05 .35 .25]);
            
            t1 = uicontrol(p,'Style','edit',...
                'tag', 'comp_entry', ...
                'String','',...
                'Max',1,'Min',0,...
                'Units', 'normalized', ...
                'Position',[0.6 0.34 0.35 0.30]);
            
            b2 = uicontrol(p,'Style','pushbutton','String','C. Detail',...
                'Units','normalized',...
                'UserData', s, ...
                'Callback', @o.b2_callback, ...
                'Position',[.05 0.05 .20 .25]);
            
            closebtn = findobj('tag', 'Set threhsolds', 'parent', h.tp);
            
            UIButtonArr = findobj(h.tp, 'Type', 'UIControl');
            OriginalButtons = findobj(UIButtonArr, 'BackgroundColor', '[0.6600 0.7600 1]');
            for button_i = 1 : length(OriginalButtons), OriginalButtons(button_i).Visible = 'off'; end
            % UI = findobj(UIButtonArr, 'String', 'OK');
            
            % okbutton.Visible = 'off';
            
            % loop with comp number
            
            for ri = 1 : maxcomps
                
                chbutton = findobj('tag', ['comp' num2str(ri)], 'Parent', h.tp);
                %disp(chbutton);
                chbutton.Callback = ['pop_prop_extended( s.EEG, 0,' num2str(ri) ')']';
                
            end
            
            %  delete(t2)
            t2 = uicontrol(p,'Style','edit',...
                'tag', 'comp_entry2', ...
                'String','',...
                'Max',1,'Min',0,...
                'Units', 'normalized', ...
                'Position',[0.05 0.34 0.20 0.30]);
            
            b3 = uicontrol(p,'Style','pushbutton','String','ICLABEL',...
                'Units','normalized',...
                'UserData', s, ...
                'Callback', @o.b3_callback, ...
                'Position',[.35 0.05 .20 .25]);
            
            
            % Open component time series
            pop_eegplot( s.EEG, 0, 1, 1);
            h.ep = gcf;
            h.ep.Units = 'pixels';
            h.ep.Position = [100 550 700 450];
            
            g = h.ep.UserData;
            
            % adjust default spacing/zoom
            ESpacing = findobj('tag','ESpacing','parent', h.ep);   % ui handle
            ESpacing.String = 50;
            eegplot('draws',0);
            
            % adjust default number of epochs & components shown
            g.winlength = 10;
            g.dispchans = 10;
            
            if g.dispchans < 0 || g.dispchans > g.chans
                g.dispchans = g.chans;
            end
            
            set(h.ep, 'UserData', g);
            eegplot('updateslider', h.ep);
            eegplot('drawp',0);
            eegplot('scaleeye', [], h.ep);
            
            uiwait(h.ep);
            
            s.proc_state = 'postcomps';
            
            % save cleaned dataset into the preica directory
            s.storeDataset( s.EEG, pathdb.postcomps, s.subj_subfolder, s.filename.postcomps);
            
            
            % unload data & decrease memory footprint
            s.unloadDataset;
            
            
        end
        
        %CURRENTLY UNUTILIZED
        function b2_callback(o, src, event)
            
            comps = findobj('tag', 'comp_entry2');
            
            EEG = src.UserData.EEG;
            
            % pop_prop( EEG , 0, str2num(comps.String), NaN, {'freqrange' [2 50] });
            
            pop_prop_extended( EEG, 0, str2num(comps.String));
            
            %pop_selectcomps(src.UserData.EEG);
            
        end
        
        %CURRENTLY UNUTILIZED
        function b3_callback(o, src, event)
            
            comps = findobj('tag', 'comp_entry2');
            
            EEG = src.UserData.EEG;
            
            EEG = pop_iclabel(EEG);
            
            pop_viewprops( EEG, 0);
            
            src.UserData.EEG = EEG;
            
            %pop_selectcomps(src.UserData.EEG);
            
        end
        
        %CURRENTLY UNUTILIZED
        function b1_callback(o, src, event)
            
            comps = findobj('tag', 'comp_entry');
            
            src.UserData.proc_removeComps = str2num(comps.String);
            
            close all;
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = quickplot( o, stage, type )
            
            
            
            o.loadDataset(stage);
            
            EEG = o.EEG;
            
            pop_eegplot(EEG, type, 1, 0);
            
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = quickplot_compRemove( o )
            
            
            
            % o.loadDataset('postcomps');
            
            o.compRemove;
            
            EEG = eeg_checkset(  o.EEG );
            
            
            
            pop_eegplot(EEG, 1, 1, 0);
            
            o.unloadDataset;
            
        end
        
        %Utilize the ICLABEL plugin of EEGLAB to perform automatic
        %independent component classification and the output label is 
        %stored to the EEG structure for future reference or usage along 
        %with a plugin like Viewprops to obtain visualization of 
        %classification.
        function o = icview( o )
            
            EEG = o.EEG;
            
            EEG = iclabel(EEG);
            
            o.EEG = EEG;
            
        end
        
        %Perform dipole fitting on the post component selection dataset
        %(Stage 4 completed) to localize neuronal activity.
        %Dipole fitting settings initialized via
        %EEGLAB function utilizing the specified coordinate, hdm, mri, and
        %chanfile as well as the specified channel selection from the
        %provided data to ensure appropriate dipole fitting is performed.
        %Independent components representing bilateral 
        %source activity are identified to alert the user as to significant
        %components.
        function o = generic_dipfit( o )
            
            if isempty(o.EEG.data)
                
                o.loadDataset('postcomps')
                
            end
            
            EEG = o.EEG;
            
            o.dipfit.chansel = 1 : size(EEG.data,1);
            
            dipfit = o.dipfit;
            
            
            [EEG, com] = pop_dipfit_settings( EEG, ...
                'hdmfile',     dipfit.hdmfile, ...
                'coordformat', dipfit.coordformat, ...
                'mrifile',     dipfit.mrifile, ...
                'chanfile',    dipfit.elcfile, ...
                'coord_transform',dipfit.transform, ...
                'chansel', dipfit.chansel);
            
          %  EEG = pop_dipfit_settings( EEG, 'hdmfile','G:\\Dropbox\\bitbucket\\htp_dev\\source\\standard_vol.mat','coordformat','MNI','mrifile','G:\\Dropbox\\bitbucket\\htp_dev\\source\\standard_mri.mat','chanfile','G:\\Dropbox\\bitbucket\\htp_dev\\source\\std_129.elc','coord_transform',
          %   ,'chansel',[1:128] );

          %  EEG = pop_multifit(EEG, [1:108] ,'threshold',100,'rmout','on','dipoles',2,'dipplot','on','plotopt',{'normlen' 'on'});

            EEG = pop_multifit(EEG, dipfit.chansel ,'threshold',100,'plotopt',{'normlen' 'on'});
            EEG = eeg_checkset( EEG );
            
            % Piazza C. et al. (2016) An Automated Function for Identifying EEG 
            % Independent Components Representing Bilateral Source Activity. 
            % In: Kyriacou E., Christofides S., Pattichis C. (eds) XIV Mediterranean 
            % Conference on Medical and Biological Engineering and Computing 2016. 
            % IFMBE Proceedings, vol 57. Springer, Cham
            
            EEG = fitTwoDipoles(EEG, 'LRR', 35);
            
            
            
            o.EEG = EEG;
            
        end
        
        %Set dipole fitting flag to appropriate status (0 or 1) if being 
        %calculated or not.
        function o = set_dipfitcalc( o, status )
            
            o.dipfit.calc = status;
            
        end
        
        %CURRENTLY UNUTILIZED
        function o = plot_dipole( o )
            
            EEG = o.EEG;
            
            dipfit = o.dipfit;
            
            pop_dipplot( EEG, dipfit.compsel ,'mri', dipfit.mrifile,'normlen','on');
            
            o.EEG = EEG;
            
        end
        
        %Set the dipole fitting settings such as coordinate files, 
        %electrode configuration files, MRI files, and channels 
        %to select to ensure that accurate dipole fitting is performed
        %later on, if necessary.
        function o = set_dipfitsettings( o )
            
            o.dipfit.hdmfile = o.htpcfg.chanNow.net_hdmfile; %fullfile(o.htpcfg.pathdb.source, o.htpcfg.chanNow.net_hdmfile);
            o.dipfit.mrifile = o.htpcfg.chanNow.net_mrifile; %fullfile(o.htpcfg.pathdb.source, o.htpcfg.chanNow.net_mrifile);
            o.dipfit.elcfile = o.htpcfg.chanNow.net_elcfile; fullfile(o.htpcfg.pathdb.source,  o.htpcfg.chanNow.net_elcfile);
            o.dipfit.coordformat = 'MNI';
            o.dipfit.chanfile = o.net_file;
            o.dipfit.chansel = 1: o.net_nbchan_post;
            o.dipfit.compsel = 1 : o.net_nbchan_post;
            o.dipfit.transform = str2num(o.htpcfg.chanNow.net_coord_transform);

            
        end
        
        %Create a structured results table to display to the user every
        %available dataset in each stage for the current subject object
        %to give potential indication of preprocessing progress.
        function o = checkAvailableDatasets( o )
            
            fns = o.filename;
            pathdb = o.pathdb;
            subf = o.subj_subfolder;
            
            resultTbl(1).stage = 'import';
            resultTbl(1).available = isfile(fullfile(pathdb.import, subf, fns.import));
            
            resultTbl(2).stage = 'preica';
            resultTbl(2).available = isfile(fullfile(pathdb.preica, subf, fns.preica));
            
            resultTbl(3).stage = 'postica';
            resultTbl(3).available = isfile(fullfile(pathdb.postica, subf, fns.postica));
            
            resultTbl(4).stage = 'postcomps';
            resultTbl(4).available = isfile(fullfile(pathdb.postcomps, subf, fns.postcomps));
            
            resultTbl(5).stage = 'level1';
            resultTbl(5).available = isfile(fullfile(pathdb.level1, subf, fns.level1));
            
            o.resultTbl = resultTbl;
            
            struct2table(resultTbl);
            
        end
        
        %Check if the input epoch is of event type and return boolean for
        %further action to take place, if necessary.
        function result = is_event_EEG( obj )
            try
            result = strcmp('Event', obj.htpcfg.optnow.Stage2_EpochType{1});
            catch
                result = 0;
            end
        end
        
        %Correctly match channel configuration with channel number of 
        %EEG file.  Can be used as a final check 
        %following pre-processing to ensure accurate configuration for 
        %further analysis steps.
        function nbchan = autoAssignChannel( o )
                        
            o.checkAvailableDatasets;
            
            postcompIdx = find(strcmp('postcomps', {o.resultTbl(:).stage}));
            if o.resultTbl(postcompIdx).available == 1
                
                fprintf('%s: Post Comp Dataset is Available.', o.subj_basename);
                
            else
                
                disp('Post Comp Dataset NOT available, check data directory.');
                return
            end
            o.loadDataset('postcomps');
            nbchan = o.EEG.nbchan;
            o.unloadDataset;
            
            load('chanfiles/elec_obj.mat');
            
            objIndex = find([chanObjects.net_nochans] == nbchan);
            
            o.setElectrodeSystem( chanObjects( objIndex ) );
            
            o.unloadDataset;
        end
        
        %Notify the base pipeline object as to the event that just occurred
        %based upon the message type.  The message is displayed via GUI 
        %output console and is logged for the user to inspect whenever 
        %they may need to during, or after, preprocessing.
        function obj = msgout( obj, str, msgtype )
            
            obj.msg = str;
            
            switch msgtype
                
                case 'proc_error'
                    notify( obj, 'proc_error' );
                    obj.msgtype = 'Error';
                    obj.htpcfg.logger.error('s.msgout',obj.msg);
                case 'proc_warning'
                    notify( obj, 'proc_warning' )
                    obj.msgtype = 'Warning';
                    obj.htpcfg.logger.warn('s.msgout',obj.msg);
                case 'proc_msg'
                    notify(obj, 'proc_msg');
                    obj.msgtype = '';
                    obj.htpcfg.logger.info('s.msgout',obj.msg);
                case 'proc_complete'
                    notify(obj, 'proc_complete');
                    obj.msgtype = 'Complete';
                    obj.htpcfg.logger.info('s.msgout',obj.msg);
                otherwise
                    notify(obj, 'proc_complete');
                    obj.msgtype = 'Complete';
                    obj.htpcfg.logger.info('s.msgout',obj.msg);
            end
            
            %obj.lm(obj.msg);
            
        end
        
        %Log the input string with a timsetamp included and written to the
        %local log file.  The logged message is then displayed to the 
        %GUI output console for the user.
        function lm( obj, inputStr )
            
            %obj.htpUF.turnOffWarnings;
            
            datetime.setDefaultFormats('default','MMddyy hh:mm');
            
            obj.outStr = inputStr;
           
            %outStr = sprintf('%s\n%s (%s)\t%s' , obj.outStr, datetime, obj.msgtype, inputStr);
            obj.outStr = sprintf('\n%s (%s)\t%s' ,  datetime, obj.msgtype, inputStr);
            
            %obj.outStr = outStr;
            
            obj.htpcfg.logfile_id = fopen(fullfile(obj.htpcfg.scriptPath, 'local/logfiles/', obj.htpcfg.logfile),'a');
            fprintf(obj.htpcfg.logfile_id, regexprep(obj.outStr,'\','\\\\'));
            %fprintf('%s',obj.outStr);
            disp(obj.outStr)
            fclose(obj.htpcfg.logfile_id);
            
        end
        
        %Sets the appropriate data rank, based upon specific type needed, 
        %for Principle Component Analysis to be accurately performed for 
        %proceeding ICA computation in stage 3 of preprocessing. 
        function rank_value = setPCARank( obj, option )
            
            user_selected_option = option;
            
            switch user_selected_option
                
                case 'Data Rank'
                    
                    %rank_value = obj.proc_dataRank;
                    
                    if ~isempty(obj.proc_badchans)
                            rank_value = obj.net_nbchan_post;
                    else
                        rank_value = length(obj.EEG.chanlocs);
                    end
                    
                case 'K-Number'
                    
                    rank_value = 24;
                    
                case '24'
                    
                    rank_value = 24;
                    
            end
            
            
            
        end
        
        %Calculate the dipoles and perform dipole fitting for possible
        %source modeling and investigation into bilateral activity.
        function o = calc_dipoles( o )
            
            if isempty(o.EEG)
                o.loadDataset('postcomps');
                EEG = o.EEG;
            else
                EEG = o.EEG;
            end
            adddir = @(x) fullfile(o.htpcfg.scriptPath, 'chanfiles', x);
            hdm = adddir(o.htpcfg.chanNow.net_hdmfile);
            mri = adddir(o.htpcfg.chanNow.net_mrifile);
            elc = adddir(o.htpcfg.chanNow.net_elcfile);
            coord = str2num(o.htpcfg.chanNow.net_coord_transform);
            
            % check if dipfit is to be recalculated
            %             if o.dipfit.calc == 1
            %                 flag = 1;
            %                 o.msgout('DIPFIT already calculated.','step_warning');
            %             else
            %                 flag = 0;
            %             end
            % calculations
            %[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
            %EEG = pop_loadset('filename','D3295_rest_postcomp.set','filepath','D:\\D128_good\\S04_POSTCOMP\\Group1\\');
            %[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
            
            EEG = pop_dipfit_settings( EEG, 'hdmfile', hdm, 'coordformat','MNI', 'mrifile', mri, 'chanfile', elc, 'chansel',[1:length(o.EEG.chanlocs)]);
            EEG = pop_multifit(EEG, [1:length(o.EEG.chanlocs)] ,'threshold',100,'plotopt',{'normlen' 'on'});
            
            EEG = fitTwoDipoles(EEG, 'LRR', 35);
            
            o.EEG = EEG;
            
            %'C:\\Users\\ernie\\Dropbox\\bitbucket\\htp_dev\\source\\standard_vol.mat','coordformat','MNI','mrifile','C:\\Users\\ernie\\Dropbox\\bitbucket\\htp_dev\\source\\standard_mri.mat','chanfile','C:\\Users\\ernie\\Dropbox\\bitbucket\\htp_dev\\source\\std_129.elc','chansel',[1:128] );
            
            % [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
            %EEG = pop_multifit(EEG, [1:128] ,'threshold',100,'plotopt',{'normlen' 'on'});
            %[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
            %pop_dipplot( EEG,[1:128] ,'mri','C:\\code\\eeglab\\plugins\\dipfit2.3\\standard_BEM\\standard_mri.mat','normlen','on');
            %EEG = pop_dipfit_settings( EEG, 'hdmfile','C:\\Users\\ernie\\Dropbox\\bitbucket\\htp_dev\\source\\standard_vol.mat','coordformat','MNI','mrifile','C:\\Users\\ernie\\Dropbox\\bitbucket\\htp_dev\\source\\standard_mri.mat','chanfile','C:\\Users\\ernie\\Dropbox\\bitbucket\\htp_dev\\source\\std_129.elc','coord_transform',[2 -15 -4.8248 0.029714 -0.004076 -1.6124 11.5 12 11.9985] ,'chansel',[1:128] );
            %[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
            %EEG = pop_multifit(EEG, [1:128] ,'threshold',100,'plotopt',{'normlen' 'on'});
            %[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
            
        end
        
        %Automatic cleaning performed during stage 2 to remove bad channels
        %and segments of data and then performing average reference
        %calculations to ensure cleaned, corrected data.  Afterwards any
        %ASR burst segments are removed as well with average reference
        %calculation once again to finalize the cleaning.
        function o = autoclean( o )
            
            threshold = str2num(o.htpcfg.optnow.Stage2_ChanCleanThreshold{1});            
            o.autobadchannel( threshold );
            o.removeInterpolateChans
            
            o.autobadsegments;
            
            o.averageRefData;
            
            % stage 1 channel only
            % o.htpcfg.asr_param = CleanRawDataClass.CleanRawDataInit;
            % o.htpcfg.asr_param.arg_burst = -1;
            % o.htpcfg.asr_param.arg_window = -1;
            
            % o.asrData( o.htpcfg.asr_param );
            % o.averageRefData;
            
            o.htpcfg.asr_param = CleanRawDataClass.CleanRawDataInit;
            o.htpcfg.asr_param.arg_channel = -1;
            o.htpcfg.asr_param.arg_flatline = -1;
            o.htpcfg.asr_param.arg_highpass = -1;
            o.htpcfg.asr_param.arg_noisy = -1;
            
            o.asrData( o.htpcfg.asr_param );
            
            o.averageRefData;
            
        end
        
        %Perform automatic channel rejection based upon the specified 
        %threshold and populate related bad channel fields in the EEG
        %dataset structure to guide further preprocessing steps.
        function o = autobadchannel( o, threshold )
            
            if isempty(o.EEG)
                o.msgout('No dataset loaded. Method requires loaded dataset.', 'step_warning');
            else
                EEG = o.EEG;
                
                maxchannels = floor(size(EEG.data, 1) * 0.15);
                
                measure = {'prob','kurt','spec'}; % 'spec'
                indelec = cell(1,length(measure));
                com = cell(1,length(measure));
                
                %indelec{end+1} = o.find_zeroed_chans( EEG.data );
                
                for i = 1 : length(measure)
                    try
                        [OUTEEG, indelec{i}, measure_name{i}, com{i}] = pop_rejchan(EEG, 'elec',[1:EEG.nbchan]...
                            ,'threshold',threshold,'norm','on','measure',measure{i} );
                    catch ME
                        o.msgout(sprintf('%s: Channel Routine failed (%s)', o.subj_basename, ME.message), 'step_warning');
                    end
                end
                zerochan = o.find_zeroed_chans( EEG.data ); if ~isempty( zerochan ), indelec{end+1} = zerochan'; end
                badchans = cell2mat(indelec(1:length(indelec)));
                o.proc_autobadchannel = unique( badchans, 'stable' );
                o.proc_badchans = unique( badchans, 'stable' );
                
                
                if length(o.proc_autobadchannel) > maxchannels
                    o.msgout(sprintf('%s: %d bad channels, 15% threshold exceeded.', o.subj_basename, length(o.proc_autobadchannel)),'step_warning');
                    o.proc_state = 'CHANNEL';
                end
                
                %o.EEG = EEG;
            end
            
        end
        
        %Perform automatic rejection of continuous segments and remove the
        %rejected regions for correct preprocessing in later stages, if no 
        %rejected regions exist the appropriate EEG dataset structure 
        %are updated to reflect this for later stages as well.
        function o = autobadsegments( o )
            if isempty(o.EEG)
                o.msgout('No dataset loaded. Method requires loaded dataset.', 'step_warning');
            else
                [OUTEEG, selectedregions, precompstruct, com] = pop_rejcont(o.EEG, 'elecrange',[1:o.EEG.nbchan] ,'freqlimit',[20 40] ...
                    ,'threshold',10,'epochlength',0.5,'contiguous',4, ...
                    'onlyreturnselection', 'on', 'addlength',0.25,'taper','hamming', 'verbose', 'on');
                %OUTEEG = [];
                
                winrej = selectedregions;
                
                if ~isempty(winrej)
                    winrej = zeros(size(selectedregions,1), size(selectedregions,2) + 3 + size(o.EEG.data, 1));
                    winrej(:, 1:2) = selectedregions(:,1:2);
                    winrej(:, 3:5) = repmat([0 0.9 0],size(selectedregions,1),1);
                    
                    o.proc_autobadsegment = winrej;
                    
                    tmprej = eegplot2event(winrej, -1);
                    o.proc_tmprej_cont = tmprej;
                    [o.EEG,~] = eeg_eegrej(o.EEG,tmprej(:,[3 4]));
                    o.EEG = eeg_checkset( o.EEG );
                    o.getBoundaryEvents(o.EEG);
                else
                    o.proc_removed_regions = '';
                    o.proc_autobadsegment = '';
                end
            end
            
            
        end
        
        %CURRENTLY UNUTILIZED
        function latency = getFirstEventLatency( o )
            
            o.loadDataset('import');
            
            try
                latency = o.EEG.event(1).latency;
            catch
                o.msgout(sprintf('%s: No events found.', o.subj_basename),'step_warning');
                latency = 0;
            end
        end
        
        %Perform data trimming for stage 2 based upon the input time to 
        %trim and if the data is long enough to trim based upon said time.  
        %Usually utilized for trimming beginning and ending of EEG data 
        %to remove edge artifacts, but can be used due to specific
        %preprocessing needs.
        function o = trim_edges( o, time )
            if isempty(o.EEG)
                o.msgout('No dataset loaded. Method requires loaded dataset.', 'step_warning');
            else
                EEGTMP = o.EEG;
                if time * 6 > o.EEG.xmax
                    validtime = 0;
                    o.msgout('Data too short to trim. Marking as excluded.', 'step_warning');
                    o.proc_state = 'SHORT';
                else
                    cut1 = [0 time];
                    EEGTMP = eeg_checkset(pop_select(EEGTMP, 'notime', cut1));
                    cut2 = [(EEGTMP.xmax - time) EEGTMP.xmax];
                    EEGTMP = eeg_checkset(pop_select(EEGTMP, 'notime', cut2));
                end
                
                o.EEG = EEGTMP;
            end
            
        end
        
        %Obtain duration of EEG data, or if the EEG attribute is empty the
        %raw data, to be used in various scenarions such as ensuring the
        %data is longer than the minimum duration for stage 2 preprocessing
        function xmax = getDuration( o )
            if isempty(o.EEG.data)
                xmax = o.proc_xmax_raw;
                o.msgout('No dataset loaded. Method using proc_xmax_raw.', 'step_warning');
            else
                xmax = o.EEG.xmax;
            end
        end
        
    end
    
    methods % Brainstorm Functions
       
        %CURRENTLY UNUTILIZED
        function o = test(o )
        end
        
    end
    
end