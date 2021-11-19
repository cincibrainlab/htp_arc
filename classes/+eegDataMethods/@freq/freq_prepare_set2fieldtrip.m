function o = freq_prepare_set2fieldtrip( o )
try
    o.loadDataset('postcomps');
    
    % convert to continous data from epochs
    o.EEG = eeg_checkset( eeg_epoch2continuous( o.EEG ) );
    
    % convert to fieldtrip data structure
    datPre = eeglab2fieldtrip( o.EEG, 'preprocessing', 'dipfit' );
    
    o.unloadDataset;
    
    % assign importing preprocessing data
    o.ftcfg.freqFToutput = struct();
    o.ftcfg.freqFTdat.datPre = datPre;
    o.ftcfg.freqFTconfig.Avail.datPre = true;
    o.msgout('EEG setfile imported to Fieldtrip format.', 'msg_complete');
    
catch
    o.msgout('Unable to import Postcomps EEG setfile.', 'msg_error');
    o.ftcfg.freqFTconfig.Avail.datPre = false;
    
end
end
