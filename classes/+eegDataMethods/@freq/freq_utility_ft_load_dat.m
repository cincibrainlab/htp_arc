function o = freq_utility_ft_load_dat( o )

try
    
   loadfile = fullfile(o.pathdb.ft, o.subj_subfolder, o.filename.ftdat);
   dat = load(loadfile);
 
   o.ftcfg.freqFTdat = dat;

catch
    
    msg = 'FT loadfile unavailable.';
    o.msgout(msg,'step_warning');
    
end

end