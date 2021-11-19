%% Import file list
%
%%% Usage
%    
% obj = import_filelist( obj )
%
% The optional parameter if the function is not self-invoked is obj which
% is the htpPreprocessMaster object passed in.  The output, if the function
% is not self-invoked, is the updated htpPreprocessMaster object with the 
% various configuration attributes (RAW File, Time tags, base path, etc.) 
% updated.
%
% Copyright (C) 2020  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% import_filelist
% When reloading stages the configuration attributes for the group and its
% subjects must be set.  After filtering for the electrode system and seperation of event data
% into specific sets, the following function then assigns the correct
% values for aspects such as base path, RAW file location, study
% title, and stage file names for eventual preprocessing stages.
function obj = import_filelist( obj )

htpcfg = obj.htpcfg;

if strcmp('init', htpcfg.basePath)
    obj.msgout('Critical. No source folder (basePath) assigned.', 'step_error');
    return;
end

if strcmp('init', htpcfg.chanNow)
    obj.msgout('Critical. No electrode system assigned.', 'step_error');
    return;
end


obj.msgout('Import via Filelist...', 'step_msg');

obj.configObject = eegDataClass();
obj.configObject.createPaths( htpcfg.basePath );
obj.msgout(sprintf('Creating/Updating Base Path: %s\n', htpcfg.basePath), 'step_msg');
htpcfg.pathdb = obj.configObject.pathdb;


filter = htpcfg.chanNow.net_filter;


obj.dirlist = obj.getFileList( filter, htpcfg.pathdb.raw );
fnlist = obj.dirlist.full';
subfolderlist = obj.dirlist.subfolder';


file_eventIdx = contains(fnlist,'dig.edf');
file_dataIdx = ~contains(fnlist,'dig.edf');
event_subfolderlist = subfolderlist(file_eventIdx);
event_fnlist = fnlist(file_eventIdx);

subfolderlist = subfolderlist(file_dataIdx);

if isempty(subfolderlist{1})
    obj.msgout('\n\nERROR: Please place files in subfolders and restart.\n', 'step_warning');
    return;
end

obj.fnlist = fnlist(file_dataIdx);
obj.subfolderlist = subfolderlist;

if strcmp('No File', obj.fnlist) 

    obj.msgout('WARNING: No raw files found in directory, will look for other stages.', 'step_warning');
    obj.sub = [];
else
    for i = 1:length(fnlist), sub(i) = eegDataClass();  end
    obj.msgout(sprintf('Creating %d data objects.', length(fnlist)), 'step_msg');

    for i = 1:length(fnlist), sub(i).updatePaths( htpcfg.basePath ); end
    obj.msgout(sprintf('Updating base path: %s', htpcfg.basePath), 'step_msg');

    for i = 1:length(fnlist), sub(i).assignRawFile( subfolderlist{i}, fnlist{i} ); end
    obj.msgout(sprintf('Assign Raw File (%d): %s', i, fnlist{i}), 'step_msg');

    for i = 1:length(fnlist), sub(i).setUser( htpcfg.user ); end
    obj.msgout(sprintf('User Assigned: %s', htpcfg.user), 'step_msg');

    for i = 1:length(fnlist), sub(i).setTimeTag( htpcfg.timetag2 ); end
    obj.msgout(sprintf('Time Tag Assigned: %s', htpcfg.timetag2), 'step_msg');

    for i = 1:length(fnlist), sub(i).changeStudyTitle( htpcfg.title_string ); end
    obj.msgout(sprintf('Study Title Assigned: %s', htpcfg.title_string), 'step_msg');

    for i = 1:length(fnlist), sub(i).createFileNames; end
    obj.msgout(sprintf('Creating Stage File Names.'), 'step_msg');

    for i = 1:length(fnlist), sub(i).setHtpCfg( htpcfg ); end
    obj.msgout(sprintf('Setting Study Configuration in each Subject (sub.htpcfg).'), 'step_msg');


    obj.htpcfg = htpcfg;
    obj.sub = sub;

end

 
end