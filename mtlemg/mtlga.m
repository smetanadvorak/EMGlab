%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function mDat = mtlga(cMup, vLis, oSeg, wGen, mFac, ...
    vLon, cOri, cOrd, jRan, kRan, nUth, nDth, sCur, sMin, nSec)

NEPS = 1e-6;
SMIN = 1/3; 
CMAX = 3;
GMAX = 15; 
RMUT = .025; 
NRAN = 1000;
MMIN = 2;
CFAC = 1.1;

nMup = size(cMup, 2);
lSeg = size(oSeg, 2);
nOsp = size(cMup{1}, 1);
vOsp = ones(nOsp, 1);
iMid = ceil(nOsp / 2);

zDat = zeros(3, nMup);

nMoy = 0;
nCon = 0;
nItr = 0;

nLis = length(vLis);
nPar = 2 ^ nLis;
nPop = 2 * nPar;
vPar = 1 : nPar;

mGen = [];
for i = MMIN : nLis
    c = nchoosek(1 : nLis, i);
    z = zeros(NRAN, nLis);
    for j = 1 : size(c, 1)
        v = z;
        v(:, c(j, :)) = 1;
        mGen = [mGen; v];
    end
end

iMax = find(mtlloc(oSeg, 0, nUth));
iMax = iMax(iMax > jRan & iMax < kRan);
iMin = find(mtlloc(-oSeg, 0, nDth));
iMin = iMin(iMin > jRan & iMin < kRan);
vTmp = [iMax, iMin];
vExt = [min(vTmp); max(vTmp)];

nThr = min(nUth, nDth);

mLim = [0; Inf];

nGen = size(mGen, 1);
vLim = zeros(1, nLis);
for i = 1 : nLis
    k = vLis(i);
    vLim(i) = lSeg - vLon(k) - 1;
    wExt = find(mtlloc(abs(cMup{1, i}(iMid, :)), 0, nThr));
    if any(wExt)
        vTmp = min(max([vExt(1) - wExt(1) - nSec; vExt(end) - wExt(end) + nSec], 2), vLim(i));
    else
        vTmp = [jRan; min(kRan, vLim(i))];
    end
    mLim = [max(mLim(1), vTmp(1)); min(mLim(2), vTmp(2))];
    mGen(:, i) = mGen(:, i) .* ceil(sum(vTmp) / 2 + diff(vTmp) * (rand(nGen, 1) - .5));
end

mGen = [mGen; wGen];

nGra = 2 ^ nLis - 1;
cGra = cell(1, nGra);
cCos = cell(1, nGra);
cRef = cell(1, nGra); 
vBas = 2 .^ (0 : (nLis - 1))';

uSeg = oSeg(ones(nPop, 1), :);
nNor = sum(abs(oSeg));
nPos = max(vLim) * nLis;

gDat = zDat;
gCos = Inf;

