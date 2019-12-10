%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function bOut = mexseg(vIn, t, w)

[a, b] = size(vIn);
bOut = false(a, b);

if b > 1
    vIn = vIn(:);
    a = b;
end

vIN = abs(vIn);
vSlo = sign(diff(vIn));
bBon = ((vIN > t) | (abs([0; vSlo] - [vSlo; 0]) ~= 2)) & (vIN ~= 0);

m = 2 * w;
d = 2 * t;
p = 0;

for i = 2 : m
    
    q = 0;
   
    if bBon(i)
        q = 1;
    else
        if vIn(i)
            c = 0;
            while (c < m) && (q == 0)
                if abs(vIn(i) - vIn(i + m - c)) > d
                    q = 1;
                end
                c = c + 1;
            end
        end
    end
    
    if q ~= p
        bOut(i) = 1;
    end
    
    p = q;
                
end

for i = m + 1 : a - m
    
    q = 0;
   
    if bBon(i)
        q = 1;
    else
        if vIn(i)
            c = 0;
            while (c < w) && (q == 0)
                if (abs(vIn(i + w - c) - vIn(i - w + c)) > d) || ...
                        (abs(vIn(i + w) - vIn(i - w + c)) > d) || ...
                        (abs(vIn(i + w - c) - vIn(i - w)) > d)
                    q = 1;
                end
                c = c + 1;
            end
        end
    end
    
    if q ~= p
        bOut(i) = 1;
    end
                
    p = q;
    
end


for i = a - m + 1 : a - 1
    
    q = 0;
   
    if bBon(i)
        q = 1;
    else
        if vIn(i)
            c = 0;
            while (c < m) && (q == 0)
                if abs(vIn(i) - vIn(i - m + c)) > d
                    q = 1;
                end
                c = c + 1;
            end
        end
    end
    
    if q ~= p
        bOut(i) = 1;
    end
                
    p = q;
    
end