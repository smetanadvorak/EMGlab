function [varargout] = read_wfdb (opt, varargin)
% Reader for data files associated with a WFDB header

% Copyright (c) 2006-2009. Edward A. Clancy, Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net


switch lower (opt)
    case 'open'
        hea_filename = varargin{1};
        hea_pathname = fileparts (hea_filename);

        % Read the header file into info.
        [info, FF] = e_readWFDBhea (hea_filename);
        if FF ~= -2,  varargout = {[], [], 0}; return; end

        chan(info.Rsigs).name = '';
        for i=1:info.Rsigs;
            chan(i).name=info.chan(i).info.Desc;
            chan(i).rate=info.rate*info.chan(i).info.Spf;
            chan(i).start = info.startTime;
            chan(i).gain=info.chan(i).info.ADCgain;
            chan(i).units=info.chan(i).Units;
            chan(i).length = 0;
        end

        % Build vector; one element per file indicating number of signals/file.
        Scount = [1];  % First file, first signal.
        for I = 2:info.Rsigs
            if strcmp(info.chan(I).fileName, info.chan(I-1).fileName)
                Scount(end) = Scount(end) + 1;  % Another signal in same file.
            else
                Scount = [Scount 1];            % New file.
            end
        end
        info.Scount = Scount;
        
        % Now, try to open each file.
        
        status = 1;
        for ifile = 1:length(Scount);
            isig = sum(Scount(1:ifile-1)) + 1;
            nsigs = Scount(ifile);            
            try
              	filename = e_find_file (info.chan(isig).fileName, 0, hea_pathname);  % Find full path name.
                fid = fopen (filename);
                fseek (fid, 0, 'eof');
                databytes = ftell(fid) - info.chan(i).info.ByteOff;
                fclose (fid);
                len = 0;
                switch info.chan(isig).format;
                    case {16, 61}
                        len = databytes  / 2 / nsigs;
                end
            catch
                status = 0;
                break;
            end;
            
            for i=1:nsigs;
                info.chan(isig+i-1).fileName = filename;
                chan(isig+i-1).length = len;
            end;
            
        end

        varargout = {chan, info, 2};


    case 'load'
        [info, sigrange, start, count] = deal (varargin{:});

        nchans = sigrange(end) - sigrange(1) + 1;
        try
%             data = zeros (count, nchans, 'int16');
            data(count,nchans)=int16(0);
        catch 
        try
            data = int16 (zeros(count, nchans));
        catch
            data = zeros (count, nchans);
        end; end
    
        nsigs = info.Scount;
        last = cumsum(nsigs);
        first = [1, last(1:end-1)+1];
        isig = sigrange(1);
        dptr = 1;
        
        while isig<=sigrange(end);
            ifile = min(find(isig <= last));
            d = e_readWFDBdat (info, ifile, start, count);
            i1 = isig - first (ifile) + 1;
            i2 = min (nsigs(ifile), sigrange(end)-first(ifile)+1);
            data (1:size(d,1), dptr:dptr+i2-i1) = d(:,i1:i2);
            dptr = dptr + i2-i1 + 1;
            isig = last(ifile)+1;
        end;
        varargout{1} = data;
        return;
        

    end
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% function e_readWFDBhea() %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [WFDBinfo, Flag] = e_readWFDBhea(Rname)
% Returns WFDBinfo structure, completely filled out.
% Flag: -2 ==> OK; -1==>Failed opening file; 0==>Failed at Record Line;
%       1+ ==> Failed at corresponding Signal Line.
% Rname: (string) Record name, with or without the '.hea' filename extension.

Flag = -2;  % Default to "OK."
% Append '.hea' to the file name, if omited.
if length(Rname)<=4, Rname = [Rname '.hea']; end
if length(Rname)>4 & ~strcmp(lower(Rname(end-3:end)), '.hea'), Rname = [Rname '.hea']; end

