%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function cSit = mtlidentify(mSig, oMup, nRat, mPsC, bGen)

if isempty(oMup)
    cSit = [];
    return;
end

NREF = 40; 
NEFF = 10;
FNOR = 1/3;
KPAR = 2/3;
NPAT = 6;
NRUM = 3;
NRUN = 5;
LLIM = .5;
ULIM = 2;
FMAX = 1.25;
FENG = 2;
IRAT = 100e3;

SBEG = [.8 .7 .6 .5];
SEND = .4;

[nCan, nMup] = size(oMup);

bCan = nCan > 1;

cMup = cell(9, nMup, nCan);
cSit = cell(nCan, nMup);

nPts = length(mSig);
if size(mSig, 1) == nPts
    mSig = mSig.';
end

if ~exist('bGen', 'var')
    bGen = false;
end
if bGen
    nLev = 3;
else
    nLev = 2;
end

if size(oMup{1}, 1) > 1
    for i = 1 : nMup
        for j = 1 : nCan
            oMup{j, i} = oMup{j, i}.';
        end
    end
end

nSur = min(max(ceil(IRAT / nRat), 3), 10);
vDel = -(0 : (nSur - 1)) * 1 / nSur;

iMid = ceil(nSur / 2);
nRat = round(nRat);
nSec = round(nRat / 1000);
if rem(nSec, 2)
    nSec = nSec + 1;
end
nJit = round(nSec / 2);

vLis = 1 : nMup;
vThr = zeros(1, nCan);
vLon = zeros(1, nMup);
zCrs = zeros(nMup, 1);
zMup = zeros(1, 5 * nSec);

vOne = ones(1, size([oMup{1, :}], 2));
vOne(2 : 2 : end) = -1;

vThr = mtlthresh(mSig, nRat);
wThr = NRUM * vThr;
mFac = ones(nCan, nMup);
mNor = mFac;

if ~exist('mPsC', 'var')
    mPsC = mFac;
else
    bZer = (mPsC == 0);
    mPsC = min(mPsC / SBEG(1), 1);
    mPsC(bZer) = 1;
    mPsC = min(1 ./ mPsC, FMAX);
    mPsC(bZer) = 1;
end

for i = vLis

    for j = 1 : nCan

        v = oMup{j, i};
        n = size(v, 2);
        m = reshape(interp(v, nSur), nSur, n);
        v = m(iMid, :);

        [x, ix] = max(v);
        [w, iw] = min(v);

        if x > -w
            p = ix;
        else
            p = iw;
        end
        
        t = min(wThr(j), min(x, -w) / 2);
        r = mtlshrink(v, NEFF, nSec, nSec, t, 3);
        u = length(r);

        g = r(1) : min(r(1) + ceil(KPAR * u) - 1, r(u));
        h = max(r(u) - ceil(KPAR * u) + 1, r(1)) : r(u);
        
        a = v(r);
        b = a + vThr(j) * .25 * vOne(1 : u);
        y = max(abs(a), abs(b));
        f = min(max(sum(y .^ 2, 2) ./ sum(b .* a - abs(a - b) .* y, 2)), FMAX);
        c = zCrs;
        
        if bCan
            mFac(j, i) = f;
            mNor(j, i) = norm(v) / vThr(j);
            if all([x, -w] >= wThr(j))
                vMup = v(r);
                nExt = v(p);
                for iMup = vLis(vLis ~= i)
                    wMup = [zMup, oMup{j, iMup}, zMup];
                    if nExt > 0
                        iAbs = find(wMup >= LLIM * nExt & wMup <= ULIM * nExt);
                    else
                        iAbs = find(wMup <= LLIM * nExt & wMup >= ULIM * nExt);
                    end
                    iAbs = iAbs - (p - r(1));
                    iAbs = iAbs(iAbs > 0);
                    if any(iAbs)
                        c(iMup) = max(mtlpc(vMup, wMup, abs(wMup), iAbs, 0));
                    end
                end
            end
        end
        
        cMup{1, i, j} = m;
        cMup{2, i, j} = r;
        cMup{3, i, j} = g;
        cMup{4, i, j} = h;
        cMup{5, i, j} = [ix, iw];
        cMup{6, i, j} = v([ix, iw]);
        cMup{7, i, j} = p;
        cMup{8, i, j} = f; 
        cMup{9, i, j} = c;

    end

    vLon(i) = n;

