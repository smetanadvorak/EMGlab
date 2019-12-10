%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function mSeg = mtlsegment(vSig, t, w, n, f)

vSeg = find(mtlseg(vSig, t, floor(w / 2)));

nSeg = length(vSeg);

if rem(nSeg, 2) == 0
    mSeg = reshape(vSeg, 2, nSeg/2)';
else
    vSeg(nSeg + 1) = length(vSig);
    mSeg = reshape(vSeg, 2, (nSeg + 1) / 2)';
end

d = diff(mSeg, [], 2);
b = (d >= n);

if exist('f', 'var')
    u = f * t;
    p = (d > (n / 4)) & (d < n);
    t = find(p);
    for i = 1 : length(t)
        k = t(i);
        v = vSig(mSeg(k, 1) : mSeg(k, 2));
        if max(v) - min(v) > u
            b(k) = true;
        end
    end
end

mSeg = mSeg(b, :);


