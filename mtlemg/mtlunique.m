%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function [vOut, iOut] = mtlunique(vIn)

[vOut, iOut] = sort(vIn);
vDif = diff(vOut);
a = (vDif ~= 0);
a(end + 1) = 1;
vOut = vOut(a);
if nargout == 2
    iOut = iOut(a);
end


