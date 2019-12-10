function [ret]=SONCanWrite(fh)
% SONCANWRITE test whether a file can be written to
% BOOLEAN=SONCANWRITE(FH)
%                 FH SON32.DLL file handle
% Returns 0 if FALSE, 1 if TRUE
%
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006

if nargin ~= 1
    ret=-1000;
    return;
end;

ret=calllib('son32','SONCanWrite',fh);
return;