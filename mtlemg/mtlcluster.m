%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function [cMuap, cSeg, mPsC] = mtlcluster(mSig, nRat, nLev)

NRUM = 3;
NEXC = 5;
NMIN = 5;
NMAX = 20; 
NHWD = 10;
PMAX = 10;
LAMP = 25;
LDUR = 25;
NREF = 30;

cMuap = [];
cSeg = [];

nRat = round(nRat);
fDur = 3 * nRat / 10000;
nTwd = round(nRat / 1000);
nHwd = round(NHWD * nTwd);
nRef = NREF * nRat / 1000;

nPts = length(mSig);
if size(mSig, 2) == nPts
    mSig = mSig.';
end

nMin = min(max(round(nPts / nRat), NMIN), NMAX);

nCan = size(mSig, 2);
cCan = cell(1, nCan);
oThr = zeros(1, nCan);

bSin = (nCan == 1);
bCan = ~bSin;

switch nLev
    case 1
        nSim = .50;
        nMrg = .50;
    case 2
        nSim = .60;
        nMrg = .60;
    case 3
        nSim = .70;
        nMrg = .70;
    otherwise
        error('Level is an integer between 1 and 3!')
end

for iCan = 1 : nCan

    n = min(nPts, nRat);
    v = mSig(1 : n, iCan);
    u = mean(abs(mSig(:, iCan)));

    m = mtlsegment(v, u, nTwd, nTwd, NEXC);
    b = true(1, n);
    for j = 1 : size(m, 1)
        b(m(j, 1) : m(j, 2)) = false;
    end

    oThr(iCan) = mean(abs(v(b)));  
    vThr = oThr(iCan) * [10 NRUM];
    nThr = vThr(end);

    mSeg = mtlsegment(mSig(:, iCan), vThr(end), nTwd, 2 * nTwd, NEXC);
    nSeg = size(mSeg, 1);
    bSeg = true(1, nSeg);

    nMax = 2 * nSeg;
    vInd = zeros(nMax, 1);
    mInd = zeros(nMax, 2);
    mFea = zeros(nMax, PMAX, 3);
    mFea(:, :, 3) = 1;

    iThr = 0;
    iSeg = 0;

    while iThr < length(vThr)

        iThr = iThr + 1;
        t = vThr(iThr);
        h = -t;

        vInd(iSeg + 1 : end) = iThr;

        for iTmp = find(bSeg)

            x = mSeg(iTmp, 1) : mSeg(iTmp, 2);

            vSeg = mSig(x, iCan);
            vSEG = abs(vSeg);
            iPic = find(mtlloc(vSeg, vSEG, t));
            wSeg = vSeg(iPic);

            if any(wSeg < h) && any(wSeg > t)

                bSeg(iTmp) = 0;

                wSEG = abs(wSeg);
                iSeg = iSeg + 1;
                mInd(iSeg, :) = mSeg(iTmp, :);
                nPic = length(iPic);

                if nPic > PMAX
                    [tmp, iTri] = sort(wSEG);
                    iPic = sort(iPic(iTri(end : -1 : (nPic - PMAX + 1))));
                    wSeg = vSeg(iPic);
                    wSEG = abs(wSeg);
                    nPic = PMAX;
                end

                v = 1 : nPic;
                vSeq = (wSeg > 0) + 1;
                mFea(iSeg, v, 1) = vSeq;
                vAmp = round(wSEG / t);
                mFea(iSeg, v, 2) = vAmp;
                vDur = diff(iPic);
                mFea(iSeg, v(1 : end - 1), 3) = vDur;
                bAmp = (vAmp > 1);
                nSum = sum(bAmp);

                if (nSum ~= nPic) && any(wSeg(bAmp) < h) && any(wSeg(bAmp) > t)
                    iSeg = iSeg + 1;
                    mInd(iSeg, :) = mSeg(iTmp, :);
                    v = 1 : nSum;
                    mFea(iSeg, v, 1) = vSeq(bAmp);
                    mFea(iSeg, v, 2) = vAmp(bAmp);
                    mFea(iSeg, v(1 : end - 1), 3) = diff(iPic(bAmp));
                end

            end
        end
    end

    clear b bSeg m mSeg t v vAmp vOne vSeg vSEG vSeq vSIG vThr vTmp wSeg wSEG x

    if ~isempty(mFea)

        iFin = any(mFea(:, :, 1), 2);
        mInd = [mInd(iFin, :), vInd(iFin)];
        mFea = mFea(iFin, :, :);
        [tmp, iFin] = sort(mInd(:, 1));
        mInd = mInd(iFin, :);
        mFea = mFea(iFin, :, :);
        mFea((mInd(:, 2) - mInd(:, 1)) > 2 * nHwd, :) = 0;

        wFea = mFea(:, :, 2);
        wFea(wFea > LAMP) = LAMP;
        mFea(:, :, 2) = wFea;

        wFea = mFea(:, :, 3);
        if fDur > 1
            bFin = wFea > 1;
            wFea(bFin) = ceil(wFea(bFin) / fDur);
        end
        wFea(wFea > LDUR) = LDUR;
        mFea(:, :, 3) = wFea;

        [vCla, mInd] = classify(mFea, mInd);

        if all(vCla == 0)
            if bSin
                return;
            end
        else

            vCla(mInd(:, 1) < nHwd | mInd(:, 2) > nPts - nHwd) = 0;

            clear bFin iFin iPic iTri mFea vInd vZer tmp wFea

            cSeg = align(mSig(:, iCan), mInd, vCla, nTwd, nSim, nThr, nRef, nHwd, bCan);

            if isempty(cSeg{1, 1})
                if bSin
                    return;
                end
            else

                clear mInd vCla

                cSeg = merge(cSeg, nRef, nMrg, nMin, bCan);
                if isempty(cSeg) || isempty(cSeg{1, 1})
                    if bSin
                        return;
                    end
                end

                cCan{iCan} = unlock(cSeg, nTwd);

            end

        end
    end
