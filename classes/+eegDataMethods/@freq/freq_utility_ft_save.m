function o = freq_utility_ft_save( o )

md = @(x) mkdir(x);

datsavefile = fullfile(o.pathdb.ft, o.subj_subfolder, o.filename.ftdat);
outputsavefile = fullfile(o.pathdb.ft, o.subj_subfolder, o.filename.ftoutput);
cfgsavefile = fullfile(o.pathdb.ft, o.subj_subfolder, o.filename.ftcfg);

folder = fullfile(o.pathdb.ft, o.subj_subfolder);

if ~exist(folder, 'dir'), md(folder); end

try
    freqFTdat = o.ftcfg.freqFTdat;
    save( datsavefile, '-struct', 'freqFTdat', '-V7.3');
    o.msgout(sprintf('ftcfg.dat File Saved in MAT file %s', datsavefile), 'step_complete');
    
    freqFToutput = o.ftcfg.freqFToutput;
    save( outputsavefile, '-struct', 'freqFToutput', '-V7.3');
    o.msgout(sprintf('ftcfg.output File Saved in MAT file %s', outputsavefile), 'step_complete');
    
    freqFTconfig = o.ftcfg.freqFTconfig;
    save( cfgsavefile, '-struct', 'freqFTconfig', '-V7.3');
    o.msgout(sprintf('ftcfg.cfg File Saved in MAT file %s', cfgsavefile), 'step_complete');  
   
catch
    o.msgout('Error: ftcfg File Not Saved.', 'step_warning');
end

dat = [];

end