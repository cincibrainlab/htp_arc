function o = freq_utility_ft_load_ftoutput( o )

try
    
   loadfile = fullfile(o.pathdb.ft, o.subj_subfolder, o.filename.ftoutput);
   output = load(loadfile);
 
   o.ftcfg.freqFToutput = output;

catch
    
    msg = 'FT loadfile unavailable.';
    o.msgout(msg,'step_warning');
    
end

end