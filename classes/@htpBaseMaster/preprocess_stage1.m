%% Stage 1 Preprocessing
%%% Usage
% obj = preprocess_stage1( obj )
%
%%% Parameters
%
% * INPUTS: obj
%  
% * OUTPUTS: obj
%
% The optional input, obj if the function is not self-invoked, is the 
% htpPreprocessMaster object.  
% The output, obj if the function is not self-invoked, is the updated 
% htpPreprocessMaster object with information updated regarding the status 
% and details of stage 1 completion of preprocessing.
%
%%% Copyright and Contact Information
% Copyright © 2020 Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
%
% See https://bitbucket.org/eped1745/htp_stable/src/master/
%
% Contact: ernest.pedapati@cchmc.org

%%  preprocess_stage1
% Configure logs to produce needed notifications, warning, and errors to
% user during stage 1 preprocessing and configure stage specific information
% to guide preprocessing.
% Setup stage to start by configuring datasets (channel, user, title, and resample hz),
% loading all RAW files, performing necessary filtering and resampling, 
% and creating a corresponding result csv for each file. If results are not able to be created,
% then create backup of post stage 1 data to retain completed stage 1 work.

function obj = preprocess_stage1( obj )
obj.reset_msg_log;                      
[mc, mm, mw] = obj.tools_log;           
mc(getmsg(obj, 1));                     

stage_last = 'raw';
stage_next = 'import';
opt        = obj.formatOptions;         

fnlist     = obj.fnlist;                
flength    = length(fnlist);
obj.htpcfg.xmax_arr = [];

arrayfun( @(s) setAssets( obj, s ), obj.sub, 'uni', 0);

is_edf = strcmp(obj.htpcfg.chanNow.net_name, 'EDFGENERIC');

is_arc = strcmp(obj.htpcfg.chanNow.net_name, 'ARCEDF');

mc(getmsg(obj, 2));                     
mc(getmsg(obj, 3));                     
mc(getmsg(obj, 4));                     
mc(getmsg(obj, 5));                     

if ~(is_edf) && ~(is_arc)
    totalsubs = length( obj.sub );
    sub = obj.sub;
else
    if (is_edf)
        %totalsubs = length( obj.sub );
        sub(1:length(obj.sub)*3) = eegDataClass(); 
        num_Subs = length(obj.sub);
        for i=1:length(obj.sub) 
            sub(i) = obj.sub(i);
            sub((i*2)+num_Subs-1) = eegDataClass(); 
            sub((i*2)+num_Subs) = eegDataClass();
            setAssets(obj,sub((i*2)+num_Subs-1));
            setAssets(obj,sub((i*2)+num_Subs));
        end
    else
        %totalsubs = length( obj.sub );
        sub(1:length(obj.sub)*4) = eegDataClass(); 
        num_Subs = length(obj.sub);
        for i=1:length(obj.sub) 
            sub(i) = obj.sub(i);
            sub((i*2)+num_Subs-1) = eegDataClass(); 
            sub((i*2)+num_Subs) = eegDataClass();
            sub((i*2)+num_Subs+1) = eegDataClass();
            setAssets(obj,sub((i*2)+num_Subs-1));
            setAssets(obj,sub((i*2)+num_Subs));
            setAssets(obj, sub((i*2)+num_Subs+1));
        end
    end
    %totalsubs = length( sub );
    totalsubs = length( obj.sub );
    %sub = obj.sub;
end

if ~(is_edf) && ~(is_arc)
    for i = 1 : totalsubs
        s = sub(i); 
        importData( obj, s );
    end
else
    %for i = 1:num_Subs
    for i=1:totalsubs
        s = sub(i); 
        importData( obj, s );
        s.loadDataset('import');
        %s.averageRefData;
        %reref_only(obj,s);
        s.convertBipolarMontage;
        if (is_edf)
            edf_import(obj.htpcfg,s,sub((i*2)+num_Subs-1), sub((i*2)+num_Subs));
        else
            arc_import(obj.htpcfg,s,sub((i*3)+num_Subs-2),sub((i*3)+num_Subs-1),sub((i*3)+num_Subs));
            obj.htpcfg.xmax_arr(i) = obj.htpcfg.xmax_arr(i)/4;
        end
        s.unloadDataset;
        %obj.htpcfg.xmax_arr(end+1) = s.EEG.xmax;
%         s.storeDataset( s.EEG, ...
%             obj.htpcfg.pathdb.('import'), ...
%             s.subj_subfolder, ...
%             s.filename.( 'import' ) );
%         s.unloadDataset;
%         s.outputRow( 'import' );
    end
    obj.sub = sub;
