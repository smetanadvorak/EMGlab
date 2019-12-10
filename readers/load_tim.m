function [Ann, Fvar] = load_tim(Fname)
% [Ann, Fvar] = eaf_load_xxx(Fname)
%
% eaf_load_xxx() is a subprogram to eaf_load that is used to specifically
% load annotations from an EMGlab ".xxx" annotation file into
% the EMGlab annotation structure.  The function inputs and outputs
% are standardized so that different annotation formats can be facilitated
% by different functions with names of the form: eaf_load_xxx, where
% xxx generally denotes the filename extension of the annotation file.
% See eaf_load() for complete definitions of Fname, Ann, status and Fvar.
% If output variable Fvar is unused, then it should be set to [].
%
% At a minimum, Ann must return the fields Ann.time and Ann.unit,
% as defined in the EMGlab annotation structure.  Be sure to close any
% files that were opened, even if errors occur.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Format: MUtools (.tim)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MUtools annotation files are comprised of a series of 10-byte binary
% entries, arranged as:
% 1) uint16: motor unit number,
% 2) uint32: firing time, in samples since the beginning of the file,
% 3) uint16: the firing time minus this value gives the location of
%            the first sample in this pulse,
% 4) uint16: the firing time plus  this value gives the location of
%            the last  sample in this pulse.
% A sampling rate of 51200 is assumed.

% Copyright (c) 2006-2009. Edward A. Clancy, Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net


Fvar = [];  % Unused output variable, but must be supplied.
NM = 'eaf_load_tim';  % Name of this MATLAB function (short hand).
Ann = []; status = -1;  % Defaults in case of error return.

% Open the annotation file, with error checking.
fid = fopen(Fname, 'rb', 'l');
if fid<0, error(['Can''t open file "' Fname '".']); end

% Check that file has a valid length (multiple of ten).
fseek(fid, 0, 'eof');                       % Moves to end of file.
FileBytes = fliplr( int2str(ftell(fid)) );  % File length (bytes); reversed.
if FileBytes(1)~='0'
    fclose(fid); return

    error ('MUtools (.tim) annotation file length not multiple of 10');
end
fseek(fid, 0, 'bof');                   % Rewind for reading.

% Read using four passes (less looping --> more efficient in MATLAB).
Ann.unit = fread(fid, 'uint16', 8);      % Reads all MU numbers.
fseek(fid, 2, 'bof');                   % Rewind to first time value.
Ann.time = fread(fid, 'uint32', 6);     % Reads all time values.
fseek(fid, 6, 'bof');                   % Rewind to first start time.
Ann.start = fread(fid, 'uint16', 8);    % Reads all start times.
fseek(fid, 8, 'bof');                   % Rewind to first stop time.
Ann.stop = fread(fid, 'uint16', 8);     % Reads all stop times.

% Convert to absolute start, stop times.
Ann.start = Ann.time - Ann.start;       % Convert to absolute.
Ann.stop  = Ann.time + Ann.stop;        % Convert.  Can be out of range.

% Convert from time in samples to time in seconds.
Ann.samprate = 51200;
Ann.time  = Ann.time  / Ann.samprate;
Ann.start = Ann.start / Ann.samprate;
Ann.stop  = Ann.stop  / Ann.samprate;

% Close the annotation file.
fclose(fid);

status = 0;  return