while (nItr <= GMAX) 

    if nItr > 1

        iMom = randperm(nPar);
        iDad = randperm(nPar);

        m = mGen(iMom, :);
        d = mGen(iDad, :);
        f = zeros(nPar, nLis);
        g = zeros(nPar, nLis);
        p = ceil(nLis * rand(nPar, 1)) .* sign(rand(nPar, 1) - .5);

        for i = vPar

            a = abs(p(i));

            if p(i) > 0
                if (a <= 1)
                    c = (m(i, 1) - d(i, 1)) * (m(i, 1) & d(i, 1)) * .5;
                    f(i, :) = [m(i, 1) - c, d(i, 2 : end)];
                    g(i, :) = [d(i, 1) + c, m(i, 2 : end)];
                elseif (a >= nLis)
                    c = (m(i, :) - d(i, :)) .* (m(i, :) & d(i, :)) * .5;
                    f(i, :) = m(i, :) - c;
                    g(i, :) = d(i, :) + c;
                else
                    x = 1 : a;
                    c = (m(i, x) - d(i, x)) .* (m(i, x) & d(i, x)) * .5;
                    f(i, :) = [m(i, x) - c, d(i, a + 1 : end)];
                    g(i, :) = [d(i, x) + c, m(i, a + 1 : end)];
                end
            else
                if (a <= 1)
                    x = 2 : nLis;
                    c = (m(i, x) - d(i, x)) .* (m(i, x) & d(i, x)) * .5;
                    f(i, :) = [d(i, 1), m(i, x) - c];
                    g(i, :) = [m(i, 1), d(i, x) + c];
                elseif (a >= nLis)
                    c = (m(i, :) - d(i, :)) .* (m(i, :) & d(i, :)) * .5;
                    f(i, :) = d(i, :) - c;
                    g(i, :) = m(i, :) + c;
                else
                    x = a + 1 : nLis;
                    c = (m(i, x) - d(i, x)) .* (m(i, x) & d(i, x)) * .5;
                    f(i, :) = [d(i, 1 : a), m(i, x) - c];
                    g(i, :) = [m(i, 1 : a), d(i, x) + c];
                end
            end

        end

        mGen = round([g; f]);
        mGen(mGen <= nSec) = 0;
        for i = 1 : nLis
            mGen(mGen(:, i) >= vLim(i), i) = 0;
        end

        nAll = numel(mGen);
        nMut = ceil(RMUT * nAll);
        
        vRan = randperm(nAll);
        vRan = vRan(1 : nMut);
        mGen(vRan) = 0;
        
        vRan = randperm(nAll);
        vRan = vRan(1 : nMut);
        mGen(vRan) = ceil(sum(mLim) / 2 + diff(mLim) * (rand(nMut, 1) - .5));

        bTmp = sum(mGen > 0, 2) < 2;
        if any(bTmp)
            mGen(bTmp, :) = vEli(ones(sum(bTmp), 1), :); 
        end

    end

    if nItr ~= 1

        nTmp = 0;
        rGen = zeros(nGen, nLis);
        oSup = zeros(nPos, lSeg);

        for i = 1 : nLis
            if any(mGen(:, i))
                u = mtlunique([0; mGen(:, i)]);
                k = vLis(i);
                for j = 2 : length(u)
                    nTmp = nTmp + 1;
                    oSup(nTmp, u(j) + cMup{5, k}) = cMup{1, k}(iMid, :); 
                    rGen(mGen(:, i) == u(j), i) = nTmp; 
                end
            end
        end

        oSup = oSup(1 : nTmp, :);
        mSup = zeros(nGen, lSeg);
        for i = 1 : nGen 
            mSup(i, :) = sum(oSup(rGen(i, rGen(i, :) > 0), :), 1); 
        end

    end

    if nItr == 0
        iGen = [];
        vCos = sum(abs(oSeg(ones(nGen, 1), :) - mSup), 2) / nNor;
        vEli = mGen(1, :);
    elseif nItr > 1
        vCos = sum(abs(uSeg - mSup), 2) / nNor;
        [vCos, iTri] = sort(vCos);
        mGen = mGen(iTri, :);
    end

    for i = iGen

        bBon = mGen(i, :) > 0;
        iGra = bBon * vBas;
        jGen = find(abs(cCos{1, iGra} - vCos(i)) < NEPS, 1, 'first'); 

        if isempty(jGen) && (isempty(cCos{1, iGra}) || ...
            ~any(all(abs(mGen(ones(size(cCos{1, iGra}, 1), 1) * i, bBon) - cGra{1, iGra}) <= 1, 2)))

            iBon = find(bBon);
            iLis = vLis(iBon);
            uLis = length(iLis);

            [a, b] = mtlgrad(mGen(i, iBon), cMup(:, iLis), oSeg, nNor, nSec, ...
                cOri{uLis}, cOrd{uLis}, vCos(i), vLim(iBon), cCos(:, iGra));

            cGra{1, iGra} = [cGra{1, iGra}; a];
            cCos{1, iGra} = [cCos{1, iGra}; b];

            mGen(i, iBon) = a(end, :);
            vCos(i) = b(end);

        end

        if ((vCos(i) < 1/2) || (i < nLis)) && all(abs(cRef{1, iGra} - vCos(i)) > NEPS)

            iBon = find(bBon);
            iLis = vLis(iBon);
            uLis = length(iLis);

            cRef{1, iGra} = [cRef{1, iGra}; vCos(i)];

            wSup = zeros(uLis, lSeg);
            mDat = zDat;
            mDat(1, iLis) = mGen(i, iBon);
            mDat(2, iLis) = iMid;

            wLis = 1 : uLis;
            for j = wLis
                k = iLis(j);
                wSup(j, mDat(1, k) + cMup{5, k}) = cMup{1, k}(iMid, :); 
            end
            
            for k = iLis
                v = mDat(1, k) + cMup{6, k};
                a = oSeg(v) - sum(wSup(iLis ~= k, v), 1);
                b = cMup{7, k}(iMid, :);
                mMAX = max(abs(a), abs(b));
                mDat(end, k) = sum(b .* a - abs(a - b) .* mMAX, 2) ./ sum(mMAX .^ 2, 2);
            end
            
            if any(mDat(end, iLis) > 0) 
                nIte = min([mGen(i, iBon), vLim(iBon) - mGen(i, iBon)]) - 1;
                mDat = mtlrefine(cMup, mDat, wSup, oSeg, iLis, vOsp, nOsp, nIte);
                mDat(end, iLis) = mDat(end, iLis) .* mFac(iLis);
            end
            
            if (sum(mDat(end, iLis)) / uLis > nMoy) && (vCos(i) <= gCos * CFAC) 
                
                gCos = vCos(i);
                
                vTmp = abs(mDat(1, :) - gDat(1, :));
                if any(vTmp > 1)
                    nCon = 1;
                end
                
                gDat = mDat;
                nMoy = sum(mDat(end, iLis)) / uLis;
                
                v = mDat(end, iLis);
                
                if all(v > sCur) || (all(v > sMin) && (sum(v > sCur) >= 4))
                    nItr = 2 * GMAX;
                    break;
                end

                vEli = mDat(1, vLis);
                
            end

        end
    end

    [vCos, iTri] = sort(vCos);
    mGen = mGen(iTri, :);
    bTmp = mtlprune(mGen, 1) | (sum(mGen > 0, 2) <= 2); 
    vTmp = vCos;
    vTmp(bTmp) = vTmp(bTmp) + 1;
    [tmp, iTri] = sort(vTmp);

    if nItr == 0
        nGen = nPop;
        v = iTri(1 : nGen);
        vCos = vCos(v);
        mGen = mGen(v, :);
        iGen = 1 : nGen;  
    else
        mGen = mGen(iTri(vPar), :);
    end                

    if ((nItr >= GMAX) || (nCon > CMAX)) && any(gDat(1, :))
        mDat = gDat;
        nItr = 2 * GMAX;
    end

    nItr = nItr + 1;
    nCon = nCon + 1;

end  