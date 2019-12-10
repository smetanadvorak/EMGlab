function Data = get_sc123(FileName)
%
% Data = get_sc123(FileName)
%
% Get three channels of data from a Gary Kamen database data file.
%
% FileName: (String) Name of the data file.  The file extension(s) can
%            be omitted, or any of the following extensions are
%            accepted: '.sc1', '.sc2', '.sc3' or '.sc*'.
%            If the file is not in the MATLAB path, then specify the
%            file name using the complete path name.
%
% Data(N,3):    Data array of .sc1, .sc2, .sc3 data files, respectively.

% This work is licensed under the Creative Commons
% Attribution-NonCommercial-ShareAlike 2.5 License. To view a copy of
% this license, visit http://creativecommons.org/licenses/by-nc-sa/2.5/
% or send a letter to Creative Commons, 543 Howard Street, 5th Floor,
% San Francisco, California, 94105, USA.

if nargin ~= 1, error('Must have one argument exactly.'); end
LL = length(FileName);
if LL<8, error(['Data file name "' FileName '" too short.']); end
% Strip any valid file name extension.
switch FileName(LL-3:LL)
  case {'.sc1', '.sc2', '.sc3', '.sc*'}, FileName = FileName(1:LL-4);
end

Data = [];
for i = 1:3
  DataName = [FileName '.sc' int2str(i)];
  fid = fopen(DataName, 'r');
  if fid<0, error(['Can''t open file ' DataName '.']); end
  [A, count] = fread(fid, 'int16');
  fclose(fid);
  if i>1 & count~=length(Data), error([DataName ' not same length.']); end
  Data = [Data A];
end

return
