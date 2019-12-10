function y = interp (x, r)
% Interp function for those without signal toolbox

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

x = x(:).'; 
t = [-1 : length(x)]; 
p = 1/r;
t1 = [0: p : (length(x) - p)]; 
y = spline(t, [0, 0, x, 0, 0], t1); 
