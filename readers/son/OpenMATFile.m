function fh=OpenMATFile(filename)
% Open MAT file for use by SON library
%
% This function is called when writing data to a standard MAT-file.
% Called from the MATLAB SON library
%
% Malcolm Lidierth 07/06
% Copyright © The Author & King's College London 2006

file=dir(filename);
if isempty(file)
    MakeMATFile(filename)
end
fh=fopen(filename,'r+');
fseek(fh,0,'eof');