% Try to open the WFDB info file.
fid = fopen (Rname);
if fid<0;
    AbsName = e_find_file(Rname);  % Find full path name.
    fid = fopen(AbsName, 'rb');
end;
if fid<0, Flag = -1; WFDBinfo = []; return; end

% Loop through the record line, signal line(s) and comment/info lines.
Nsig = -1; % Used as a flag.  Set initially to -1 to
%  indicate that the record line has not yet been
%  encountered.  After the record line has been read, Nsig
%  lists the number of remaining signal lines.  Note that
%  comment lines prior to the last required signal line are
%  stored as comments.  Thereafter, stored as info
%  strings.  (WFDB distinction.)
Ncomment = 0;  % Number of comment lines.  Init to zero.
Ninfo    = 0;  % Number of info    lines.  Init to zero.
WFDBinfo = [];
WFDBinfo.Com = [];  WFDBinfo.Iline = [];  % Initialize.

str = fgetl(fid);  % Get first line of text from file.
while ischar(str)
    [TempStr Count] = sscanf(str, '%s', Inf);  % Count non-white strings.
    if Count>0  % Skip null lines or lines with just white space.
        if str(1)=='#'  % Comment line or info string.
            if Nsig==0  % Info string.
                Ninfo = Ninfo + 1;        WFDBinfo.Iline{Ninfo} = str;
            else       % Comment line.
                Ncomment = Ncomment + 1;  WFDBinfo.Com{Ncomment} = str;
            end
        else  % Record line or signal line.
            if Nsig<0  % Record line.
                [WFDBinfo FF] = get_rec(str, WFDBinfo);
                if FF>0, Flag = 0; fclose(fid); return, end
                Nsig = WFDBinfo.Rsigs;
            else  % Signal line.
                if Nsig>0  % Fails if there are too many signal lines.
                    [WFDBinfo FF] = get_sig(str, WFDBinfo);
                    if FF>0, Flag = WFDBinfo.Rsigs - Nsig + 1; fclose(fid); return; end
                    Nsig = Nsig - 1;
                end
            end
        end
    end  % length(str).
    str = fgetl(fid);  % Next line for next pass.
end

fclose(fid);
if ~isfield(WFDBinfo, 'Rsigs'), Flag = 0; return, end  % No lines.
if Nsig~=0, Flag = WFDBinfo.Rsigs - Nsig + 1; end  % Too few sig lines.

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% function get_rec()  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Info, Flag] = get_rec(Line, Info)

% Convert the Record Line to entries in the information structure Info.

% Set defaults.
Flag = 0; % OK.
Info.Rname = [];   Info.Rsegs = 1;        Info.Rsigs = [];
Info.rate  = 250;  Info.Rcfr  = [];       Info.Rbcnt = 0;
Info.Rsps  = [];   Info.Rbtm  = '0:0:0';  Info.Rbdt  = [];
Info.startTime=0;

% Parse the line into distinct strings.
II = 0;
[TempStr count errmsg Inext] = sscanf(Line, '%s', 1);
while count>0
    II = II + 1;
    RecStr{II} = TempStr;
    Line = Line(Inext:end);  % Chop off most recent string.
    [TempStr count errmsg Inext] = sscanf(Line, '%s', 1);
end
% Return if the two required arguments are not supplied.
if length(RecStr)<2, Flag = 1+length(RecStr); return; end

% Record name and number of segments.
II = find( RecStr{1} == '/');  % Look for optional Number of Segments.
if isempty(II)
    Info.Rname = RecStr{1};
else
    Info.Rname = RecStr{1}(1:II-1);
    Info.Rsegs = sscanf(RecStr{1}(II+1:end), '%d', 1);
end

% Number of signals.
Info.Rsigs = sscanf(RecStr{2}, '%d', 1);

