%% Tool for Manual Channel Cleaning
%
%%% Usage
%    
% s = tool_manualChanClean( obj, s )
%
%%% Parameters
%
% * INPUTS: obj, s
%
% * OUTPUTS: s
%
% The input parameters are s which is a subject object (RestEegDataClass object) and
% obj is the htpPreprocessMaster object that is passed in if the function
% is not self-invoked.  The output is the subject object with the cleaned channels
% and the corresponding updated channel information such as rejects, etc. 
%
%%% Copyright and Contact Information
%
% Copyright (C) 2019  Cincinnati Children's (Pedapati Lab)
%
% This file is part of High Throughput Pipeline (HTP)
% 
% See https://bitbucket.org/eped1745/htp_stable/src/master/
% 
% Contact: ernest.pedapati@cchmc.org

%% tool_manualChanClean
% Perform interpolation for channels and proceed to clean channels manually
% and trim edge artifacts to prepare data for future preprocessing stages.
% Update the subject with the channel information regarding cleaning and
% rejection statuses.
function  s = tool_manualChanClean( obj, s )

htpcfg = obj.htpcfg;
opt = htpcfg.optnow;

% Interpolation = opt.Stage2_Interpolation;
ChanCleanThreshold = opt.Stage2_ChanCleanThreshold;
CleanMode = char(opt.Stage2_CleanMode);
EpochType = opt.Stage2_EpochType;
MergeType = char(opt.Stage2_MergeType);
Merge = char(opt.Stage2_MergeFiles);

% ============= MANUAL CHANNEL CLEANING ======================
%
if htpcfg.autoprocflag == 1
    s.proc_badchans = s.proc_tmprej_chans;
    %s.autoContClean;
else
    s.manualChanClean;
end
s.removeInterpolateChans;
% ============= MANUAL CONTINUOUS ARTIFACT CLEANING ==========

if strcmp(EpochType, 'Event') == 1 && strcmp('Yes', Merge)
    if length(s.proc_merge.EEG2) > 1
        
        switch MergeType
            case 'TrimMergeOnly'
                
                bidx = find(strcmp('boundary', {s.EEG.event.type}));
                
                cut_seconds = 4;
                
                for i = 1 : length(bidx)
                    points_to_remove = s.EEG.srate * cut_seconds;
                    cut_center = s.EEG.event(bidx(i)).latency;
                    
                    cut_point = [(cut_center - points_to_remove) (cut_center + points_to_remove)];
                    
                    
                    s.EEG = eeg_eegrej( s.EEG, cut_point);
                    s.EEG = eeg_checkset( s.EEG );
                    obj.msgout(sprintf('\nMerge Artifact %d/%d Trimmed (%s sec) ', i, length(bidx), num2str(cut_point/s.EEG.srate)), 'step_complete');
                    
                    
                end
                
            case 'TrimStartEnd'
                
                bidx = find(strcmp('boundary', {s.EEG.event.type}));
                
                cut_seconds = 4;
                
                for i = 1 : length(bidx)
                    points_to_remove = s.EEG.srate * cut_seconds;
                    cut_center = s.EEG.event(bidx(i)).latency;
                    
                    cut_point = [(cut_center - points_to_remove) (cut_center + points_to_remove)];
                    
                    
                    s.EEG = eeg_eegrej( s.EEG, cut_point);
                    s.EEG = eeg_checkset( s.EEG );
                    obj.msgout(sprintf('Merge Artifact %d/%d Trimmed (%s sec) ', i, length(bidx), num2str(cut_point/s.EEG.srate)), 'step_complete');
                    
                    
                end
                
                trim_seconds = 4;
                totalpoints = s.EEG.pnts;
                endpoint = totalpoints(end);
                startpoint = 1;
                points_to_remove = s.EEG.srate * trim_seconds;
                trimpoint_start = [startpoint startpoint + points_to_remove];
                trimpoint_end = [endpoint-points_to_remove endpoint];
                cut_point = [trimpoint_start; trimpoint_end];
                s.EEG = eeg_eegrej( s.EEG, cut_point);
                s.EEG = eeg_checkset( s.EEG );
                obj.msgout(sprintf('Trim Start and End Artifact (%d sec)', trim_seconds), 'step_complete');
                
                
        end
        
        
        
        
        
    end
end

if strcmp(EpochType, 'Event') == 0
    obj.msgout('\nManual Continuous Data Rejection: ', 'step_complete');
   
    if htpcfg.autoprocflag == 1
        s.autoContClean;
    else
        s.manualContClean;
    end
    
    
    obj.msgout('\nSegments removed: ', 'step_complete');
    obj.msgout(sprintf('Data Length: Pre Post %d', s.EEG.etc.dataRank), 'step_complete');
    
end

if strcmp(EpochType, 'Event') == 1
    obj.msgout('\nManual Continuous Data Rejection: ', 'step_complete');
   
    if htpcfg.autoprocflag == 1
       % s.autoContClean;
    else
        s.manualContClean;
    end
    
    
    obj.msgout('\nSegments removed: ', 'step_complete');
    obj.msgout(sprintf('Data Length: Pre Post %d', s.EEG.etc.dataRank), 'step_complete');
    
end

%
%     case 'asr'
%
%         htpcfg.asr_param = CleanRawDataClass.CleanRawDataInit;
%         s.asrData( htpcfg.asr_param );
%
%      s.cleanData;
% s.removeInterpolateChans;
%end

obj.msgout('\nManual Bad Channel Selection: ', 'step_complete');
obj.msgout(sprintf('\nBad Channel IDs Removed (blank = none): %s\n', num2str(s.proc_badchans)), 'step_complete');

obj.msgout(sprintf('True Data Rank: %d\n', s.EEG.etc.dataRank), 'step_complete');

s.proc_ipchans = length(s.proc_badchans);
s.proc_badchans = ['['  num2str(s.proc_badchans) ']'];
s.proc_dataRank = s.EEG.etc.dataRank;


end
