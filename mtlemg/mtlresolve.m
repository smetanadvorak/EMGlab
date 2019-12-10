%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function vSit = mtlresolve(vSig, oMup, nRat)

VSIM = [.8 .7 .4];
NEPS = 1e-6;
NSUR = 10;
NEFF = 10;
MMIN = 2;
HOFF = [-1 0 1];
NOFF = 3;
KPAR = 2/3; 
NRUM = 3;
SMIN = NEPS;
NROW = 2;
HROW = 1 : NROW;
MFAC = 1.25;

vSig = vSig(:).';

if ~iscell(oMup)
    mMup = oMup;
    [n, m] = size(mMup);
    if n > m
        mMup = mMup.';
        n = m;
    end
    oMup = cell(1, n);
    for i = 1 : n
        oMup{i} = mMup(i, :);
    end
end

if ~exist('nRat', 'var')
    nRat = 10e3;
else
    nRat = round(nRat);
end

nMup = size(oMup, 2);

vDel = -(0 : (NSUR - 1)) * 1 / NSUR;
vSur = ones(NSUR, 1);

nSec = round(nRat / 1000);
if rem(nSec, 2)
    nSec = nSec + 1;
end
iMid = ceil(NSUR / 2);

if nMup > 1
    sCur = VSIM(1);
else
    sCur = VSIM(end);
end

sMin = VSIM(end);

vSit = NaN * ones(1, nMup); 

oCor = zeros(1, nMup);
zCor = zeros(2, nMup);
zDat = zeros(3, nMup);

u = mean(abs(vSig));
n = round(nRat / 1000);
m = mtlsegment(vSig, u, n, n);
b = true(size(vSig));
for i = 1 : size(m, 1)
    b(m(i, 1) : m(i, 2)) = false;
end

if any(b)
    vTmp = vSig(b);
    vTmp = vTmp(vTmp ~= 0);
else
    vTmp = u;
end
    
uThr = mean(abs(vTmp));
nThr = NRUM * uThr;
vUth = zeros(1, nMup);
vDth = vUth;

nBuf = 0;

vOne = ones(1, length([oMup{:}]));
vOne(2 : 2 : end) = -1;
vOne = vOne / 2;

cMup = cell(8, nMup);
vLon = zeros(1, nMup);
vPic = vLon;
mFac = vLon;

mPic = zeros(2, nMup);
wPic = mPic;
mPar = mPic;
mIzq = mPic;
mDer = mPic;

for i = 1 : nMup
    
    v = oMup{i}(:).';
    n = size(v, 2);
    m = reshape(interp(v, NSUR), NSUR, n);
    v = m(iMid, :);
        
    [x, ix] = max(v);
    [w, iw] = min(v);

    t = min(nThr, min(x, -w) / 2);
    r = mtlshrink(v, NEFF, nSec, nSec, t); 
    u = length(r);

    vIzq = r(1) : min(r(1) + ceil(KPAR * u) - 1, r(u));
    vDer = max(r(u) - ceil(KPAR * u) + 1, r(1)) : r(u);
        
    a = v(r);
    b = a + uThr * vOne(1 : u);
    x = max(abs(a), abs(b));
    f = sum(x .^ 2, 2) ./ sum(b .* a - abs(a - b) .* x, 2);
        
    cMup{1, i} = m;
    cMup{2, i} = r;
    cMup{3, i} = vIzq;
    cMup{4, i} = vDer;
    cMup{5, i} = 0 : (n - 1);
    cMup{6, i} = r - 1;
    cMup{7, i} = m(:, r);
    cMup{8, i} = abs(m(:, r));
    cMup{9, i} = v(cMup{3, i}); 
    cMup{10, i} = v(cMup{4, i}); 
    
    nBuf = max(nBuf, n);
    vLon(i) = n;
    [tmp, vPic(i)] = max(abs(v));
    
    vUth(i) = max(v);
    vDth(i) = -min(v);
    
    mFac(i) = f;
    
    mPic(:, i) = [ix; iw];
    wPic(:, i) = [ix; iw] - r(1);
    mIzq(:, i) = [ix; iw] - vIzq(1);
    mDer(:, i) = [ix; iw] - vDer(1);
    mPar(:, i) = [vIzq(1); vDer(1)];
    
