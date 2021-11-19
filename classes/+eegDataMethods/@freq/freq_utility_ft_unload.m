function o = freq_utility_ft_unload( o, varname )

validFields = fields(o.ftcfg.freqFTdat);

if any(strcmpi( varname, validFields ))
    o.ftcfg.dat.(varname) = [];
 %   o.ftcfg.Avail.(varname) = false;
    
else
    o.msgout('Dataset field not found.', 'step_error');
end

end