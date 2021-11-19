% HTP_CONTENTS A description of HTP functions and files.
%
% High Throughput Pipeline (HTP) is an object orientated software
% toolbox to process EEG data. By design, an EEG subject object has
% properties and methods that can be "wrapped" around any EEG software.
% Currently, in addition to custom code, functions are implemented with
% a combination of EEGLAB and Fieldtrip Opensource software toolboxes.
%
% As an example, electrodeConfigClass is a configuration class to define
% an object that serve as an abstraction layer for different EEG
% recording systems. By defining system specific files within the object
% (i.e. a custom channel file and montage) analysis and import code can 
% be written to be device agnostic. Electrode systems can be defined
% through a structured text file located in config/cfg_electrodeSystems.txt
%
% Version 2.0 (First Public Release)
%
% Object Classes
%
% Superclasses
%   @eegDataClass
%   @htpBaseMaster
%   @htpPreprocessMaster
%   @htpAnalysisMaster
%   @restingAnalysisModule
%
%
% Use as
%    [ output ] = function( inputs )
%
% arguments
% 
% Functions
%    Config
%    htp_readEegSystems import EEG net parameters from textfile
%     
%
%
%
%  htpPreprocessClass
%    init_path          
%    init_environment
%    import_elec
%    import_options
%    setOptNow
%    calc_cont_EpochLimits
%    openFolderInExplorer
%
%
%  htpUtilityFunctions
%    getHostName
%    checkEegPlugin
%    turnOffWarnings
%    getFileList
%    filtInitParam
%    filtData
%    createResultsCSV
%    getStageCSV
%    selectObjects
%    populateDatatable.m
%
%

% Copyright (C) 2019  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP), see 
% https://bitbucket.org/eped1745/htp_stable/src/master/
% Contact: ernest.pedapati@cchmc.org