end

mFac = min(mFac, MFAC);
wFac = ones(size(mFac));

nUth = max(nThr, .25 * min(vUth));
nDth = max(nThr, .25 * min(vDth));

mPic = mPic - 1;

cOri = cell(1, nMup);
cOrd = cell(1, nMup);
for i = MMIN : nMup
    mOri = mtld2t((0 : 3 ^ i - 1)', i) - 1;
    mOrd = zeros(size(mOri)); 
    for j = 1 : i
        for k = 1 : NOFF
            mOrd(mOri(:, j) == HOFF(k), j) = NOFF * (j - 1) + k;
        end
    end
    cOri{i} = mOri;
    cOrd{i} = int8(mOrd');
end

vBuf = zeros(1, nBuf);
lSig = length(vSig);
vSig = [vBuf, vSig, vBuf];

sBeg = 2;
sEnd = length(vSig) - 1;
lSeg = sEnd - sBeg + 1;  
oSeg = vSig(sBeg : sEnd);
vSeg = oSeg;

iRan = (nBuf + 1) : (nBuf + lSig);
jRan = iRan(1);
kRan = iRan(end);

pLis = true(1, nMup);
bLis = pLis;
oLis = 1 : nMup;

bDif = nMup > 1;
bGen = true;

cGen = cell(1, 1);

mDat = zDat;
xDat = zDat;

iMax = find(mtlloc(vSeg(iRan), 0, nUth)) + jRan - 1; 
iMax = iMax(iMax > jRan & iMax < kRan);
oMax = iMax;
iMin = find(mtlloc(-vSeg(iRan), 0, nDth)) + jRan - 1;
iMin = iMin(iMin > jRan & iMin < kRan);
oMin = iMin;

mDat = mtlpartial(mDat, vSeg, cMup, bLis, zCor, iMin, iMax, ...
    mPar, mIzq, mDer, vSur, iRan, jRan, kRan, nUth, nDth);

iLis = find(mDat(1, :));
if any(iLis)
    [xDat, cGen] = mtlReval(cMup, mDat, oSeg, iLis, cGen, vSur, NSUR, lSeg, sMin, wFac);
    if all(xDat(end, iLis) >= sCur)
        bDif = false;
    else
        vLis = zeros(1, nMup);
        vLis(iLis) = xDat(1, iLis);
        cGen{1} = vLis;
    end
end

if bDif 

    iLis = find(xDat(1, :));
    if any(iLis)
        nDat = max(xDat(end, iLis));
    else
        nDat = 0;
    end
    
    vLis = oLis; 
    uLis = length(vLis);
    sCor = 0;

    iMax = oMax; 
    iMin = oMin;
   
    nIni = length([iMax, iMin]);
    mIni = zeros(uLis, nIni);
    iMxx = mIni;

    for i = 1 : uLis
        k = vLis(i);
        v = [iMax - wPic(1, k), iMin - wPic(2, k)];
        mIni(i, :) = mtlcor(cMup{7, k}(iMid, :), oSeg, v);
        iMxx(i, :) = [iMax - mPic(1, k), iMin - mPic(2, k)];
    end

    v = reshape(vLis(ones(nIni, 1), :), uLis * nIni, 1);
    w = reshape(iMxx', uLis * nIni, 1);
    x = reshape(mIni', uLis * nIni, 1);

    mIni = [v, w, floor(x)];
    [tmp, iBon] = mtlunique(-mIni(:, end));  
    mIni = mIni(iBon, :);
    
    iIni = 0;
    nIni = size(mIni, 1);

    while (iIni < nIni)

        iIni = iIni + 1;
        k = mIni(iIni, 1);

        bLis = pLis;
        bLis(k) = false;

        v = mIni(iIni, 2) + cMup{5, k};
        w = v;

        vSeg = oSeg;
        vSeg(v) = vSeg(v) - cMup{1, k}(iMid, :);

        mDat = zDat;
        mDat(HROW, k) = [mIni(iIni, 2); iMid];

        while any(bLis)

            vCor = oCor; 
            vPos = oCor;

            wSeg = vSeg(w);

            iMax = find(mtlloc(wSeg, 0, nUth)) + w(1) - 1; 
            iMax = iMax(iMax > jRan & iMax < kRan);
            iMin = find(mtlloc(-wSeg, 0, nDth)) + w(1) - 1;
            iMin = iMin(iMin > jRan & iMin < kRan);

            if any(iMax) && any(iMin) 

                vSEG = abs(vSeg);

                for k = find(bLis)
                    d = [iMax - wPic(1, k), iMin - wPic(2, k)];
                    v = [iMax - mPic(1, k), iMin - mPic(2, k)];
                    [vCor(k), y] = max(mtlpc(vSeg, cMup{7, k}(iMid, :), vSEG, d, SMIN));
                    vPos(k) = v(y);
                end

            end

            if any(vCor > sCor)

                [tmp, k] = max(vCor);
                d = vPos(k);

                bLis(k) = false;

                v = d + cMup{5, k};

                vSeg(v) = vSeg(v) - cMup{1, k}(iMid, :);
                mDat(HROW, k) = [d; iMid]; 

                w = min(v(1), w(1)) : max(v(end), w(end));

            else    
                bLis(:) = false;    
            end

        end

        iLis = find(mDat(1, :));
        if length(iLis) > 1
            [mDat, cGen] = mtlReval(cMup, mDat, oSeg, iLis, cGen, vSur, NSUR, lSeg, sMin, wFac);            
            if all(mDat(end, iLis) >= sCur)
                xDat = mDat;
                iIni = Inf;
                bGen = false;
            else
                uDat = max(mDat(end, iLis));
                if uDat > nDat
                    xDat = mDat;
                    nDat = uDat;
                end
            end
        end

    end

    if bGen && (nMup > 1)
        
        if isempty(cGen{1})
            mGen = [];
        else
            mGen = cGen{1};
            mGen = mGen(sum(mGen > 0, 2) > 1, :);
        end
        
        sCur = VSIM(2);
        
        xDat = mtlga(cMup, oLis, oSeg, mGen, wFac, ...
            vLon, cOri, cOrd, jRan, kRan, nUth, nDth, sCur, sMin, nSec);
        
        xDat(end, :) = xDat(end, :) .* mFac;
        
    end
    
end

mDat = zDat;
iLis = find(xDat(end, :) >= sMin);

if bDif && any(iLis) && (length(iLis) ~= nMup)
    
    vSeg = oSeg;
    bLis = pLis;
    
    mDat([1 2], iLis) = xDat([1 2], iLis);
    for i = 1 : length(iLis)
        k = iLis(i);
        v = mDat(1, k) + cMup{5, k};
        vSeg(v) = vSeg(v) - cMup{1, k}(mDat(2, k), :);
        bLis(k) = false;
    end

    iMax = find(mtlloc(vSeg(iRan), 0, nUth)) + jRan - 1; 
    if isempty(iMax)
        [tmp, iMax] = max(vSeg(iRan));
        iMax = iMax + jRan - 1;
    end
    iMax = iMax(iMax > jRan & iMax < kRan);
    
    iMin = find(mtlloc(-vSeg(iRan), 0, nDth)) + jRan - 1;
    if isempty(iMin)
        [tmp, iMin] = max(vSeg(iRan));
        iMin = iMin + jRan - 1;
    end
    iMin = iMin(iMin > jRan & iMin < kRan);
    
    mDat = mtlpartial(mDat, vSeg, cMup, bLis, zCor, iMin, iMax, ...
        mPar, mIzq, mDer, vSur, iRan, jRan, kRan, nUth, nDth);
    
    jLis = find(mDat(1, :));
    mDat = mtlReval(cMup, mDat, oSeg, jLis, cGen, vSur, NSUR, lSeg, sMin, mFac);
    
    jLis = find(mDat(end, :) >= sMin);
    if length(jLis) >= length(iLis)
        xDat = zDat;
        xDat(:, jLis) = mDat(:, jLis);
    end
    
elseif isempty(iLis)
    
    iMax = oMax;
    iMin = oMin;
    vSeg = oSeg;
    pLis = pLis;
    sCur = VSIM(end);
    
    xDat = mtlpartial(mDat, vSeg, cMup, bLis, zCor, iMin, iMax, ...
        mPar, mIzq, mDer, vSur, iRan, jRan, kRan, nUth, nDth);

    iLis = find(xDat(1, :));
    if any(iLis)
        xDat = mtlReval(cMup, xDat, oSeg, iLis, cGen, vSur, NSUR, lSeg, sMin, wFac);
    end

end    

iLis = find(xDat(end, :) >= sMin);
if any(iLis)
    vSit(iLis) = xDat(1, iLis) + vDel(xDat(2, iLis)) - nBuf;
end

function [mDat, cGen] = mtlReval(cMup, mDat, oSeg, iLis, cGen, vSur, nSur, lSeg, sMin, mFac)

NEPS = 1e-6;

uLis = length(iLis);
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
    mDat(3, k) = mtlpc(vRem, cMup{7, k}(mDat(2, k), :), 0, 1, NEPS); 
end

cGen{1}(end + 1, :) = mDat(1, :);

if any(mDat(end, iLis) > NEPS)
    mDat = mtlrefine(cMup, mDat, wSup, oSeg, iLis, vSur, nSur, min(uLis, 2));
    mDat(end, iLis) = mDat(end, iLis) .* mFac(iLis);
end


function mDat = mtlpartial(mDat, vSeg, cMup, bLis, zCor, iMin, iMax, ...
    mPar, mIzq, mDer, vSur, iRan, jRan, kRan, nUth, nDth)   

NEPS = 1e-6;
SMIN = NEPS;
NROW = 2;
HROW = 1 : NROW;

while any(bLis) 

    mCor = zCor; 
    mPos = zCor;

    if any(iMin) && any(iMax)

        vSEG = abs(vSeg);

        for i = find(bLis) 
            d = [iMax - mIzq(1, i), iMin - mIzq(2, i)];
            [mCor(1, i), y] = max(mtlpc(vSeg, cMup{9, i}, vSEG, d, SMIN));
            mPos(1, i) = d(y) - mPar(1, i); 
            d = [iMax - mDer(1, i), iMin - mDer(2, i)];
            [mCor(2, i), y] = max(mtlpc(vSeg, cMup{10, i}, vSEG, d, SMIN));
            mPos(2, i) = d(y) - mPar(2, i);
        end

    end

    if any(mCor(:) > SMIN)

        if any(all(mCor) & (diff(mPos) == 0))
            wCor = mCor;
            wCor(:, diff(mPos) ~= 0) = 0;
            [tmp, k] = max(max(wCor));
            d = mPos(1, k) + 1;
        else
            [tmp, y] = max(mCor(:));
            k = ceil((y - NEPS) / NROW);
            d = mPos(ceil(mod(y, NROW + NEPS)), k) + 1;
        end

        v = d + cMup{5, k};
        r = v(cMup{2, k});

        [tmp, iBon] = max(sum(vSeg(vSur, r) .* cMup{7, k}, 2)); 

        vSeg(v) = vSeg(v) - cMup{1, k}(iBon, :);
        mDat(HROW, k) = [d; iBon]; 

        iMax = find(mtlloc(vSeg(iRan), 0, nUth));
        iMax = iMax + jRan - 1; 
        iMax = iMax(iMax > jRan & iMax < kRan);
        iMin = find(mtlloc(-vSeg(iRan), 0, nDth));
        iMin = iMin + jRan - 1;
        iMin = iMin(iMin > jRan & iMin < kRan);

        bLis(k) = false;

    else
        bLis(:) = false;
    end

end