% Sampling frequency, counter frequency and base counter value.
if length(RecStr)<3, Info.Rcfr = Info.rate; return; end
II = find( RecStr{3} == '/');  % Look for optional counter frequency.
if isempty(II)
    Info.rate = sscanf(RecStr{3}, '%f', 1);
    Info.Rcfr = Info.rate;  % The default, since not specified.
else  % Counter frequency is specified.
    Info.rate = sscanf(RecStr{3}(1:II-1), '%f', 1);  % Sampling frequency.
    JJ = find( RecStr{3} == '(');  % Look for optional base counter value.
    if isempty(JJ)
        Info.Rcfr = sscanf(RecStr{3}(II+1:end), '%f', 1);  % Counter freq.
    else  % Base counter value is specified.
        KK = find( RecStr{3} == ')'); % Finds tail of base counter value.
        Info.Rbcnt = sscanf(RecStr{3}(JJ+1:KK-1), '%f', 1);
    end
end

% Number of samples per signal, base time and base date.
if length(RecStr)>3, Info.Rsps = sscanf(RecStr{4}, '%d', 1); end
if length(RecStr)>4, Info.Rbtm = RecStr{5}; end
if length(RecStr)>5, Info.Rbdt = RecStr{6}; end
if length(RecStr)>6, Info.startTime = str2num(RecStr{7}); end

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% function get_sig()  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Info, Flag] = get_sig(Line, Info)

% Convert the Signal Line to entries in the information structure Info.

% Set defaults.
Flag = 0; % OK.
I = 1;
if isfield(Info, 'chan'), I = length(Info.chan) + 1; end

% Defaults.  Note that SigName, SigUnits and SigDescript are cells.
% Defaults.
Info.chan(I).fileName = [];       Info.chan(I).format = [];
Info.chan(I).info.Spf = 1;        Info.chan(I).info.Skew = [];
Info.chan(I).info.ByteOff = 0;    Info.chan(I).info.ADCgain = 200;
Info.chan(I).info.Baseline = [];  Info.chan(I).Units = [];
Info.chan(I).info.ADCres = [];    Info.chan(I).info.ADCzero = 0;
Info.chan(I).info.InitVal = [];   Info.chan(I).info.Checksum = [];
Info.chan(I).info.Block = [];     Info.chan(I).info.Desc = [];

% Parse the line into distinct strings.
II = 0;
[TempStr count errmsg Inext] = sscanf(Line, '%s', 1);
while count>0
    II = II + 1;
    SigStr{II} = TempStr;
    Line = Line(Inext:end);  % Chop off most recent string.
    [TempStr count errmsg Inext] = sscanf(Line, '%s', 1);
end
% Return if the two required arguments are not supplied.
if length(SigStr)<2, Flag = 1+length(SigStr); return; end

% File Name.
Info.chan(I).fileName = SigStr{1};

% Format, Samps/frame, skew and byte offset.
% Grab Format, which is required (and listed first).
[Info.chan(I).format count errmsg Inext] = sscanf(SigStr{2}, '%d', 1);
% Now, process any optional specifications bound to Format.
SigStr{2} = SigStr{2}(Inext:end);  % Remove Format.
while ~isempty(SigStr{2})
    Sep = SigStr{2}(1);           % Copy the separator character.
    SigStr{2} = SigStr{2}(2:end); % Remove the separator.
    switch Sep
        case 'x', [Info.chan(I).info.Spf     count errmsg Inext] = sscanf(SigStr{2}, '%d', 1);
        case ':', [Info.chan(I).info.Skew    count errmsg Inext] = sscanf(SigStr{2}, '%d', 1);
        case '+', [Info.chan(I).info.ByteOff count errmsg Inext] = sscanf(SigStr{2}, '%d', 1);
    end
    SigStr{2} = SigStr{2}(Inext:end);  % Remove optional specification.
end

