%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function vThr = mtlthresh(mSig, nRat) 

nSec = ceil(nRat / 1000);
[nCan, nPts] = size(mSig);

for i = 1 : nCan
    n = round(min(nPts, nRat));
    v = mSig(i, 1 : n);
    u = mean(abs(mSig(i, :)));
    m = mtlsegment(v, u, nSec, nSec);
    b = true(1, n);
    for j = 1 : size(m, 1)
        b(m(j, 1) : m(j, 2)) = false;
    end
    vThr(i) = mean(abs(v(b)));
end
