%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% function e_readWFDBdat() %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Data, Flag duration] = e_readWFDBdat(info,Sig,N, supplied_path,range)
% Read binary data from a WFDB data file.
%
% [Data Flag] = e_readWFDBdat(Sig, N)
%
% Sig:  Signal line information structure for first signal in this file.
% N:    Number of signals in this file.
% Data: Data matrix, one signal per row.  Returned as int16 for MATLAB
%       versions that support int16 (version 5.3+).  Else, returned as
%       regular MATLAB double.
% Flag: -2 ==> OK; -1==>Failed opening file; 0==>Failed reading file.

duration=0;
if nargin<5; range=[]; end
% Check the input.
if nargin<3, error('Need three command-line arguments'); end
Flag = 0;  % Set "OK" as default.

% Use Sig.Format to set endianess for fopen().
switch Sig.Format
  case {16}, EndianFlag = 'l';
  case {61}, EndianFlag = 'b';
  otherwise
    fclose(fid);
    errordlg('Illegal WFDB format (1)', 'EMGlab read_wfdb');
    return;
end

% Try to open the WFDB data file.
AbsName = e_find_file(Sig.Name, 0, supplied_path);  % Find full path name.
fid = fopen(AbsName, 'rb', EndianFlag);
if fid<0, Flag = -1; Data = []; return; end
DirInfo = dir(AbsName);  % Get directory listing information.
if round( (DirInfo.bytes-Sig.ByteOff)/N ) * N ~= DirInfo.bytes-Sig.ByteOff
  fclose(fid);
  errordlg(['Data file "' AbsName '": Bogus number of bytes (minus header).'], 'EMGlab read_wfdb');
  return;
end
%get the buffer length
buff_length_sec=emgprefs ('buffer_length');
if(isempty(range))
	t0=0;
	t1=buff_length_sec;
else
	t0=range(1);
	t1=range(2);
end
% Skip header, if any.
if isfield(Sig, 'ByteOff') & ~isempty(Sig.ByteOff)
  fseek(fid, Sig.ByteOff, 'bof');
end

%Skip to t0
offset=floor(t0*info.rate)*N*2;
fseek (fid,offset, 'cof');
%if the bytes to read are more than  the filesize
	if(DirInfo.bytes-Sig.ByteOff <= (t1-t0)*N*info.rate*2)
		count=inf;
		duration=(DirInfo.bytes-Sig.ByteOff)/(2*info.rate*N);
	else
		count=floor((t1-t0)*info.rate);
		duration=(DirInfo.bytes-Sig.ByteOff)/(2*info.rate*N);
	end

% Read data, based on the signal file format and MATLAB version.
switch Sig.Format
  case {16, 61}  % Note: '*int16' not available in MATLAB 5.2.
    try,          Data = fread(fid, [N count], '*int16')';  % Newer MATLAB.
      catch, try, Data = int16( fread(fid, [N count], 'int16')' );   % 5.3.
      catch,      Data = fread(fid, [N count], 'int16')';            % 5.2.
    end, end
  otherwise
    fclose(fid);
    errordlg('Illegal WFDB format (2)', 'EMGlab read_wfdb');
    return;
end  

fclose(fid);
return
