function [err]=SONCloseFile(fh)
% SONCLOSEFILE closes an opened SON file
% ERR=SONCLOSEFILE(FH) where FH is the SON32.DLL handle for the file
% Returns zero if all OK.
% 
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

if nargin ~= 1
    err=-1000;
    return;
end;

err=calllib('son32','SONCloseFile',fh);
return;
