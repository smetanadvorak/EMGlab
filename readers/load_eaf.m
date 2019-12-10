function [Ann, Fvar] = load_eaf (Fname)
% [Ann, Fvar] = load_eaf (Fname)
%
% Loads annotations from an EMGlab ".eaf" annotation file.
%
% Fname:    annotation file name.
%
% Ann:    Returned annotation structure.  Required members (each returned
%         as a column vector) are:
%           unit:   Motor unit number (integer, stored as Matlab double),
%           time:  Absolute (since begin of data) firing time (seconds, double),
%           version: For EAF files, lists the annotation specification
%               version as a string.
%         Optional members (depends on the file format) are documented in
%           EMGlab documentation (see "EMGlab Annotation Structure within
%           MATLAB".
% Fvar:    Optional output variable holding freeform variables, if any
%          were supplied in the EAF.  If none, Fvar = [].  Else, Fvar
%          is a structure vector, one structure element per freeform
%          variable.  Each structure element has two fields.  Field
%          'nam' is a string holding a variable name.  Field 'val'
%          is a variable holding the corresponding variable value.
%          The class of val corresponds to the variable class.  Thus,
%          all freeform variables can be unpacked into the calling
%          function's workspace with:
%          for k=1:length(Fvar), eval([Fvar(k).nam ' = Fvar(k).val;']); end
%

% Copyright (c) 2006-2009. Edward A. Clancy, Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Format: EMGlab Annotation File
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Open the annotation file, with error checking.
Ann = [];
Fvar = [];
fid = fopen (Fname, 'rb');
if fid<0, error (['Can''t open file "' Fname '".']); end

X.data = setstr(fread(fid)');
fclose (fid);

X.lbracket = find(X.data=='<');
X.rbracket = find(X.data=='>');
X.ntags = length(X.lbracket);
if length(X.rbracket)~=X.ntags; error ('< > mismatch '); end
X.tag_ptr = 1;

X = xml_get_tag (X, '?xml'); 
X = xml_get_tag (X, 'emglab_annotation_file'); 
X = xml_get_tag (X, 'emglab_version' ); 
  Ann.version = X.content;
  if Ann.version == -1, error ('Bad version content'); end
X = xml_get_tag (X, '/emglab_version'); 


% Optional general information.
X = xml_get_tag (X);  % General information element.
Geninfo = strcmp(X.name, 'emglab_general_information');   

    % Loop below only executes if optional gen info supplied.
while Geninfo  % "break" used internally to exit "while".
  X = xml_get_tag (X);  % Read next tag.
  if strcmp(X.name,'/emglab_general_information'), break; end  % Loop exit.
  if X.content==-1; error (['Bad ', X.name, ' content']); end;
  close_tag = ['/', X.name];
  switch X.name
    case 'annotname'
      Ann.annotname = X.content;
    case 'annotpath'
      X = xml_get_path (X);
      Ann.annotpath = X.content;
    case 'contributor'
      Ann.contributor = X.content;
    case 'datadate'
      TT = X.content; % Put in temp. buffer for now.
      k = findstr('-', TT);
      if length(k)~=2 | k(1)==1 | k(end)==length(TT) | k(2)-k(1)==1
       error ('Bad datadate format');
      end
      % Convert from XML format (yyyy-mm-dd) to MATLAB format (dd-mmm-yyyy).
      TT = [TT(k(1)+1:k(2)-1) '/' TT(k(2)+1:end) '/' TT(1:k(1)-1)];% dd/mm/yyyy
      try, Ann.datadate = datestr(TT, 'dd-mmm-yyyy');  % Valid?
      catch, error ('datadate not valid.');
      end
    case 'dataname'
      Ann.dataname = X.content;
    case 'datapath'
      X = xml_get_path (X);
      Ann.datapath = X.content;
    case 'datastart'
      Ann.datastart = sscanf(X.content);  % Read datastart.
      if isempty(Ann.datastart), error ('Bad datastart'); end
    case 'datastop'
      Ann.datastop = sscanf(X.content);  % Read datastop.
      if isempty(Ann.datastop), error ('Bad datastop');end
    case 'datatod'
      Ann.datatod = sscanf(X.contents, '%d %*1c %d %*1c %f', 3);  % Read tod values.
      if length(Ann.datatod)<3, error ('Bad datatod');end
    case 'infotext'
      Ann.infotext = X.content;
    case 'samprate'
      Ann.samprate = sscanf(X.content, '%f', 1);  % Read sampling rate.
    otherwise, 
      error (['Unknown tag: ' X.name '. In general info.']);
  end
  X = xml_get_tag (X, close_tag);  % Read closing tag.
end

if ~Geninfo;
  X.tag_ptr = X.tag_ptr - 1;
end;


% Required and optional spike header tags.
X = xml_get_tag (X, 'emglab_spike_header');

% Prepare information data structures.
%          Name     Format  Complex_Permitted?
VarInfo = {'chan',     '%d', 0;     'errtpl',   '%f', 1; ...
           'instance', '%d', 0;     'unit',     '%d', 0; ...
           'numsub',   '%d', 0;     'start',    '%f', 0; ...
           'stop',     '%f', 0;     'super',    '%d', 0; ...
           'time',     '%f', 0};
VarFld = cell(0);  % Each element lists an entered field, in listed order.
VarFmt = [];       % Build format read string.

% Read the field definition tags.
while 1
  X = xml_get_tag (X); % Read next tag.
  close_tag = ['/', X.name];
  Msg1 = 'emglab_spike_header';
  Msg2 = ['Expired/bad tag within ' Msg1];
  if strcmp(X.name,'/emglab_spike_header'), break; end  % LOOP EXIT.
  k = find( strcmp(X.name, VarInfo(:,1)) == 1 );
  if isempty(k), error ([Msg1 ': Unknown tag: ' X.name]);end
  VarFld{end+1} = VarInfo{k,1};        % Capture field name.
  VarFmt = [VarFmt VarInfo{k,2} ' '];  % Capture read format.
  if ~isempty(X.aname)  % Complex-valued attribute?
    if length(X.aname)>1, error ([Msg1 ': tag has > 1 attribute']);end
    if ~strcmp(X.aname,'complex'), error ([Msg1 ': Bad tag: ' X.aname{1}]);end
    if ~any(strcmpi(X.aval,{'on','off'})), error([Msg1 ': Bad tag value: ' X.aval{1}]);end
    if strcmpi(X.aval,'on')&VarInfo{k,3}==0, errord([Msg1 ': Unexpected complex attribute']);end
    if strcmpi(X.aval, 'on')
      VarFld{end+1} = VarInfo{k,1};        % Capture field name.
      VarFmt = [VarFmt VarInfo{k,2} ' '];  % Capture read format.
    end
  end
  X = xml_get_tag (X, close_tag);   % Read closing tag.
end
% Were any required fields missing?
if ~strcmp('time',VarFld), error('Missing spike event time field');end
if ~strcmp('unit', VarFld), error('Missing spike event unit field');end

% Now, read the spike data, row by row.  Place in temp matrix A.
X = xml_get_tag (X, 'emglab_spike_events'); 
[A, c, er, p] = sscanf (X.content, [VarFmt, '\n']);
A = reshape (A, length(VarFld), c/length(VarFld))';
X = xml_get_tag (X, '/emglab_spike_events'); 

% Transfer data from temp matrix to Ann structure.
Ann = setfield(Ann, VarFld{1}, A(:,1));  % First field.
for k = 2:length(VarFld)
  if strcmp(VarFld{k}, VarFld{k-1}) % If same, this column is complex part.
    Ann = setfield(Ann, VarFld{k}, A(:,k-1) + i*A(:,k));
  else  % If not same, this column is new field.
    Ann = setfield(Ann, VarFld{k}, A(:,k));
  end
end

% Additional EMGlab annotation structure fields, if any.
X = xml_get_tag (X);
if strcmp(X.name, '/emglab_annotation_file'), return; end  % Done!
if strcmp(X.name, 'emglab_additional_fields')  % Additional Ann fields.
  while 1==1
    [X, Var, Vname] = xml_read (X);
    if strcmp(Vname, '/emglab_additional_fields'), break, end  % WHILE EXIT.
    if isfield(Ann, Vname), error(['Repeated tag: ' Vname]);end
    Ann = setfield(Ann, Vname, Var);
  end
else  % No additional Ann fields, so must be freeform.  Push tag back.
    X.tag_ptr = X.tag_ptr - 1;
end

% Additional freeform variables, if any.
X = xml_get_tag (X);
if strcmp(X.name, '/emglab_annotation_file'), status = 0; return; end  % Done!
if strcmp(X.name, 'emglab_freeform')  % Additional freeform variables.
    
 while 1 
    [X, Var, Vname] = xml_read (X);
    if strcmp(Vname, '/emglab_freeform'), break, end  % WHILE EXIT.
    if strncmp(Vname, '/', 1), errord(['Unexpected close tag: ' Vname]);end
 %   Fvar(k).nam = Vname;
 %   Fvar(k).val = Var;
    Fvar = setfield (Fvar, Vname,  Var);
  end
else
  error (['Unexpected tag: ' X.name]);
end

% Closing root tag.
X = xml_get_tag (X, '/emglab_annotation_file');

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Utility: X = xml_get_tag(X [,option])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function X = xml_get_tag (X, looking_for)
% Gets the next tag and puts it into X.
% looking_for:
%      If this argument is supplied, then an error is thrown if the
%      next Tag Name does not match this string,
%      If not supplied, then the next tag is returned regardless of its
%      name.
% X: Structure containing xml data and pointers.
%   These fields are added on output:
%      name: Tag name.  For closing tags, the name will begin with '/'.
%      aname{}: Vector of string cells, each holding the name of
%        any supplied attributes.  First attribute name is X.aname{1},
%        etc.  If no attributes are supplied, X.aname = [];
%      aval{}: Vector of string cells, each holding the corresponding
%        value of any supplied attributes.  First value is X.aval{1}.
%      content: contents between this tag and next one.

X.name = [];
X.aname = [];
X.aval = [];
X.content = [];

skipping_comments = 1;
while skipping_comments;
  buffer = X.data(X.lbracket(X.tag_ptr)+1:X.rbracket(X.tag_ptr)-1);
  X.tag_ptr = X.tag_ptr+1;
  skipping_comments = strncmp (buffer, '!--', 3);
end;

% Read the tag name.
[X.name, count, errmsg, nextindex] = sscanf(buffer, '%s', 1);
if count==0, error ('Missing tag'); end;
if strcmp(X.name,'?xml'), buffer=buffer(1:end-1); end % XML line not really XML!
buffer = buffer(nextindex:end);  % Trim name.

% Read any attributes.
k = find(buffer == '=');  % '=' delimits attributes.
buffer(k) = ' ';          % Put white space in '=' locations.
for m = 1:length(k)           % Below: Attribute name (no spaces allowed).
  [TT, count, errmsg, nextindex] = sscanf(buffer, '%s', 1); X.aname{m}=TT;
  if count==0, error ('Attribute problem.'); end;
  buffer = buffer(nextindex+1:end);  % Trim this attribute name.
  while 1   % Search buffer for leading quote.
    TT = sscanf(buffer, '%c', 1);
    if isempty(TT), error ('Attribute problem.'); end
    buffer = buffer(2:end);  % Delete character from buffer.
    if TT == '"', break, end
  end
  X.aval{m} = [];  % Build value as string between quotes.
  while 1
    TT = sscanf(buffer, '%c', 1);
    if isempty(TT), error('Attribute problem.'); end
    buffer = buffer(2:end);  % Delete character from buffer.
    if TT == '"', break, end
    X.aval{m} = [X.aval{m} TT];  % Append character.
  end
end

if nargin==2;
  if ~strcmp(X.name, looking_for);
    error  (['Expected tag: ', looking_for, ' not found.']);
  end;
end;

if X.tag_ptr < X.ntags;
  S = X.data(X.rbracket(X.tag_ptr-1)+1:X.lbracket(X.tag_ptr)-1);
  % Entity substitution.
  if length(S)>=4;
    for k=fliplr(findstr(S, '&lt;' )), S=[S(1:k-1) '<' S(k+4:end)]; end
  end;
  if length(S)>=5;
    for k=fliplr(findstr(S, '&amp;')), S=[S(1:k-1) '&' S(k+5:end)]; end
  end;
  X.content = S;
end;

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Utility: S = xml_get_path(fid)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function X = xml_get_path (X)
% Reads and assembles a string path from path content in input stream fid.
% Each level of the path is embedded within the content of an '<a>' tag.
% So, tags and their content are read sequentially until the tag is
% not '<a>'.  The final tag is then pushed back on the stream (using
% a rewind command).  Thus, the stream points to the '<' of the
% non-'<a>' tag upon function return.
%   S is set to -1 if an error occurs.

S = {};
while 1==1
  X = xml_get_tag(X);     % Opening '<a>' tag.
  if ~strcmp(X.name, 'a')   % Are we done?
    X.tag_ptr = X.tag_ptr - 1;
    break  % Exit the while loop.
  end
  S2 = X.content; % Read the path info for this tag.
  if isempty(S2); error ('Invalid path.'); end;
  S{end+1}= S2;        % Append next level.
  X = xml_get_tag(X,'/a');     % Closing '</a>' tag.
end

if isempty(S), error('Empty path name.'); end  
X.content = fullfile(S{:});
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Utility function: xml_read()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [X, Var, Vname] = xml_read(X)
% Reads a variable from the xml file.  Used recursively for variables
% of classes 'cell' and 'struct'.
% fid:    xml file identifier.
% Var:    Variable value.  Class of Var corresponds to data class.
% Vname:  Variable name (string).
% If the first tag found is a closing tag, the function returns
%   Var = [] and Vname = tag name (which begins with '/').  

NM = 'load_eaf';
% Read opening tag.
Vclass = [];   % Variable class.
Vsize  = [];   % Variable dimensions.
Vcomplex = []; % Flag.  1 ==> complex, 0 ==> not complex.
Var = [];  Vname = '';

X = xml_get_tag(X);
close_tag = ['/', X.name];
if isempty(X), errordlg('xml_read: No more tags'); return; end  % No more tags.
if X.name == -1; errordlg('Tag read error in xml_read()',NM); return; end
if X.name(1) == '/', Vname = X.name; return; end  % End tag encountered.
Vname = X.name;
for k = 1:length(X.aname), switch X.aname{k}
  case 'complex'
    if ~isempty(Vcomplex), error ([X.name ': Repeated attribute complex']);end
    Vcomplex = lower( X.aval{k} );
    if ~any(strcmp(Vcomplex, {'on','off'}))
      error ([X.name ': complex must be on or off']);
    end
  case 'class'
    if ~isempty(Vclass),error ([X.name ': Repeated attribute class']);end
    Vclass = X.aval{k};
    if isempty(Vclass),error ([X.name ': Empty attribute class']);end
  case 'size'
    if ~isempty(Vsize),errorg([X.name ': Repeated attribute size']);end
    Vsize = sscanf(X.aval{k}, '%d');
    if isempty(Vsize),error ([X.name ': Empty attribute size']);end
  otherwise, 
    error ([X.name ': Unknown attribute: ' X.aname{k}]);
end, end
if isempty(Vclass), error ([X.name ': Missing class attribute']);end
if isempty(Vsize),  error ([X.name ': Missing size attribute']);end
if isempty(Vcomplex), Vcomplex = 'off'; end

% Read contents.
switch Vclass
  case 'logical'
    Var = sscanf(X.content, '%d');
    Var = logical(Var);  % Convert to logical data type.
  case 'char'
    Var = X.content;
  case {'uint8', 'uint16', 'uint32', 'uint64', ...
         'int8',  'int16',  'int32',  'int64', ...
         'single', 'double'}
    Var = sscanf(X.content, '%f');  % Read initially as doubles.
    if strcmp(Vcomplex, 'on')
      if round(0.25+length(Var)/2)*2 ~= length(Var)
        error ([X.name ': Complex vars need even length']); 
      end
      Var = Var(1:2:end) + i*Var(2:2:end);  % Complex values.
    end
    try, eval(['Var = ' Vclass '(Var);']); end  % Cast. No 64-bit, some MATLABs.
  case 'cell'
    for k = 1:prod(Vsize)
%      [X, Var2, Vname2, stat2] = xml_read(X);
%      if stat2 == -1, return, end
      [X, Var2, Vname2] = xml_read(X);
      Var{k} = Var2;
    end
  case 'struct'
    for k = 1:prod(Vsize)
      X = xml_get_tag(X);  % Get the opening index tag.
      if X.name == -1 | ~strcmp(X.name,['I' int2str(k)])
        error ([Vname ': Bad structure index tag: ' X.name]); 
      end
      while 1==1  % Get fields.  Exit when find trailing index tag.
        [X,Var2, Vname2] = xml_read(X);
        if strcmp(Vname2, ['/I' int2str(k)]), break, end
        if strncmp(Vname2, '/', 1)
          error ([Vname ': Unexpected close tag: ' Vname2]); 
        end
        eval(['Var(k).' Vname2 ' = Var2;']);
      end
    end
  case 'function_handle'
    Var = X.content;
    Var = str2func(Var);  % Name shouldn't contain &, <.
  otherwise
    error ([X.name ': Bad class attribute: ' Vclass]);
end
% Reshape into correct matrix format.
if prod(Vsize)~=length(Var), error ([X.name ': Bad size']);end
Var = reshape(Var, Vsize(:).');  % Use .' to avoid complex conjugate.

% Read closing tag.
X = xml_get_tag(X, close_tag);

% If make it this far, all is OK.
return
