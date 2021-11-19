%EEG = current_convertBipolarMontage( EEG );
EEG_AB = EEG;
Parameters = [];
Parameters.Approach = 'Window';
Parameters.Threshold = 50; % muV
Parameters.Fs = EEG_AB.srate; 
Parameters.WindowSize = 10; % unit in second
Parameters.InData = EEG.data(2,find(~isnan(EEG.data(2,:)))); % data matrix
tic;Parameters = Run_AB(Parameters);toc % quick
% [~,warnID] = lastwarn;
EEG_AB.data = Parameters.OutData;
pop_eegplot(EEG_AB,1,0,0)

%% 
figure
% for i=1:EEG.nbchan
%     subplot(2,3,i);h=histogram(AB_Parameters.InData(i,:),-100:10:150);
%     h.Normalization = 'countdensity';xlabel('amplitude (muV)');ylabel('count');
%     title(EEG.chanlocs(i).labels)
% end

subplot(2,3,1);h=histogram(Parameters.InData(1,:),-100:10:150);
h.Normalization = 'countdensity';xlabel('amplitude (muV)');ylabel('count');
title(EEG.chanlocs(2).labels)