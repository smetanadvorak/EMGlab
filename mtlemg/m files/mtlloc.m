%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function bOut = mexloc(vIn, vIN, t)

bFlp = false;

if numel(vIn) ~= numel(vIN)
    if size(vIn, 2) > 1
        vIn = vIn(:);
        bFlp = true;
    end
    vSlo = sign(diff(vIn));
    bMax = ([0; vSlo] - [vSlo; 0] == 2) | ([1; vSlo] == 0);
    bOut = bMax & (vIn > t);
else
    
    if size(vIn, 2) > 1
        vIn = vIn(:);
        vIN = vIN(:);
        bFlp = true;
    end
    vSlo = sign(diff(vIn));
    bMax = (abs([0; vSlo] - [vSlo; 0]) == 2) | ([1; vSlo] == 0);
    bOut = bMax & (vIN > t);
    
    iFin = find(bOut);
    
    if length(iFin) > 1
        
        p = iFin(1);
        g = vIn(p);

        for i = 2 : length(iFin)
            q = iFin(i);
            h = vIn(q);
%             if (g * h > 0) && all(vIN(p : q) > t)
            if (g * h > 0) && all(sign(vIn(p : q)) == sign(vIn(p)))
                if vIN(q) > vIN(p)
                    bOut(p) = 0;
                    p = q;
                    g = h;
                else
                    bOut(q) = 0;
                end
            else
                p = q;
                g = h;
            end
        end
        
    end
end

if bFlp
    bOut = bOut.';
end