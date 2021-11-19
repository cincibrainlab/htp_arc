function A_detrended = detrend3(A,varargin) 
% detrend3 performs linear least squares detrending along the third dimension
% of a 3D matrix.
% 
%% Syntax
% 
%  A_detrended = detrend3(A) 
%  A_detrended = detrend3(A,t)
% 
%% Description
% 
% A_detrended = detrend3(A) removes the linear trend from the third dimension of A
% assuming slices of A are sampled at constant intervals. 
% 
% A_detrended = detrend3(A,t) specifies times t associated with each slice of A. 
% 
%% Example 
% This sample dataset has a trend of 3.2 units/timestep everywhere: 
% 
%   t = 50:50:1000; 
%   Z = bsxfun(@plus,peaks(5),3.2*permute(t,[1 3 2])); 
% 
% Here's proof via the trend function (on File Exchange): 
% 
%   trend(Z,t,3)
%   ans =
%      3.2000    3.2000    3.2000    3.2000    3.2000
%      3.2000    3.2000    3.2000    3.2000    3.2000
%      3.2000    3.2000    3.2000    3.2000    3.2000
%      3.2000    3.2000    3.2000    3.2000    3.2000
%      3.2000    3.2000    3.2000    3.2000    3.2000
% 
% Now let's detrend: 
% 
%   Z_detrend = detrend3(Z,t); 
% 
% And now what's the trend? 
% 
%   trend(Z_detrend,t,3)
%   ans =
%     1.0e-14 *
%     -0.1695   -0.2144   -0.1437   -0.1630   -0.2332
%     -0.2147   -0.2007   -0.1838   -0.1680   -0.1751
%     -0.1502   -0.2058   -0.1607   -0.1630   -0.1684
%     -0.2139   -0.2044   -0.1958   -0.1958   -0.1695
%     -0.2143   -0.2039   -0.1672   -0.1679   -0.1722
% 
% Just numerical noise (note the 1.0e-14). 
% 
%% Author Info
% This function was written by Chad A. Greene of the University of Texas Institute 
% for Geophysics (UTIG), January 2017. http://www.chadagreene.com 
% 
% See also detrend and polyfit. 

%% Error checks

assert(ndims(A)==3,'Input error: Matrix A must be 3 dimensional.') 
narginchk(1,2) 

%% Set defaults and parse inputs: 

N = size(A,3); % number of samples
t = (1:N)';    % default "time" vector

if nargin>1
   if isnumeric(varargin{1})
      t = squeeze(varargin{1}); 
      assert(isvector(t)==1,'Input error: Time reference vector t must be a vector.') 
   end
end

%% Perform mathematics: 

% Center and scale t to improve fit: 
t = (t(:)-mean(t))/std(t); 

% Reshape A such that each column contains a time series of a pixel: 
Ar = reshape(permute(A,[3 1 2]),size(A,3),[]);

% Detrend Ar by removing least squares trend: 
Ar = Ar - [t ones(N,1)]*([t ones(N,1)]\Ar); 

% Unreshape back to original size of A: 
A_detrended = ipermute(reshape(Ar,[size(A,3) size(A,1) size(A,2)]),[3 1 2]); 

end