end

mc(getmsg(obj, 6));                     

valid_idx = check_duration( obj, sub );

if strcmpi(opt.cleanmode, 'ASR')
    for i = 1 : length(valid_idx)        
        idx = valid_idx(i);
        s = sub(idx);        
        asr_clean(obj, s, 2);
    end
else
    if ~(is_edf) && ~(is_arc)
        for i=1:totalsubs
            reref_only( obj, sub(i))
        end
    end
end

obj.sub = sub;
clear sub;

try
    obj.createResultsCsv(obj.sub, stage_next,'Default');
catch
    htps1_backup = createbackup( obj, stage_next );
    assignin('base', 'htps1_backup', htps1_backup);
    try
        save(fullfile(obj.htpcfg.pathdb.analysis, ['backup_' obj.htpcfg.timetag2 '.mat']), 'htps1_backup');
    catch
        obj.msgout('Check folder or reload to create directories.', 'step_error');
    end
end

end

%%  createbackup
% Creates backup of object to be utilized for reprocessing if the initial
% processing does not successfully complete
function backup = createbackup( obj, stage_next )
backup.obj = obj;
backup.stage_next = stage_next;

end

%%  getmsg
% Produces the stage related information that may be of interest to the user
% The command console will display this appropriate information.
function str = getmsg(obj, index )
sf = @sprintf;

opt = obj.formatOptions;

msg{1} = sf('version: htp2020v1\nStarting Stage 1: Import Raw Files...');
msg{2} = sf('Assign Electrode System: %s', obj.htpcfg.chanNow.net_name);
msg{3} = sf('User: %s', obj.htpcfg.user);
msg{4} = sf('Study Title: %s', obj.study_title);
msg{5} = sf('Set Resample Rate: %d', opt.srate);
msg{6} = 'Convert RAW data to EEGLAB datasets.';

str = msg{index};

end

%%  setAssets
% Configures the information needed for stage 1 preprocessing epr subject
% such as channel files, user, study title, resampling rate, and gui-set
% options
function s = setAssets(obj, s)
opt = obj.formatOptions;

s.setElectrodeSystem( obj.htpcfg.chanNow );     
s.setUser(obj.htpcfg.user);                     
s.changeStudyTitle(obj.study_title);            
s.setResampleRate( opt.srate );                 
s.setopt( opt );                               

end

%%  importData
% imports the subject data and performs the necessary steps of filtering,
% resampling, and downgrading, as needed.  Then stores updated data and
% configurations for later use in preprocessing.
function s = importData( obj, s )
stage_next = 'import';
opt = obj.formatOptions;

s.getRawData;                                    % import data (biosig)

s = filt_and_resample( obj, s, opt );            % filter, resample

if strcmpi(opt.netdowngrade, 'EGI128->EGI32')
    s = net_downgrade( obj, s, opt ); end        % downgrade all 128 nets to 32

if ~(strcmp(obj.htpcfg.chanNow.net_name, 'EDFGENERIC'))
    s.storeDataset( s.EEG, ...
            obj.htpcfg.pathdb.(stage_next), ...
            s.subj_subfolder, ...
            s.filename.( stage_next ) );
        
    s.unloadDataset;
end

% s.storeDataset( s.EEG, ...
%             obj.htpcfg.pathdb.(stage_next), ...
%             s.subj_subfolder, ...
%             s.filename.( stage_next ) );
        
% s.unloadDataset;

s.outputRow( stage_next );
obj.update_htpcfg( s );

end

%%  net_downgrade
% Perform downgrade to obtain ideal electrode configuration
% per user need specified via gui prior to start of stage 1 preprocessing
function s = net_downgrade( obj, s, opt )
if length(s.EEG.chanlocs) == 128 && strcmp(s.net_name, 'EGI128')
    
    searchChanInfo = {obj.htpcfg.chaninfo.net_displayname};
    chanInfoIdx = strcmpi('EGI Hydrocel 32', searchChanInfo);
    
    obj.htpcfg.chanNow = obj.htpcfg.chaninfo(chanInfoIdx);
    s.setElectrodeSystem( obj.htpcfg.chanNow )
    s.eeglab128to32;
    obj.setElecNow('EGI32'); 
    
end

% TODO add other net conversions

end

%%  filt_and_resample
% Perform necessary filtering and resampling of data per user need
% specified via gui setting prior to stage 1 preprocessing.
function s = filt_and_resample( obj, s, opt )


lowcut_on       = true;
highcut_on      = true;
notch_on        = true;
cleanline_on    = false;

if s.proc_sRate_raw > 2000
    s.resampleData( 1000 );
end

