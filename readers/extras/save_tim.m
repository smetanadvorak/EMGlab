function status = save_tim(Fname, Ann, Vars)
% status = save_xxx(Fname, Ann, Vars)
%
% save_xxx() is a subprogram to eaf_save that is used to specifically
% save annotations to an EMGlab ".xxx" annotation file from
% the EMGlab annotation structure.  The function inputs and outputs
% are standardized so that different annotation formats can be facilitated
% by different functions with names of the form: save_xxx, where
% xxx generally denotes the filename extension of the annotation file.
% See eaf_save() for complete definitions of Fname, Ann, Vars and status.
% If input variable Vars is unused, it must still be included in the
% function prototype.
%
% At a minimum, Ann must include the fields Ann.time and Ann.unit,
% as defined in the EMGlab annotation structure.  Be sure to close any
% files that were opened, even if errors occur.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Format: MUtools
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% MUtools annotation files are comprised of a series of 10-byte entries,
% arranged as:
% 1) uint16: motor unit number,
% 2) uint32: firing time, in samples since the beginning of the file,
% 3) uint16: the firing time minus this value gives the location of
%            the first sample in this pulse,
% 4) uint16: the firing time plus  this value gives the location of
%            the last  sample in this pulse.
% A sampling rate of 51200 is assumed.
NM = 'save_tim';  % Name of this MATLAB function (short hand).
Fsamp = 51200;

status = -1; % Default to error in case of early return.
if ~isfield(Ann, 'start'), errordlg('Annotation "start" missing.', NM); return; end
if ~isfield(Ann, 'stop'),  errordlg('Annotation "stop" missing.',  NM); return; end
Msg = 'Annotation "time" and "start" lengths differ.';
if length(Ann.time)~=length(Ann.start), errordlg(Msg, NM); return; end
Msg = 'Annotation "time" and "stop" lengths differ.';
if length(Ann.time)~=length(Ann.stop), errordlg(Msg,  NM); return; end

% Arrange data into MUtools format (absolute vs. relative stop, start).
Ann.start = Ann.time - Ann.start;
Ann.stop  = Ann.stop  - Ann.time;  % Can be out of range.

% Convert from time in seconds to time in samples.
Ann.time  = round(Ann.time  * Fsamp);
Ann.unit   = round(Ann.unit   * Fsamp);
Ann.start = round(Ann.start * Fsamp);
Ann.stop  = round(Ann.stop  * Fsamp);

% Open the annotation file, with error checking.
fid = fopen(Fname, 'wb', 'l');
if fid<0, errordlg(['Can''t open file "' Fname '".'], NM); return; end

% Can't yet figure out how to do this efficiently.  Use brute force for now.
for i=1:length(Ann.unit)
  fwrite(fid, Ann.unit(i),   'uint16');
  fwrite(fid, Ann.time(i),  'uint32');
  fwrite(fid, Ann.start(i), 'uint16');
  fwrite(fid, Ann.stop(i),  'uint16');
end

% Close the annotation file.
fclose(fid);

status = 0;  return