end

if bCan
    
    mFac(mFac < 1) = FMAX;
    mAll = max(mFac, mPsC);
    
    vNor = max(mNor, [], 1);
    mNor = mNor ./ vNor(ones(nCan, 1), :);
    
    for i = vLis
        for j = 1 : nCan
            fMin = SEND / cMup{8, i, j};
            if mNor(j, i) > FNOR
                if all(cMup{9, i, j} < fMin)
                    cMup{8, i, j} = mAll(j, i);
                else
                    cMup{8, i, j} = 1;
                end
            else
                cMup{8, i, j} = 1;
                cMup{9, i, j}(i) = 1;
            end
        end
    end
    
else
    
    for i = vLis
        for j = 1 : nCan
            cMup{8, i, j} = max(cMup{8, i, j}, mPsC(j, i));
        end
    end
    
end

nBuf = round(1.5 * max(vLon));
mSig = [zeros(nCan, nBuf), mSig, zeros(nCan, nBuf)];
vRef = NREF * nSec * ones(1, nMup);
pMin = NPAT * round(nPts / nRat);

cFlg = [];
mNew = [];
    
if bCan
    
    cRun = 0;
    nSit = Inf;
    
    while (nSit ~= length([cSit{:}])) && cRun < NRUN
        cRun = cRun + 1;
        nSit = length([cSit{:}]);
        [cSit, mSig, mNew, cFlg, vRef] = ...
            mtltrack(mSig, cSit, cMup, SBEG([1 end]), nRat, vRef, wThr, nJit, 0, cFlg, mNew, []);
    end

    [cSit, mSig, mNew, cFlg] = ...
        mtlmatch(mSig, cSit, cMup, SBEG(2 : end), vRef, wThr, nSec, nJit, mNew, cFlg, nLev);
    
    [cSit, mSig, mNew, cFlg] = ...
        mtltrack(mSig, cSit, cMup, SBEG(end), nRat, vRef, wThr, nJit, 1, cFlg, mNew, []);

    [cSit, mSig, mNew, cFlg] = ...
        mtlmatch(mSig, cSit, cMup, SEND, vRef, wThr, nSec, nJit, mNew, cFlg, nLev);
    
    cRun = 0;
    nSit = Inf;

    while (nSit ~= length([cSit{:}])) && cRun < NRUN
        cRun = cRun + 1;
        nSit = length([cSit{:}]);
        [cSit, mSig, mNew, cFlg] = ...
            mtltrack(mSig, cSit, cMup, SEND, nRat, vRef, wThr, nJit, FENG, cFlg, mNew, pMin);
    end

else
    
    [cSit, mSig, mNew, cFlg, vRef] = ...
        mtltrack(mSig, cSit, cMup, SBEG([1 end]), nRat, vRef, wThr, nJit, 0, cFlg, mNew, []);
    
    [cSit, mSig, mNew, cFlg] = ...
        mtlmatch(mSig, cSit, cMup, SBEG(2 : end), vRef, wThr, nSec, nJit, mNew, cFlg, nLev);

    [cSit, mSig, mNew, cFlg] = ...
        mtltrack(mSig, cSit, cMup, SEND, nRat, vRef, wThr, nJit, 1, cFlg, mNew, pMin);
        
    cSit = mtltrack(mSig, cSit, cMup, SEND, nRat, vRef, wThr, nJit, 1, cFlg, mNew, pMin);
    
end

for iMup = 1 : nMup
    for iCan = 1 : nCan
        if ~isempty(cSit{iCan, iMup})
            v = cSit{iCan, iMup}(1, :) + vDel(cSit{iCan, iMup}(2, :)) - 1;
            cSit{iCan, iMup} = sort(v - nBuf);
        end
    end
end