function  EEGdata = AB_alg_window_GUI(oldX,threshold,Approach);
%function  EEGdata = AB_alg_window_GUI(oldX,threshold,Approach);



[N,T] = size(oldX); 
if nargin < 3; Approach = 'Total '; end; %25*N; end
if nargin < 2; threshold = 80; end

if strcmp(Approach,'Total')
    LWind = T;
elseif strcmp(Approach,'Window')
    LWind = min([T ,25*N]);
else
    error('Unknown approach parameter');
end

index = 0; m = 0; 
if N > T
    oldX = oldX';
    index = 1;
end
[N,T] = size(oldX); 
 
%======================================================================
% removing the mean value of the input data
%======================================================================
for i = 1:N
    meanValue = nanmean(oldX(i,:));
    oldX(i,:) = oldX(i,:) - meanValue ;
end
%======================================================================
% Removing the artifacts
%======================================================================
X_max = max(max(abs(oldX)));
while X_max > (threshold + 10)
    if LWind == T
        EEGdata =  AB_correct(oldX,threshold);
    else
        EEGdata = zeros(N,T);
        Iin = 1; Ifin = LWind + 1; r = 0.02;
        while 1
            ind = 1;LWind2 = LWind;
            if Iin == 1; ind = 0; end
            if Ifin > T; ind = 2; Ifin = T; LWind2 = Ifin - Iin; end
            W = mywindow(LWind,r,ind,LWind2);
            W = W(:)';
            X = oldX(:,Iin:Ifin -1);
            %     [size(X) size(W)]
            for i = 1:N

                X(i,:) = W.*X(i,:);
            end
            %     [size(EEGdata(:,Iin:Ifin-1)) size(X)]
            EEGdata(:,Iin:Ifin-1) = EEGdata(:,Iin:Ifin-1) + AB_correct(X,threshold);
            if Ifin >= T; break; end
            Iin = Ifin - fix(r*LWind/4) + 1;
            Ifin = Iin + LWind;
            %     [T Ifin]
        end
    end
    X_max = max(max(abs(EEGdata)));
    if X_max > threshold;  oldX = EEGdata;  end
end
if index == 1
%     oldX = oldX';
    EEGdata = EEGdata';
end
% save (mat_file_name,'EEGdata');



%#####################################################################
function EEGdata = AB_correct(X,threshold);
[N,M]=  size(X);
if M > N
    D = find(abs(X) >= threshold);
    Y = X;
    Y(D) = 0 ;
    Rxx = X*X';
    Ryx = Y*X';
    W = Ryx * inv(Rxx);
    EEGdata = W * X;
else
    EEGdata = zeros(N,M);
end


