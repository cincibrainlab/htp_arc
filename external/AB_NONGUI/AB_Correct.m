function EEGdata = AB_Correct(X,threshold)
% reference:
% Mourad 2007. A simple and fast algorithm for automatic suppression of
% high-amplitude artifacts in EEG data. 
%
% minimize the mean square error of Y-WX, where
% Y - target, W - smoothing mat (channel specific time weights)
% 
% J(W) = (Y-WX)' * (Y-WX)
% dJ(W)/dW = -2X' * (Y-WX) = 0 
% W = (XX')(YX')
% 
% X - input nbchan x time (default by outer function)
    D = find(abs(X) >= threshold);
    Y = X;
    Y(D) = 0 ; % reference mat
    Rxx = X*X';
    Ryx = Y*X';
    W = Ryx * inv(Rxx); % smoothing mat
    EEGdata = W * X; % smoothed output

end