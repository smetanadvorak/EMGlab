%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function [cSit, mSig, mNew, cFlg] = ...
    mtlmatch(mSig, cSit, cMup, vSim, vRef, vThr, nSec, nJit, mNew, cFlg, nLev)

NEPS = 1e-6;
SMIN = 1/3;
SGEN = 1/2;
NROW = 2;
HROW = [1 2];
RLOC = [2 3];
NAMP = 5;
NGAP = 2;
PMIN = 6;
MMAX = 6;
MMIN = 2;
NRUM = 3;

nPts = size(mSig, 2);

[tmp, nMup, nCan] = size(cMup);
bCan = nCan > 1;
bSin = ~bCan;
vCan = 1 : nCan;

nSur = size(cMup{1}, 1);
iMid = ceil(nSur / 2);
vSur = ones(nSur, 1);

vDel = -(0 : (nSur - 1)) * 1 / nSur;

pDif = (nLev > 1);
pGen = (nLev > 2);

pMin = round(PMIN * nPts / (nSec * 1000));

zCor = zeros(2, nMup);
zDat = zeros(3, nMup);

vLon = zeros(1, nMup);
for iMup = 1 : nMup
    vLon(iMup) = size(cMup{1, iMup, 1}, 2);
end

iPik = zeros(nCan, 2 * nMup);
mPik = iPik;
mAmp = zeros(nCan, nMup);
mFac = mAmp;
cCrs = cell(nCan, nMup); 

for iCan = 1 : nCan
    iPik(iCan, :) = [cMup{5, :, iCan}];
    mPik(iCan, :) = [cMup{6, :, iCan}];
    mAmp(iCan, :) = -diff(reshape(mPik(iCan, :), 2, nMup));
    mFac(iCan, :) = [cMup{8, :, iCan}];
    cCrs(iCan, :) = cMup(9, :, iCan);
end

if bCan
    
    bThr = mtlselect(cMup, vThr);
    
    nGit = 1;
    uGit = 2 * nGit + 1;
    vGit = -nGit : nGit;
    zGit = zeros(1, nGit);
    
    uJit = 2 * nJit + 1;
    vJit = (-nJit : nJit).';
    zJit = zeros(1, uJit);
    
else
    bThr = true(1, nMup);
end

mPar = zeros(2, nMup, nCan);
mDer = mPar;
mIzq = mPar;
mPic = mPar;
wPic = mPar;

vUth = zeros(1, nCan);
vDth = vUth;

mBuf = zeros(nCan, 2 * nMup);

for iCan = 1 : nCan

    mPic(:, :, iCan) = reshape(iPik(iCan, :), 2, nMup);
    wPic(:, :, iCan) = mPic(:, :, iCan);

    iPar = zeros(2, nMup);

    for iMup = 1 : nMup

        m = cMup{1, iMup, iCan};
        v = m(iMid, :);
        r = cMup{2, iMup, iCan};

        cMup{5, iMup, iCan} = 0 : (size(m, 2) - 1);
        cMup{6, iMup, iCan} = r - 1;
        cMup{7, iMup, iCan} = m(:, r);
        cMup{8, iMup, iCan} = abs(m(:, r));
        cMup{9, iMup, iCan} = v(cMup{3, iMup, iCan});
        cMup{10, iMup, iCan} = v(cMup{4, iMup, iCan});

        wPic(:, iMup, iCan) = wPic(:, iMup, iCan) - r(1);

        iPar(:, iMup) = [cMup{3, iMup, iCan}(1); cMup{4, iMup, iCan}(1)];

    end

    mTmp = reshape(mPik(iCan, :), 2, nMup).';
    mTmp(~bThr(iCan, :), :) = Inf;
    vTmp = min(abs(mTmp), [], 1);
    
    vUth(iCan) = max(vTmp(1), vThr(iCan));
    vDth(iCan) = max(vTmp(2), vThr(iCan));

    mBuf(iCan, :) = [vLon - iPik(iCan, 1 : 2 : end), vLon - iPik(iCan, 2 : 2 : end)];

    mPar(:, :, iCan) = iPar - 1;
    mIzq(:, :, iCan) = mPic(:, :, iCan) - iPar([1 1], :);
    mDer(:, :, iCan) = mPic(:, :, iCan) - iPar([2 2], :);

end

mPic = mPic - 1;