end

if nCan == 1
    [cMuap, cSeg] = create1(mSig, cCan{1}, nTwd, oThr);
else
    [cMuap, cSeg] = createN(mSig, cCan, nTwd, oThr, nRef);
end

if nargout == 3

    NEFF = 10;

    [nCan, nMup] = size(cMuap);
    mPsC = zeros(nCan, nMup);
    vThr = mtlthresh(mSig.', nRat);

    for iMup = 1 : nMup
        for iCan = 1 : nCan

            v = cMuap{iCan, iMup};
            x = max(v);
            w = min(v);
            n = size(cSeg{iCan, iMup}, 2); 
            t = min(2 * vThr(iCan), min(x, -w) / 2);
            r = mtlshrink(v, NEFF, nTwd, nTwd, t, 3);

            a = cSeg{iCan, iMup}(r, :);
            b = v(r, ones(1, n));
            m = max(abs(a), abs(b));

            s = sort(sum(b .* a - abs(a - b) .* m, 1) ./ sum(m .^ 2, 1));
            s = s(ceil(.5 * n) : end);

            mPsC(iCan, iMup) = median(s);

        end
    end

    mPsC(mPsC < 0) = 0;

end


function [vCla, mInd] = classify(wFea, mInd)

NMIN = 2;

[nSeg, nCol, nFea] = size(wFea);
mLab = zeros(nSeg, nFea + 1);
mLab(:, 1) = mInd(:, end);
nNiv = length(mtlunique(mInd(:, end)));
uMin = NMIN ^ nFea;

nBas = (max(wFea(:)) + 1);
vBas = nBas .^ (0 : (nCol - 1));
mBas = vBas(ones(nSeg, 1), :);

mFea = zeros(nSeg, nFea);
for i = 1 : nFea
    mFea(:, i) = sum(wFea(:, :, i) .* mBas, 2);
end

for y = 1 : nNiv

    yFin = find(mInd(:, end) == y);
    vSeq = mFea(yFin, 1);
    vUni = mtlunique([0; vSeq]);
    vLog = [0; ceil(log(vUni(2 : end)) / log(nBas))];
    vBas = nBas .^ (0 : max(vLog));

    iSeq = 0;

    for i = 2 : length(vUni)

        iFin = find(vSeq == vUni(i));

        if length(iFin) > uMin

            iSeq = iSeq + 1;
            mLab(yFin(iFin), 2) = iSeq;
            iLab = [iSeq, 1, 1];

            for iFea = 2 : nFea

                vF = mFea(yFin(iFin), iFea);
                vU = mtlunique(vF);

                n = length(vU);
                v = zeros(1, n);
                for j = 1 : n
                    v(j) = sum(vF == vU(j));
                end
                [tmp, iTri] = sort(v, 'descend');
                vU = vU(iTri);

                nLog = vLog(i);
                vOne = ones(n, 1);
                a = vBas(vOne, 1 : nLog);
                b = vBas(vOne, 2 : (nLog + 1));
                mU = floor(rem(vU(:, ones(1, nLog)), b) ./ a);

                m = mU(1, :);
                v = vU(1);
                sm = 1;

                for j = 2 : n
                    kU = mU(j * ones(sm, 1), :);
                    jU = abs(kU - m);
                    jFin = find(all(jU <= 1, 2));
                    if any(jFin)
                        vF(vF == vU(j)) = v(jFin(1));
                    else
                        m = [m; mU(j, :)];
                        v = [v; vU(j)];
                        sm = sm + 1;
                    end
                end

                for j = 1 : sm
                    jFin = find(vF == v(j));
                    if length(jFin) >= NMIN
                        mLab(yFin(iFin(jFin)), iFea + 1) = iLab(iFea);
                        iLab(iFea) = iLab(iFea) + 1;
                    end
                end

            end
        end
    end
end

vCla = zeros(nSeg, 1);
vTmp = vCla;
vLab = vCla;
vBas = (max(mLab(:)) + 1) .^ (nFea : -1 : 0);
bLab = all(mLab, 2);
vLab(bLab) = sum(vBas(ones(sum(bLab), 1), :) .* mLab(bLab, :), 2);
iLab = find(bLab);
wLab = vLab(iLab);
vUni = mtlunique([0; vLab]);

nCla = 0;
nUni = length(vUni);
vSiz = zeros(1, nUni);
for i = 2 : nUni
    iFin = find(wLab == vUni(i));
    nSiz = length(iFin);
    if nSiz >= NMIN
        nCla = nCla + 1;
        vTmp(iLab(iFin)) = nCla;
        vSiz(nCla) = nSiz;
    end
end

[tmp, iTri] = sort(vSiz(1 : nCla));
for i = 1 : nCla
    vCla(vTmp == iTri(i)) = i;
end

iFin = find(diff(mInd(:, 1)) == 0);
bBon = true(1, nSeg);
for i = 1 : length(iFin)
    k = iFin(i);
    a = vCla(k);
    b = vCla(k + 1);
    if (a <= b)
        bBon(k) = 0;
    else
        bBon(k + 1) = 0;
    end
end

vCla = vCla(bBon);
mInd = mInd(bBon, :);

vUni = mtlunique([0; vCla]);
for i = 2 : length(vUni)
    iFin = find(vCla == vUni(i));
    if length(iFin) < NMIN
        vCla(iFin) = 0;
    end
end


function cSeg = align(vSig, mInd, vCla, nTwd, nSim, nThr, nRef, nHwd, bCan)

NMIN = 2;
NTRY = 10;
SZFL = .6;
FSIM = .75;

nPts = length(vSig);
vThr = nThr * [2, 1];
vNiv = mInd(:, 3);
wNiv = mtlunique(vNiv);
nNiv = length(wNiv);
cCla = cell(1, nNiv);
cInd = cCla;

for i = 1 : nNiv
    iFin = (mInd(:, 3) <= wNiv(i));
    cCla{i} = vCla(iFin);
    cInd{i} = [[1, 1]; mInd(iFin, [1 2]); [nPts, nPts]];
end

hTwd = round(nTwd / 2);
vUni = mtlunique([0; vCla]);
vUni = vUni(2 : end);
nCla = length(vUni);
nFwd = 2 * nHwd + 1;
vZer = zeros(nFwd, 1);

vTes = nHwd - 2 * nTwd : ceil(nTwd / 4) : nHwd + 2 * nTwd;
wTes = (nHwd - 5 * nTwd) : (nHwd + 5 * nTwd);
yTes = wTes(1 : end - 1);
zTes = [1 : (nHwd - 5 * nTwd - 1), (nHwd + 5 * nTwd + 1) : nFwd];

tSim = FSIM * nSim;

iSeg = 0;
cSeg = cell(4, 1);

for i = 1 : nCla

    iNiv = vNiv(find(vCla == vUni(i), 1));
    iCla = find(cCla{iNiv} == vUni(i)) + 1;
    mInd = cInd{iNiv};
    nSeg = length(iCla);

    mMax = zeros(nFwd, nSeg);
    mMin = mMax;
    jMax = zeros(2, nSeg);
    jMin = jMax;

    for j = 1 : nSeg

        c = iCla(j);
        k = mInd(c, 1);
        s = vSig(k : mInd(c, 2));

        [tmp, imax] = max(s);
        imax = imax + k - 1;
        [tmp, imin] = min(s);
        imin = imin + k - 1;

        jMax(:, j) = [imax - nHwd; imax + nHwd];
        jMin(:, j) = [imin - nHwd; imin + nHwd];

        w = jMax(1, j);
        s = vSig(jMax(1, j) : jMax(2, j));

        k = mInd(c - 1, 2);
        if k > w
            s(1 : k - w + 1) = 0;
        end

        k = mInd(c + 1, 1);
        if k < jMax(2, j)
            s(k - w + 1 : nFwd) = 0;
        end

        z = vZer;

        d = imax - imin;
        if d > 0
            z(d + 1 : end) = s(1 : nFwd - d);
        else
            z(1 : nFwd + d) = s(-d + 1 : end);
        end

        mMax(:, j) = s;
        mMin(:, j) = z;

    end

    if mtlvar(mMax(vTes, :), 2) <= mtlvar(mMin(vTes, :), 2)
        mSeg = mMax;
        iInd = jMax;
    else
        mSeg = mMin;
        iInd = jMin;
    end
    
    bOne = true;
    bSur = true;

    vSeg = mean(mSeg, 2);

    b = abs(vSeg) > vThr(iNiv);
    b(zTes) = 0;
    v = vZer;
    v(yTes) = sign(diff(vSeg(wTes)));

    x = find(b, 1, 'first') - 1;
    r(1) = x;
    k = find(v == -v(x));
    k = max(k(k < x));
    if any(k)
        r(1) = k;
    end

    x = find(b, 1, 'last') + 1;
    r(2) = x;
    k = find(v == -v(x));
    k = min(k(k > x));
    if any(k)
        r(2) = k + 1;
    end

    r = r(1) : r(2);

    d = diff(iInd(1, :));
    sSeg = cell(2, 1);

    if any(d < nRef)

        if bCan 
            bSur = false;
        end

        cDif = 0;

        while size(mSeg, 2) > NMIN

            cDif = cDif + 1;
            bDif = true(1, size(mSeg, 2));

            d = diff(iInd(1, :));

            while any(d < nRef)

                iDif = find(bDif);
                [tmp, iMin] = min(d);

                p = mSeg(r, iDif);
                n = length(iDif);
                o = ones(1, n);

                q = p(:, iMin * o);
                vEuc = 1 - sum(abs(p - q), 1) ./ sum(sqrt(abs(p .* q)), 1);
                q = p(:, (iMin + 1) * o);
                wEuc = 1 - sum(abs(p - q), 1) ./ sum(sqrt(abs(p .* q)), 1);

                b = (vEuc >= wEuc);

                if sum(b) >= n/2
                    bDif(iDif(~b)) = false;
                else
                    bDif(iDif(b)) = false;
                end

                d = diff(iInd(1, bDif));

            end

            sSeg{1, cDif} = mSeg(:, bDif);
            sSeg{2, cDif} = iInd(:, bDif);

            mSeg = mSeg(:, ~bDif);
            iInd = iInd(:, ~bDif);

        end

    else
        sSeg{1} = mSeg;
        sSeg{2} = iInd;
    end
        
    for jSeg = 1 : size(sSeg, 2)

        mSeg = sSeg{1, jSeg};
        nSeg = size(mSeg, 2);
        iInd = sSeg{2, jSeg};
            
        while (nSeg >= NMIN)        
        
            if iNiv > 1
                bBon = all(mSeg(r, :), 1);
            else
                bBon = true(1, nSeg);
            end
        
            if (sum(bBon) >= NMIN)

                vSeg = mean(mSeg, 2);
                mSeg = mSeg(:, bBon);
                iInd = iInd(:, bBon);
                nSeg = size(mSeg, 2);

                a = mSeg(r, :);
                o = ones(1, nSeg);
                b = vSeg(r, o);

                [tmp, vLis] = sort(sum(a .* b, 1), 'descend');
                b = a(:, vLis(1) * o);

                vEuc = 1 - sum(abs(a - b), 1) ./ sum(sqrt(abs(a .* b)), 1);
                
                bBon = (vEuc >= nSim);

                if (sum(bBon) < NMIN) && (nSeg > NMIN)
                    c = 1;
                    n = min(NTRY, nSeg);
                    while c < n
                        c = c + 1;
                        b = a(:, vLis(c) * o);
                        vEuc = 1 - sum(abs(a - b), 1) ./ sum(sqrt(abs(a .* b)), 1);
                        bBon = (vEuc >= nSim);
                        if (sum(bBon) >= NMIN)
                            c = Inf;
                        end
                    end
                end

            end

            if (sum(bBon) >= NMIN)

                iSeg = iSeg + 1;

                m = mSeg(:, bBon);
                k = [iInd(:, bBon); bSur * iNiv * ones(1, size(m, 2))];
                v = mean(m, 2);
                x = (r(1) - hTwd) : (r(end) + hTwd);
                
                if ~bOne
                    b = abs(v) > vThr(iNiv);
                    b(zTes) = 0;
                    g = find(b, 1, 'first');
                    h = find(b, 1, 'last');
                    x = x + round(((g + h) - (x(1) + x(end))) / 2);
                end

                cSeg(:, iSeg) = {m; k; v; x};

                b = ~bBon;
                nSeg = sum(b);

                if nSeg >= NMIN
                    mSeg = mSeg(:, b);
                    iInd = iInd(:, b);
                end

                bOne = false;
                
            else
                nSeg = 0;
            end
            
        end

    end
end

n = size(cSeg, 2);
if n > 1
    v = zeros(1, n);
    for i = 1 : n
        v(i) = size(cSeg{1, i}, 2);
    end
    [tmp, iTri] = sort(v, 'descend');
    cSeg = cSeg(:, iTri);
end


function cSeg = merge(oSeg, nRef, nSim, nMin, bCan)

NMIN = 2;
NOSP = 3;
LLIM = nSim;
ULIM = 2 - nSim;

if bCan
    eMax = 1;
else
    eMax = 0;
end

nChk = nSim / 2;
nCla = size(oSeg, 2);
nFwd = size(oSeg{1, 1}, 1);

iMid = ceil(NOSP / 2);
vOth = 1 : NOSP;
vOth = vOth(vOth ~= iMid);

cMUP = cell(1, nCla);
cMoy = oSeg(3, :);
cRan = oSeg(4, :);
oSeg = oSeg([1 2], :);

vOne = ones(NOSP, 1);
vAmp = zeros(1, nCla);
vExt = vAmp;
vMax = vAmp;

cSeg = cell(2, 1);

iSeg = 0;

for i = 1 : nCla

    v = cMoy{i};

    cMUP{i} = abs(v);

    [x, ix] = max(v);
    [m, im] = min(v);
    vAmp(i) = x - m;

    if x > -m
        vMax(i) = x;
        vExt(i) = ix;
    else
        vMax(i) = m;
        vExt(i) = im;
    end

end

bNew = true;

while (size(oSeg, 2) > 0)

    nCla = size(oSeg, 2);
    iRst = 2 : nCla;

    if bNew
        bTry = true(1, nCla);
    end

    if nCla > 1

        mPci = [vOne, zeros(NOSP, nCla - 1)];
        mDeb = ones(NOSP, nCla);

        vRan = cRan{1};
        nBeg = vRan(1);

        if vMax(1) > 0
            lLim = vMax(1) * LLIM;
            uLim = vMax(1) * ULIM;
        else
            lLim = vMax(1) * ULIM;
            uLim = vMax(1) * LLIM;
        end

        y = cMoy{1}(vRan);
        w = vAmp / vAmp(1);
        v = find((w > LLIM) & (w < ULIM) & bTry);

        yy = reshape(mtlinterp(y, NOSP, 2), NOSP, length(y));
        uSim = min(nSim, mtlpc(yy(vOth(1), :), yy(vOth(end), :), abs(yy(vOth(1), :)), 1, 0));

        for i = 2 : length(v)

            k = v(i);
            z = cMoy{k};
            r = cRan{k};
            t = z(r);

            x = find((t > lLim) & (t < uLim));
            x = x + r(1) - (vExt(1) - nBeg) - 1;
            x = x(x > 0);

            if any(x)
                [s, q] = max(mtlpc(y, z, cMUP{k}, x, nChk));
                if s > nChk
                    mPci(iMid, k) = s;
                    mDeb(iMid, k) = x(q);
                    if s < nSim
                        for j = vOth
                            [mPci(j, k), q] = max(mtlpc(yy(j, :), z, cMUP{k}, x, nChk));
                            mDeb(j, k) = x(q);
                        end
                        if max(mPci(:, k)) >= uSim
                            mPci(:, k) = max(mPci(:, k), nSim);
                            oSeg{2, k}(3, :) = NaN;
                        end
                    end
                end
            end

        end

        [vPci, iMax] = max(mPci, [], 1);
        iDeb = mDeb(iMax + (0 : NOSP : NOSP * (nCla - 1)));

        bTry(vPci < nChk) = false;
        iMrg = find(vPci >= nSim);
        [tmp, iTri] = sort(vPci(iMrg), 'descend');
        iChk = iMrg(iTri);

        iMrg = 1;
        w = oSeg{2, 1}(1, :);

        for j = 2 : length(iChk)
            k = [w, oSeg{2, iChk(j)}(1, :)];
            vDif = diff(sort(k));
            nBad = sum(vDif < nRef);
            if nBad <= eMax
                iMrg = [iMrg, iChk(j)];
                iRst = iRst(iRst ~= iChk(j));
                w = k;
            else
                bTry(k) = false;
                if bCan
                    oSeg{2, 1}(3, :) = 0;
                    oSeg{2, iChk(j)}(3, :) = 0;
                else
                    if any(isnan(oSeg{2, iChk(j)}))
                        oSeg{2, iChk(j)}(3, :) = 1;
                    end
                end
            end
        end

    else
        iMrg = 1;
    end

    iSeg = iSeg + 1;
    nMrg = length(iMrg);

    if nMrg == 1
        bNew = true;
        cSeg(:, iSeg) = oSeg(:, 1);
    else

        bNew = false;
        bBon = true(1, nCla);
        bBon([1, iMrg]) = false;
        pBon = bBon;
        pBon(1) = true;

        for i = 2 : nMrg

            k = iMrg(i);
            n = size(oSeg{1, k}, 2);
            d = vRan(1) - iDeb(k);

            if d > 0
                oSeg{1, k} = [zeros(d, n); oSeg{1, k}(1 : nFwd - d, :)];
            else
                oSeg{1, k} = [oSeg{1, k}(-d + 1 : nFwd, :); zeros(-d, n)];
            end

            oSeg{2, k}([1 2], :) = oSeg{2, k}([1 2], :) - d;

        end

        oSeg = [[{[oSeg{1, iMrg}]}; {[oSeg{2, iMrg}]}], oSeg(:, bBon)];
        cMoy{1}(vRan) = mean(oSeg{1}(vRan, :), 2);
        cMoy = [cMoy(1), cMoy(:, bBon)];

        cRan = cRan(pBon);
        cMUP = cMUP(pBon);
        vAmp = vAmp(pBon);
        vMax = vMax(pBon);
        vExt = vExt(pBon);
        bTry = bTry(pBon);

        iRst = 1 : size(oSeg, 2);

    end

    oSeg = oSeg(:, iRst);
    cMoy = cMoy(iRst);
    cRan = cRan(iRst);
    cMUP = cMUP(iRst);
    vAmp = vAmp(iRst);
    vMax = vMax(iRst);
    vExt = vExt(iRst);
    bTry = bTry(iRst);

end

nCla = size(cSeg, 2);
bBon = false(1, nCla);
for i = 1 : nCla
    bBon(i) = (size(cSeg{1, i}, 2) >= nMin);
end
cSeg = cSeg(:, bBon);


function cSeg = unlock(oSeg, nTwd)

PLIM = 2/3;
QLIM = 1/3;

if isempty(oSeg)
    cSeg = [];
    return;
end

nFwd = size(oSeg{1, 1}, 1);
nHwd = nFwd / 2;
tLok = ceil(nTwd / 2);
nMup = size(oSeg, 2);

iBeg = round(nHwd - 5 * nTwd);
iEnd = round(nHwd + 5 * nTwd);
mLok = zeros(nMup, 2);
vNum = zeros(1, nMup);

for i = 1 : nMup
    vTmp = sum(oSeg{1, i}([iBeg, iEnd], :) == 0, 2);
    vNum(i) = size(oSeg{1, i}, 2);
    wLok(i, :) = vTmp;
    mLok(i, :) = vTmp .* (vTmp / vNum(i) > PLIM);
end

while any(mLok(:))

    z = 1 : nMup;
    x = find(any(mLok, 2), 1, 'first');
    v = oSeg{2, x}(1, :);
    bBad = false(1, nMup);
    mLok(x, :) = 0;

    for i = find(z ~= x)

        uMin = min(vNum([i, x]) * QLIM);

        w = diff(sort([v, oSeg{2, i}(1, :)]));
        w = w(w < nFwd);

        if (length(w) >= uMin) 

            q = mtlunique(w);
            n = length(q);

            c = 0;
            bLok = false;
            while (c < n) && ~bLok
                c = c + 1;
                if length(w((w >= q(c) - tLok) & (w <= q(c) + tLok))) >= uMin
                    bLok = true;
                end
            end

            if bLok

                iLev = max(oSeg{2, i}(3, :));
                xLev = max(oSeg{2, x}(3, :));

                if iLev > xLev
                    bBad(i) = true;
                elseif iLev < xLev
                    bBad(x) = true;
                else
                    if size(oSeg{2, i}, 2) > size(oSeg{2, x}, 2)
                        bBad(x) = true;
                    else
                        bBad(i) = true;
                    end
                end

            end
        end
    end

    if ~any(bBad) && any(oSeg{2, x}(3, :) > 1)

        w = zeros(2, vNum(x));
        for j = 1 : vNum(x)
            q = find(oSeg{1, x}(:, j));
            w(1, j) = min(q);
            w(2, j) = max(q);
        end
        w = w(w > iBeg & w < iEnd);

        if any(w)
            q = mtlunique(w);
            n = length(q);
            c = 0;
            while (c < n) && ~bBad(x)
                c = c + 1;
                if (length(w((w >= q(c) - tLok) & (w <= q(c) + tLok))) >= uMin)
                    bBad(x) = true;
                end
            end
        end

    end

    oSeg = oSeg(:, ~bBad);
    mLok = mLok(~bBad, :);
    wLok = wLok(~bBad, :);
    vNum = vNum(~bBad);
    nMup = size(oSeg, 2);

end

cSeg = oSeg;


function [cMup, cSeg] = create1(vSig, oSeg, nTwd, nThr)

hTwd = round(nTwd / 2);
nMup = size(oSeg, 2);
vThr = nThr * [1 .5];

cSeg = cell(1, nMup);
cMup = cSeg;

u = size(oSeg{1, 1}, 1);
c = (0 : (u - 1)).';
z = (2 * nTwd + 1) : (u - 2 * nTwd - 1);
q = length(z);
o = ones(1, q);

uTwd = 2 * nTwd;

for i = 1 : nMup

    x = oSeg{2, i}(1, :);
    n = size(oSeg{1, i}, 2);
    y = x(o, :) + c(z, ones(1, n));
    m = vSig(y);

    b = ~isnan(oSeg{2, i}(3, :));
    v = median(m(:, b), 2);
    w = min(max(v), max(-v));
    t = vThr(max(oSeg{2, i}(3, :)));

    r = mtlshrink(v, w / nThr, uTwd, uTwd, t, 1);
    r = max(1, r(1) - hTwd) : min(q, r(end) + hTwd);

    cSeg{i} = m(r, :);
    cMup{i} = v(r);

end

nMup = length(cMup);
vAmp = zeros(1, nMup);
for i = 1 : nMup
    vAmp(i) = max(cMup{i}) - min(cMup{i});
end

[tmp, iTri] = sort(vAmp, 'descend');
cMup = cMup(iTri);
cSeg = cSeg(iTri);


function [cMup, cSeg] = createN(vSig, cCan, nTwd, oThr, nRef)

QBAS = 1/5;
QHAU = 1/2;
QMIN = 5;
NHWD = 50;
NMIN = 30;
VOFF = [-1 0 1];
TLOK = 2;

nCan = size(cCan, 2);
nPts = size(vSig, 1);

vCan = [];
for iCan = 1 : nCan
    vCan = [vCan, iCan * ones(1, size(cCan{iCan}, 2))];
end

cCan = [cCan{:}];
nCla = size(cCan, 2);
vLab = zeros(1, nCla);

nHwd = NHWD * nTwd;
hTwd = round(nTwd / 2);
tLok = round(nTwd / 2);

vNum = zeros(1, nCla);
for i = 1 : nCla
    vNum(i) = size(cCan{2, i}, 2);
end

wCan = 1 : nCla;

mDup = zeros(nCla);
bGen = true(nCla, 1);

iLab = 0;

while any(vLab == 0)

    iPos = find(vLab == 0, 1, 'first');
    iLab = iLab + 1;
    vLab(iPos) = iLab;

    bSur = all(cCan{2, iPos}(3, :) ~= 0);
    
    v = cCan{2, iPos}(1, :);

    for i = wCan(wCan ~= iPos)

        y = diff(sort([v, cCan{2, i}(1, :)]));
        w = y(y < nHwd);
        q = diff(sort(w));
        q = q(q <= TLOK);
        
        n = vNum([iPos, i]);
        u = floor(min([max(min(n * QBAS), QMIN), n * QHAU]));
        
        if (length(w) >= u) && (length(q) >= (u - 1))

            q = mtlunique(w);
            n = length(q);

            s = zeros(1, n);
            for j = 1 : n
                s(j) = length(find(w == q(j)));
            end

            [tmp, z] = sort(s, 2, 'descend');

            c = 0;

            while (c < n)

                c = c + 1;
                k = q(z(c));

                ww = w((w >= k - TLOK) & (w <= k + TLOK));
                
                if length(ww) >= u
        
                    c = Inf;
                    bLok = false;

                    if bSur ~= all(cCan{2, i}(3, :) ~= 0)
                        if bSur
                            j = [i, find(vLab == vLab(i) & vLab ~= 0)];
                            bGen(j) = false;
                        else
                            j = [iPos, find(vLab == vLab(iPos) & vLab ~= 0)];
                            bGen(j) = false;
                        end
                    end

                    if all(bGen([iPos, i]))
                        yy = y((y > k + nTwd) & (y < nRef));
                        if any(yy)
                            x = [diff(sort(cCan{2, iPos}(1, :))), ...
                                diff(sort(cCan{2, i}(1, :)))];
                            if length(yy) <= length(x(x < nRef)) + 1
                                bLok = true;
                            else
                                mDup(iPos, i) = 1;
                            end
                        else
                            bLok = true;
                        end
                    end
                    
                    if bLok

                        k = round(mean(ww)); 
                        w = cCan{2, i}(1, :);

                        a = diff(sort([v, w - k]));
                        a = a(a <= tLok);
                        if any(a)
                            aa = sum(a);
                        else
                            aa = Inf;
                        end

                        b = diff(sort([v, w + k]));
                        b = b(b <= tLok);
                        if any(b)
                            bb = sum(b);
                        else
                            bb = Inf;
                        end

                        if length(a) > (2 * length(b))
                            kk = -k;
                        elseif length(b) > (2 * length(a))
                            kk = k;
                        else
                            if aa < bb
                                kk = -k;
                            else
                                kk = k;
                            end
                        end

                        if vLab(i) == 0
                            vLab(i) = iLab;
                            cCan{2, i}(1 : 2, :) = cCan{2, i}(1 : 2, :) + kk;
                        else
                            jLab = find(vLab == vLab(i));
                            vLab(jLab) = iLab;
                            for j = jLab
                                cCan{2, j}(1 : 2, :) = cCan{2, j}(1 : 2, :) + kk;
                            end
                        end

                    end
                end
            end
        end
    end
end

vDup = sum(mDup, 2);
if any(vDup)
    for i = find(vDup > 1).'
        vDup(i) = 0;
        bGen(i) = false;
        iFin = find(mDup(i, :));
        vDup(iFin) = vDup(iFin) - 1;
    end
    for i = find(vDup > 0).'
        iFin = find(mDup(i, :));
        if all(bGen([i, iFin]))
            if vNum(i) > vNum(iFin)
                bGen(iFin) = false;
            else
                bGen(i) = false;
            end
        end
    end
end

uLab = mtlunique(vLab(bGen));
nMup = length(uLab);

cSeg = cell(nCan, nMup);
cMup = cell(1, nMup);

vWin = (-nHwd : nHwd).';
nWin = length(vWin);
vOne = ones(1, nWin);
uTwd = 2 * nTwd;
kTwd = 5 * nTwd;
vStd = [1 : kTwd, 2 * nHwd + 1 - kTwd : 2 * nHwd + 1];

for iMup = 1 : nMup

    iFin = find(vLab == uLab(iMup));
    nFin = length(iFin);

    x = [cCan{2, iFin}]; 
    if  (nFin == 1) || all(x(end, :) == 0) || all(x(end, :) ~= 0)
        [x, iTri] = sort(ceil(sum(x([1 2], :), 1) / 2));
    else
        bBon = true(1, nFin);
        for i = 1 : nFin
            bBon(i) = all(cCan{2, iFin(i)}(end, :) ~= 0);
        end
        if any(bBon)
            x = [cCan{2, iFin(bBon)}];
            [x, iTri] = sort(ceil(sum(x([1 2], :), 1) / 2));
        else
            [x, iTri] = sort(ceil(sum(x([1 2], :), 1) / 2));
        end
    end
    
    if nFin > 1
        vNum = zeros(1, nFin);
        for i = 1 : nFin
            vNum(i) = size(cCan{2, iFin(i)}, 2); 
        end
        [vNum, jTri] = sort(vNum);
        v = [];
        for i = 1 : nFin
            j = find(jTri == i);
            v = [v, j * ones(1, vNum(j))]; 
        end
        x = mtlchoose(x, v(iTri), nRef);
    end
    
    x = x(:, (x > nHwd) & (x + nHwd < nPts));
    n = size(x, 2);

    mRan = zeros(nCan, 2);
        
    for iCan = 1 : nCan

        y = nPts * (iCan - 1) + x;
        y = y(vOne, :) + vWin(:, ones(1, n));

        mSeg = vSig(y);

        if any(vCan(iFin) == iCan)
            bTmp = (vLab == uLab(iMup)) & (vCan == iCan);
            xx = [cCan{2, find(bTmp, 1, 'first')}];
            if all(xx(end, :) ~= 0) && (size(xx, 2) > size(mSeg, 2) / 2) 
                xx = sort(ceil(sum(xx([1 2], ~isnan(xx(end, :))), 1) / 2));
                xx = xx(:, (xx > nHwd) & (xx + nHwd < nPts));
                nn = size(xx, 2);
                yy = nPts * (iCan - 1) + xx;
                yy = yy(vOne, :) + vWin(:, ones(1, nn));
                vv = median(vSig(yy), 2);
            else
                vv = median(mSeg, 2);
            end
        else
            vv = median(mSeg, 2);
        end

        m = min(max(vv), max(-vv));
        t = oThr(iCan);

        if ~any(vCan(iFin) == iCan)
            t = max(oThr(iCan), 3 * std(vv(vStd)));
            if n < NMIN 
                t = 2 * t;
                if n < NMIN / 2
                    t = 2 * t;
                end
            end
        else
            if n < NMIN
                t = max(t, (max(vv) - min(vv)) / 100);
            end
        end

        cSeg{iCan, iMup} = mSeg;
        cMup{iCan, iMup} = vv;

        if m > t
            r = mtlshrink(vv, ceil(m / t), uTwd, uTwd, t, 2);
            w = vv(r);
            if (max(w) < t) || (max(-w) < t)
                r = 1;
            end
        else
            r = 1;
        end

        if (r(1) > 1)
            mRan(iCan, :) = [r(1), r(end)];
        else
            mRan(iCan, :) = [Inf, 0];
        end

    end

    r = max(1, min(mRan(:, 1)) - hTwd) : min(nWin, max(mRan(:, 2)) + hTwd);

    for iCan = 1 : nCan
        cSeg{iCan, iMup} = cSeg{iCan, iMup}(r, :);
        cMup{iCan, iMup} = cMup{iCan, iMup}(r);
    end

end


function nOut = mtlvar(mIns, nDim)

vMoy = mean(mIns, nDim);

if nDim == 1
    mVar = abs(mIns - vMoy(ones(size(mIns, 1), 1), :));
else
    mVar = abs(mIns - vMoy(:, ones(size(mIns, 2), 1)));
end

nOut = sum(mVar(:));


function v = mtlinterp(y, nSur, nDim)

m = length(y);
q = m * nSur;
x = 1 : m;
u = [1 + (0 : q - 2) * (m - 1) / (q - 1), m];
k = min(max(1 + floor(u - 1), 1), m - 1);

if nDim == 2
    u = u.';
    x = x.';
end

v = y(k) + (u - x(k)) .* (y(k + 1) - y(k));