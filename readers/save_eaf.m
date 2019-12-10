function status =save_eaf (Fname, Ann, varargin)
% Writer for .eaf annotation files.
% status = save_eaf (Fname, Ann, [Var1, Var2, ...])
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
%         of the EMGlab annotation file.  
%         If the variable is specified by the calling program by name,
%             e.g., save_eaf (Fname, Ann, x), then the variable will be 
%             saved with that name.
%         If the variable is specified by a constant,
%             e.g., save_eaf (Fname, Ann, [1 2 3 4]), then the variable
%             will be saved with the name 'VarI', where I is 1, 2, ...
%
% status:  -1 ==> error, 0 ==> OK.
%

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Format: EMGlab Annotation File
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Open the annotation file, with error checking.
fid = fopen(Fname, 'wb');
NM = 'save_eaf';  % Name of this MATLAB function (short hand).
if fid<0, errordlg(['Can''t open file "' Fname '".'], NM); return; end
if isfield(Ann, 'version');
    Ann = rmfield (Ann, 'version');
end;
% Process optional additional variables.
Vars = [];  % Initialize. For additional variable names, values.
for k=1:length(varargin);
    name = inputname(k+2);
    if isempty(name); name = sprintf ('var%i', k); end;
    Vars(k).name = name;
    Vars(k).data = varargin{k};
end;

% Call local subfunction for processing.  When return, must close file.
status = save_eaf_writer(fid, Ann, Vars);

% Close the annotation file.
fclose(fid);

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Function: eaf_save_eaf_writer()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function status = save_eaf_writer(fid, Ann, Vars)

NM = 'save_eaf';  % Name of this MATLAB function (short hand).
status = -1;  % Default to error.
Version = '0.01';  % EMGlab annotation file version.