nBuf = max(iPik(:)) + 1;
uBuf = max(mBuf(:)) + 1;

sMin = min(vSim);
sPat = max(sMin / 2, SMIN);

vSim = vSim([ones(1, nLev - 1), 1 : end, end]);
nSim = length(vSim);

if bCan
    vSig = sum(mSig, 1);
    nThr = NRUM * mtlthresh(vSig, 1000 * nSec);
    mSeg = mtlsegment(vSig, nThr, nSec, 2 * nSec);
else
    mSeg = mtlsegment(mSig, vThr, nSec, 2 * nSec);
end

nSeg = size(mSeg, 1);
bSeg = true(1, nSeg);

nRef = min(vRef);
for i = 2 : nSeg - 1
    if (mSeg(i, 1) - mSeg(i - 1, 2) <= nSec) && (mSeg(i, 2) - mSeg(i - 1, 1) < nRef)
        bSeg(i - 1) = false;
        v = [mSeg(i - 1, 1), mSeg(i, 2)];
        mSeg([i - 1, i], :) = v([1 1], :);
    end
end

mSeg = mSeg(bSeg, :);
nSeg = size(mSeg, 1);
bSeg = false(1, nSeg);

for iCan = 1 : nCan
    nUth = vUth(iCan);
    nDth = vDth(iCan);
    for iSeg = 1 : nSeg
        if (bSeg(iSeg) == 0)
            v = mSig(iCan, mSeg(iSeg, 1) : mSeg(iSeg, 2));
            if any(mtlloc(v, 0, nUth)) && any(mtlloc(-v, 0, nDth))
                bSeg(iSeg) = true;
            end
        end
    end
end

mSeg = mSeg(bSeg, :);
nSeg = size(mSeg, 1);

bNew = true(nCan, nSeg);

cIni = cell(nCan, nSeg);
cPat = cIni;
cGen = cIni;

if pGen
    HOFF = [-1, 0, 1];
    NOFF = length(HOFF);
    cOri = cell(1, MMAX);
    cOrd = cell(1, MMAX);
    for i = MMIN : MMAX
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
    clear mOrd mOri HOFF NOFF;
end

xHis = zeros(3, nMup, nSeg, nCan);
mHis = zeros(nSeg, nCan);

mLis = true(nSeg, nMup, nCan); 
gLis = mLis;
fLis = false(nSeg, nMup, nCan);

if bCan
    mFlg = fLis;
end

hSeg = sum(mSeg, 2).' / 2;

for iMup = 1 : nMup
    
    if ~isempty([cSit{:, iMup}])
        v = [cSit{:, iMup}];
        v = v(1, :);
    else
        v = [];
    end
    
    if bCan
        w = [cFlg{:, iMup}];
        v = [v, w]; 
    end
    
    nRef = vRef(iMup);
    for i = 1 : length(v)
        mLis(abs(hSeg - v(i)) < nRef, iMup, :) = false;
    end
    
    if bCan
        for iCan = 1 : nCan
            v = cFlg{iCan, iMup};
            for i = 1 : length(v)
                x = mSeg(:, 1) <= v(i) & mSeg(:, 2) >= v(i);
                mLis(x, iMup, iCan) = true;
                mFlg(x, iMup, iCan) = true;
            end
        end
    end
    
end

if bSin
    vFlg = [cFlg{:}];
    fSeg = false(1, nSeg);
    for iSeg = 1 : nSeg
        if any(vFlg >= mSeg(iSeg, 1) & vFlg <= mSeg(iSeg, 2))
            fSeg(iSeg) = true;
        end
    end
end

bTry = true(nSeg, nCan);

[vTmp, vNum] = sort(sum(mLis(:, :, iCan), 2));
for iCan = 1 : nCan
    for i = find(vTmp > 0, 1, 'first') : nSeg
        v = vNum(i);
        bNew(iCan, v) = all(mNew(iCan, mSeg(v, 1) : mSeg(v, 2)));
    end
end

vThr = vThr(:);

clear bSeg iPar iPik m mBuf mPik vInf vSig

