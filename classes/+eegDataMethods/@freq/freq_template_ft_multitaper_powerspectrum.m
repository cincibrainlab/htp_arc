 function o = freq_template_ft_multitaper_powerspectrum( o )
            
            o.freq_prepare_set2fieldtrip;
            o.freq_utility_ft_save;
            o.freq_utility_ft_unload('datPre');
           
            o.freq_utility_ft_load_dat;
            o.freq_calc_ft_multitap_pow;
            o.freq_utility_ft_setChanArr( 1:o.net_nbchan_orig );
            o.freq_plot_ft_spectro;
            o.freq_utility_ft_unload('datSeg');
            
            o.freq_utility_ft_save;
            
        end