if isnan(opt.highcutoff), highcut_on = false;
else
    if opt.highcutoff < opt.notch(2); notch_on = false;
        str = sprintf('\n%s: Low pass filter below notch. Notch filter not performed.', s.subj_basename);
        s.msgout(str, 'proc_warning');
    end
end

if strcmpi(opt.cleanline, 'Enabled'), notch_on = false; cleanline_on= true; end

if lowcut_on,   s.filtHandler(  'lowcutoff', opt.lowcutoff ); end
if highcut_on, s.filtHandler(  'highcutoff', opt.highcutoff ); end
if notch_on && ~strcmp(obj.htpcfg.optnow.Stage1_Notch1,'none'),    s.filtHandler(  'notch', [opt.notch(1) opt.notch(2)] ); end
if cleanline_on, s.filtHandler( 'cleanline' ); end

s.resampleData;

obj.htpcfg.xmax_arr(end+1) = s.EEG.xmax;

end

%%  check_duration
% Marks certain files that are too small (meaning 2 std below the mean in this case)
% and makes sure to ignore the files during the stage 1 preprocessing step.
function valid_idx = check_duration( obj, sub ) 
xmax_arr = obj.htpcfg.xmax_arr;

minsize = floor(mean(xmax_arr) - std(xmax_arr)*2);
valid_idx  = false(1, length(sub));

for i = 1 : length(sub)
    sub(i).loadDataset('import');
    currentsize = sub(i).EEG.xmax;
    
    if currentsize < minsize
        str = sprintf('File Index %d: %s (%d secs)rejected based on min. length of %d.', i, obj.sub(i).subj_basename, floor( currentsize ), minsize);
        obj.msgout(str,'step_warning');
        sub(i).proc_state = 'SHORT';
    elseif sub(i).proc_contains_all_nans
        str = sprintf('File Index %d: %s rejected based on every data point being NaN', i, obj.sub(i).subj_basename);
        obj.msgout(str, 'step_warning');
        sub(i).proc_state = 'EMPTY';
    else
        valid_idx(i) = 1;
    end
    sub(i).unloadDataset;
end

valid_idx = find(valid_idx);

end

%%  reref_only
% Rereferencing EEG data as needed per user requirement
function reref_only( obj, s )

stage_next = 'import';

s.loadDataset('import');
s.averageRefData;
s.storeDataset( s.EEG, ...
    obj.htpcfg.pathdb.(stage_next), ...
    s.subj_subfolder, ...
    s.filename.( stage_next ) );

s.outputRow( stage_next );
obj.update_htpcfg( s );
s.unloadDataset;

end

%%  asr_clean
% Update per Makoto's recs <https://bit.ly/2m1FzHI>
% * optional and active in htp2020 on *
% -> ASR chan. clean only -> interpolate -> re-ref -> ASR -> reref
% Perform interpolation and manual continuous cleaning for channels
% and proceed depending on user's need in terms of mode of method: 
% mode: 1 - ASR channel only; 2 - ASR only; 3 - Outlier channel; 
%     4 - ASR both; 5 - Outlier + ASR
% mode 1 and 3 being performed for stage 1 channel and then mode 2, 3, and 5
% being performed for stage 2 burst correction.
function asr_clean(obj, s, mode)
stage_next = 'import';
s.loadDataset('import');

s = obj.tool_manualChanClean( s );

if mode == 1 || mode == 3
    
    obj.htpcfg.asr_param = CleanRawDataClass.CleanRawDataInit;
    obj.htpcfg.asr_param.arg_burst = -1;
    obj.htpcfg.asr_param.arg_window = -1;
    
    s.asrData( obj.htpcfg.asr_param );
    s.averageRefData;
    
end

if mode == 4 || mode == 5
%TODO    
end

if mode == 2 || mode == 3 || mode == 5    
    
    obj.htpcfg.asr_param = CleanRawDataClass.CleanRawDataInit;
    obj.htpcfg.asr_param.arg_channel = -1;
    obj.htpcfg.asr_param.arg_flatline = -1;
    obj.htpcfg.asr_param.arg_highpass = -1;
    obj.htpcfg.asr_param.arg_noisy = -1;
    
    s.asrData( obj.htpcfg.asr_param );  
    
    s.averageRefData;                   
    
    obj.msgout('\nRe-Reference 2 | Average','step_complete');
    
    obj.htpcfg.asr_param = CleanRawDataClass.CleanRawDataInit;
    
end

s.storeDataset( s.EEG, ...
    obj.htpcfg.pathdb.(stage_next), ...
    s.subj_subfolder, ...
    s.filename.( stage_next ) );