for iSim = 1 : length(vSim)

    sCur = vSim(iSim);
    sCrs = sCur .^ 2;
    sFlg = SMIN;
    
    bPas = pDif && iSim > 1;
    bTri = iSim >= 3;
    bGen = pGen && (iSim == 3);
    bPat = ~pGen && (iSim >= 3);
    bEnd = (iSim == nSim);
    
    if bPat && bSin
        if (pMin > 0)
            mPat = mtlpattern(cSit, nPts, NGAP, pMin);
            vAny = find(any(mLis, 2));
            for i = 1 : length(vAny)
                v = vAny(i);
                cPat{v} = find(any(mPat(:, mSeg(v, 1) : mSeg(v, 2)), 2).');
            end
            clear mPat;
        end
    end

    vLis = sum(any(mLis, 3), 2);
    [vTmp, vNum] = sort(vLis);
    
    if bSin && iSim == 1
        vNum = [vNum(fSeg(vNum)); vNum(~fSeg(vNum))];
        jSeg = 0;
    else
        jSeg = find(vTmp > 0, 1, 'first') - 1;
    end
    
    while jSeg < nSeg

        jSeg = jSeg + 1;
        iSeg = vNum(jSeg);
        iRan = mSeg(iSeg, 1) : mSeg(iSeg, 2);

        if bCan
            if any(mHis(iSeg, :))
                vOrd = mHis(iSeg, :);
            else
                vOrd = max(abs(mSig(:, iRan)), [], 2) ./ vThr;
            end
            [tmp, iOrd] = sort(vOrd, 'descend');
        else
            iOrd = 1;
        end

        for jCan = 1 : nCan

            iCan = iOrd(jCan);
            nDth = vDth(iCan);
            nUth = vUth(iCan);

            bRem = false;
            vPat = [];

            mDat = xHis(:, :, iSeg, iCan);

            if any(mDat(end, :) >= sCur)

                if all(mLis(iSeg, mDat(1, :) > 0, iCan))
                    bRem = true;
                    sBeg = mSeg(iSeg, 1) - nBuf;
                else
                    xHis(:, :, iSeg, iCan) = zDat;
                    mHis(iSeg, iCan) = 0;
                    fLis(iSeg, :, iCan) = false;
                    bTry(iSeg, iCan) = true;
                end

            elseif bPat

                vPat = cPat{iCan, iSeg};
                vPat = vPat(ismember(vPat, find(mLis(iSeg, :, iCan))));

                if any(vPat)
                    v = mDat(end, vPat);
                    w = mDat(end, mDat(1, :) > 0);
                    if (all(v >= sMin) && all(w >= sMin)) || ...
                            (bEnd && all(v >= sPat) && all(w >= sPat))
                        bTry(iSeg, iCan) = false;
                    end
                end

            end

            vSeg = mSig(iCan, mSeg(iSeg, 1) : mSeg(iSeg, 2));
            if ~(any(mtlloc(vSeg, 0, nUth)) && any(mtlloc(-vSeg, 0, nDth)))
                bTry(iSeg, iCan) = false;
            end

            if ~bRem && bTry(iSeg, iCan)

                pLis = mLis(iSeg, :, iCan) & bThr(iCan, :);
                bLis = pLis;
                oLis = find(bLis);
                nLis = length(oLis);
                mDat = zDat;

                bDif = bPas && (nLis > 1);

                sBeg = mSeg(iSeg, 1) - nBuf;
                sEnd = mSeg(iSeg, 2) + uBuf;
                oSeg = mSig(iCan, sBeg : sEnd);
                vSeg = oSeg;

                vTmp = mSeg(iSeg, 1) - sBeg + 1;
                iRan = vTmp : (vTmp + mSeg(iSeg, 2) - mSeg(iSeg, 1));
                jRan = iRan(1);
                kRan = iRan(end);
                
                if any(mLis(iSeg, gLis(iSeg, :, iCan), iCan) ~= ...
                        fLis(iSeg, gLis(iSeg, :, iCan), iCan))

                    fLis(iSeg, :, iCan) = mLis(iSeg, :, iCan);
                    gLis(iSeg, :, iCan) = false;

                    iMax = find(mtlloc(vSeg(iRan), 0, nUth)) + jRan - 1;
                    iMax = iMax(iMax > jRan & iMax < kRan);
                    iMin = find(mtlloc(-vSeg(iRan), 0, nDth)) + jRan - 1;
                    iMin = iMin(iMin > jRan & iMin < kRan);

                    while any(bLis)

                        mCor = zCor;
                        mPos = zCor;

                        if any(iMin) && any(iMax)

                            vSEG = abs(vSeg);

                            for i = find(bLis)
                                d = [iMax - mIzq(1, i, iCan), iMin - mIzq(2, i, iCan)];
                                [mCor(1, i), y] = max(mtlpc(vSeg, cMup{9, i, iCan}, vSEG, d, 0));
                                mPos(1, i) = d(y) - mPar(1, i, iCan);
                                d = [iMax - mDer(1, i, iCan), iMin - mDer(2, i, iCan)];
                                [mCor(2, i), y] = max(mtlpc(vSeg, cMup{10, i, iCan}, vSEG, d, 0));
                                mPos(2, i) = d(y) - mPar(2, i, iCan);
                            end

                        end

                        gLis(iSeg, any(mCor), iCan) = true;

                        if any(mCor(:) > SMIN)

                            if any(all(mCor) & (diff(mPos) == 0))
                                wCor = mCor;
                                wCor(:, diff(mPos) ~= 0) = 0;
                                [tmp, k] = max(max(wCor));
                                d = mPos(1, k);
                            else
                                [tmp, y] = max(mCor(:));
                                k = ceil((y - NEPS) / NROW);
                                d = mPos(round(mod(y, NROW + NEPS)), k);
                            end

                            v = d + cMup{5, k, iCan};
                            r = v(cMup{2, k, iCan});

                            [tmp, iBon] = min(sum(abs(vSeg(vSur, r) - cMup{7, k, iCan}), 2));

                            vSeg(v) = vSeg(v) - cMup{1, k, iCan}(iBon, :);
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

                    if any(mDat(1, :))
                        iLis = find(mDat(1, :));
                        mDat = mtleval(cMup(:, :, iCan), mDat, oSeg, iLis, vSur, nSur, mFac(iCan, :));
                        if any(mDat(end, iLis) >= sCur)
                            bDif = false;
                        else
                            wDat = xHis(:, :, iSeg, iCan);
                            jLis = find(wDat(1, :));
                            if any(iLis) && (isempty(jLis) || (any(jLis) && (mean(mDat(end, iLis)) > mean(wDat(end, jLis)))))
                                xHis(:, :, iSeg, iCan) = mDat;
                                mHis(iSeg, iCan) = max(mDat(end, :));
                            end
                        end
                    end

                end

                if bDif
                    
                    vSeg = abs(hSeg - hSeg(iSeg));
                    bSeg = (vSeg > 0) & (vSeg < min(vRef(oLis)));
                    
                    if any(bSeg)
                        vSeg = oSeg(iRan);
                        nAmp = max(vSeg) - min(vSeg);
                        bAmp = (mAmp(iCan, oLis) < nAmp * NAMP) & (mAmp(iCan, oLis) > nAmp / NAMP);
                        bSim = max(xHis(end, oLis, bSeg, iCan), [], 3) < sMin;
                        bLis = bSim & bAmp;
                    else
                        bLis = false(1, nLis);
                    end
                    
                    vLis = oLis(bLis); 
                    uLis = length(vLis);

                    if bNew(iCan, iSeg)
                        iMax = find(mtlloc(oSeg(iRan), 0, nUth)) + jRan - 1;
                        iMin = find(mtlloc(-oSeg(iRan), 0, nDth)) + jRan - 1;
                    else
                        vNew = mNew(iCan, sBeg : sEnd);
                        vNew = vNew(iRan);
                        iMax = find(mtlloc(oSeg(iRan), 0, nUth) & vNew) + jRan - 1;
                        iMin = find(mtlloc(-oSeg(iRan), 0, nDth) & vNew) + jRan - 1;
                        if isempty(iMax) && isempty(iMin)
                            uLis = 0;
                        end
                    end

                    if bGen
                        oMax = iMax;
                        oMin = iMin;
                    end
                    
                    if uLis > 0

                        nIni = length([iMax, iMin]);
                        mIni = zeros(uLis, nIni);
                        iMxx = mIni;

                        for i = 1 : uLis
                            k = vLis(i);
                            v = [iMax - wPic(1, k, iCan), iMin - wPic(2, k, iCan)];
                            mIni(i, :) = mtlcor(cMup{7, k, iCan}(iMid, :), oSeg, v);
                            iMxx(i, :) = [iMax - mPic(1, k, iCan), iMin - mPic(2, k, iCan)];
                        end

                        v = reshape(vLis(ones(nIni, 1), :), uLis * nIni, 1);
                        w = reshape(iMxx', uLis * nIni, 1);
                        x = reshape(mIni', uLis * nIni, 1);

                        mIni = [v, w, floor(x)];
                        [tmp, iBon] = mtlunique(-mIni(:, end));
                        mIni = mIni(iBon, :);

                        if ~isempty(cIni{iCan, iSeg})
                            bTmp = ismember(mIni(:, end), cIni{iCan, iSeg}(:, end));
                            mIni = mIni(~bTmp, :);
                        end

                        if bTri
                            if any(mIni(:, 3) > 0)
                                iFin = find(mIni(:, 3) > 0, 1, 'last');
                                nBon = min(iFin + 2 * uLis, size(mIni, 1));
                            else
                                nBon = min(2 * uLis, size(mIni, 1));
                            end
                            mIni = mIni(1 : nBon, :);
                        else
                            mIni = mIni(mIni(:, 3) > 0, :);
                        end

                        if any(cIni{iCan, iSeg})
                            cIni{iCan, iSeg} = [cIni{iCan, iSeg}; mIni];
                        else
                            cIni{iCan, iSeg} = mIni;
                        end
                        
                    else
                        mIni = [];
                    end

                    iIni = 0;
                    nIni = size(mIni, 1);

                    while (iIni < nIni)

                        iIni = iIni + 1;
                        k = mIni(iIni, 1);

                        bLis = pLis;
                        bLis(k) = false;

                        v = mIni(iIni, 2) + cMup{5, k, iCan};
                        w = v;

                        vSeg = oSeg;
                        vSeg(v) = vSeg(v) - cMup{1, k, iCan}(iMid, :);

                        mDat = zDat;
                        mDat(HROW, k) = [mIni(iIni, 2); iMid];

                        while any(bLis)

                            mCor = zCor;
                            mPos = zCor;

                            wSeg = vSeg(w);

                            iMax = find(mtlloc(wSeg, 0, nUth)) + w(1) - 1;
                            iMax = iMax(iMax > jRan & iMax < kRan);
                            iMin = find(mtlloc(-wSeg, 0, nDth)) + w(1) - 1;
                            iMin = iMin(iMin > jRan & iMin < kRan);

                            if any(iMax) && any(iMin)

                                vSEG = abs(vSeg);

                                for i = find(bLis)
                                    d = [iMax - mIzq(1, i, iCan), iMin - mIzq(2, i, iCan)];
                                    [mCor(1, i), y] = max(mtlpc(vSeg, cMup{9, i, iCan}, vSEG, d, 0));
                                    mPos(1, i) = d(y) - mPar(1, i, iCan);
                                    d = [iMax - mDer(1, i, iCan), iMin - mDer(2, i, iCan)];
                                    [mCor(2, i), y] = max(mtlpc(vSeg, cMup{10, i, iCan}, vSEG, d, 0));
                                    mPos(2, i) = d(y) - mPar(2, i, iCan);
                                end

                            end

                            if any(mCor(:))

                                if any(all(mCor) & (diff(mPos) == 0))
                                    wCor = mCor;
                                    wCor(:, diff(mPos) ~= 0) = 0;
                                    [tmp, k] = max(max(wCor));
                                    d = mPos(1, k);
                                else
                                    [tmp, y] = max(mCor(:));
                                    k = ceil((y - NEPS) / NROW);
                                    d = mPos(round(mod(y, NROW + NEPS)), k);
                                end

                                bLis(k) = false;

                                v = d + cMup{5, k, iCan};

                                vSeg(v) = vSeg(v) - cMup{1, k, iCan}(iMid, :);
                                mDat(HROW, k) = [d; iMid]; 

                                w = min(v(1), w(1)) : max(v(end), w(end));

                            else    
                                bLis(:) = false;    
                            end
                            
                        end

                        iLis = find(mDat(1, :));
                        if size(iLis, 2) > 1
                            mDat = mtleval(cMup(:, :, iCan), mDat, oSeg, iLis, vSur, nSur, mFac(iCan, :));
                            if any(mDat(end, :) >= sCur)
                                iIni = Inf;
                            else
                                
                                wDat = xHis(:, :, iSeg, iCan);
                                jLis = find(wDat(1, :));
                                if any(iLis) && (isempty(jLis) || (any(jLis) && (max(mDat(end, iLis)) > max(wDat(end, jLis)))))
                                    xHis(:, :, iSeg, iCan) = mDat;
                                    mHis(iSeg, iCan) = max(mDat(end, :));
                                end
                                
                                if pGen
                                    cGen{iCan, iSeg}(end + 1, :) = mDat(1, :);
                                end
                                
                            end
                        end

                    end

                    if bGen && ~isinf(iIni) && any(oMax) && any(oMin)

                        if (max(mDat(end, :)) >= max(xHis(end, :, iSeg, iCan)))
                            wDat = mDat;
                        else
                            wDat = xHis(:, :, iSeg, iCan);
                        end
                        
                        uLis = length(oLis);
                            
                        if (uLis >= MMIN)

                            if uLis > MMAX
                                vTmp = [vPat, setdiff(oLis, vPat)];
                                vLis = vTmp(1 : MMAX);
                            else
                                vLis = oLis;
                            end

                            if isempty(cGen{iCan, iSeg})
                                mGen = [];
                            else
                                mGen = cGen{iCan, iSeg}(:, vLis);
                                mGen = mGen(sum(mGen > 0, 2) > 1, :);
                            end
                            
                            mDat = mtlga(cMup(:, :, iCan), vLis, oSeg, mGen, mFac, ...
                                vLon, cOri, cOrd, jRan, kRan, nUth, nDth, sCur, sMin, nSec);

                            iLis = find(mDat(1, :));
                            if any(iLis)
                                mDat = mtleval(cMup(:, :, iCan), mDat, oSeg, iLis, vSur, nSur, mFac(iCan, :));
                            end

                            if (max(mDat(end, :)) > max(xHis(end, :, iSeg, iCan)))
                                xHis(:, :, iSeg, iCan) = mDat;
                            end
                
                        end
                    end
                end

                if any(mDat(end, :) >= sCur)
                    bRem = true;
                end

            end

            if bCan
                if bEnd && (max(xHis(end, :, iSeg, iCan)) > max(mDat(end, :)))
                    mDat = xHis(:, :, iSeg, iCan);
                end
                iLis = find(mDat(1, :));
                if any(iLis)
                    oLis = find(mLis(iSeg, :, iCan) & bThr(iCan, :));
                    for i = 1 : length(iLis)
                        if any(cCrs{iCan, iMup}(oLis) >= sCrs)
                            mDat(end, iLis(i)) = min(mDat(end, iLis(i)), SMIN);
                            bRem = any(mDat(end, :) >= sCur);
                        end
                    end
                    v = mDat(end, iLis);
                    iFlg = find(v > sFlg & v < sCur & mFlg(iSeg, iLis, iCan));
                    for i = 1 : length(iFlg)
                        k = iLis(iFlg(i));
                        v = cFlg{iCan, k};
                        x = sBeg + mDat(1, k) - 1; 
                        if any(abs(v - x) <= uJit)
                            mDat(end, k) = mDat(end, k) + 1;
                            bRem = true;
                        end
                    end
                end
            end
            
            if bRem

                iBon = find(mDat(end, :) >= sCur);
                
                if bCan && any(mFlg(iSeg, iBon, iCan))
                    nBon = length(iBon);
                    bBon = true(1, length(iBon));
                    for i = 1 : nBon
                        k = iBon(i);
                        if mFlg(iSeg, k, iCan)
                            v = cFlg{iCan, k};
                            x = sBeg + mDat(1, k) - 1;
                            f = (v >= x - uJit & v <= x + uJit);
                            if any(f)
                                mFlg(iSeg, k, iCan) = false;
                                cFlg{iCan, k} = v(~f);
                            else
                                bBon(i) = false;
                                mLis(iSeg, k, iCan) = false;
                            end
                        end
                    end
                    iBon = iBon(bBon);
                end
                
                if any(iBon)

                    mLis(iSeg, iBon, iCan) = false;

                    for k = iBon

                        x = sBeg + mDat(1, k) - 1;
                        mDat(3, k) = mDat(3, k) / mFac(iCan, k);
                        cSit{iCan, k}(:, end + 1) = [x; mDat(RLOC, k); iSim];

                        t = sBeg + mDat(1, k) + cMup{5, k, iCan} - 1;
                        mNew(iCan, t(cMup{2, k, iCan})) = false;
                        mSig(iCan, t) = mSig(iCan, t) - cMup{1, k, iCan}(mDat(2, k), :);

                        h = find(abs(hSeg - hSeg(iSeg)) < vRef(k));
                        h = h(h ~= iSeg);
                        for j = h
                            mLis(j, k, :) = false;
                        end

                        if bCan
                            for jCan = vCan(vCan ~= iCan)
                                if bThr(jCan, k)
                                    if mLis(iSeg, k, jCan) && ~mFlg(iSeg, k, jCan)
                                        mFlg(iSeg, k, jCan) = true;
                                        cFlg{jCan, k}(end + 1) = x;
                                    end
                                else
                                    
                                    f = sBeg + mDat(1, k) - 1;
                                    s = cSit{jCan, k};
                                    e = isempty(s);
                                    
                                    if e || (~e && all(abs(s(1, :) - f) > uJit))
                                        
                                        w = cMup{1, k, jCan};
                                        n = size(w, 2) - 1;
                                        z = 0 : n;
                                        r = cMup{2, k, jCan};
                                        q = r - 1;
                                        a = w(:, r);
                                        
                                        tSig = mSig(jCan, f - nGit : f + nGit + n);
                                        mGit = zGit;
                                        yGit = zGit;
                                        for iGit = 1 : uGit
                                            [mGit(iGit), yGit(iGit)] = max(sum(a .* tSig(vSur, q + iGit), 2));
                                        end
                                        [tmp, yy] = max(mGit);
                                        o = vGit(yy);
                                
                                        v = tSig(nGit + 1 + o + z) - w(yGit(yy), :);

                                        mSig(jCan, f + o + z) = v;
                                        cSit{jCan, k}(:, end + 1) = [f + o; yGit(yy); 0; iSim];
                                        
                                    end
                                end
                            end
                        end
                        
                    end

                    if bCan
                        bDat = mDat(end, :) >= sMin;
                        jBeg = mSeg(iSeg, 1) - nBuf;
                        jEnd = mSeg(iSeg, 2) + uBuf;
                        for jCan = vCan(vCan ~= iCan)
                            jLis = find(mLis(iSeg, :, jCan) & bThr(jCan, :) & bDat);
                            if any(jLis)
                                wDat = zDat;    
                                wDat(1, jLis) = mDat(1, jLis);
                                wDat(2, jLis) = iMid;
                                vSeg = mSig(jCan, jBeg : jEnd);
                                wDat = mtleval(cMup(:, :, jCan), wDat, vSeg, jLis, vSur, nSur, mFac(jCan, :));
                                if max(wDat(end, :)) > max(xHis(:, :, iSeg, jCan))
                                    b = (wDat(end, :) >= sFlg) & (wDat(end, :) < sCur);
                                    wDat(end, b) = wDat(end, b) + 1;
                                    xHis(:, :, iSeg, jCan) = wDat;
                                end
                            end        
                        end
                    end
                    
                    mDat(:, iBon) = 0;

                    iBon = find(mDat(1, :));
                    for k = iBon
                        t = sBeg + mDat(1, k) + cMup{5, k, iCan} - 1;
                        mNew(iCan, t(cMup{2, k, iCan})) = true;
                    end

                    r = mSeg(iSeg, 1) : mSeg(iSeg, 2);
                    v = mSig(iCan, r);

                    bBad = ~(any(mtlloc(v, 0, nUth)) && any(mtlloc(-v, 0, nDth)));

                    if bBad
                        bTry(iSeg, iCan) = false;
                        cGen{iCan, iSeg} = [];
                        xHis(:, :, iSeg, iCan) = 0;
                        mHis(iSeg, iCan) = 0;
                    else

                        xHis(:, :, iSeg, iCan) = mDat;
                        mHis(iSeg, iCan) = max(mDat(end, :));
                        gLis(iSeg, :, iCan) = true;

                        if bSin 
                            iLis = find(mDat(1, :));
                            if (isempty(iLis) || (any(iLis) && any(mDat(end, iLis) < sCur)))
                                jSeg = jSeg - 1;
                            end
                        end

                        bNew(iCan, iSeg) = all(mNew(iCan, r));

                    end
                    
                end
            end
        end
    end
end