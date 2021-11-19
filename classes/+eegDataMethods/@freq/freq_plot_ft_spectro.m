function o = freq_plot_ft_spectro( o )

channelSpectrum( o );

end
function o = channelSpectrum( o )

chanArr = o.ftcfg.freqFTplot.chanArr;

figure;
hold on;

for i = 1 : length( o.ftcfg.freqFToutput.datFreq )
    datFreq = o.ftcfg.freqFToutput.datFreq{i};
    
    tmpPow = mean(datFreq.powspctrm( chanArr, : ),1);
    
    plot( datFreq.freq,tmpPow);
end

legend('1 sec window','2 sec window','4 sec window')
xlabel('Frequency (Hz)');
ylabel('absolute power (uV^2)');


end
