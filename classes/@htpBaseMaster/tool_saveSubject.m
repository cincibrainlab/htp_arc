%% Tool to Save Subject
% 
%%% Usage
%    
% tool_saveSubject( obj, s, stage )
%
%%% Parameters
%
% The input parameters are s which is a subject object (RestEegDataClass object), 
% stage is the string representing the next stage of preprocessing and the
% third optional input parameter if the function is not self-invoked obj
% is the htpPreprocessMaster object.  There is no output, instead the subject, input s parameter, is saved to the 
% designated preica file directory.
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

%% tool_saveSubject
% Obtain the various attributes needed to save the subject such as epoch type, 
% stage information, and file paths, then save the subject and its information
% into the preica directory to use in further steps of preprocessing.
function tool_saveSubject( obj, s, stage)
 
try
EpochType = char(obj.htpcfg.optnow.Stage2_EpochType);
catch
    EpochType = 'Unspecified';
end
obj.check_stages( s );
stage_fields = obj.stage_info(1,:);
stage_search = find(strcmp(stage, stage_fields));

path_fields = fields(obj.htpcfg.pathdb);
path_search = find(strcmp(stage, path_fields));


save_eeg        = s.EEG;
save_path       = obj.htpcfg.pathdb.(stage);
save_subfolder  = s.subj_subfolder;



switch EpochType
    
    case 'Event'
       s.EEG.filepath   = fullfile(save_path, save_subfolder);
       save_filename    = s.EEG.filename;
    case 'Rest'
        s.EEG.filename = s.filename.(stage);
        save_filename   = s.EEG.filename;
        
    otherwise
        s.EEG.filename = s.filename.(stage);
        save_filename   = s.EEG.filename;
end

s.storeDataset( save_eeg, save_path, save_subfolder, save_filename);

end