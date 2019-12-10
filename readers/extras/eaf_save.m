function status = eaf_save(Fname, Ann, varargin)
%
% status = eaf_save(Fname, Ann [, option pairs])
% status = eaf_save(Fname, Ann, Var1 [, Var2, ...] [, option pairs])
%
% Fname: (String) Name of the annotation file (filename extension MUST be
%         included).
%
% Ann:    Ann is the annotation structure to write.
%         Required vector members for an EMGlab annotation file are:
%           unit:   Motor unit number (integer),
%           time:  Absolute (since begin of file) firing time (seconds),
%           version: For EAF files, lists the annotation specification
%               version as a string.
%         Optional members (depends on the file format) are documented in
%           EMGlab documentation (see "EMGlab Annotation Structure within
%           MATLAB").
%
% Var1 (etc.): Optional additional variables to be written to the end
%         of the EMGlab annotation file.  Note that actual variable
%         names MUST be supplied rather than constants.  Thus, if
%         vector x is the double vector x = [1 2 3 4], it is legal
%         for the calling program to issue the command:
%              eaf_save(Fname, Ann, x);  % Legal.
%         but illegal for the calling program to issue the command:
%              eaf_save(Fname, Ann, [1 2 3 4]);  % ILLEGAL!
%         Each of the optional variables must produce a non-empty
%         string result when queried by the MATLAB inputname() function.
%
% Option Pairs:  Note that the option string argument MUST be entered
%      by the calling program as a constant (not a variable).  Doing
%      so distinguishes the option strings from optional variables.
% 'Format' format_string: Format specifier (case sensitive).  When absent,
%         eaf_save() determines the file format via the filename extension.
%         In particular, the filename extension IS the file format
%         specifier.  If the extension is denoted as "xxx", then eaf_save
%         looks for another function named "eaf_save_xxx" that
%         saves annotations from the EMGlab annotation structure Ann.  The
%         table below gives the names of pre-defined formats whose functions
%         are provided with EMGlab.  Examples of how to write an
%         eaf_save_xxx function can be found by looking at the functions
%         for these pre-defined formats.  A common set of input and output
%         arguments is used.
%              When Format is specified, the file name extension is
%         ignored and the function "eaf_save_'Format'" is used to save the
%         EMGlab annotation structure.
%
% status:  -1 ==> error, 0 ==> OK.
%
%
% The table of available filename "Format"s and their corresponding
% implicit filename extensions (if any) follows.  Formats are case
% sensitive.
%
% Format      Ext  Definition
% 'ann'      .ann  EMGlab simple ASCII format for time and unit number.
% 'eaf'      .eaf  "EMGlab annotation file" matching the standard set forth
%                  by this software,
% 'tim'      .tim  Legacy format (binary, little endian) from MUtools 
%                  software.  Note: sampling rate hardcoded as 51200.
%
% Copyright (c) 2006. Edward A. Clancy, Kevin C. McGill and others.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.stanford.edu

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform some simple checking of the command line arguments.
NM = 'eaf_save';  % Name of this MATLAB function (short hand).
status = -1;  % Default to error.  Alter after annotations are written.
if nargin<2, errordlg('Too few arguments.', NM); return; end
if ~isfield(Ann, 'time'), errordlg('Annotation "time" missing.', NM); return; end
if ~isfield(Ann, 'unit'),  errordlg('Annotation "unit" missing.',  NM); return; end
Msg = 'Annotation "time" and "unit" lengths differ.';
if length(Ann.time)~=length(Ann.unit), errordlg(Msg, NM); return; end
if ~isnumeric(Ann.time), errordlg('"time" not numeric.', NM); return; end
if ~isnumeric(Ann.unit),  errordlg( '"unit" not numeric.', NM); return; end
if ~isreal(Ann.time), errordlg('"time" not real-valued.', NM); return; end
if ~isreal(Ann.unit),  errordlg( '"unit" not real-valued.', NM); return; end
% Coerce .time and .unit to be column vectors.
Ann.time = Ann.time(:);  Ann.unit = Ann.unit(:);

% Process command-line options.
%   First, look for optional additional variables.
Vars = [];  % Initialize. For additional variable names, values.
k = 3; % First possible optional variable argument index.
while ~isempty(varargin)
  if ~strcmp(inputname(k), '')
    Vars(end+1).name = inputname(k);  % Add cell element, capture name.
    Vars(end).data = varargin{1};     % Capture variable values.
    varargin = {varargin{2:end}};     % Delete from varargin.
    k = k + 1;
  else
    break  % Exit while loop if inputs are not variables.
  end
end
%   Second, look for command option pairs.
Format = NaN;  % Not yet specified.
Msg = 'Options must each be entered as pairs. ABORTED.';
if mod(length(varargin), 2) == 1, errordlg(Msg, NM); return; end
for k = 1:2:length(varargin)
  switch lower(varargin{k})
    case 'format', Format = varargin{k+1};
    otherwise
      errordlg(['Bogus option: "' varargin{k} '". ABORTED.'], NM);
      return
  end
end
      
% If file format is not specified, get it from the filename extension.
if isnan(Format)  % File format not specified.
  Index = find('.' == Fname);  % Find periods in file name, if any.
  if isempty(Index) | length(Fname)<Index(end)+1 % No '.' or text after '.'.
    errordlg(['Filename lacks extension: ' Fname], NM); return
  else  % One or more periods found in file name.
    Format = Fname(Index(end)+1:end);
  end
end

% Write the annotations, based on the format.
try, eval(['status = save_' Format '(Fname, Ann, Vars);']);
catch, errordlg(['Save function not found/failed: save_' Format], NM);
       return
end

return
