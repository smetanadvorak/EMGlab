function fh=MakeMATFile(filename)
% Create MAT-file and write header
%
% This function is used by the MATLAB SON library
%
% Malcolm Lidierth 07/06
% Copyright © The Author & King's College London 2006

fh=fopen(filename,'w');
str=['MATLAB 5.0 MAT-file, Platform: ' computer ', Created on: ' datestr(clock)...
    ' by SON Library version ' sprintf('%3.2f',SONVersion('nodisplay'))];
str(116)=0;
str=str(1:116);
fwrite(fh,str,'uint8');
SDO=0;
fwrite(fh,SDO,'uint32');
fwrite(fh,SDO,'uint32');
v=256;
fwrite(fh,v,'uint16');
endian=uint16(19785);
fwrite(fh,endian,'uint16');
fclose(fh);
return
end

