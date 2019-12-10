%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function [mDat, mSup] = mtlrefine(cMup, mDat, mSup, vSeg, iLis, vSur, nSur, nIte) 

wDat = mDat;
nMup = length(iLis);
bTry = true(1, nMup);

for c = 1 : nIte

    for i = 1 : nMup
        
        k = iLis(i);
        g = iLis ~= k;
        v = mDat(1, k) + cMup{6, k};
        b = cMup{7, k}; 
        
        a = vSeg(v) - sum(mSup(g, v), 1); 
        A = abs(a);
        a = a(vSur, :);
        A = A(vSur, :);
        mMAX = max(A, cMup{8, k});
        
        vPsc = sum(b .* a - abs(a - b) .* mMAX, 2) ./ sum(mMAX .^ 2, 2);
        
        [m, y] = max(vPsc);

        o = 0;

        if bTry(i)
            if y == 1 
                o = 1;
                bTry(i) = false;
            elseif y == nSur
                o = -1;
                bTry(i) = false;
            end
        end
        
        if o
            v = v + o;
            a = vSeg(v) - sum(mSup(g, v), 1); 
            A = abs(a);
            a = a(vSur, :);
            A = A(vSur, :);
            mMAX = max(A, cMup{8, k});
            vPsc = sum(b .* a - abs(a - b) .* mMAX, 2) ./ sum(mMAX .^ 2, 2);
            [mm, yy] = max(vPsc);
            if mm > m
                mDat(2, k) = 0;
                m = mm;
                y = yy;
            else
                o = 0;
            end
        end

        if y ~= mDat(2, k)
            mDat(:, k) = [mDat(1, k) + o; y; m];
            mSup(i, mDat(1, k) + cMup{5, k}) = cMup{1, k}(y, :);
        else
            mDat(3, k) = m;
        end
        
    end

    if sum(mDat(end, iLis)) <= sum(wDat(end, iLis))
        mDat = wDat;
        break;
    else
        wDat = mDat;
    end

end


