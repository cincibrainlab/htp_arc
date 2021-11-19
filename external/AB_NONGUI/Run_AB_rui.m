function Parameters = Run_AB_rui(Parameters)
% Reference:
% Fujioka 2011. Comparison of artifact correction methods for infant EEG
% applied to extraction of event-related potential signals. Appendix B.
% Artifact Blocking algorithm.

    AB_Parameters = Parameters;
    threshold = AB_Parameters.Threshold;
    [N,T] = size(AB_Parameters.InData);        
    
    % removing DC offset (minor)
    AB_Parameters.InData = AB_Parameters.InData - ...
        mean(AB_Parameters.InData,2);

    % AB denoising (high amplitude)
    if strcmp(AB_Parameters.Approach,'Total')
        AB_Parameters.OutData = AB_Correct( AB_Parameters.InData, str2num(threshold) );
%         [~,warnID] = lastwarn;
    elseif strcmp(AB_Parameters.Approach,'Window')
        LWind = min([T , str2num(AB_Parameters.WindowSize)*AB_Parameters.Fs]);
        AB_Parameters.OutData = zeros(N,T);
        
        Iin = 1; 
        Ifin = LWind + 1; 
        r = 0.02; % ratio - nearly rectangular window
        while 1 % until the next Ifin >= T (line 46)
            ind = 1; % default window type
            LWind2 = LWind; % for common use line 37
            if Iin == 1
                ind = 0; % 1st window
            end
            if Ifin > T
                ind = 2; 
                Ifin = T; 
                LWind2 = Ifin - Iin; 
            end
            W = mywindow(LWind,r,ind,LWind2); % column vector
            % truncate in
            X = AB_Parameters.InData(:, Iin:Ifin-1);
            if (size(W,1)>1)
                Xwind = repmat(W',N,1).*X;
            else
                Xwind = repmat(W,N,1).*X;
            end
            % truncate out
            AB_Parameters.OutData(:,Iin:Ifin-1) = ...
                AB_Parameters.OutData(:,Iin:Ifin-1) + ... % overlapping windows
                AB_Correct(Xwind,str2num(threshold)); % current window correction

            if Ifin >= T, break; end
            % overlap period: fix(r*LWind/4)
            Iin = Ifin + 1 - fix(r*LWind/2); % e.g. 5097/10193/15289
            Ifin = Iin + LWind; % e.g. 10217/15313/20409
        end
    else
        error('Unknown approach parameter');
    end
    Parameters.OutData = AB_Parameters.OutData;
end