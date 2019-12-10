%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function [wPos, wCos] = mtlgrad(wPos, cMup, vSeg, nNor, uOff, mOri, mOrd, wCos, vLim, cCos)

NOFF = 3;
VOFF = [-1, 0, 1];
NEPS = 1e-9;

iMid = ceil(size(cMup{1}, 1) / 2);
nLis = size(wPos, 2);
nLon = length(vSeg);
nOri = size(mOri, 1);
bZer = false(nLis * NOFF, 1);

vPos = wPos(end, :);
mWav = zeros(nLis * NOFF, nLon);
for i = 1 : nLis
    for j = 1 : NOFF
        mWav(NOFF * (i - 1) + j, vPos(i) + VOFF(j) + cMup{5, i}) = cMup{1, i}(iMid, :);
    end
end
mWav = mWav / nNor; 

v = -uOff : 2 : uOff; 
w = [uOff : -2 : 0, 2 : 2 : uOff];
n = length(v);
z = 1 : nLis;

bTru = any(cCos{1});
zCos = cCos{1};
zWav = zeros(n, nLon);
wWav = mWav(2 : NOFF : nLis * NOFF, :);
mCos = zeros(n, nLis);
oCos = wCos(end);
nCos = 0;
vOne = ones(n, 1);
vSeg = vSeg / nNor;
mSeg = vSeg(vOne, :);

while (nCos < oCos)

    for j = z

        vWav = wWav(j, :);
        tSup = sum(wWav(z ~= j, :), 1);

        tWav = zWav;
        for i = 1 : n
            k = w(i);
            if v(i) < 0
                tWav(i, 1 : end - k) = vWav(k + 1 : end);
            elseif v(i) > 0
                tWav(i, k + 1 : end) = vWav(1 : end - k);
            else
                tWav(i, :) = vWav;
            end
        end

        mCos(:, j) = sum(abs(mSeg - tSup(vOne, :) - tWav), 2);
        
    end    
        
    nCos = oCos;
    vCos = mCos(:);
    
    while any(vCos < oCos)
        [nCos, jMin] = min(vCos);
        if all(abs(zCos - vCos(jMin)) > NEPS) 
            j = ceil(jMin / n);
            iMin = ceil(rem(jMin - 1e-3, n));
            tPos = vPos(j) + v(iMin);
            nCos = vCos(jMin);
            vCos = Inf;
        else
            nCos = Inf;
            vCos(jMin) = nCos;
        end
    end
    
    if (nCos < oCos) && (tPos > 1) && (tPos < vLim(j))
        
        vPos(j) = tPos;
        oCos = nCos;
        nCos = 0;
        k = w(iMin);
        p = NOFF * (j - 1) + 1 : NOFF * j;
        
        if v(iMin) <= 0
            mWav(p, 1 : end - k) = mWav(p, k + 1 : end);
        else
            mWav(p, k + 1 : end) = mWav(p, 1 : end - k);
        end
        
        wWav(j, :) = mWav(p(2), :);
        wPos(end + 1, :) = vPos;
        wCos(end + 1) = oCos;
        
    else
        nCos = oCos;
    end

end

if bTru && any(abs(zCos - oCos) < NEPS)
    wCos = wCos(:);
    return;
end

mSeg = vSeg(ones(nOri, 1), :);
mSup = zeros(nOri, nLon);
for i = 1 : nOri
    mSup(i, :) = sum(mWav(mOrd(:, i), :), 1);
end

vCos = sum(abs(mSeg - mSup), 2);

oCos = vCos(ceil(nOri / 2));
[nCos, iMin] = min(vCos);

if nCos < oCos - NEPS
    vOri = mOri(iMin, :);
    vPos = vPos + vOri;
    if all(vPos > 1) && all(vPos < vLim)
        wPos(end + 1, :) = vPos;
        wCos(end + 1) = nCos;
        a = 1 : nLon - 1;
        b = 2 : nLon;
    else
        nCos = oCos;
    end
else
    nCos = oCos;
end

while nCos < oCos

    oCos = nCos;
    bWav = bZer;
    
    for i = 1 : nLis
        if vOri(i)
            v = NOFF * (i - 1) + 1 : NOFF * i;
            if (vOri(i) == 1)
                mWav(v, :) = [mWav(v, nLon), mWav(v, a)];
                bWav(NOFF * (i - 1) + NOFF) = true;
            else
                mWav(v, :) = [mWav(v, b), mWav(v, 1)];
                bWav(NOFF * (i - 1) + 1) = true;
            end
        end
    end
 
    v = any(bWav(mOrd));
    for i = 1 : nOri
        if v(i)
            mSup(i, :) = sum(mWav(mOrd(:, i), :), 1);
        end
    end
    
    vCos = sum(abs(mSeg - mSup), 2);
    [nCos, iMin] = min(vCos);
    
    if nCos < oCos
        vOri = mOri(iMin, :);
        vPos = vPos + vOri;
        if all(vPos > 1) && all(vPos < vLim)
            wPos(end + 1, :) = vPos;
            wCos(end + 1) = nCos;
        else
            nCos = oCos;
        end
    else
        nCos = oCos;
    end
    
end

wCos = wCos(:);
