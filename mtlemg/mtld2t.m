%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function tOut = mtld2t(mIn, nTit)

[m, n] = size(mIn);
mIn = mIn';
tOut = rem(floor(mIn(:) * 3 .^ ((1 - nTit) : 0)), 3)';
tOut = reshape(tOut(:), n * nTit, m)';