s.outputRow( stage_next );
obj.update_htpcfg( s );
s.unloadDataset;

end

%% edf_import
% Secondary importing of edf data, and splitting the initial dataset into
% three segments to preserve memory and speed up preprocessing time for
% manual cleaning, etc.
% First subject object represents first ten minutes of initial file,
% second subject objet represents 10 minutes at halfway point of initial file, 
% and finally third subject object represents last 10 minutes of initial file.
function edf_import(htpcfg,s,edf_SecondSub,edf_ThirdSub)
    edf_SecondSub.EEG = eeg_emptyset;
    edf_SecondSub.subj_basename = [s.subj_basename '_F'];
    edf_SecondSub.createFileNames;
    edf_SecondSub.setHtpCfg(htpcfg);
    edf_SecondSub.updatePaths(htpcfg.basePath);
    edf_SecondSub.setTimeTag(htpcfg.timetag2);
    edf_SecondSub.subj_subfolder = s.subj_subfolder;
    edf_SecondSub.EEG.data = s.EEG.data(:,(1+s.EEG.pnts/3):((s.EEG.pnts/3)*2));
    edf_SecondSub.EEG.times = s.EEG.times((1+s.EEG.pnts/3):((s.EEG.pnts/3)*2));
    edf_SecondSub.EEG.pnts = size(edf_SecondSub.EEG.data,2);
    edf_SecondSub.EEG.srate = s.EEG.srate;
    edf_SecondSub.proc_xmax_raw = s.proc_xmax_raw;
    edf_SecondSub.proc_sRate_raw = s.proc_sRate_raw;
    edf_SecondSub.proc_filt_lowcutoff = s.proc_filt_lowcutoff;
    edf_SecondSub.proc_filt_highcutoff = s.proc_filt_highcutoff;
    edf_SecondSub.EEG.chanlocs = s.EEG.chanlocs;
    edf_SecondSub.EEG.nbchan = s.EEG.nbchan;
    edf_SecondSub.EEG = eeg_checkset(edf_SecondSub.EEG);
    edf_SecondSub.EEG = eeg_checkchanlocs(edf_SecondSub.EEG);
    edf_SecondSub.net_nbchan_orig = s.net_nbchan_orig;
    edf_SecondSub.outputRow('import');
    edf_SecondSub.storeDataset( edf_SecondSub.EEG, ...
     htpcfg.pathdb.('import'), ...
     edf_SecondSub.subj_subfolder, ...
     edf_SecondSub.filename.( 'import' ) );

    edf_ThirdSub.subj_basename = [s.subj_basename '_A'];
    edf_ThirdSub.EEG = eeg_emptyset;
    edf_ThirdSub.createFileNames;
    edf_ThirdSub.setHtpCfg(htpcfg);
    edf_ThirdSub.updatePaths(htpcfg.basePath);
    edf_ThirdSub.setTimeTag(htpcfg.timetag2);
    edf_ThirdSub.subj_subfolder = s.subj_subfolder;
    edf_ThirdSub.EEG.data = s.EEG.data(:,(s.EEG.pnts/3*2)+1:end);
    edf_ThirdSub.EEG.times = s.EEG.times((s.EEG.pnts/3*2)+1:end);
    edf_ThirdSub.EEG.pnts = size(edf_ThirdSub.EEG.data,2);
    edf_ThirdSub.EEG.srate = s.EEG.srate;
    edf_ThirdSub.proc_xmax_raw = s.proc_xmax_raw;
    edf_ThirdSub.proc_sRate_raw = s.proc_sRate_raw;
    edf_ThirdSub.proc_filt_lowcutoff = s.proc_filt_lowcutoff;
    edf_ThirdSub.proc_filt_highcutoff = s.proc_filt_highcutoff;
    edf_ThirdSub.EEG.chanlocs = s.EEG.chanlocs;
    edf_ThirdSub.EEG.nbchan = s.EEG.nbchan;
    edf_ThirdSub.EEG = eeg_checkset(edf_ThirdSub.EEG);
    edf_ThirdSub.EEG = eeg_checkchanlocs(edf_ThirdSub.EEG);
    edf_ThirdSub.net_nbchan_orig = s.net_nbchan_orig;
    edf_ThirdSub.outputRow('import');
    edf_ThirdSub.storeDataset( edf_ThirdSub.EEG, ...
     htpcfg.pathdb.('import'), ...
     edf_ThirdSub.subj_subfolder, ...
     edf_ThirdSub.filename.( 'import' ) );

 
    s.subj_basename = [s.subj_basename '_D'];
    s.createFileNames;
    s.EEG.data = s.EEG.data(:,1:s.EEG.pnts/3);
    %s.EEG.pnts = s.EEG.pnts/3;
    s.EEG.pnts = size(s.EEG.data,2);
    s.EEG = eeg_checkset(s.EEG);
    s.outputRow('import');
    s.storeDataset( s.EEG, ...
     htpcfg.pathdb.('import'), ...
     s.subj_subfolder, ...
     s.filename.( 'import' ) );
 
    edf_SecondSub.unloadDataset;
    edf_ThirdSub.unloadDataset;
