function flag=SONImport(fid,varargin)
% SONIMPORT copies all channels into a MAT-file
%
% Note: Use ImportSMR in the sigTOOL package in preference to SONImport
% unless you want data stored in the same way as with previous versions of
% the SON library.
%
% SONIMPORT(FID, {OPTIONS});
% where:
%         FID is the matlab file handle
%         OPTIONS if present, are a set of one or more arguments
%                   (see below)
% When present, OPTIONS must be the last input argument. Valid options
% are:
% 'ticks', 'microseconds', 'milliseconds' and 'seconds' cause times to
%    be scaled to the appropriate unit (seconds by default)in HEADER
% 'scale' - calls SONADCToDouble to apply the channel scale and offset to DATA
%    which will  be cast to double precision
% Other options will have no effect
%
% Returns 0 if successful, -1 otherwise
%
% SONIMPORT stores data in a Level 5 Version 6 compatible MAT-file that can
% be read on any MATLAB supported platform.
% SONIMPORT copies the FileHeader returned by SONFileHeader to the MAT-file
% then loads each channel in turn. The DATA and HEADER fields that would be
% returned by SONGETCHANNEL are then saved. The DATA vector, matrix or
% structure is saved as CHANX where X is the channel number e.g.
% CHAN1 for channel 1. The HEADER is saved as a structure named
% HEADX.
%
% Note that SONIMPORT loads each channel in turn but loads the entire
% channel. Very lengthy channels can cause an out-of-memory error,
% particularly when scaling waveform data to double precision. 
% SONIMPORT issues a warning when this happens and attempts to recover by
% calling
%   SONGETCHANNEL(FID, CHAN, 'MAT', 'MATFILENAME' {,OPTIONS})
% The waveform load routines (SONGETADCCHANNEL and SONGETREALWAVECHANNEL)
% will add the data for the specified channel block-by-block (or
% frame-by-frame) using low-level I/O without having all the data loaded at
% once. If this fails, an incomplete channel entry will be left corrupting
% the MAT-file. SONIMPORT then deletes the MAT-file and returns -1.
% The low-level I/O to the MAT-files has not yet been tested on the
% Mac or other big-endian platforms.
%
% Malcolm Lidierth 07/06
% Copyright © The Author & King's College London 2006

% Check there is no 'mat' or 'progress' option in varargin
if nargin>1
for i=1:length(varargin)
    if strcmpi(varargin{i},'mat') || strcmpi(varargin{i},'progress')
        varargin{i}='';
        varargin{i+1}='';
    end
end
end

v=ver;
v=str2double(v(1).Version);
if v>=7
    fv='-v6';
else
    fv='';
end

% Set up MAT-file...
[pathname, name] = fileparts(fopen(fid));
if ~isempty(pathname)
    pathname=[pathname filesep];
end
matfilename=[pathname name '.mat'];
FileInfo=SONFileHeader(fid);
% ...overwriting any existing file
save(matfilename,'FileInfo',fv)

% get list of valid channels
c=SONChanList(fid);

progbar=progressbar(0,'','Name', fopen(fid));

% Import the data.
for i=1:length(c)
    chan=c(i).number;
    progressbar(chan/length(c), progbar, ...
        sprintf('Importing data on Channel %d',chan));
    try
        [data,header]=SONGetChannel(fid, chan,'progress',varargin{:});
    catch
        % If we get here it is probably an out-of-memory error
        % Try a memory efficient call
        try
            m=lasterror;
            disp(m.message);
            disp(sprintf('\nSONImport: problem encountered on channel %d. Trying memory efficient method',chan));
            [data,header]=SONGetChannel(fid, chan,'progress','mat',matfilename,varargin{:});
            disp(sprintf('Channel %d imported OK\n',chan));
            continue
        catch
            % If this fails, issue a warning.
            % It is probable the failure will have corrupted the mat-file, so delete it.
            disp(sprintf('SONImport: Failed during import of channel %d.\n%s may have been corrupted.\n',...
                chan,matfilename));
            flag=-1;
            delete(matfilename);
            return
        end
    end
    

    if ~isempty(data)
        progressbar(i/length(c), progbar,sprintf('Saving Channel %d',chan));
        temp=['chan' num2str(chan)];
        eval(sprintf('%s=data;',temp));
        save(matfilename,temp,'-append',fv);
        eval(sprintf('clear %s;',temp));
    end

    if ~isempty(header)
        temp=['head' num2str(chan)];
        eval(sprintf('%s=header;',temp));
        save(matfilename,temp,'-append',fv);
        eval(sprintf('clear %s',temp));
    end
    clear('data');

end
close(progbar);
flag=0;


