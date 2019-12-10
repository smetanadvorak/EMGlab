function fh=SONOpenOldFile(filename, iMode)
% SONOPENOLDFILE opens an existing a SON file and returns a handle
% from SON32.DLL. Note that this is not a MATLAB handle.
% FH=SONOPENOLDFILE(filename, iMode)
%                     filename is a string
%                     iMode = 0 for Read/Write
%                             1 for Read Only
%                             2 for Read/Write but accept Read Only
%
% Returns the SON file handle or a negative error code
%                                 
% Author:Malcolm Lidierth
% Matlab SON library:
% Copyright © The Author & King's College London 2005-2006


if nargin ~= 2 || iMode<0 || iMode>2
    fh=-1000;
    return;
end;


fh=calllib('son32','SONOpenOldFile',filename,iMode);
return;