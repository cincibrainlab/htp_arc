%% Initialize Environment
%%% Usage
% obj = init_environment( obj )
%
%%% Parameters
%
% * INPUTS: obj
%
% * OUTPUTS: obj
%
% The input is the htpPreprocessMaster object if the function is not
% self-invoked.  The output, if the function is not self-invoked, is the 
% htpPreprocessMaster object that was passed in with the preprocessing 
% enviornment updated with various information (user selection options,
% channel location info, and eeglab plugin paths) to guide the
% preprocessing steps throughout the entire process.
%
%%% Copyright and Contact Information
% Copyright © 2020  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% init_environment
% Set the user defined options for the preprocessing gui options from
% various XMLs.  Along with those gui-based options, further XML-defined options for
% powerbands, electrode configuration, channel information, etc. are set to
% allow the preprocessing the ability to correctly proceed.  
%
% On top of initiation of accurate preprocessing options, the excessive warning 
% messages that do not correspond to warnings that the user should worry 
% about are turned off to keep the console clean and easily readable.
%
% All EEGLAB plugins that are possibly utilized during preprocessing are
% checked to ensure their existence on the MATLAB path, so that they can be 
% reached at the appropriate time during preprocessing and if not then alert the user to
% ensure that EEGLAB is installed and added to the MATLAB path so the
% preprocessing experience can be smooth and accurate.

function obj = init_environment( obj )

obj.msgout('Initializing Configuration ...');

obj.xmlfile_options = 'config/cfg_htpPreprocessingOptions.xml';
obj.xmlfile_elec    = 'config/cfg_htpEegSystems.xml';
obj.xmlfile_presets =  'config/cfg_htpPresets.xml';
obj.xmlfile_exclude =  'config/cfg_exclude.xml';
obj.xmlfile_power = 'config/cfg_htpAnalysisPowerBands.xml';  

obj.import_options( obj.xmlfile_options );
obj.import_elec( obj.xmlfile_elec );
obj.import_presets( obj.xmlfile_presets );
obj.import_exclude( obj.xmlfile_exclude );
obj.import_powerbands( obj.xmlfile_power );

htpcfg = obj.htpcfg;

base_configEnvironment;


obj.msgout(sprintf('Electrode Configurations: Loaded.'), 'step_complete');
htpcfg.chaninfo = obj.xml_elec;


obj.msgout(sprintf('Available Options from %s: Loaded.\n', obj.xmlfile_options ), 'step_complete');

% htpcfg.opt.lowcutoff    = obj.xml_opt.Stage1.FilterLow;
% htpcfg.opt.highcutoff   = obj.xml_opt.Stage1.FilterHigh;
% htpcfg.opt.notch        = obj.xml_opt.Stage1.Notch1; %{'57 63 3330'};
% htpcfg.opt.resample     = obj.xml_opt.Stage1.Resample;
% htpcfg.opt.epochlength  = obj.xml_opt.Stage2.EpochLength;
% htpcfg.opt.cleanmode    = obj.xml_opt.Stage2.CleanMode;
% htpcfg.opt.pcacomps     = obj.xml_opt.Stage3.PCA;
% htpcfg.opt.brainonly    = obj.xml_opt.Stage3.CompSelect;
% htpcfg.opt.plots        = {'Off', 'Minimal', 'Maximum'};
% htpcfg.opt.parforS1     = obj.xml_opt.Stage1.ParforS1;


try
    
    htpcfg.hdmfile = fullfile(htpcfg.eeglabpath, '\plugins\dipfit2.3\standard_BEM\standard_vol_SCCN.mat');
    htpcfg.mrifile = fullfile(htpcfg.eeglabpath, '\plugins\dipfit2.3\standard_BEM\standard_mri.mat');
    
    htpcfg.eegpluginspath = fullfile([htpcfg.eeglabpath 'plugins']);
    htpcfg.plugerr = 0;
    
    
    
    if obj.checkEegPlugin('iclabel', htpcfg.eegpluginspath), else,    htpcfg.plugerr = 1; pluginErrMsg('ICLabel'); end
    if obj.checkEegPlugin('dipfit', htpcfg.eegpluginspath), else,     htpcfg.plugerr = 1; pluginErrMsg('dipfit2.0'); end
    if obj.checkEegPlugin('viewprops', htpcfg.eegpluginspath), else,  htpcfg.plugerr = 1; pluginErrMsg('ViewProps'); end
    if obj.checkEegPlugin('fieldtrip', htpcfg.eegpluginspath), else,  htpcfg.plugerr = 1; pluginErrMsg('FieldTrip-lite'); end
    if obj.checkEegPlugin('firfilt', htpcfg.eegpluginspath), else,    htpcfg.plugerr = 1; pluginErrMsg('FirFilt'); end
    if obj.checkEegPlugin('biosig', htpcfg.eegpluginspath), else,    htpcfg.plugerr = 1; pluginErrMsg('Biosig'); end
    if obj.checkEegPlugin('mass_univ', htpcfg.eegpluginspath), else,    htpcfg.plugerr = 1; pluginErrMsg('mass_univ'); end
        
    if exist('ALLCOM', 'var')
        
    else
        obj.start_EegLab_If_Needed;
        
    end
catch
    
    obj.msg = sprintf('ERROR: Please set EEGLAB path in Matlab.');
    notify( obj, 'step_complete');
    
end


obj.htpcfg = htpcfg;
assignin('base', 'htpcfg', htpcfg);


end

%% base_configEnvironment
% Turn off excessive warnings so command console is not cluttered
% with said warnings

function result = base_configEnvironment()

    fprintf('\nExcessive Warnings Off\n');
    evalin('base', 'warning( ''off'', ''MATLAB:MKDIR:DirectoryExists'');');
    evalin('base', 'warning( ''off'', ''MATLAB:xlswrite:AddSheet'');' ) ;
    evalin('base', 'warning( ''off'', ''MATLAB:table:ModifiedAndSavedVarnames'');');
    evalin('base', 'warning( ''off'', ''MATLAB:subscripting:noSubscriptsSpecified'');');
    evalin('base', 'warning( ''off'', ''MATLAB:rmpath:DirNotFound'');');
    evalin('base', 'warning( ''off'', ''MATLAB:printf:BadEscapeSequenceInFormat'');'); 


    fprintf('\nDisplay Units set to Pixels\n');
    evalin('base', 'set(0,''units'',''pixels'');');

    result = 1;
end

%% pluginErrMsg
% Need to alert user that EEGLAB plugin possibly utilized by
% pipeline is not installed on their system.

function pluginErrMsg( error_str )

   obj.msgout(sprintf('\nERROR: EEGLAB plugin "%s" is not installed. \n\n', error_str), 'msg_warning');

end