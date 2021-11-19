function o = freq_calc_ft_multitap_pow( o )

if  o.ftcfg.freqFTconfig.Avail.datPre
    
    segArr = [1, 2, 4];
    
    epochTrial( o, segArr );
    
    o.freq_utility_ft_unload('datPre');

    
    freqPow( o );
    
else
    try
        o.loadDataFT;
        o.msgout('FT Data loaded from disk.', 'step_complete');        
    catch
        o.msgout('FT Data unavailable. Use prepareDataFT.', 'step_complete');  
    end
end


end

function o = epochTrial( o, segArr )

% segArr: matrix of epoch length in seconds

segn = length( segArr );

datseg = {};

for i = 1 : segn
    
    cfg = [];
    cfg.length = segArr( i );
    cfg.overlap = 0;
    
    datseg{i} = ft_redefinetrial(cfg, o.ftcfg.freqFTdat.datPre);
    
end

    o.ftcfg.freqFTdat.datSeg = datseg;
    o.ftcfg.freqFTconfig.Avail.datSeg = true;
    
    datseg = {};
    
    
end

function o = freqPow( o )

cfg = [];
cfg.output = 'pow'; %'fourier';
cfg.channel = 'all';
cfg.method = 'mtmfft';
cfg.taper = 'boxcar';
cfg.pad='nextpow2';
%cfg.keeptrials ='yes';

foi1 = 0.5:1:45;
foi2 = 0.5:0.5:45;
foi3 = 0.5:0.25:45;

foiArr = {foi1, foi2, foi3};

datFreq = cell(1, length( foiArr ));

for i = 1 : length( foiArr )
    
    cfg.foi = foiArr{i};
    
    datFreq{i} = ft_freqanalysis(cfg, o.ftcfg.freqFTdat.datSeg{i});
    
end

o.ftcfg.freqFToutput.datFreq = datFreq;

end