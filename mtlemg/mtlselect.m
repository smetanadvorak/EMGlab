%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function [bThr, iTri] = mtlselect(cMup, vThr) 

[tmp, nMup, nCan] = size(cMup);
wThr = vThr(ones(nMup, 1), :);
mAmp = abs(reshape([cMup{6, :, :}], 2, nCan * nMup));
[tmp, iTri] = sort(sum(mAmp, 1) ./ wThr(:).', 2, 'descend');

mTmp = vThr(ones(nMup, 1), :);
mTmp = mTmp(:).';
mTmp = mTmp(ones(2, 1), :);
bTmp = reshape(all(mAmp > mTmp, 1), nMup, nCan);
bThr = bTmp.';

bAny = any(bThr, 1);
if ~all(bAny)
    mAmp = reshape(sum(mAmp, 1), nMup, nCan).';
    for iMup = find(~bAny)
        [tmp, iCan] = max(mAmp(:, iMup));
        bThr(iCan, iMup) = true;
    end
end

if nargout > 1
    bTmp = bTmp(:).';
    iTri = iTri(bTmp(iTri));
end
