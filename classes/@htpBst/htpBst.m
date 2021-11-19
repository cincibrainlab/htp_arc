classdef htpBst < handle
    % htp interface to brainstorm
    % unusual script in that it uses a running instance of brainstorm to function

    % start new study
    % bst_prepareContinousData  - custom function to convert htp/EEGLAB set to continuous format
    % bst_createNewProtocol;
    % bst_loadDatasets - load htp object into bst
    % bst_updateProtocolInfo; - get general protocol info
    % bst_getData;
    % bst_getSources;
    % bst_getTfreq;
    % bst_getMatrix;
    % bst_setChan - set channel file across all bst subjects
    % bst_estimateSrc_mne - headmodel and minimum norm estimate src model (default)
    % bst_noisecov_identity - identitiy covariance matrix
    % bst_noisecov_none - no covariance matrix
    % bst_pow_src;
    % bst_pow_elec;
    % bst_pac
    % bst_scoutTimeSeries

    % bst_getAtlas - retreive list of atlas and scouts

    properties

        atlasList;
        ProtocolInfo;
        isGUI;
        sFiles;
        groupidx;
        taghx;

    end

    methods

        function obj = htpBst()

            %             % initiate object with htpBaseMasterObject
            %             try
            %                 o.am = htpBaseMasterObject;
            %             catch
            %                 fprintf('No htpBaseMaster object found (am).')
            %             end
            obj.taghx{1} = 'Start Tag history';
        end

        % create new Protocol
        % option: "Yes, use protocols default anatomy."
        % option: "Yes, use only one global channel file."
        % validate function input
        function o = bst_createNewProtocol(o, ProtocolName)

            validateattributes(ProtocolName, {'char'}, {'nonempty'});

            gui_brainstorm('CreateProtocol', ProtocolName, 1, 2);
            o.bst_updateProtocolInfo;
            o.msgout('Active Protocol: %s Created.', o.ProtocolInfo.Comment)

        end

        function o = bst_deleteActiveProtocol(o, varargin)

            if nargin > 1 && nargin < 3
                % validate function input
                validateattributes(varargin{1}, {'char'}, {'nonempty'});
                ProtocolName = varargin{1};
            else
                o.bst_updateProtocolInfo;
                ProtocolName = o.ProtocolInfo.Comment;
            end

            gui_brainstorm('DeleteProtocol', ProtocolName);
            o.msgout('Active Protocol: %s Deleted.', ProtocolName)

        end

        function o = bst_prepareContinuousData(o)

            % shortcut function
            exportsub = @(x, y) o.tool_exportSubject(x, y);

            % prepare eegDataClass array for parallel computing
            % assign to temporary variable
            tmpsub = o.sub;
            % parallel computing switch
            try
                runInSerial = o.htpcfg.grp.bstoptions.parforArg;
            catch
                o.msgout('Default: Run in Serial.');
                runInSerial = true;
            end

            if ~runInSerial, parforArg = Inf; else, parforArg = 0; end

            % label dataset
            save_desc = 'htp2bst';

            % output folder from object (and define type)
            o.htpcfg.optnow.Stage2_EpochType = 'Rest';
            outputfolder = o.htpcfg.pathdb.source;

            % create output folder (clear directory if it exists)
            [status, message, messageid] = rmdir(outputfolder, 's');
            mkdir(outputfolder);

            % conditional parfor
            parfor (i = 1:length(tmpsub), parforArg)

                s = tmpsub(i);
                s.loadDataset('postcomps');
                s.epoch2cont;
                s = exportsub(s, outputfolder);
                s.unloadDataset;
                s.outputRow('postcomps');
                tmpsub(i) = s;

            end

            % restore eegDataClassArray to htpBaseMaster
            o.sub = tmpsub;
            o.clearRestAnalysisVariables;
            % create CSV and MAT file
            o.createResultsCsv(o.sub, 'postcomps', save_desc);

        end

        function o = bst_updateProtocolInfo(o)

            try
                o.isGUI = bst_get('isGUI');
                o.ProtocolInfo = bst_get('ProtocolInfo');
            catch
                fprintf('No active protocol. Start Brainstorm.')
            end

        end

        function o = bst_loadProtocol(o, ProtocolName)
            % Get the protocol index
            iProtocol = bst_get('Protocol', ProtocolName);

            if isempty(iProtocol)
                error(['Unknown protocol: ' ProtocolName]);
            end

            % Select the current procotol
            gui_brainstorm('SetCurrentProtocol', iProtocol);
        end

        function o = bst_startBstNoGui(o)

            if ~brainstorm('status')
                evalin('base', 'brainstorm nogui');
            end

        end

        function o = bst_startBstServer(o)

            if ~brainstorm('status')
                evalin('base', 'brainstorm server');
            end

        end

        function o = bst_quitBstServer(o)
            brainstorm stop; % Quit Brainstorm
        end

        function o = bst_controller_htp(o, cmd)
            % loop for operating on htp eegDataClass to BST

            [mc, mm, mw] = o.tools_log; % output log

            % temporary assign eegDataClass object
            sub = o.sub;
            N = length(o.sub);

            for i = 1:N

                s = sub(i);
                mm(sprintf('Loading (%d/%d): %s', i, N, s.subj_basename));

                switch cmd

                    case 'addSubjectToProtocol_rest'
                        sFile = o.bst_addSubjectToProtocol_rest(s);

                    otherwise
                        mw('No command, no operations performed.');
                end

                if i == 1, sFiles = sFile; else, sFiles(i) = sFile; end

                sub(i) = s;

                o.sFiles = sFiles;

            end

            o.sub = sub;

        end

        function sFiles = bst_controller_recordings(o, cmd, sFiles)

            if nargin < 3
                %idx = o.bst_searchSubjectString( sFiles, 'FileName', 'Group2');
                sFiles = o.bst_getAllRecordings();
            end

            for i = 1:length(sFiles)
                sFile = sFiles(i);

                switch cmd
                    case 'fixChannels'
                        sFile = o.bst_fixChannels(sFile);
                    case 'computeHeadModel'
                        if i == 1, sFile = o.bst_computeHeadModel(sFile); end
                    case 'computeIdentityNoisecov'
                        if i == 1, sFile = o.bst_computeIdentityNoisecov(sFile); end
                    otherwise
                end

                sFiles(i) = sFile;
            end

            o.sFiles = sFiles;

        end

        function sFiles = bst_controller_sources(o, cmd, sFiles, cfg)
            [mc, mm, mw] = o.tools_log; % output log
            calcpow = @o.bst_calcSpectralPower;

            r = o.bst_generateRandomTag;

            %  o.bst_quitBstServer;
            %   o.bst_startBstServerProtocol('P1htpBstTest');
            if nargin < 3
                %idx = o.bst_searchSubjectString( sFiles, 'FileName', 'Group2');
                sFiles = o.bst_getAllSources();
            end

            N = length(sFiles);

            try
                runInSerial = o.htpcfg.grp.bstoptions.parforArg;
            catch
                o.msgout('Default: Run in Serial.');
                runInSerial = true;
            end

            if ~runInSerial, parforArg = Inf; else, parforArg = 0; end

            for i = 1:N
                sFile = sFiles(i);

                mm(sprintf('Loading (%d/%d): %s', i, N, sFile.SubjectName));

                switch cmd
                    case 'calcPower_default'

                        sFile = calcpow(cfg, sFile);
                        tag = o.bst_generateTag(r, 'abspow');
                    case 'relativePower_default'
                        o.bst_relativePower(sFile);
                        tag = o.bst_generateTag(r, 'relpow');
                    case 'scoutTimeSeries'

                        sFile = o.bst_markScoutSeries(cfg, sFile);
                        tag = o.bst_generateTag(r, sprintf('scoutseries_%s', cfg.atlasname));

                    case 'withinChanDirectPac'

                        %res(:,i) = o.bst_withinChanDirectPac( cfg, sFile );

                        ipac{i} = o.bst_withinChanDirectPac(cfg, sFile);

                        tag = o.bst_generateTag(r, 'withinChanPac');

                    otherwise
                end

                sFile = o.bst_addTag(sFile, r, tag);

                sFiles(i) = sFile;
            end

            o.sFiles = sFiles;

        end

        function sFiles = bst_controller_timefrequency(o, cmd, sFiles)
            [mc, mm, mw] = o.tools_log; % output log
            % calcpow = @o.bst_calcSpectralPower;

            r = o.bst_generateRandomTag;

            %  o.bst_quitBstServer;
            %   o.bst_startBstServerProtocol('P1htpBstTest');
            if nargin < 3
                %idx = o.bst_searchSubjectString( sFiles, 'FileName', 'Group2');
                sFiles = o.bst_getAllTimeFrequency();
            end

            N = length(sFiles);

            try
                runInSerial = o.htpcfg.grp.bstoptions.parforArg;
            catch
                o.msgout('Default: Run in Serial.');
                runInSerial = true;
            end

            if ~runInSerial, parforArg = Inf; else, parforArg = 0; end

            for i = 1:N
                sFile = sFiles(i);

                mm(sprintf('Loading (%d/%d): %s', i, N, sFile.SubjectName));

                switch cmd

                    case 'relativePower_default'
                        sFile = o.bst_relativePower(sFile);
                        tag = o.bst_generateTag(r, 'relpow');
                    case 'spatialSmoothing'
                        cfg = [];
                        cfg.fwhm = 3;
                        cfg.overwrite = 0;
                        sFile = o.bst_spatialSmoothing(cfg, sFile);
                        tag = o.bst_generateTag(r, sprintf('ssmooth_%s', num2str(cfg.fwhm)));

                    otherwise
                end

                sFile = o.bst_addTag(sFile, r, tag);

                sFiles(i) = sFile;
            end

            o.sFiles = sFiles;

        end

        function [sFiles cfg] = bst_controller_matrix(o, cmd, sFiles, cfg)

            [mc, mm, mw] = o.tools_log; % output log

            r = o.bst_generateRandomTag;

            N = length(sFiles);

            try
                runInSerial = o.htpcfg.grp.bstoptions.parforArg;
            catch
                o.msgout('Default: Run in Serial.');
                runInSerial = true;
            end

            if ~runInSerial, parforArg = Inf; else, parforArg = 0; end

            for i = 1:N
                sFile = sFiles(i);

                mm(sprintf('Loading (%d/%d): %s', i, N, sFile.SubjectName));

                switch cmd
                    case 'withinChanDirectPac'

                        %res(:,i) = o.bst_withinChanDirectPac( cfg, sFile );

                        ipac{i} = o.bst_withinChanDirectPac(cfg, sFile);

                        tag = o.bst_generateTag(r, 'withinChanPac');
                        
                    case 'getFblock'
                        cfg.Fblock{i} = o.bst_getFblock(cfg, sFile);
                        tag = o.bst_generateTag(r, 'getFblock');
                        
                    otherwise
                end

               % sFile = o.bst_addTag(sFile, r, tag);
                
                sFiles(i) = sFile;
            end

            cfg.sFiles = sFiles;
            try
            ipac_save_file = fullfile(o.htpcfg.pathdb.analysis, [cfg.desc '_' r '_.mat']);
            %ipac_save_file = fullfile(o.htpcfg.pathdb.analysis, [cfg.desc '.mat']);
            save(ipac_save_file, 'ipac');
            cfg.filename = ipac_save_file;
            catch
               o.msgout('Warning: No Ipac Available'); 
               o.htpcfg.pacInfo = 'NA';
            end
            try o.htpcfg.pacInfo{end + 1} = cfg;
                catch, o.htpcfg.pacInfo = cell(1); o.htpcfg.pacInfo{end + 1} = cfg; end

                pacinfo_save_file = fullfile(o.htpcfg.pathdb.analysis, ['pacinfo''_' r '_.mat']);
                pacInfo = o.htpcfg.pacInfo;
                save(pacinfo_save_file, 'pacInfo');

            end

            function sFile = bst_fixChannels(o, sFile)
                sFile = bst_process('CallProcess', 'process_import_channel', sFile, [], ...
                    'usedefault', 71, ...% ICBM152: GSN HydroCel 128 E1
                'channelalign', 1, ...
                    'fixunits', 1, ...
                    'vox2ras', 1);
            end

            function sFile = bst_addSubjectToProtocol_rest(o, s)

                try filetype = o.htpcfg.chanNow.net_bst_filetype;
                    catch, filetype = 'EEG-EEGLAB'; mw('Using default EGI128');
                end

                try channelreplace = o.htpcfg.chanNow.net_bst_channelreplace;
                    catch, channelreplace = 71; mw('Using default EGI128');
                end

                % create filename and subject name
                rawFile = fullfile(s.pathdb.source, s.subj_subfolder, s.filename.source);
                [~, subjectName, ~] = fileparts(s.filename.source);

                sFile = bst_process('CallProcess', 'process_import_data_raw', [], [], ...
                    'subjectname', subjectName, ...
                    'datafile', {rawFile, filetype}, ...
                    'channelreplace', channelreplace, ...
                    'channelalign', 1, ...
                    'evtmode', 'value');

            end

            function sFile = bst_computeHeadModel(o, sFile)

                % ProtocolInfo = bst_get('ProtocolInfo');

                % Process: Compute head model
                sFile = bst_process('CallProcess', 'process_headmodel', sFile, [], ...
                    'Comment', '', ...
                    'sourcespace', 1, ...% Cortex surface
                'volumegrid', struct(...
                    'Method', 'isotropic', ...
                    'nLayers', 17, ...
                    'Reduction', 3, ...
                    'nVerticesInit', 4000, ...
                    'Resolution', 0.005, ...
                    'FileName', ''), ...
                    'meg', 3, ...% Overlapping spheres
                'eeg', 3, ...% OpenMEEG BEM
                'ecog', 2, ...% OpenMEEG BEM
                'seeg', 2, ...% OpenMEEG BEM
                'openmeeg', struct(...
                    'BemSelect', [1, 1, 1], ...
                    'BemCond', [1, 0.0125, 1], ...
                    'BemNames', {{'Scalp', 'Skull', 'Brain'}}, ...
                    'BemFiles', {{}}, ...
                    'isAdjoint', 0, ...
                    'isAdaptative', 1, ...
                    'isSplit', 0, ...
                    'SplitLength', 4000));

            end

            function sFile = bst_computeIdentityNoisecov(o, sFile)

                % Process: Compute covariance (noise or data)
                sFile = bst_process('CallProcess', 'process_noisecov', sFile, [], ...
                    'baseline', [-500, -0.001], ...
                    'datatimewindow', [0, 500], ...
                    'sensortypes', 'MEG, EEG, SEEG, ECOG', ...
                    'target', 1, ...% Noise covariance     (covariance over baseline time window)
                'dcoffset', 1, ...% Block by block, to avoid effects of slow shifts in data
                'identity', 1, ...
                    'copycond', 0, ...
                    'copysubj', 0, ...
                    'copymatch', 0, ...
                    'replacefile', 1); % Replace

            end

            function sFile = bst_computeSources(o, cmd, sFile)

                sFile = o.bst_getAllRecordings;

                switch cmd
                    case 'mne_default'
                        sFile = bst_process('CallProcess', 'process_inverse_2018', sFile, [], ...
                            'output', 1, ...% Kernel only: shared
                        'inverse', struct(...
                            'Comment', 'MN: EEG', ...
                            'InverseMethod', 'minnorm', ...
                            'InverseMeasure', 'amplitude', ...
                            'SourceOrient', {{'fixed'}}, ...
                            'Loose', 0.2, ...
                            'UseDepth', 1, ...
                            'WeightExp', 0.5, ...
                            'WeightLimit', 10, ...
                            'NoiseMethod', 'none', ...
                            'NoiseReg', 0.1, ...
                            'SnrMethod', 'fixed', ...
                            'SnrRms', 1e-06, ...
                            'SnrFixed', 3, ...
                            'ComputeKernel', 1, ...
                            'DataTypes', {{'EEG'}}));
                    otherwise
                end

            end

            function sFile = bst_calcSpectralPower(o, cfg, sFile)

                sFile = bst_process('CallProcess', 'process_psd', sFile, [], ...
                    'timewindow', cfg.timewindow, ...
                    'win_length', cfg.win_length, ...
                    'win_overlap', cfg.win_overlap, ...
                    'clusters', {}, ...
                    'scoutfunc', cfg.scoutfunc, ...% Mean
                'win_std', 0, ...
                    'edit', struct(...
                    'Comment', 'Power,FreqBands', ...
                    'TimeBands', [], ...
                    'Freqs', {cfg.freqs}, ...
                    'ClusterFuncTime', 'none', ...
                    'Measure', 'power', ...
                    'Output', 'all', ...
                    'SaveKernel', 0));
            end

            function ipac = bst_withinSourceDirectPac(o, cfg, sFiles)
                % mark scout time series
                sFiles = o.bst_controller_sources('scoutTimeSeries', sFiles, cfg);
                sMat = in_bst(sFiles.FileName); % contains raw values

            end
            
             function [Fblock] = bst_getFblock(o, cfg, sFile)
                % get time series of each channel
                sMat = in_bst(sFile.FileName); % contains raw values
                sProps = in_bst_data(sFile.FileName); % contains properies, srate etc.
                cfg.nesting = round(cfg.nesting);
                cfg.nested = round(cfg.nested);
                cfg.duration = 60;

                if cfg.sourceson == true
                    ipac.chanlocs = sMat.Atlas.Scouts;
                    sMat.F = sMat.Value;
                else
                    ipac.chanlocs = sProps.F.header.EEG.chanlocs;
                end

                %cfg.srate = round(sProps.F.prop.sfreq);

                cfg.isParallel = 0;
                cfg.isMex = 1;
                cfg.NumFreqs = 0;
                cfg.no_plot_columns = 5;
                gpuOn = cfg.gpuOn;
                % intraelectrode pac structure
                ipac.srate = cfg.srate;
                ipac.leadintime = 10; % time in seconds
                ipac.time = cfg.duration; % time in seconds
                ipac.targetsamples = round(ipac.time * ipac.srate);

                ipac.totalsamples = zeros(1, length(sMat.F));

                leadin_index = round(ipac.leadintime * ipac.srate);

                ipac.target_idx = logical(ipac.totalsamples);
                ipac.target_idx(leadin_index:leadin_index + ipac.targetsamples) = true;

                N = length(ipac.chanlocs);
                
                Fblock = sMat.F(:, ipac.target_idx); % active time series
             end

            function ipac = bst_withinChanDirectPac(o, cfg, sFile)
                % get time series of each channel
                sMat = in_bst(sFile.FileName); % contains raw values
                sProps = in_bst_data(sFile.FileName); % contains properies, srate etc.
                cfg.nesting = round(cfg.nesting);
                cfg.nested = round(cfg.nested);
                cfg.duration = 60;

                if cfg.sourceson == true
                    ipac.chanlocs = sMat.Atlas.Scouts;
                    sMat.F = sMat.Value;
                else
                    ipac.chanlocs = sProps.F.header.EEG.chanlocs;
                end

                %cfg.srate = round(sProps.F.prop.sfreq);

                cfg.isParallel = 0;
                cfg.isMex = 1;
                cfg.NumFreqs = 0;
                cfg.no_plot_columns = 5;
                gpuOn = cfg.gpuOn;
                % intraelectrode pac structure
                ipac.srate = cfg.srate;
                ipac.leadintime = 10; % time in seconds
                ipac.time = cfg.duration; % time in seconds
                ipac.targetsamples = round(ipac.time * ipac.srate);

                ipac.totalsamples = zeros(1, length(sMat.F));

                leadin_index = round(ipac.leadintime * ipac.srate);

                ipac.target_idx = logical(ipac.totalsamples);
                ipac.target_idx(leadin_index:leadin_index + ipac.targetsamples) = true;

                N = length(ipac.chanlocs);
                tic;

                if gpuOn

                    Fblock = sMat.F(:, ipac.target_idx); % active time series
     
                    switch cfg.pacmethod

                        case 'MI'

                            [DirectPAC_block, LowFreqs, HighFreqs] = ...
                                Kyle_pac_bst_continuous(Fblock, cfg.srate, cfg.nesting, cfg.nested);

                        case 'htp_directpac_chirplet'
                            [DirectPAC_block, LowFreqs, HighFreqs] = Kyle_directPAC_chirplet(Fblock, cfg.srate, cfg.nesting, cfg.nested);

                        case 'htp_directpac_wavelet'
                            [DirectPAC_block, LowFreqs, HighFreqs] = Rui_wavelet_directPAC_speed(Fblock, cfg.srate, cfg.nesting, ...
                                cfg.nested); % not exactly the same narrow-band filtering

                        case 'CanoltyMap'
                            
                            
                        otherwise
                            disp('Invalid method name.');
                    end

                    % [TF, ERP, TimeOut, chirp_center_high, errMsg] = o.bst_ComputeCanoltyMap(Fblock(1,:), cfg.srate, cfg.nesting, [-.500 .500])
                    % gpuversion output DirectPAC_block nbchan 1 3 9
                    gpu_tmppac = squeeze(DirectPAC_block);

                    for i = 1:length(DirectPAC_block)
                        tmppac = squeeze(gpu_tmppac(i, :, :));
                        %tmppac = squeeze(DirectPAC_block);
                        %tmppac = squeeze(tmppac(1, :, :));

                        tmppac_meanphase = mean(tmppac, 1);

                        ipac.maxpac(i) = max(tmppac_meanphase);
                        ipac.meanpac(i) = mean(tmppac_meanphase);
                        ipac.minpac(i) = min(tmppac_meanphase);
                        ipac.sdpac(i) = std(tmppac_meanphase);
                        ipac.medianpac(i) = median(tmppac_meanphase);

                    end

                    ipac = o.bst_appendStructure(ipac, sFile);
                    ipac.totalsamples = [];

                else

                    if ~gpuOn

                        for i = 1:N
                            dat = sMat.F(i, ipac.target_idx); % active time series
                            Fblock = [dat; dat]; % double array

                            switch cfg.pacmethod

                                case 'bst_directpac'
                                    [DirectPAC_block, LowFreqs, HighFreqs] = bst_pac(Fblock, cfg.srate, cfg.nesting, ...
                                        cfg.nested, cfg.isParallel, cfg.isMex, cfg.NumFreqs);

                                case 'htp_directpac'
                                    [DirectPAC_block, LowFreqs, HighFreqs] = Rui_wavelet_directPAC(Fblock, cfg.srate, cfg.nesting, ...
                                        cfg.nested); % not exactly the same narrow-band filtering

                                case 'htp_directpac_chirplet'
                                    [DirectPAC_block, LowFreqs, HighFreqs] = Rui_directPAC_chirplet(Fblock, cfg.srate, cfg.nesting, ...
                                        cfg.nested);

                                case 'htp_ruidirectpac'
                                    [~, DirectPAC_block, LowFreqs, HighFreqs] = Rui_directPAC_v2(Fblock, cfg.srate, cfg.nesting, ...
                                        cfg.nested);
                                    % DirectPAC_block is RuiPAC_block (First
                                    % output is void)

                                otherwise

                            end

                            tmppac = squeeze(DirectPAC_block);
                            tmppac = squeeze(tmppac(1, :, :));

                            tmppac_meanphase = mean(tmppac, 1);

                            ipac.maxpac(i) = max(tmppac_meanphase);
                            ipac.meanpac(i) = mean(tmppac_meanphase);
                            ipac.minpac(i) = min(tmppac_meanphase);
                            ipac.sdpac(i) = std(tmppac_meanphase);
                            ipac.medianpac(i) = median(tmppac_meanphase);

                            ipac = o.bst_appendStructure(ipac, sFile);

                            ipac.totalsamples = [];

                        end

                    end

                end

                res = ipac;
                toc;

                %  [MI, distKL] = pk_modulationIndex(Fblock(1,:),
                % %  Fblock(1,:),18); % Rui curious
                %DirectPAC_block = [];
                %DirectPAC_block = PAC_block;

                % get single channel
                %size(DirectPAC_block)

                % gpuVersion 128/3/9
                % gpu_tmppac = squeeze(DirectPAC_block);

                figureson = false;
                tableon = false;

                if tableon
                    pactbl = array2table(tmppac);
                    labelarr2cell = @(x) split(cellstr(num2str(round(x, 0))));
                    pactbl.Properties.VariableNames = cellfun(@(x) sprintf('F%s', x), labelarr2cell(HighFreqs), 'uni', 0);
                    pactbl.Properties.RowNames = cellfun(@(x) sprintf('F%s', x), labelarr2cell(LowFreqs), 'uni', 0);
                end

                if figureson% get index of subplot
                    % graphics
                    clear g;
                    grid = o.createSubplotGrid(N, cfg.no_plot_columns);

                    [row, col] = o.getIndicesSubplotGrid(grid, i);

                    X = HighFreqs;
                    Y = [tmppac; mean(tmppac, 1)]; %_meanphase;

                    %mean(tmppac,2)

                    figure;
                    g(row, col) = gramm('X', X, 'Y', Y, 'Color', [LowFreqs; 'Test'])% 1:size(Y, 1));

                    g(row, col).geom_line;
                    g(row, col).set_names('x', 'Amplitude Frequency', ...
                        'y', 'PAC (higher: greater coupling)', 'color', 'Phase Freq.');

                    g.draw;

                    figure;
                    g(1) = gramm('X', X, 'Y', Y, 'Color', [arrayfun(@(X) num2str(X), LowFreqs, 'uni', 0) 'Mean']);

                    g(1).geom_line;
                    g(1).set_names('x', 'Amplitude Frequency', ...
                        'y', 'PAC (higher: greater coupling)', 'color', 'Phase Freq.');

                    g(1).draw;

                    figure; [M, c] = contourf(HighFreqs, LowFreqs, tmppac)

                end

                %   end
                %res = squeeze(DirectPAC_block);
                %res_mean = mean(mean(res,3),2);

                %  res2 = in_bst_data(sFile.FileName)

                %  chanlocs = res2.F.header.EEG.chanlocs;

                %  topoplot(res_mean, chanlocs)
                %bst_pac(Fblock, sRate,
                % OPTIONS.BandNesting, OPTIONS.BandNested, OPTIONS.isParallel,
                % OPTIONS.isMex, OPTIONS.NumFreqs);

            end

            function sFile = bst_relativePower(o, sFile)

                sFile = bst_process('CallProcess', 'process_tf_norm', sFile, [], ...
                    'normalize', 'relative', ...% Relative power (divide by total power)
                'overwrite', 0);

            end

            function sFile = bst_spatialSmoothing(o, cfg, sFile)
                sFile = bst_process('CallProcess', 'process_ssmooth_surfstat', sFile, [], ...
                    'fwhm', cfg.fwhm, ...
                    'overwrite', cfg.overwrite);

            end

            function sFile = bst_addTag(o, sFile, r, tag)

                % Process: Add tag: test
                sFile = bst_process('CallProcess', 'process_add_tag', sFile, [], ...
                    'tag', tag, ...
                    'output', 1); % Add to comment
                o.taghx{end + 1} = tag;
            end

            function bst_averageEverythingByGroup(o, sFiles, GroupIdx)

                cfg.r = o.bst_generateRandomTag;

                for i = 1:size(GroupIdx, 1)
                    cfg.tag = o.bst_generateTag(cfg.r, sprintf('avg_grp_%s', num2str(i)));

                    idx = GroupIdx(i, :);
                    sFiles_subset = o.bst_selectSfilesSubset(sFiles, idx);

                    o.bst_averageEverything(cfg, sFiles_subset);

                end

            end

            function sFiles = bst_averageEverything(o, cfg, sFiles)
                % Process: Average: Everything
                sFiles = bst_process('CallProcess', 'process_average', sFiles, [], ...
                    'avgtype', 1, ...% Everything
                'avg_func', 1, ...% Arithmetic average:  mean(x)
                'weighted', 0, ...
                    'matchrows', 1, ...
                    'iszerobad', 1);
                sFiles = o.bst_addTag(sFiles, cfg.r, cfg.tag);

            end

            function sFiles = bst_ft_sourcestatistics(o, cfg, sFiles, sFiles2)

                sFiles = bst_process('CallProcess', 'process_ft_sourcestatistics', sFiles, sFiles2, ...
                    'timewindow', cfg.timewindow, ...
                    'isabs', cfg.isabs, ...
                    'avgtime', cfg.avgtime, ...
                    'avgfreq', cfg.avgfreq, ...
                    'randomizations', cfg.randomizations, ...
                    'statistictype', cfg.statisticstype, ...% Independent t-test
                'tail', cfg.tail, ...% Two-tailed
                'correctiontype', cfg.correctiontype, ...% no
                'minnbchan', cfg.minnbchan, ...
                    'clusteralpha', cfg.clusteralpha);

                sFiles = o.bst_addTag(sFiles, cfg.r, cfg.tag);

            end

            function o = bst_reloadCurrentProtocol(o)

                db_reload_database('current');

            end

            function sFile = bst_markScoutSeries(o, cfg, sFile)

                sFile = bst_process('CallProcess', 'process_extract_scout', sFile, [], ...
                    'timewindow', cfg.timew, ...
                    'scouts', {cfg.atlasname, cfg.scouts}, ...
                    'scoutfunc', 1, ...% Mean
                'isflip', 1, ...
                    'isnorm', 0, ...
                    'concatenate', 1, ...
                    'save', 1, ...
                    'addrowcomment', 1, ...
                    'addfilecomment', 1);

            end

            function res = bst_getScoutSeries(o, cfg, sFile)

                res = bst_process('in_bst_matrix', sFile.FileName);

            end

            function result_table = generate_PowTable(o, cfg, sFiles, grpInfo)
                % cfg = [];

                % mark scout time series
                 sFiles = o.bst_controller_sources('scoutTimeSeries', sFiles, cfg);

                % retreive values
                g = 1; % global count
                t = {};
                v = [];
                N = length(sFiles);

                for i = 1:N
                   
                    fullResults{i} = o.bst_getScoutSeries(cfg, sFiles(i));
                    f = fullResults{i};
                    s = o.sub(i);
   
                    tmp = split(f.Description, ' ');
                    
                    if i == 1
                        for tmp_i = 1 : length(tmp)
                            header_value{tmp_i} = strcat(tmp{tmp_i, 1}, '_', tmp{tmp_i, 2}, '_', tmp{tmp_i, end});
                        end
                    end
                                                                               
                    t{i,1} = cfg.atlasname;
                    t{i,2} = s.subj_subfolder;
                    t{i,3} = s.subj_basename;
                    t{i,4} = s.subj_gender;
                    t{i,5} = s.subj_age;
                    t{i,6} = s.meas.iq_dev{1};
                    v(i,:) = f.Value(:,1)';

                end

                resRowHeader = [{'Atlas', 'Group', 'subid', 'sex', 'age', 'iq_dev'} header_value];

                result_table = [cell2table(t) array2table(v)];
                result_table.Properties.VariableNames = resRowHeader;

                fn = fullfile(o.htpcfg.pathdb.analysis, ...
                    sprintf('B%d_powcsv_%s_N%d.csv', str2num(o.bst_generateRandomTag), cfg.atlasname, N));
                writetable(result_table, fn)

                % generate rows

                % collate into tables

                % get headings

            end

            function o = bst_topoplot_pac_single(o, cfg, ipac)

                cfg.pactype = 'TGC';
                cfg.pacmethod = 'bst_directpac';
                cfg.features = {'maxpac', 'meanpac', 'minpac', 'sdpac', 'medianpac'};
                cfg.select_chans = [1:16, 18:37, 39:42, 45:47, 50:55, 57:72, 74:80, 82:87, 89:106, 108:112, 115:118, 122:124];
                cfg.chanhood = load('128-chan_hood.mat');
                chanlocs = ipac{1}.chanlocs;
                selchans = chanlocs(cfg.select_chans);

                N_features = length(cfg.features);
                N_subjects = length(ipac);

                subplot_rows = N_subjects;
                subplot_cols = N_features;

                counter = 1;

                for ipac_i = 1:N_subjects% outloop: subjects

                    ik = ipac{ipac_i};

                    for feature_i = 1:N_features% features
                        feature_now = cfg.features{feature_i};

                        tmppac(:, :) = ik.(feature_now);

                        pacmean = (mean(tmppac(:, :), 1));

                        pacscale = [min(pacmean) max(pacmean)];

                        subplot(subplot_rows, subplot_cols, feature_i);
                        hold on;
                        str = sprintf('%d: %s', feature_i, feature_now);
                        title(str);
                        topoplot(pacmean(cfg.select_chans), selchans, 'maplimits', pacscale, 'conv', 'on')
                        counter = counter + 1;
                        %cbar('horiz',0,[-1 1].*max(abs(grp1mean(select_chan))));

                    end

                    g = gcf;
                    g.Position(1) = 50;
                    g.Position(2) = 50;
                    g.Position(3) = 1000;
                    g.Position(4) = 240;

                    dim = [0 .15 1 .05];
                    str = sprintf('%s %s %s: (%s)', cfg.id, cfg.group, cfg.pactype, cfg.pacmethod);
                    annotation('textbox', dim, 'HorizontalAlignment', 'center', ...
                        'String', str, 'LineStyle', 'none', 'interpreter', 'none');
                end

            end

            function o = bst_table_pac_group(o, cfg, pacInfo)
                % pacInfo is a htpBaseMaster variable created by
                % PAC run that describes each ipac set.

                % anonymous functions
                num2str_clean = @(x) regexprep(num2str(x), ' +', ' ');
                label_split = @(x) split(x, ' ');
                r = o.bst_generateRandomTag;

                % required inputs

                try
                    analysis_mode = cfg.mode; % source or channel
                catch
                    o.msgout('No analysis mode set', 'step_error');
                end

                groupInfo = o.getGroupInfo;
                pacInfo_N = numel(pacInfo);

                global_n = 1;
                pacrow = {};

                for pacInfo_i = 1:pacInfo_N% outerloop: 33 PAC combinations

                    pi = pacInfo{pacInfo_i};

                    pacmethod = pi.pacmethod;
                    desc = pi.desc;
                    nesting = pi.nesting;
                    nested = pi.nested;

                    fn = pi.filename;

                    tmpdata = load(fn);
                    ipac = tmpdata.ipac; clear tmpdata;

                    for sub_i = 1:numel(ipac)
                        groupid = groupInfo.idx(1, sub_i);
                        tmppac = ipac{sub_i};
                        s = o.sub(sub_i);
                        chanlocs_N = numel(tmppac.chanlocs);
                        chanlocs = tmppac.chanlocs;

                        switch analysis_mode% atlas or channel

                            case 'source'
                                % specific for bst Source Atlas
                                for chan_i = 1:chanlocs_N
                                    % disp(chan_i);
                                    tmpchan = chanlocs(chan_i);
                                    atlas = tmpchan.Label;
                                    seed = tmpchan.Seed;
                                    tmpsplit = label_split(atlas);
                                    atlas_label = tmpsplit{1};
                                    side = tmpsplit{2};
                                    vertices = numel(tmpchan.Vertices);
                                    color = tmpchan.Color;
                                    region = tmpchan.Region;
                                    maxpac = tmppac.maxpac(1, chan_i);
                                    minpac = tmppac.minpac(1, chan_i);
                                    meanpac = tmppac.meanpac(1, chan_i);
                                    sdpac = tmppac.sdpac(1, chan_i);
                                    medianpac = tmppac.medianpac(1, chan_i);
                                    subjectname = tmppac.SubjectName;

                                    subid = s.meas.subid;
                                    iq_dev = s.meas.iq_dev;
                                    alert_mean = s.meas.alert_mean;
                                    visitage = s.subj_age;
                                    sex = s.subj_gender;
                                    subfolder = s.subj_subfolder;

                                    pacrow{global_n, 1} = global_n;
                                    pacrow{global_n, 2} = pacmethod;
                                    pacrow{global_n, 3} = desc;
                                    pacrow{global_n, 4} = num2str_clean(nesting);
                                    pacrow{global_n, 5} = num2str_clean(nested);
                                    pacrow{global_n, 6} = fn;
                                    pacrow{global_n, 7} = subjectname;
                                    pacrow{global_n, 8} = groupid;
                                    pacrow{global_n, 9} = atlas;
                                    pacrow{global_n, 10} = seed;
                                    pacrow{global_n, 11} = atlas_label;
                                    pacrow{global_n, 12} = side;
                                    pacrow{global_n, 13} = vertices;
                                    pacrow{global_n, 14} = num2str(color);
                                    pacrow{global_n, 15} = region;
                                    pacrow{global_n, 16} = maxpac;
                                    pacrow{global_n, 17} = minpac;
                                    pacrow{global_n, 18} = meanpac;
                                    pacrow{global_n, 19} = medianpac;
                                    pacrow{global_n, 20} = sdpac;
                                    pacrow{global_n, 21} = subid{1};
                                    pacrow{global_n, 22} = iq_dev{1};
                                    pacrow{global_n, 23} = alert_mean{1};
                                    pacrow{global_n, 24} = visitage;
                                    pacrow{global_n, 25} = sex;
                                    pacrow{global_n, 26} = subfolder;

                                    global_n = global_n + 1;

                                end

                                % header and save file

                            case 'channel'
                                % specific for bst Electrode Data
                                for chan_i = 1:chanlocs_N

                                    tmpchan = chanlocs(chan_i);
                                    channel = tmpchan.labels;
                                    maxpac = tmppac.maxpac(1, chan_i);
                                    minpac = tmppac.minpac(1, chan_i);
                                    meanpac = tmppac.meanpac(1, chan_i);
                                    sdpac = tmppac.sdpac(1, chan_i);
                                    medianpac = tmppac.medianpac(1, chan_i);
                                    subjectname = tmppac.SubjectName;
                                    eegid = s.subj_basename;
                                    subid = s.meas.subid;
                                    iq_dev = s.meas.iq_dev;
                                    alert_mean = s.meas.alert_mean;
                                    visitage = s.subj_age;
                                    sex = s.subj_gender;
                                    subfolder = s.subj_subfolder;

                                    pacrow{global_n, 1} = global_n;
                                    pacrow{global_n, 2} = pacmethod;
                                    pacrow{global_n, 3} = desc;
                                    pacrow{global_n, 4} = num2str_clean(nesting);
                                    pacrow{global_n, 5} = num2str_clean(nested);
                                    pacrow{global_n, 6} = fn;
                                    pacrow{global_n, 7} = subjectname;
                                    pacrow{global_n, 8} = groupid;
                                    pacrow{global_n, 9} = channel;
                                    pacrow{global_n, 10} = maxpac;
                                    pacrow{global_n, 11} = minpac;
                                    pacrow{global_n, 12} = meanpac;
                                    pacrow{global_n, 13} = medianpac;
                                    pacrow{global_n, 14} = sdpac;
                                    pacrow{global_n, 15} = subid;
                                    pacrow{global_n, 16} = iq_dev;
                                    pacrow{global_n, 17} = alert_mean;
                                    pacrow{global_n, 18} = visitage;
                                    pacrow{global_n, 19} = sex;
                                    pacrow{global_n, 20} = subfolder;

                                    global_n = global_n + 1;

                                end

                                %pactbl ='[pacheader; pacrow];
                                %      pactbl = cell2table(pacrow,'VariableNames', pacheader);
                                % %       pactbl_fn = fullfile(o.htpcfg.pathdb.analysis, ['pacChanTbl_' r '_.csv']);
                                %        writetable(pactbl, pactbl_fn);
                            otherwise

                        end

                    end

                end

                switch analysis_mode% atlas or channel
                        % add header and save file
                    case 'source'

                        for i = 1:1
                            pacheader{1, 1} = 'global_n';
                            pacheader{1, 2} = 'pacmethod';
                            pacheader{1, 3} = 'desc';
                            pacheader{1, 4} = 'phase';
                            pacheader{1, 5} = 'amplitude';
                            pacheader{1, 6} = 'fn';
                            pacheader{1, 7} = 'subjectname';
                            pacheader{1, 8} = 'groupid';
                            pacheader{1, 9} = 'atlas';
                            pacheader{1, 10} = 'seed';
                            pacheader{1, 11} = 'atlas_label';
                            pacheader{1, 12} = 'side';
                            pacheader{1, 13} = 'vertices';
                            pacheader{1, 14} = 'color';
                            pacheader{1, 15} = 'region';
                            pacheader{1, 16} = 'maxpac';
                            pacheader{1, 17} = 'minpac';
                            pacheader{1, 18} = 'meanpac';
                            pacheader{1, 19} = 'medianpac';
                            pacheader{1, 20} = 'sdpac';
                            pacheader{1, 21} = 'subid';
                            pacheader{1, 22} = 'iq_dev';
                            pacheader{1, 23} = 'alert_mean';
                            pacheader{1, 24} = 'visitage';
                            pacheader{1, 25} = 'sex';
                            pacheader{1, 26} = 'subfolder';
                        end

                        pactbl = [pacheader; pacrow];
                        pactbl = cell2table(pacrow, 'VariableNames', pacheader);
                        pactbl_fn = fullfile(o.htpcfg.pathdb.analysis, ['pacSrcTbl_' r '_.csv']);
                        writetable(pactbl, pactbl_fn);
                    case 'channel'

                        for i = 1:1
                            % header and save file
                            pacheader{1, 1} = 'global_n';
                            pacheader{1, 2} = 'pacmethod';
                            pacheader{1, 3} = 'desc';
                            pacheader{1, 4} = 'phase';
                            pacheader{1, 5} = 'amplitude';
                            pacheader{1, 6} = 'fn';
                            pacheader{1, 7} = 'subjectname';
                            pacheader{1, 8} = 'groupid';
                            pacheader{1, 9} = 'channel';
                            pacheader{1, 10} = 'maxpac';
                            pacheader{1, 11} = 'minpac';
                            pacheader{1, 12} = 'meanpac';
                            pacheader{1, 13} = 'medianpac';
                            pacheader{1, 14} = 'sdpac';
                            pacheader{1, 15} = 'subid';
                            pacheader{1, 16} = 'iq_dev';
                            pacheader{1, 17} = 'alert_mean';
                            pacheader{1, 18} = 'visitage';
                            pacheader{1, 19} = 'sex';
                            pacheader{1, 20} = 'subfolder';
                        end

                        pactbl = [pacheader; pacrow];
                        pactbl = cell2table(pacrow, 'VariableNames', pacheader);
                        pactbl_fn = fullfile(o.htpcfg.pathdb.analysis, ['pacChanTbl_' r '_.csv']);
                        writetable(pactbl, pactbl_fn);
                end

            end

            function o = bst_table_pac_across_frequencies(o, cfg, pacInfo)

                % anonymous functions
                num2str_clean = @(x) regexprep(num2str(x), ' +', ' ');
                label_split = @(x) split(x, ' ');
                r = o.bst_generateRandomTag;

            end

            function o = bst_topoplot_pac_group(o, cfg)

                % ipac_N = length( ipac );

                tmpvar = load(cfg.filename);

                ipac = tmpvar.ipac;

                features = {'maxpac', 'meanpac', 'minpac', 'sdpac', 'medianpac'};

                tmppac = [];

                j = 1;

                for i = 1:length(features)

                    for k = 1:length(ipac)

                        ik = ipac{k};
                        % meanpac, maxpac, minpac, sdpac, medianpac
                        % measures of interest
                        tmppac(k, :) = ik.(features{i});

                    end

                    desc = features{i};

                    % common variables
                    select_chan = [1:16, 18:37, 39:42, 45:47, 50:55, 57:72, 74:80, 82:87, 89:106, 108:112, 115:118, 122:124];
                    chanlocs = ipac{1}.chanlocs;
                    selchans = chanlocs(select_chan);
                    grpInfo = o.getGroupInfo;
                    load('128-chan_hood.mat');

                    nesting = cfg.nesting;
                    nested = cfg.nested;
                    couplingtype = cfg.pacmethod;
                    desc = cfg.desc;

                    if length(ipac) > 1

                        idx1 = grpInfo.idx(1, :);
                        idx2 = grpInfo.idx(2, :);

                        if cfg.zscore_on == true
                            zopt = '-zscore-';
                            grp1mean = zscore(mean(tmppac(idx1, :), 1));
                            grp2mean = zscore(mean(tmppac(idx2, :), 1));
                        else
                            zopt = '';
                            grp1mean = mean(tmppac(idx1, :), 1);
                            grp2mean = mean(tmppac(idx2, :), 1);
                        end

                        pacscale = [ min(min(tmppac)) max(max(tmppac))];
                        %pacscale = [0.005 0.10];

                        % plot PAC per channel per group
                        pacscale = [min(grp1mean)-0.001 max(grp1mean)];
                        figure;

                        dim = [0 .07 1 .05];
                        str = sprintf('%s (%s): %s Phase (%s Hz) Amplitude (%s Hz) Coupling\nMethod: %s', ...
                            features{i}, zopt, desc, ...
                            mat2str(nesting), mat2str(nested), couplingtype);
                        annotation('textbox', dim, 'HorizontalAlignment', 'center', ...
                            'String', str, 'LineStyle', 'none', 'interpreter', 'none');
                        subplot(2, 2, 1);
                        title(sprintf('Group 1 (n = %d)', sum(grpInfo.idx(1, :))));
                        topoplot(grp1mean(select_chan), selchans, 'maplimits', pacscale, 'conv', 'on')
                        cbar('horiz', 0, [-1 1] .* max(abs(grp1mean(select_chan))));
                        subplot(2, 2, 2);
                        title(sprintf('Group 2 (n = %d)', sum(grpInfo.idx(2, :))));
                        topoplot(grp2mean(select_chan), selchans, 'maplimits', pacscale, 'conv', 'on')
                        cbar('horiz', 0, [-1 1] .* max(abs(grp1mean(select_chan))));

                        % get grp array for pacmean
                        grp1 = tmppac(grpInfo.idx(1, :), :);
                        grp2 = tmppac(grpInfo.idx(2, :), :);

                        % make 3d array
                        grp1 = cat(3, grp1, grp1);
                        grp2 = cat(3, grp2, grp2);

                        size(grp1); % starting with sub/chan/band 71 128 2

                        % [chan, band, subjects]
                        grp1 = permute(grp1, [2 3 1]);
                        grp2 = permute(grp2, [2 3 1]);

                        disp(size(grp1)); % 128 / 2 / 71
                        disp(size(grp1(select_chan, :, :)))

                        grp1 = grp1(select_chan, :, :);
                        grp2 = grp2(select_chan, :, :);

                        [pval1, t_orig1, ~, est_alpha1] = clust_perm2_rui3(grp1, grp2, ...
                            chan_hood(select_chan, select_chan), 5000, 0.05, 1, .05, 2, [], 1); % FXS>TDC

                        [pval2, t_orig2, ~, est_alpha2] = clust_perm2_rui3(grp1, grp2, ...
                            chan_hood(select_chan, select_chan), 5000, 0.05, -1, .05, 2, [], 1); % FXS<TDC

                        subplot(2, 2, 3); topoplot(t_orig1(:, 1), chanlocs(select_chan), 'conv', 'off');
                        %cbar('vert',0,[-1 1].*max(abs(t_orig1)));
                        hold on;
                        topoplot(pval1(:, 1) < 0.05, chanlocs(select_chan), 'maplimits', 'maxmin', ...
                            'style', 'blank');
                        title('FXS > TDC');

                        subplot(2, 2, 4); topoplot(t_orig2(:, 1), chanlocs(select_chan));
                        hold on;
                        topoplot(pval2(:, 1) < 0.05, chanlocs(select_chan), 'maplimits', 'maxmin', ...
                            'style', 'blank', 'conv', 'off');
                        title('FXS < TDC');

                        fn = sprintf('Fig_%s%s_%s_PAC_%s_%s_%s.png', zopt, couplingtype, desc, ...
                            mat2str(nesting), mat2str(nested), features{i});
                        fn = fullfile(o.htpcfg.pathdb.figs, fn);
                        saveas(gcf, fn, 'png');

                        % get significant electrodes
                        feat.tail_desc = 'FXS > TDC';
                        feat.p_idx = find(pval1(:, 1) < 0.05);
                        feat.grp1_dat = grp1mean(feat.p_idx);
                        feat.grp2_dat = grp2mean(feat.p_idx);
                        feat.grp1_alldat = grp1mean;
                        feat.grp2_alldat = grp2mean;
                        feat.grp1_name = 'FXS';
                        feat.grp2_name = 'TDC';

                        grpnames = {feat.grp1_name, feat.grp2_name};
                        grpidx = [repmat({feat.grp1_name}, 1, length(feat.p_idx)) ...
                                repmat({feat.grp2_name}, 1, length(feat.p_idx))];
                        dat = [feat.grp1_dat feat.grp2_dat];
                        close(gcf);

                        % idxMF = {o.sub(:).subj_gender};
                        clear g;

                        % plot 1: significant electrode box/scatter plot
                        g(1, 1) = gramm('x', grpidx, 'y', dat, 'color', grpidx);
                        g(1, 2) = copy(g(1));

                        g(1, 1).stat_boxplot;
                        g(1, 1).set_title('boxplot');
                        g(1, 1).set_title('Box: Sig. Elec.');

                        %Jittered scatter plot
                        g(1, 2).geom_jitter('width', 0.4, 'height', 0);
                        g(1, 2).set_title('Jitter: Sig. Elec.');

                        allgrpidx = cell(1, length(idx1));

                        allgrpidx = num2cell(idx1);
                        allgrpidx(idx1) = {'FXS'};
                        allgrpidx(idx2) = {'TDC'};

                        alldat = mean(tmppac, 2);

                        mean_sig_grp1 = mean(dat(strcmp({feat.grp1_name}, grpidx)));
                        mean_sig_grp2 = mean(dat(strcmp({feat.grp2_name}, grpidx)));
                        mean_all_grp1 = mean(alldat(idx1));
                        mean_all_grp2 = mean(alldat(idx2));

                        %alldat = [grp1mean grp2mean];
                        g(2, 1) = gramm('x', dat', 'color', grpidx);
                        g(2, 2) = gramm('x', alldat', 'color', allgrpidx);

                        g(2, 1).geom_vline('xintercept', [mean_sig_grp1; mean_sig_grp2], 'style', 'k-');
                        g(2, 2).geom_vline('xintercept', [mean_all_grp1; mean_all_grp2], 'style', 'k-');

                        %  g(2,1).stat_density();
                        %  g(2,2).stat_density();
                        g(2, 1).stat_bin('normalization', 'cdf', 'geom', 'stairs');
                        g(2, 2).stat_bin('normalization', 'cdf', 'geom', 'stairs');

                        g(2, 1).set_title('Sig. Electrodes');
                        g(2, 2).set_title('All Electrodes');
                        g(2, :).set_names('x', 'Direct PAC', ...
                            'color', 'Group', 'row', '', 'y', '')

                        g(1, :).set_names('column', 'Origin', ...
                            'x', 'Group', ...
                            'y', 'Standardized Direct PAC', ...
                            'color', 'Group');

                        g.set_title(str);

                        figure('Position', [100 100 800 550]);
                        g.draw();

                        fn_boxplot = sprintf('boxPac%s%s_%s_%s_%s_%s.png', ...
                            zopt, couplingtype, desc, ...
                            mat2str(nesting), mat2str(nested), features{i});
                        fn_boxplot = fullfile(o.htpcfg.pathdb.figs, fn_boxplot);
                        saveas(gcf, fn_boxplot, 'png');

                        close(gcf);

                        % create paired plot

                        if ~isempty(feat.p_idx)
                            chanvec = {chanlocs(feat.p_idx).labels};
                            set1 = [ones(1, length(feat.grp1_dat)); feat.grp1_dat];
                            set2 = [zeros(1, length(feat.grp2_dat)); feat.grp2_dat];

                            for k = 1:size(set1, 2)
                                plot([set1(1, k), set2(1, k)], [set1(2, k), set2(2, k)], ...
                                    'ko-', 'LineWidth', 1, 'MarkerSize', 10);
                                xlim([-0.5 1.5]);
                                hold on
                                text([set1(1, k) + 0.1, set2(1, k) - 0.2], [set1(2, k), set2(2, k)], chanvec(k));
                            end

                            avgpval = num2str(mean(pval1(feat.p_idx, 1)));
                            str2 = sprintf('mean: %2.3f vs %2.3f (p=%s)', mean_sig_grp1, mean_sig_grp2, avgpval);
                            title(sprintf('FXS vs TDC\n%s\n%s', str, str2), 'Interpreter', 'None')

                            fn_pairedplot = sprintf('pairedPac%s%s_%s_%s_%s_%s.png', ...
                                zopt, couplingtype, desc, ...
                                mat2str(nesting), mat2str(nested), features{i});
                            fn_pairedplot = fullfile(o.htpcfg.pathdb.figs, fn_pairedplot);
                            saveas(gcf, fn_pairedplot, 'png');

                            close(gcf);
                        end

                    end

                end

            end

            function ipac = bst_load_ipac(o, fname)

                tmpvar = load(fullfile(o.htpcfg.pathdb.analysis, fname));
                ipac = tmpvar.ipac;
            end

            function fList = bst_get_ipac_flist(o, filter)
                analysis_directory = o.htpcfg.pathdb.analysis;
                pacfilelist = @(x) dir(fullfile(analysis_directory, x));

                switch filter
                    case 'All'
                        str = '*GC*.mat';
                    case 'Theta'
                        str = 'TGC*.mat';
                    case 'Delta'
                        str = 'TGC*.mat';
                    case 'LowAlpha'
                        str = 'LAGC*.mat';
                    case 'HighAlpha'
                        str = 'HAGC*.mat';
                    otherwise
                end

                datestr = @(x) datetime(x, 'ConvertFrom', 'datenum', 'Format', 'yyMMdd|HH:mm');

                tmpfList = pacfilelist(str);

                itemList = arrayfun(@(x) sprintf('%s %s', datestr(x.datenum), x.name), tmpfList, 'uni', 0);

                fList = arrayfun(@(x, y) setfield(x, 'itemList', y), tmpfList, itemList);

            end

            function [TF, ERP, TimeOut, chirp_center_high, errMsg] = bst_ComputeCanoltyMap(o, F, sRate, lowfreq, EpochTime)
                nTime = size(F, 2);
                errMsg = '';

                % ===== CREATE CHIRPLETS =====
                % Definitions
                fmin = 1;
                fmax = 250;
                numfreqs = 70;
                fstep = 0.75;
                % Calculate center frequencies
                temp1 = (0:numfreqs - 1) * fstep;
                temp2 = logspace(log10(fmin), log10(fmax), numfreqs);
                temp2 = (temp2 - temp2(1)) * ((temp2(end) - temp1(end)) / temp2(end)) + temp2(1);
                chirp_center_high = temp1 + temp2;
                % Delete the frequencies that are too high for the sampling frequency
                chirp_center_high(chirp_center_high >= sRate / 3) = [];
                % Calculate chirplets
                [chirpF_high, Freqs] = bst_chirplet(sRate, nTime, chirp_center_high);

                % ===== INITIALIZE RETURNED VARIABLES =====
                % Generate epoch indices
                iEpochTime = round(EpochTime(1) * sRate):round(EpochTime(2) * sRate);

                if isempty(iEpochTime)
                    errMsg = 'Invalid epoch time';
                end

                % Output time vector
                TimeOut = iEpochTime / sRate;
                % Initialize returned variable
                TF = zeros(size(F, 1), length(TimeOut), length(chirp_center_high));
                ERP = zeros(size(F, 1), length(TimeOut));

                % ===== FFT OF SIGNALS =====
                % Transform sensor time series into analytic signals
                F_fft = fft(F, length(Freqs), 2);
                % This step scales analytic signal such that: real(analytic_signal) = raw_signal
                % but note that analytic signal energy is double that of raw signal energy
                F_fft(:, Freqs < 0) = 0;
                F_fft(:, Freqs > 0) = 2 * F_fft(:, Freqs > 0);

                % ===== LOOP ON SIGNALS =====
                for iSource = 1:size(F, 1)
                    % === DETECT MIN/MAX LOW FREQ ===
                    % Calculate one chirplet for the low frequency
                    [chirpF_low, Freqs] = bst_chirplet(sRate, nTime, lowfreq(iSource));
                    % Filter again: Positive version of the signal
                    fs_low = bst_freqfilter(F(iSource, :), chirpF_low, Freqs);
                    % Detection of phase maxima of theta filtered signal (POSITIVE)
                    [tmp, iMaxTheta] = find_maxima(angle(fs_low));

                    % === FILTER GAMMA ===
                    % Filter source signal using all the low-frequency chirplet
                    fs_high = bst_freqfilter(F(iSource, :), chirpF_high, Freqs, F_fft(iSource, :));
                    % Magnitude
                    fs_high = abs(fs_high);
                    % Zscore normalization
                    fs_high = process_baseline_norm('Compute', fs_high, fs_high, 'zscore');

                    % === EPOCH ===
                    % Makes sure all triggers allow full epoch
                    iMaxTheta(iMaxTheta <= abs(iEpochTime(1))) = [];
                    iMaxTheta(iMaxTheta >= nTime - iEpochTime(end)) = [];
                    % Loop on every peak of theta
                    for i = 1:length(iMaxTheta)
                        % Find epoch indices
                        iTime = iMaxTheta(i) + iEpochTime;
                        % Phase-triggered ERP of raw signal
                        ERP(iSource, :) = ERP(iSource, :) + F(iSource, iTime) ./ length(iMaxTheta);
                        % Phase-triggered time-frequency amplitude values (normalized)
                        TF(iSource, :, :) = TF(iSource, :, :) + fs_high(1, iTime, :) ./ length(iMaxTheta);
                    end

                end


            end

        end

        methods (Static)

            function atlas = bst_getAtlas()

                global GlobalData;

                sSurf = bst_memory('GetSurface', GlobalData.CurrentScoutsSurface);

                % If there are no surface, or atlases: return
                if isempty(sSurf) || isempty(sSurf.Atlas) || isempty(sSurf.iAtlas) || (sSurf.iAtlas > length(sSurf.Atlas))
                    isReadOnly = 0;
                    return;
                end

                sAtlas = sSurf.Atlas(sSurf.iAtlas);
                sSurf = [];

            end

            function r = bst_generateRandomTag()

                a = 10000;
                b = 99999;
                r = round((b - a) .* rand(1, 1) + a);

                r = sprintf('%s', num2str(r));

            end

            function str = bst_generateTag(r, str)

                if nargin < 1
                    desc = dbstack;
                    str = desc(2).name;
                end

                str = sprintf('Tag_%s_%s', r, str);

            end

            function addstruct = bst_appendStructure(struct1, struct2)
                addstruct = struct1; %final structure

                for field = fieldnames(struct2)'
                    fname = field{1};
                    addstruct.(fname) = vertcat(struct2.(fname));
                end

            end

            function sFiles = bst_selectByTag(sFiles, cfg)
                % Process: Select file comments with tag: test2
                sFiles = bst_process('CallProcess', 'process_select_tag', sFiles, [], ...
                    'tag', cfg.tag, ...
                    'search', 2, ...% Search the file comments
                'select', 1); % Select only the files with the tag

            end

            function sFiles = bst_getAllRecordings()

                sFiles = bst_process('CallProcess', 'process_select_files_data', [], []);

            end

            function sFiles = bst_getAllSources()
                sFiles = bst_process('CallProcess', 'process_select_files_results', [], []);

            end

            function sFiles = bst_getAllTimeFrequency()

                sFiles = bst_process('CallProcess', 'process_select_files_timefreq', [], []);

            end

            function sFiles_subset = bst_selectSfilesSubset(sFiles, idx)
                % select subset of sFiles via generated index
                sFiles_subset = sFiles(idx);

            end

            function idx = bst_searchSubjectString(sFiles, field, str)
                % get index of subjects by searching a field

                if isempty(sFiles)
                end

                try
                    idx = contains({sFiles.(field)}, str);

                    if ~any(idx)
                        idx = 0;
                    end

                catch
                    idx = 0;
                end

            end

            function [grid grid_cut] = createSubplotGrid(num_elements, num_columns)
                N = num_elements;
                ncols = num_columns;

                % get remainder
                r = mod(length(1:N), ncols);

                if r ~= 0
                    no_rows = floor(N / ncols) + 1; % add extra row
                else
                    no_rows = floor(N / ncols);
                end

                mapidx = reshape(1:N - r, [], ncols);
                mapidx = reshape(1:N - r, ncols, [])';

                if r ~= 0
                    mapidx = vertcat(mapidx, mapidx(end) + 1:mapidx(end) + ncols);
                end

                grid_cut = mapidx;

                grid_cut(end, r + 1:end) = NaN;

                grid = mapidx;

            end

            function [row, col] = getIndicesSubplotGrid(grid, index)

                try
                    data = grid;
                    [maxNum, maxIndex] = max(data(:));
                    [row, col] = ind2sub(size(data), index);
                catch
                    disp('Index out of bounds.');
                end

            end

            function bst_mean_electrode_feature_plot(cfg, dat)

            end

        end

    end
