function EEG_AB = abClean(EEG)
    EEG_AB = EEG;
    Parameters = [];
    Parameters.Approach = 'Window';
    Parameters.Threshold = 50; % muV
    Parameters.Fs = EEG_AB.srate; 
    Parameters.WindowSize = 10; % unit in seconds

    EEG_AB = EEG;
    indices = find(~isnan(EEG.data(:,:)));
    Parameters.InData = EEG.data(reshape(find(~isnan(EEG.data(:,:))),size(EEG.data(:,:),1),[])); % data matrix
    tic;Parameters = Run_AB_rui(Parameters);toc % quick
    EEG_AB.data(indices) = Parameters.OutData;
    EEG_AB = eeg_checkset(EEG_AB);
end

