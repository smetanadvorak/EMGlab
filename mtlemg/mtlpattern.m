%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function mPat = mtlpattern(cSit, nPts, nGap, pMin)

KMOY = 1.5;
KSTD = 1.5;
NOFF = 1/4;

nGap = nGap + 1;
nMup = size(cSit, 2);
mPat = false(nMup, nPts);

for i = 1 : nMup

    if size(cSit{i}, 2) >= pMin
        
        vSit = cSit{i}(1, :);
        nMin = min(vSit);
        vIdi = diff(sort(vSit));
        wIdi = vIdi(vIdi < KMOY * mean(vIdi));
        nMoy = median(wIdi);
        wIdi = vIdi(vIdi < KMOY * mean(vIdi));
        nStd = std(wIdi);
        vGap = round(vIdi / nMoy - NOFF);

        vMis = [];
        for j = find(vGap > 1 & vGap <= nGap)
            a = ones(1, vGap(j)) * floor(vIdi(j) / (vGap(j)));
            n = length(a);
            a = [vIdi(j) - sum(a(2 : n)), a(2 : n)];
            a = sum(vIdi(1 : j - 1)) + cumsum(a(1 : n - 1)) + nMin;
            vMis = [vMis, a];
        end

        v = round(KSTD * nStd);
        vMis = vMis(vMis > v & vMis < (nPts - v));
        v = -v : v;
        for j = 1 : length(vMis)
            mPat(i, vMis(j) + v) = true;
        end

    end
    
end
