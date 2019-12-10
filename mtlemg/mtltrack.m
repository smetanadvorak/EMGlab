%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function [cSit, mSig, mNew, cFlg, vRef] = ...
    mtltrack(mSig, cSit, cMup, vSim, nRat, vRef, vThr, nJit, bEnd, cFlg, mNew, pMin)

NGAP = 2;
NEPS = 1e-6;
NREQ = 3;
RSTD = 2;
RMAX = 100;
SPAT = NEPS;
RLOC = [2 3];
SMIN = 1/3;
SREL = 3/4;
LSIM = 1/3;
USIM = 3;

[tmp, nMup, nCan] = size(cMup);

bCan = nCan > 1;
bSin = ~bCan;
bNew = isempty([cSit{:}]);
bDeb = bSin && bNew;
bPat = bEnd && ~isempty(pMin);
fEng = bEnd;
bEnd = bCan && (bEnd > 0);

nPts = size(mSig, 2);
mSIG = abs(mSig);

sCur = vSim(1);
sMin = vSim(end);
sCrs = sCur .^ 2;

if isempty(mNew)
    mNew = true(nCan, nPts);
    if bCan
        cFlg = cell(nCan, nMup);
    end
elseif bSin
    mPat = mtlpattern(cSit, nPts, NGAP, pMin);
end

if bDeb
    cFlg = cell(nCan, nMup);
end

nSur = size(cMup{1, 1, 1}, 1);
iMid = ceil(nSur / 2);
vSur = ones(nSur, 1);

nChk = NEPS;

cMax = cell(1, nCan);
cMin = cell(1, nCan);
cPic = cell(1, nCan);
cPos = cell(1, nCan);

for iCan = 1 : nCan

    cPos{iCan} = reshape([cMup{5, :, iCan}], 2, nMup);
    cPic{iCan} = reshape([cMup{6, :, iCan}], 2, nMup);
    iPic = (cPic{iCan}(1, :) < -cPic{iCan}(2, :)) + (1 : 2 : (2 * nMup));
    cPic{iCan} = cPic{iCan}(iPic);
    cPos{iCan} = cPos{iCan}(iPic);

    nMax = .5 * min(cPic{iCan}(cPic{iCan} > 0));
    if ~isempty(nMax)
        cMax{iCan} = find(mtlloc(mSig(iCan, :), 0, max(nMax, vThr(iCan))));
    end
    nMin = -.5 * max(cPic{iCan}(cPic{iCan} < 0));
    if ~isempty(nMin)
        cMin{iCan} = find(mtlloc(-mSig(iCan, :), 0, max(nMin, vThr(iCan))));
    end

end

mLmk = reshape([cMup{7, :, :}], nMup, nCan).';
mFac = reshape([cMup{8, :, :}], nMup, nCan).';

if bCan

    [bThr, iTri] = mtlselect(cMup, vThr);

    nGit = 1;
    uGit = 2 * nGit + 1;
    vGit = -nGit : nGit;
    zGit = zeros(1, nGit);

    uJit = 2 * nJit + 1;
    vJit = (-nJit : nJit).';
    wJit = (-uJit : uJit).';
    zJit = zeros(1, uJit);
    jOne = ones(length(wJit), 1);
    vCan = 1 : nCan;

