classdef htpAnalysisMaster < handle  & htpBaseMaster
    %HTPANALYSISMODULE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = htpAnalysisMaster()
           obj@htpBaseMaster; 
           obj.outStr = 'Constructing htpAnalysisMaster ...'; % initialize messages
        end
        
        function obj = setupVariables( obj )
           
            % pow spectrum
            obj.xmlfile_power = 'config/cfg_htpAnalysisPowerBands.xml';            
            obj.import_powerbands;
            
        end
        
        function obj = demostartup( obj )
            
            obj.setupVariables;
            
        end
        
        function obj = inheritPreProcessMaster( obj, htpPC )
           
            fn = fields(htpPC);
            
            for i = 1 : length( fn )
                obj.( fn{i} ) = htpPC.( fn{i} );
            end
            
        end
        
        
    end
end

