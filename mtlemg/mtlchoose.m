%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function iInd = mtlchoose(iInd, vCmp, nRef)

vDif = diff(iInd);
iFin = find(vDif < nRef);

while any(iFin)
    bSit = true(size(iInd));
    iSit = [iFin; iFin + 1];
    [tmp, x] = min(vCmp(iSit));
    bSit(iSit(x + 2 * (0 : size(iSit, 2) - 1))) = false;
    iInd = iInd(bSit);
    vCmp = vCmp(bSit);
    vDif = diff(iInd);
    iFin = find(vDif < nRef);
end