else
    wThr = vThr(ones(nMup, 1), :);
    mAmp = abs(reshape([cMup{6, :, :}], 2, nCan * nMup));
    [tmp, iTri] = sort(sum(mAmp, 1) ./ wThr(:).', 2, 'descend');
end

for iWav = iTri

    iCan = ceil((iWav - NEPS) / nMup);
    iMup = round(mod(iWav, nMup + NEPS));

    bCrs = true;
    if bCan
        if bEnd
            iFin = find(cMup{9, iMup, iCan} == 1);
        else
            iFin = find(cMup{9, iMup, iCan} > sCrs);
        end
        vCrs = [];
        if any(iFin)
            bCrs = false;
            if all(iFin ~= iMup)
                pCrs = true;
                vCrs = [cSit{:, iFin}];
                if isempty(vCrs)
                    pCrs = false;
                else
                    vCrs = mtlunique(vCrs(1, :));
                end
                if any(cMup{9, iMup, iCan} > sCrs / mFac(iCan, iMup))
                    mFac(iCan, iMup) = 1;
                end
            else
                pCrs = false;
            end
        end
    end

    nRef = vRef(iMup);
    nFac = mFac(iCan, iMup);
    fCur = sCur / nFac;
    fPat = SPAT / nFac;
    fMin = sMin / nFac;

    r = cMup{2, iMup, iCan};
    cPos{iCan}(iMup) = cPos{iCan}(iMup) - r(1);

    bFlg = bCan && ~isempty(cFlg{iCan, iMup});

    if cPic{iCan}(iMup) > 0
        vMax = mSig(iCan, cMax{iCan});
        vLoc = cMax{iCan}(vMax > LSIM * cPic{iCan}(iMup) & ...
            vMax < USIM * cPic{iCan}(iMup)) - cPos{iCan}(iMup);
    else
        vMin = mSig(iCan, cMin{iCan});
        vLoc = cMin{iCan}(vMin < LSIM * cPic{iCan}(iMup) & ...
            vMin > USIM * cPic{iCan}(iMup)) - cPos{iCan}(iMup);
    end

    if bFlg
        vFlg = cFlg{iCan, iMup};
        vFlg = vFlg(vFlg > 0);
        vLoc = [vLoc, vFlg];
    end

    if any(vLoc)
        
        m = cMup{1, iMup, iCan};
        a = m(:, r);
        A = abs(a);

        nLon = size(m, 2);

        gLoc = vLoc;
        vLoc = [vLoc - 1, vLoc, vLoc + 1];
        vLoc = mtlunique(vLoc(vLoc > 0));
        vCor = mtlpc(a(iMid, :), mSig(iCan, :), mSIG(iCan, :), vLoc, nChk);
        iCor = find(vCor > nChk);
        vLoc = vLoc(iCor) - r(1) + 1;

        vDif = diff(vLoc);
        iFin = find(vDif < nRef);

        while any(iFin)
            bSit = true(size(vLoc));
            iSit = [iFin; iFin + 1];
            [tmp, x] = min(vCor(iCor(iSit)));
            bSit(iSit(x + 2 * (0 : size(iSit, 2) - 1))) = false;
            vLoc = vLoc(bSit);
            vDif = diff(vLoc);
            iFin = find(vDif < nRef);
        end

        vSit = [cSit{iCan, iMup}];
        if ~isempty(vSit) && any(vLoc)
            vSit = vSit(1, :);
            nLoc = length(vLoc);
            bLoc = true(1, nLoc);
            for iLoc = 1 : nLoc
                bLoc(iLoc) = all(abs(vLoc(iLoc) - vSit) >= nRef);
            end
            vLoc = vLoc(bLoc);
        end

        if bCan && any(vLoc) && ~isempty([cSit{:, iMup}])

            vSit = [];
            for jCan = find(vCan ~= iCan)
                vTmp = [cSit{jCan, iMup}];
                if ~isempty(vTmp)
                    vSit = [vSit, vTmp(1, :)];
                end
            end

            nLoc = length(vLoc);
            bLoc = true(1, nLoc);
            for iLoc = 1 : nLoc
                vMix = abs(vLoc(iLoc) - vSit);
                vMix = vMix(vMix > uJit);
                bLoc(iLoc) = all(vMix >= nRef);
            end

            vLoc = vLoc(bLoc);

        end

        if any(vLoc)

            if bCan && bPat
                mPat = mtlpattern(cSit(iCan, iMup), nPts, NGAP, pMin);
            end

            nLoc = size(vLoc, 2);
            mLoc = zeros(4, nLoc);
            mLoc(1, :) = vLoc;
            bLoc = false(1, nLoc);

            mEdg = [vLoc; vLoc + nLon - 1];

            if bDeb
                fLoc = bLoc;
            end

            if bCan
                bDej = false;
                vDej = [cSit{:, iMup}];
                if ~isempty(vDej)
                    bDej = true;
                    vDej = mtlunique(vDej(1, mod(vDej(3, :), 1) > fMin));
                end
            end

            for iLoc = 1 : nLoc

                t = mEdg(1, iLoc) : mEdg(2, iLoc);
                v = mSig(iCan, t);
                b = v(vSur, r);
                x = max(A, abs(b));
                c = sum(b .* a - abs(a - b) .* x, 2) ./ sum(x .^ 2, 2);

                [s, y] = max(c);

                if (y == 1) || (y == nSur)

                    if (y == 1)
                        o = 1;
                    else
                        o = -1;
                    end

                    tt = t;
                    vv = v;
                    ss = s;
                    yy = y;

                    t = t + o;
                    v = mSig(iCan, t);
                    b = v(vSur, r);
                    x = max(A, abs(b));

                    c = sum(b .* a - abs(a - b) .* x, 2) ./ sum(x .^ 2, 2);
                    [s, y] = max(c);

                    if ss > s
                        s = ss;
                        t = tt;
                        v = vv;
                        y = yy;
                    else
                        mLoc(1, iLoc) = mLoc(1, iLoc) + o;
                    end

                end

                mLoc(RLOC, iLoc) = [y; s];

                if bCan
                    bBon = (bPat && (s >= fPat) && any(mPat(t))) || ...
                        (bDej && ((s >= fMin) || bEnd) && any(abs(vDej - t(1)) <= uJit));
                    if ~bBon
                        if bCrs
                            bBon = (s >= fCur);
                        else
                            bBon = (pCrs && (s >= fCur) && any(abs(vCrs - t(1)) <= nRef));
                        end
                    end
                else
                    bBon = (s >= fCur) || (bPat && (s >= fPat) && any(mPat(iMup, t)));
                end

                if bBon

                    v = v - m(y, :);

                    mSig(iCan, t) = v;
                    mSIG(iCan, t) = abs(v);
                    mNew(iCan, t(r)) = false;

                    bLoc(iLoc) = true;

                elseif s >= fMin

                    fLoc(iLoc) = true;

                end

            end

            if bFlg && any(vFlg)

                v = vFlg(vFlg > 0);

                if any(v)

                    if isempty(cSit{iCan, iMup})
                        x = mLoc(1, bLoc);
                    else
                        x = [cSit{iCan, iMup}(1, :), mLoc(1, bLoc)];
                    end

                    n = length(x);
                    w = x(jOne, :) + wJit(:, ones(1, n));
                    w = w(:).';
                    b = ismember(v, w);
                    cFlg{iCan, iMup} = v(~b);

                end

            end

            if any(bLoc)

                for jCan = 1 : nCan

                    if jCan == iCan
                        cSit{iCan, iMup} = [cSit{iCan, iMup}, mLoc(:, bLoc)];
                    else

                        if bThr(jCan, iMup)

                            x = vLoc(bLoc);

                            if ~isempty(cSit{jCan, iMup})
                                v = [cSit{jCan, iMup}(1, :), cFlg{jCan, iMup}];
                            else
                                v = cFlg{jCan, iMup};
                            end

                            if any(v)
                                n = length(v);
                                w = v(jOne, :) + wJit(:, ones(1, n));
                                w = w(:).';
                                b = ismember(x, w);
                                cFlg{jCan, iMup} = [cFlg{jCan, iMup}, x(~b)];
                            else
                                cFlg{jCan, iMup} = [cFlg{jCan, iMup}, x];
                            end

                        else

                            pLoc = bLoc;
                            zLoc = mLoc;
                            zLoc(3, :) = 0;

                            if ~isempty(cSit{jCan, iMup})
                                vSit = cSit{jCan, iMup}(1, :);
                                for i = find(bLoc)
                                    pLoc(i) = all(abs(zLoc(1, i) - vSit) > uJit);
                                end
                            end

                            w = cMup{1, iMup, jCan};
                            n = size(w, 2) - 1;
                            z = 0 : n;
                            r = cMup{2, iMup, jCan};
                            q = r - 1;
                            a = w(:, r);

                            iFin = find(pLoc);
                            for jFin = iFin

                                f = zLoc(1, jFin);
                                tSig = mSig(jCan, f - nGit : f + nGit + n);
                                mGit = zGit;
                                yGit = zGit;
                                for iGit = 1 : uGit
                                    [mGit(iGit), yGit(iGit)] = max(sum(a .* tSig(vSur, q + iGit), 2));
                                end
                                [tmp, yy] = max(mGit);

                                o = vGit(yy);
                                v = tSig(nGit + 1 + o + z) - w(yGit(yy), :);

                                zLoc(1 : 2, jFin) = [f + o; yGit(yy)];
                                mSig(jCan, f + o + z) = v;

                            end

                            cSit{jCan, iMup} = [cSit{jCan, iMup}, zLoc(:, pLoc)];

                        end
                    end
                end
            end

            if bDeb
                cFlg{iCan, iMup} = vLoc(fLoc);
            end

        end
    end
end

if bEnd

    for iWav = iTri

        iCan = ceil((iWav - NEPS) / nMup);
        iMup = round(mod(iWav, nMup + NEPS));
        
        nLon = size(cMup{1, iMup, iCan}, 2) - 1;
        bUnr = cMup{9, iMup, iCan}(iMup) == 1;

        if sum(bThr(:, iMup)) > 2
            hEng = 1;
        else
            hEng = fEng;
        end

        vFlg = cFlg{iCan, iMup};
        vFlg = vFlg(vFlg > 0);

        if any(vFlg)

            mFlg = zeros(4, size(vFlg, 2));
            mFlg(1, :) = vFlg;

            w = cMup{1, iMup, iCan};
            n = size(w, 2) - 1;
            z = 0 : n;
            r = cMup{2, iMup, iCan};
            q = r - 1;
            a = w(:, r);

            for iFlg = 1 : length(vFlg)

                f = vFlg(iFlg);
                tSig = mSig(iCan, f - nGit : f + nGit + n);

                mJit = zGit;
                yJit = zGit;

                for iJit = 1 : uGit
                    [mJit(iJit), yJit(iJit)] = min(sum(abs(a - tSig(vSur, q + iJit)), 2));
                end

                [nEng, yy] = min(mJit);

                o = vGit(yy);
                x = f + o;
                y = yJit(yy);
                v = tSig(nGit + 1 + o + z);

                bRem = false;

                if bUnr || (nEng < hEng * sum(abs(v(r)))) 
                    bRem = true;
                else
                    nBon = 0;
                    for jCan = find(vCan ~= iCan)
                        if bThr(jCan, iMup) && ~isempty(cSit{jCan, iMup})
                            vv = cSit{jCan, iMup}(1, :);
                            s = mod(cSit{jCan, iMup}(3, :), 1);
                            b = find(vv >= f - uJit & vv <= f + uJit);
                            if any(b) 
                                s = mod(s(b), 1);
                                if s > SREL
                                    nBon = nBon + 2;
                                elseif s > 0
                                    nBon = nBon + 1;
                                end
                            end
                        end
                    end
                    bRem = nBon > 1;
                end

                if bRem

                    v = v - w(y, :);
                    mSig(iCan, x + z) = v;

                    mFlg(1, iFlg) = mFlg(1, iFlg) + o;
                    mFlg(2, iFlg) = y;

                else

                    for jCan = find(vCan ~= iCan)

                        if ~isempty(cSit{jCan, iMup})
                            v = cSit{jCan, iMup}(1, :);
                            h = find(v >= f - uJit & v <= f + uJit);
                            if any(h)
                                b = true(size(v));
                                b(h) = false;
                                v = v(h) : v(h) + nLon;
                                mSig(jCan, v) = mSig(jCan, v) + ...
                                    cMup{1, iMup, jCan}(cSit{jCan, iMup}(2, ~b), :);
                                cSit{jCan, iMup} = cSit{jCan, iMup}(:, b);
                            end
                        end

                        v = cFlg{jCan, iMup};
                        if any(v)
                            h = (v >= f - uJit & v <= f + uJit);
                            if any(h)
                                cFlg{jCan, iMup} = v(~h);
                            end
                        end

                    end

                    vFlg(iFlg) = 0;

                end

            end

            cSit{iCan, iMup} = [cSit{iCan, iMup}, mFlg(:, vFlg > 0)];
            cFlg{iCan, iMup} = [];

        end
    end
end

if nargout == 5

    wRef = zeros(1, nMup);
    nReq = NREQ * round(nPts / nRat);
    zCan = zeros(1, nCan);

    for iMup = 1 : nMup

        if bCan
            vCan = zCan;
            for jCan = 1 : nCan
                vCan(jCan) = size(cSit{jCan, iMup}, 2);
            end
            [tmp, iCan] = max(vCan);
        else
            iCan = 1;
        end

        n = size(cSit{iCan, iMup}, 2);

        if n >= nReq
            v = round(sort(diff(sort(cSit{iCan, iMup}(1, :)))));
            wRef(iMup) = v(2) - RSTD * std(v(1 : ceil(n / 4)));
        end

    end

    vRef = max(vRef, wRef);
    vRef = min(vRef, RMAX * nRat / 1000);
    if any(wRef > 0)
        rMin = min(vRef(wRef > 0));
        vRef(wRef == 0) = rMin;
        vRef = round(vRef);
    end

end