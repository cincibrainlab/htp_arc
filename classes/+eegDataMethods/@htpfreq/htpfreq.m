classdef htpfreq < handle
    %KIT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ftcfg; % property base structure for fieldtrip analyses
        
    end
    
    methods
        function o = freq( )
            
            o.ftcfg.freqFTplot.chanArr = 1;
            % o.s = s;
            
            o.ftcfg.freqFToutput = [];
            o.ftcfg.freqFTconfig = [];
            o.ftcfg.freqFTdat = [];
            o.ftcfg.freqFTconfig.datPreVar = 'datPre';
            
            
        end
        
        function o = freq_utility_ft_setChanArr( o, mat )
            
            o.ftcfg.freqFTplot.chanArr = mat;
            
        end
        
       
        
    end
    
    
    
end


