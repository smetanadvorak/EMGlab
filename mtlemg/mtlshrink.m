%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function r = mtlshrink(vSig, t, w, n, a, o)

if ~exist('o', 'var')
    o = 1;
end

s = abs(vSig);
m = min(max(vSig), -min(vSig));
t = max(m / t, a);
mInd = mtlsegment(vSig, t, w, n);
u = size(mInd, 1);

if (u == 0)
    r = [1 length(vSig)];
else
    if (u == 1)
        r = mInd;
    else

        p = zeros(1, u);
        for i = 1 : u
            v = vSig(mInd(i, 1) : mInd(i, 2));
            p(i) = max(v) - min(v);
        end
        [pMax, iMax] = max(p);

        switch o

            case 1

                z = length(vSig) / 2;
                r = mInd(mInd(:, 1) < z & mInd(:, 2) > z, :);
                if ~any(r)
                    r = mInd(iMax, :);
                end

            case 2

                F = 4;
                mInd = mInd(p >= pMax / F, :);
                r = mInd([1 end]);

            case 3

                F = 3;
                r = mInd(iMax, :);
                h = 2 * w;

                d = iMax - 1;
                if (iMax > 1) && (r(1) - mInd(d, 2) < h) && (p(d) * F > p(iMax))
                    r(1) = mInd(d, 1);
                end
                
                d = iMax + 1;
                if (iMax < u) && (mInd(d, 1) - r(2) < h) && (p(d) * F > p(iMax))
                    r(2) = mInd(d, 2);
                end

            case 4

                r = mInd(iMax, :);
                
            otherwise
                error('Wrong option for function shrink!')

        end
    end
end

R = r;

if (a > 0) && (u > 0)

    vOne = ones(size(vSig));
    vOne(2 : 2 : end) = -1;
    vSig = vSig + .05 * m * vOne;

    b = s > min(a, m/2);
    b([1 : r(1), r(2) : end]) = 0;
    v = sign(diff(vSig));
    v(end + 1) = 0;

    x = find(b, 1, 'first') - 1;
    if x > r(1)
        k = find(v == -v(x));
        k = max(k(k < x));
        if any(k)
            r(1) = k + 1;
        end
    end

    x = find(b, 1, 'last') + 1;
    if x < r(end)
        k = find(v == -v(x));
        k = min(k(k > x));
        if any(k)
            r(end) = k;
        end
    end

end

if r(2) - r(1) <= 2 * w
    r = R(1) : R(2);
else
    r = r(1) : r(2);
end