end

function arc_import(htpcfg,s,arc_SecondSub,arc_ThirdSub, arc_FourthSub)
    
    for i=2:4
        switch i
            case 2
                subject = arc_SecondSub;
                subject.EEG = eeg_emptyset;
                subject.subj_basename = [s.subj_basename '_2'];
                subject.EEG.data = s.EEG.data(:,(1+s.EEG.pnts/4):((s.EEG.pnts/4)*2));
                subject.EEG.times = s.EEG.times((1+s.EEG.pnts/4):((s.EEG.pnts/4)*2));
            case 3
                subject = arc_ThirdSub;
                subject.EEG = eeg_emptyset;
                subject.subj_basename = [s.subj_basename '_3'];
                subject.EEG.data = s.EEG.data(:,(s.EEG.pnts/4*2)+1:(s.EEG.pnts/4*3));
                subject.EEG.times = s.EEG.times((s.EEG.pnts/4*2)+1:(s.EEG.pnts/4*3));
            case 4 
                subject = arc_FourthSub;
                subject.EEG = eeg_emptyset;
                subject.subj_basename = [s.subj_basename '_4'];
                subject.EEG.data = s.EEG.data(:,(s.EEG.pnts/4*3)+1:end);
                subject.EEG.times = s.EEG.times((s.EEG.pnts/4*3)+1:end);
        end
        subject.createFileNames;
        subject.setHtpCfg(htpcfg);
        subject.updatePaths(htpcfg.basePath);
        subject.setTimeTag(htpcfg.timetag2);
        subject.subj_subfolder = s.subj_subfolder;
        subject.EEG.pnts = size(subject.EEG.data,2);
        subject.EEG.srate = s.EEG.srate;
        subject.proc_xmax_raw = s.proc_xmax_raw;
        subject.proc_sRate_raw = s.proc_sRate_raw;
        subject.proc_filt_lowcutoff = s.proc_filt_lowcutoff;
        subject.proc_filt_highcutoff = s.proc_filt_highcutoff;
        subject.EEG.chanlocs = s.EEG.chanlocs;
        subject.EEG.nbchan = s.EEG.nbchan;
        subject.EEG = eeg_checkset(subject.EEG);
        subject.EEG = eeg_checkchanlocs(subject.EEG);
        subject.proc_contains_all_nans = (numel(find(~isnan(subject.EEG.data))) == 0);
        subject.net_nbchan_orig = s.net_nbchan_orig;
        subject.outputRow('import');
        subject.storeDataset( subject.EEG, ...
         htpcfg.pathdb.('import'), ...
         subject.subj_subfolder, ...
         subject.filename.( 'import' ) );
        subject.unloadDataset;
    end
    s.subj_basename = [s.subj_basename '_1'];
    s.EEG.data = s.EEG.data(:,1:s.EEG.pnts/4);
    s.createFileNames;
    s.setHtpCfg(htpcfg);
    s.updatePaths(htpcfg.basePath);
    s.setTimeTag(htpcfg.timetag2);
    s.subj_subfolder = s.subj_subfolder;
    s.EEG.pnts = size(s.EEG.data,2);
    s.EEG.srate = s.EEG.srate;
    s.proc_xmax_raw = s.proc_xmax_raw;
    s.proc_sRate_raw = s.proc_sRate_raw;
    s.proc_filt_lowcutoff = s.proc_filt_lowcutoff;
    s.proc_filt_highcutoff = s.proc_filt_highcutoff;
    s.EEG.chanlocs = s.EEG.chanlocs;
    s.EEG.nbchan = s.EEG.nbchan;
    s.EEG = eeg_checkset(s.EEG);
    s.EEG = eeg_checkchanlocs(s.EEG);
    s.proc_contains_all_nans = (numel(find(~isnan(s.EEG.data))) == 0);
    s.net_nbchan_orig = s.net_nbchan_orig;
    s.outputRow('import');
    s.storeDataset( s.EEG, ...
     htpcfg.pathdb.('import'), ...
     s.subj_subfolder, ...
     s.filename.( 'import' ) );
    s.unloadDataset;
    
end