% XML definition line; open root element; print version.
fprintf(fid, '<?xml version="1.0" encoding="ASCII"?>\n\n');
fprintf(fid, '<emglab_annotation_file\n');
fprintf(fid, 'xmlns="http://ece.wpi.edu/~ted"\n');
fprintf(fid, 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n');
fprintf(fid, 'xsi:schemaLocation="http://ece.wpi.edu/~ted http://ece.wpi.edu/~ted/emglab_annotation_file.xsd">\n\n');
fprintf(fid, ['<emglab_version>' Version '</emglab_version>\n']);

% Optional general information.
GenInfo = 0;  % Flag. Set to 1 if/when first optional gen info field found.

VarFld = cell(0);  % Names of fields.
%       Field_Name,  Type.
% Note: List 'datastop' AFTER 'datastart'.  (To check datastop>datastart.)
VarInfo = {'annotname',   'string';       'annotpath',   'path';   ...
           'contributor', 'string';       'datadate',    'date';   ...
           'dataname',    'string';       'datapath',    'path';   ...
           'datastart',   'float1';       'datastop',    'float1'; ...
           'datatod',     'tod';          'infotext',    'string'; ...
           'samprate',    'float1';};

for k = 1:size(VarInfo,1)  % Loop over each field name.
  if isfield(Ann, VarInfo{k,1})  % Does this field exist?
    if GenInfo == 0  % If first optional gen info field, open element.
      GenInfo = 1;
      fprintf(fid, '\n<!-- Optional general information. -->\n');
      fprintf(fid, '<emglab_general_information>\n');
    end
    x = getfield(Ann, VarInfo{k,1});  % Temp copy of this field.
    if isempty(x), errordlg([VarInfo{k,1} ' empty.'],NM);return; end
    switch VarInfo{k,2}  % "Standard" checks, print format based on type.
      case 'date'
        if ~ischar(x),errordlg([VarInfo{k,1} ' not a string.'],NM);return;end
        try, x = datestr(x, 'dd-mmm-yyyy');  % Coerce valid string.
        catch, errordlg([VarInfo{k,1} ' not valid date.'], NM); return
        end
        % Convert to yyyy-mm-dd XML format.
        x = datevec(x);
        x = sprintf('%4d-%02d-%02d', x(1:3));
        FF = '%s';
      case 'float1'
        if length(x)>1,errordlg([VarInfo{k,1} ' not scalor.'],NM);return;end
        if ~isnumeric(x),errordlg([VarInfo{k,1} ' not numeric.'],NM);return;end
        FF = ['%0.' int2str(RealDigits(x)) 'g'];
      case 'path'
        if ~ischar(x),errordlg([VarInfo{k,1} ' not a string.'],NM);return;end
        x_cell = PathCell(x); % Separate path.  One level per cell element.
        x = []; for m=1:length(x_cell), x = [x '<a>' x_cell{m} '</a>']; end
        FF = '%s';
      case 'string'
        if ~ischar(x),errordlg([VarInfo{k,1} ' not a string.'],NM);return;end
        FF = '%s';
      case 'tod'
        if length(x)~=3,errordlg([VarInfo{k,1} ' not length=3.'],NM);return;end
        if ~isnumeric(x),errordlg([VarInfo{k,1} ' not numeric.'],NM);return;end
        x(1:2) = round( x(1:2) ); % Coerce to integer.
        Msg = ['Bogus ' VarInfo{k,1} ' hour: ' int2str(x(1))];
        if x(1)<0 | x(1)>23,  errordlg(Msg, NM); return; end
        Msg = ['Bogus ' VarInfo{k,1} ' minute: ' int2str(x(2))];
        if x(2)<0 | x(2)>59,  errordlg(Msg, NM); return; end
        Msg = ['Bogus ' VarInfo{k,1} ' second: ' num2str(x(3))];
        if x(3)<0 | x(3)>=60, errordlg(Msg, NM); return; end
        FF = ['%0.' int2str(RealDigits(x(3))) 'g'];  % Seconds.
        FF = ['%02d:%02d:' FF];  % Hours, minutes, seconds.
    end
    fprintf(fid, ['<' VarInfo{k,1} '>' FF '</' VarInfo{k,1} '>\n'], x);
    VarFld{end+1} = VarInfo{k,1};  % Record the column.
  end
end

x = 0; if isfield(Ann, 'datastart'), x = Ann.datastart; end
if isfield(Ann, 'datastop') & Ann.datastop<=x
  errordlg('datastop <= datastart (or 0).',NM); return
end
Ann = rmfield(Ann, VarFld);  % Remove information fields.
if GenInfo==1, fprintf(fid, '</emglab_general_information>\n'); end

% Required spike header (required and optional tags).
fprintf(fid, '\n<!-- Required and optional spike header tags. -->\n');
fprintf(fid, '<emglab_spike_header>\n');
Lspike = length(Ann.time);  % Time field defines the number of spike events.
if Lspike<1, errordlg('time is empty.',NM); return; end

Hstr = [];         % Comment line header string to label columns.
Spike = [];        % Local temp copy of each spike field, column-oriented.
VarFld = cell(0);  % Mark used fields.  Must match field names.
VarFmt = cell(0);  % Format of variable columns.  'F' ==> float, ? width.
%       Field_Name,  Print_Format.  Purposely put 'time', 'unit' at front.
VarInfo = {'time',      'F';       'unit',      '%d'; ...
           'chan',     '%d';       'errtpl',   'F';  ...
           'instance', '%d';       'numsub',   '%d'; ...
           'start',    'F';        'stop',     'F';  ...
           'super',    '%d'};
for k = 1:size(VarInfo,1)  % Loop over each field name.
  if isfield(Ann, VarInfo(k,1))  % Does this field exist?
    x = getfield(Ann, VarInfo{k,1});  % Temp copy of this field.
    Msg = ['Annotation "time" and "' VarInfo{k,1} '" lengths differ.'];
    if Lspike~=length(x), errordlg(Msg, NM); return; end
    Msg = [VarInfo{k,1} ' not numeric.'];
    if ~isnumeric(x),  errordlg(Msg,NM); return; end
    % If EAF field is integer, coerce all values to integer (just in case).
    if strcmp(VarInfo{k,2},'%d'), x = round(x); end
    Spike(:,end+1) = real( x(:) ); % Append var to spike matrix.
    VarFld{end+1} = VarInfo{k,1};  % Mark the column.
    Hstr = [Hstr '  ' VarInfo{k,1}]; % Append header string.
    VarFmt{end+1} = VarInfo{k,2};  % Record print format.
    if VarInfo{k,2}=='F',VarFmt{end} = ['%0.' int2str(RealDigits(real(x))) 'g'];end
    if isnumeric(x) & ~isreal(x)  % If complex, add imag part as column.
      Spike(:,end+1) = imag( x(:) );  % Append imag part to spike matrix.
      Hstr = [Hstr '(R)  ' VarInfo{k,1} '(I)']; % Fix header.
      VarFmt{end+1} = VarInfo{k,2};   % Record print format.
      if VarInfo{k,2}=='F',VarFmt{end} = ['%0.' int2str(RealDigits(imag(x))) 'g'];end
      fprintf(fid, ['<' VarInfo{k,1} ' complex="on"></' VarInfo{k,1} '>\n']);%Spike header.
    else
      fprintf(fid, ['<' VarInfo{k,1} '></' VarInfo{k,1} '>\n']);%Spike header.
    end
  end
end
fprintf(fid, '</emglab_spike_header>\n');

% Required and optional spike events, printed row by row.
fprintf(fid, '\n<!-- Required and optional spike events. -->\n');
fprintf(fid, ['<!--' Hstr '  -->\n']);  % Comment line.
fprintf(fid, '<emglab_spike_events>\n');
%   Data lines.
%%%FF = ['<r>' VarFmt{1} ' %d'];  % Open tag, time, unit.
FF = [VarFmt{1} ' %d'];  % Open tag, time, unit.
for k = 3:length(VarFmt), FF = [FF ' ' VarFmt{k}]; end  % Other columns.
%%%FF = [FF '</r>\n'];  % Tag to close line.
FF = [FF '\n'];  % Tag to close line.
fprintf(fid, FF, Spike');
%   Close the spike event tag, then remove the spike event fields.
fprintf(fid, '</emglab_spike_events>\n');
Ann = rmfield(Ann, VarFld);

% Additional EMGlab annotation structure fields, if any.
if isfield(Ann, 'comment')
  if ~isfield(Ann(1).comment,'time'),errordlg('comment field missing time field',NM);return;end
  if ~isfield(Ann(1).comment,'text'),errordlg('comment field missing text field',NM);return;end
end
if isfield(Ann, 'spike')
  if ~isfield(Ann(1).spike,'data' ),errordlg('spike field missing data field', NM);return;end
  if ~isfield(Ann(1).spike,'unit' ),errordlg('spike field missing unit field', NM);return;end
  if ~isfield(Ann(1).spike,'start'),errordlg('spike field missing start field',NM);return;end
  if ~isfield(Ann(1).spike,'time' ),errordlg('spike field missing time field', NM);return;end
end
if isfield(Ann, 'template')
  if ~isfield(Ann(1).template,'data' ),errordlg('template field missing data field', NM);return;end
  if ~isfield(Ann(1).template,'index'),errordlg('template field missing index field',NM);return;end
  if ~isfield(Ann(1).template,'unit' ),errordlg('template field missing unit field', NM);return;end
end
NameF = fieldnames(Ann);
if ~isempty(NameF)
  fprintf(fid, '\n<!-- Additional EMGlab annotation structure fields. -->\n');
  fprintf(fid, '<emglab_additional_fields>\n');
  for k = 1:length(NameF), xml_write(fid, getfield(Ann, NameF{k}), NameF{k}); end
  fprintf(fid, '</emglab_additional_fields>\n');
end

% Additional freeform variables, if any.
if ~isempty(Vars)
  fprintf(fid, '\n<!-- Additional (freeform) variables. -->\n');
  fprintf(fid, '<emglab_freeform>\n');
  for k = 1:length(Vars), xml_write(fid, Vars(k).data, Vars(k).name); end
  fprintf(fid, '</emglab_freeform>\n');
end

% Close root element.
fprintf(fid, '\n</emglab_annotation_file>\n');

status = 0;  % If go this far, all is OK.

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Utility function: RealDigits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function N = RealDigits(Rvec)
% Given a real-valued vector, determine the minimum number of base
% ten digits after the decimal point required such that each number
% is represented to the precision of the input when printed using the
% format %0.Ng.  Limit the search for N between 0 and 35.
% Rvec: Input vector of real values.
% N:    Output number of digits required after decimal point (scalor).

if strcmp(class(Rvec), 'single'), Rvec = double(Rvec); end

for N = [15,16,17,35]                 % Below: Need space after g ==> vectors.
  FF = ['%0.' int2str(N) 'g ']; % Format string.  N digits after decimal.
  Rchar = sprintf(FF, Rvec);    % Writes each element as a string.
  Rtest = sscanf(Rchar, '%f');  % Convert element strings back to binary.
  if ~any(Rvec(:)-Rtest(:) ~= 0), return, end  % Done if no error.
end

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Utility function: PathCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function OutCell = PathCell(InPath)
% Separate complete path into each level, beginning with the top level.
% Return a cell vector with each level (highest level first).
% Assume InPath is length > 0.
% InPath:  Input path string.
% OutCell: Output cell.  Each element is string row vector.

InPath = InPath(:)';  % Coerce to row vector.
if InPath(end)~=filesep, InPath = [InPath filesep]; end  % Coerces lead
if InPath(1)  ~=filesep, InPath = [filesep InPath]; end  %  & tail seps.

CellPath = [];  % Cell vector with one level per cell.
k = findstr(filesep, InPath);  % Locations of file sep char.

% Separate.
for m = 1:length(k)-1, OutCell{m} = InPath( k(m)+1:k(m+1)-1 ); end

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Utility function: xml_write
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xml_write(fid, Var, Vname)
% Writes a variable to the xml file.  Used recursively for variables
% of classes 'cell' and 'struct'.
% fid:   xml file identifier.
% Var:   Variable.
% Vname: Variable name (string).

Vclass = class(Var);  % Variable class.
Vsize = size(Var);    % Variable dimensions.
SS = int2str(Vsize(1));  % Below: Remove extra spaces from size string.
for k=2:length(Vsize), SS = [SS ' ' int2str(Vsize(k))]; end
Vcomplex = [];  % Is variable complex (must be numeric).
if isnumeric(Var) & ~isreal(Var), Vcomplex = ' complex="on"'; end
fprintf(fid, ['<' Vname ' class="' Vclass '" size="' SS '"' Vcomplex '>']);
% Below: Need dot-apostrophy (.') to avoid complex conjugate.
if ~strcmp(Vclass, 'function_handle'), Var=Var(:).'; end % Row vec.

if ~isempty(Var), switch Vclass
  case 'logical'
    Var = +Var;  % Convert from logical to numeric.
    fprintf(fid, '%d', Var(1));
    if length(Var)>1, fprintf(fid, ' %d', Var(2:end)); end
  case 'char'  % Below: Substitute entities for illegal XML &, < chars.
    for k=fliplr(find(Var=='&')), Var=[Var(1:k-1) '&amp;' Var(k+1:end)]; end
    for k=fliplr(find(Var=='<')), Var=[Var(1:k-1) '&lt;'  Var(k+1:end)]; end
    fprintf(fid, '%c', Var);
  case {'uint8', 'uint16', 'uint32', 'uint64', ...
           'int8',  'int16',  'int32',  'int64'}
    if ~isreal(Var), Var = [real(Var); imag(Var)]; Var = Var(:)'; end%Real, imag, etc.
    Var = double(Var);  % Older MATLAB versions can't print uint* or int*.
    fprintf(fid, '%0.0f', Var(1));
    if length(Var)>1, fprintf(fid, ' %0.0f', Var(2:end)); end
  case {'single', 'double'}
    if ~isreal(Var), Var = [real(Var); imag(Var)]; Var = Var(:)'; end%Real, imag, etc.
    Var = double(Var);  % Older MATLAB versions can't print single.
    FF = ['%0.' int2str(RealDigits(Var)) 'g'];
    fprintf(fid, FF, Var(1));
    if length(Var)>1, fprintf(fid, [' ' FF], Var(2:end)); end
  case 'cell'  % Uses recursion.
    fprintf(fid, '\n');
    for k = 1:length(Var), xml_write(fid, Var{k}, ['I' int2str(k)]); end
  case 'struct'  % Uses recursion.
    fprintf(fid, '\n');
    for m = 1:length(Var)
      fprintf(fid, ['<I' int2str(m) '>\n']); % 'I' gives struct element index.
      NameF = fieldnames(Var(m));  % All field names.
      if ~isempty(NameF)
        for k = 1:length(NameF)  % Loop over all field names.
          xml_write(fid, getfield(Var(m), NameF{k}), NameF{k});
        end
      end
      fprintf(fid, ['</I' int2str(m) '>\n']);
    end
  case 'function_handle'
    x = func2str(Var);  % Must be scalor.  Name shouldn't contain &, <.
    fprintf(fid, '%c', x);
  otherwise
    error(['Unsupported class "' Vclass '" for variable "' Vname '".']);
  end, end

fprintf(fid, ['</' Vname '>\n']);

return
