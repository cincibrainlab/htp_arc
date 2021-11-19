function W = mywindow(N,r,ind,N1);
%function W = mywindow(N,r,ind);
% This function generates tukeywin window of length N and ratio r.
% Based on the value of index, the window can take 3 different shapes. if
% ind = 1, the window is a regular tukeywin window with two tails, while
% ind = 0 (2) generates a tukeywin with the leading (trailing) tail
% truncated, respectively.
if nargin < 4; N1 = N;  end

if ind == 0
    W = tukeywin(N,r);
    W(1:fix(r*N/2)) = 1;
elseif ind == 1
    W = tukeywin(N,r);
elseif ind == 2
    W = ones(1,N1);
    W1 = tukeywin(N,r);
    %W(1:r*N/2) = W1(1:r*N/2);
    W(1:N1) = W1(1:N1);
end
    
