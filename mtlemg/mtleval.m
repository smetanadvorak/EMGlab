%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function mDat = mtleval(cMup, mDat, oSeg, iLis, vSur, nSur, mFac)

SMIN = 1/3;

uLis = size(iLis, 2);
lSeg = size(oSeg, 2);
wLis = 1 : uLis;
wSup = zeros(uLis, lSeg);

for i = wLis
    k = iLis(i);
    wSup(i, mDat(1, k) + cMup{5, k}) = cMup{1, k}(mDat(2, k), :);
end

for i = wLis
    k = iLis(i);
    v = mDat(1, k) + cMup{6, k};
    vRem = oSeg(v) - sum(wSup(wLis ~= find(iLis == k), v), 1);
    mDat(3, k) = mtlpc(vRem, cMup{7, k}(mDat(2, k), :), 0, 1, 0);
end

if any(mDat(end, iLis) >= SMIN)
    if uLis > 1
        nIte = 2;
    else
        nIte = 1;
    end
    mDat = mtlrefine(cMup, mDat, wSup, oSeg, iLis, vSur, nSur, nIte);
    mDat(end, iLis) = mDat(end, iLis) .* mFac(iLis);
end

