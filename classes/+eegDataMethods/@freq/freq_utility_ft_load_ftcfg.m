function o = freq_utility_ft_load_ftcfg( o )

try
    
   loadfile = fullfile(o.pathdb.ft, o.subj_subfolder, o.filename.ftcfg);
   cfg = load(loadfile);
 
   o.ftcfg.freqFTconfig = cfg;

catch
    
    msg = 'FT loadfile unavailable.';
    o.msgout(msg,'step_warning');
    
end

end