 function obj = generateStoreRoom( obj )

            EEG = obj.EEG; 
            dat = EEG.data;
            data = permute(dat, [2, 1, 3]); % pnts*nchan*trials(nseg)
            datap = permute(data, [1, 3, 2]); % pnts*trials(nseg)*nchan
            %datap = gpuArray(datap);
            
%             
%             if size(datap, 1) == EEG.pnts
%                 complex = zeros(size(datap));
%                 for chani=1:EEG.nbchan
%                     for triali=1:EEG.trials
%                         datapd = detrend(datap(:, triali, chani)); % detrend
%                         complex(:, triali, chani) = fft(datapd.*hann(length(datapd)));
%                     end
%                 end
%             else
%                 obj.msgout('ERROR: Wrong dimension for FFT.', 'step_warning');
%             end
            
            datapd = detrend3( datap );
            complex = zeros(size(datap));
            complex = fft( datap .* hann(length(datapd)));

            
            % absolute & normalized power
            EEG.abs_power = 2*abs(complex(1:EEG.pnts/2,:,:)).^2/(EEG.pnts*EEG.srate); % uV^2/Hz
            % normalization #1
%             EEG.phase = angle(complex(1:EEG.pnts/2,:,:));

            pnt = obj.pntsTable;n = size(pnt,1);
            intervals = []; 
            for k = 1:n
                intervals = [intervals, pnt(k,1):pnt(k,2)];
            end
            freq = obj.freqTable;
            EEG.rel_power = NaN*ones(size(EEG.abs_power));EEG.rel_power = EEG.rel_power(1:pnt(end,2),:,:);
            for i = 1:EEG.nbchan
                for j = 1:EEG.trials 

%                     EEG.rel_power_sum(1:EEG.srate/2+1, j, i) = EEG.abs_power(1:EEG.srate/2+1, j, i)./ ...
%                         sum(EEG.abs_power(1:EEG.srate/2+1, j, i)); % Jeste & Jun's
% relative power from here:
                    EEG.rel_power_sum(:, j, i) = EEG.abs_power(1:pnt(end,2), j, i)./ ...
                        sum(EEG.abs_power(intervals,j,i)); % align with rui_localpipeline
%                     EEG.rel_power_sum(:, j, i) = EEG.abs_power(intervals, j, i)./ ...
%                         sum(EEG.abs_power(intervals,j,i)); %11/08 not consistent with bandAverage
%                         sum(EEG.abs_power([ pnt(1,1):pnt(1,2),...
%                                             pnt(2,1):pnt(2,2),...
%                                             pnt(3,1):pnt(3,2),...
%                                             pnt(4,1):pnt(4,2),...
%                                             pnt(5,1):pnt(5,2)], j, i)); 
%                                             pnt(5,1):pnt(5,2),...
%                                             pnt(6,1):pnt(6,2)], j, i)); 
%                                             pnt(6,1):pnt(6,2),...
%                                             pnt(7,1):pnt(7,2),...
%                                             pnt(8,1):pnt(8,2),...
%                                             pnt(9,1):pnt(9,2)], j, i)); 
                    % denominator: sum over target frequency bands
                    
                end
            end
            
%             cross_spectrum = NaN(EEG.trials, EEG.nbchan, EEG.nbchan, EEG.srate+1);
%             for k = 1:5%EEG.trials
%                 for i = 1:EEG.nbchan
%                     for j = 1:EEG.nbchan
%                         cross_spectrum(k, i, j, :) = cpsd(datap(:,k,i),datap(:,k,j), ...
%                             hann(1000),[],1000);
%                         
%                     end
%                 end
%             end
%             pli(i, j, :) = abs(squeeze(mean(sign(imag(cross_spectrum(:,:,:,1:161))))));
            
%             obj.rest_abs_power = 10*log10(EEG.abs_power); % save as dB
            obj.rest_abs_power = EEG.abs_power; % save as uV^2/Hz
%             obj.rest_fft_phase = EEG.phase;
            obj.rest_abs_hz = linspace(0, EEG.srate/2, EEG.pnts/2+1);
            obj.rest_rel_power = EEG.rel_power_sum;
            obj.rest_rel_hz = linspace(0, freq(end,2), pnt(end,2));
%             obj.rest_cpsd_pli = pli;
            
        end
        
       