% ADC gain, Baseline and Units.
if length(SigStr)>2
    % Grab ADCgain.
    [Info.chan(I).info.ADCgain count errmsg Inext] = sscanf(SigStr{3}, '%f', 1);
    SigStr{3} = SigStr{3}(Inext:end);  % Remove ADCgain.
    % If Baseline is supplied, it must be next.
    if ~isempty(SigStr{3}) & SigStr{3}(1)=='('
        SigStr{3} = SigStr{3}(2:end);  % Remove '('.
        [Info.chan(I).Baseline count errmsg Inext] = sscanf(SigStr{3}, '%d', 1);
        SigStr{3} = SigStr{3}(Inext+1:end);  % Remove through/including ')'.
    end
    % If Units is supplied, it must be last.
    if ~isempty(SigStr{3}) & SigStr{3}(1)=='/'
        Info.chan(I).Units = sscanf(SigStr{3}(2:end), '%s', 1);
    end
end

% Remaining optional parameters.
if length(SigStr)>3, Info.chan(I).info.ADCres   = sscanf(SigStr{4}, '%d', 1); end
if length(SigStr)>4, Info.chan(I).info.ADCzero  = sscanf(SigStr{5}, '%d', 1); end
if length(SigStr)>5, Info.chan(I).info.InitVal  = sscanf(SigStr{6}, '%d', 1);
else,                Info.chan(I).info.InitVal  = Info.chan(I).info.ADCzero;
end
if length(SigStr)>6, Info.chan(I).info.Checksum = sscanf(SigStr{7}, '%d', 1); end
if length(SigStr)>7, Info.chan(I).info.Block    = sscanf(SigStr{8}, '%d', 1); end
Info.chan(I).info.Desc = sprintf('record %s, signal %d', Info.chan(I).fileName, I-1);
if length(SigStr)>8
    Info.chan(I).info.Desc = SigStr{9};
    for k=10:length(SigStr)  % Re-assemble description.
        Info.chan(I).info.Desc = [Info.chan(I).info.Desc ' ' SigStr{k}];
    end
end

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% function e_readWFDBdat() %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Data = e_readWFDBdat (info, ifile, start, count)
% Read binary data from a WFDB data file.
%
% [Data Flag] = e_readWFDBdat (info, N)
%
% info:   info structure from read_wfdb ('open')
% ifile:    file to be read. 
% start:    first element to be read (zero based)
% count:    number of elements to be read (per channel)
% Data:     Data matrix, one signal per row.  Returned as int16 for MATLAB
%           versions that support int16 (version 5.3+).  Else, returned as
%           regular MATLAB double.

    Data = [];
    if ifile>length(info.Scount); error ('Read_wfdb: Illegal file number.'); end;
    isig = sum(info.Scount(1:ifile-1)) + 1;
    cinfo = info.chan(isig);

% Use Sig.Format to set endianess for fopen().
    switch cinfo.format
        case {16};    EndianFlag = 'l';
        case {61};    EndianFlag = 'b';
        case {212};   EndianFlag = 'l';
        otherwise     error ('Read_wfdb: Illegal WFDB format');
    end

% Try to open the WFDB data file.
    filename = cinfo.fileName;
    fid = fopen (filename, 'rb', EndianFlag);
    if fid<0, error (['Read_wfdb: Cannot open wfdb data file ', filename]); end;

% Move to start of range
    nchannels = info.Scount(ifile);
    offset = cinfo.info.ByteOff + start * nchannels * 2;
    fseek (fid, offset, 'bof');
    
% Read data, based on the signal file format and MATLAB version.
    switch cinfo.format
        case {16, 61}  % Note: '*int16' not available in MATLAB 5.2.
            try          Data = fread(fid, [nchannels, count], '*int16')';  % Newer MATLAB.
            catch
                try     Data = int16( fread(fid, [nchannels, count], 'int16')' );   % 5.3.
                catch   Data = fread(fid, [nchannels, count], 'int16')';            % 5.2.
                end
             end
        case {212}
            try         Data = fread(fid, [nchannels, count], 'bit12=>int16');
            end;
    end
  fclose(fid);
