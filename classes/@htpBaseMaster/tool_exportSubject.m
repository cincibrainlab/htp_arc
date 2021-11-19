function s = tool_exportSubject( obj, s, outdir)
md = @(x) mkdir(x);

try
EpochType = char(obj.htpcfg.optnow.Stage2_EpochType);
catch
    disp('WARNING: No Optnow, set to default');
    EpochType = 'Rest';
end

save_eeg        = s.EEG;
save_path       = outdir;
save_subfolder  = s.subj_subfolder;

fldr = fullfile(save_path, save_subfolder);

if ~exist(fldr, 'dir'), md(fldr); end

% create source filename
src_filename = sprintf('G%s-N%s', save_subfolder, s.filename.('postcomps'));
s.filename.source = src_filename;
s.EEG.filename = s.filename.('source');

switch EpochType
    
    case 'Event'
       s.EEG.filepath   = fullfile(save_path, save_subfolder);
       save_filename    = s.EEG.filename;
    case 'Rest'
        s.EEG.filename = s.filename.('source');
        save_filename   = s.EEG.filename;
end


% save cleaned dataset into the preica directory
s.storeDataset( save_eeg, save_path, save_subfolder, save_filename);

end