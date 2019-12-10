%
% Copyright (c) 2007-2009. J.R. Florestal, P.A. Mathieu, and others. 
% This work is licensed under the Aladdin free public license. 
% For copying permissions see license.txt. 
% email: florestal@hotmail.com, emglab@emglab.net 
%
% This work was funded by grants from NSERC and FQRNT
% 
function bOut = mtlprune(mGen, n)

[nGen, nLis] = size(mGen);
v = 2 .^ (0 : (nLis - 1));
vFam = sum((mGen ~= 0) .* v(ones(nGen, 1), :), 2);
vUni = mtlunique(vFam);

bOut = true(nGen, 1);
for i = 1 : length(vUni)
    bOut(find(vFam == vUni(i), n, 'first')) = false;
end


