%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function vOut = mexpc(x, y, X, r, s)

vOut = zeros(size(r));

if size(x, 2) > 1
    x = x(:);
end
if size(y, 2) > 1
    y = y(:);
end

if length(x) > length(y)
    t = x;
    x = y;
    y = t;
end
    
X = abs(x);

nx = length(x);
ny = length(y);
nr = length(r);
nn = ny - nx + 1;

vx = 0 : (nx - 1);

t = s * sum(x .^ 2);

for i = 1 : nr
    
    j = r(i);
    
    if j <= nn
        a = x;
        A = X;
        b = y(j + vx);
    else
        wx = 1 : ny - j;
        a = x(wx);
        A = abs(a);
        b = y(j + wx);
    end
    
    m = max(A, abs(b));
    c = sum(a .* b - abs(a - b) .* m);
    
    if c > t
        vOut(i) = c / sum(m .* m);
    end
    
end
