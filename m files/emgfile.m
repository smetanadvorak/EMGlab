function [varargout] = emgfile (opt, varargin)
% EMGlab function handles low-level commands for reading data files.

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net
% updated  5/28/09 -(filter order)

    global EMGLAB EMG

    switch lower (opt)

    case 'open'
        reader_dir = fullfile (EMGLAB.path,'readers');
        reader = dir (fullfile (reader_dir, 'read_*.m'));
        extChoice = cell (length(reader)+1, 2);
        
        extChoice{1,1}='*.*';
        extChoice{1,2}='All files(*.*)';
        
%ZDT      5/28/09 
%         extChoice{1,1} = '*.HEA;*.hea';
%         extChoice{1,2} = 'WFDB header files';
        p = 1;
        for i=1:length(reader);
            ext = reader(i).name(6:end-2);
            if strcmp (ext, 'generic')
            elseif strcmp (ext, 'wfdb');
            else
                p = p + 1;
                extChoice{p,1} = ['*.', ext];
                extChoice{p,2} = ['*.', ext];
            end;
        end;
        p = p + 1;
%ZDT      5/28/09 
%         extChoice{p,1}='*.*';
%         extChoice{p,2}='All files(*.*)';
        extChoice{p,1} = '*.HEA;*.hea';
        extChoice{p,2} = 'WFDB header files';
        extChoice(p+1:end,:) = [];

        olddir = pwd;
        try
            cd (emgprefs('data_path'));
        catch
        end;

        %Problem with 7.04 on a Mac '*.*' cannot be on first place
        if ~ispc & EMGLAB.matlab_version==7.04 %#ok 
            newExtChoices=sprintf('%s;',extChoice{2:end,1});
            newExtChoices=[newExtChoices,'*.dat;*.DAT'];
            [file, path] = uigetfile (newExtChoices, 'Open EMG file');
        elseif EMGLAB.matlab_version > 6;
            [file, path] = uigetfile (extChoice, 'Open EMG file');
        else
            [file, path] = uigetfile ('*', 'Open EMG file');
        end
        
        cd (olddir);
        figure (EMGLAB.figure);
        drawnow;
        
        if ~ischar(file);
            varargout = {[], [], 0};
            return;
        end;

        emg_file = fullfile (path, file);
        [path, barename, extension] = fileparts (emg_file);
        if strcmp (lower(extension), '.hea');
            reader = 'read_wfdb';
        elseif exist (fullfile (path, [barename, '.hea']));
            reader = 'read_wfdb';
            emg_file = fullfile (path, [barename, '.hea']);
        elseif exist (fullfile (reader_dir, ['read_', lower(extension(2:end)), '.m']))
            reader = ['read_', lower(extension(2:end))];
        else
            reader = 'read_generic';
        end;
        
        [chan, info, status] = feval (reader, 'open', emg_file);
        if ~status;
            varargout = {[], [], 0};
            return;
        end;
        
        for i=1:length(chan);
            if ~isfield (chan(i), 'name'); chan(i).name = ' '; end;
            if ~isfield (chan(i), 'start'); chan(i).start = 0; end;
            if ~isfield (chan(i), 'gain'); chan(i).gain = 1; end;
            if ~isfield (chan(i), 'units'); chan(i).units = 'ADC'; end;
            if ~isfield (chan(i), 'rate'); error ('EMGfile: sampling rate must be specified.'); end;
            if ~isfield (chan(i), 'length'); error ('EMGfile: signal length must be specified.'); end;
        end;
               
        File.name = emg_file;
        File.info = info;
        if status == 2;
            File.reader = reader;
        else 
            File.reader = 'import';
        end;
        status = 1;
        varargout = {File, chan, status};
     
    case 'import'
        imported_data = varargin{1};
        d = [];
        d = clerk ('add', d, 'name', 'string', 'imported', {}, 1, 'Name')';
        d = clerk ('add', d, 'rate', 'double', 10000, {}, 1, 'Sampling rate (Hz)');
        d = clerk ('add', d, 'start', 'double', 0, {}, 1, 'Start time (s)');
        d = clerk ('add', d, 'gain', 'double', 1, {}, 1, 'Gain');
        d = clerk ('add', d, 'units', 'string', 'ADC units', {'ADC units', 'mV', 'uV'}, 1, 'Units');

        gotInfo = 0;
        if ~isstruct (imported_data);
            data = imported_data;
        else
            if isfield (imported_data, 'rate');
                [d, err] = clerk ('set', d, 'rate', imported_data.rate);
                gotInfo = isempty(err);
            end;
            if isfield (imported_data, 'start');
                d = clerk ('set', d, 'start', imported_data.start);
            end;
            if isfield (imported_data, 'gain');
                d = clerk ('set', d, 'gain', imported_data.gain);
            end;
            if isfield (imported_data, 'units');
                d = clerk ('set', d, 'units', imported_data.units);
            end;
            if isfield (imported_data, 'data');
                data = imported_data.data;
            else
                error ('Imported data does not have a "data" field.')
                status = 0;
                return;
            end;
        end;

        if gotInfo;
            status = 1;
        else
            [d, status] = gendialog (d, 'Import data format', emgprefs('font_size'));
        end;

        if ~status; varargout = {[], [], 0}; return; end;
        
        file.name = d.name.value;
        file.info = data;
        file.reader = 'import';
        
        [r, c] = size(data);
        if c>r;
            data = data';
        end;
        
        nchans = size(data,2);
        for i=1:nchans;
            if nchans ==1;
                chan(i).name = file.name;
            else
                chan(i).name=sprintf ('%s %i', file.name, i);
            end;
            chan(i).rate=d.rate.value;
            chan(i).start = d.start.value;
            chan(i).gain=d.gain.value;
            chan(i).units=d.units.value;
            chan(i).length = size(data,1);
        end
        status = 1;
        varargout = {file, chan, status};

    case 'buffer'
        [ithread, t1, t2] = deal (varargin{:});
        EMG.thread(ithread).time = nan;
        status = emgfile ('load', ithread, t1, t2);
        varargout = {status};
        
	case 'load'
        [ithread, t1, t2] = deal (varargin{:});
        
        T = EMG.thread(ithread);
        S = EMG.source(T.source);
        n0 = round((t1-T.start)*T.rate);
        n1 = round((t2-T.start)*T.rate);

        b0 = round ((T.time-T.start) * T.rate);
        bl = round (EMG.buffer_length*T.rate);
        b1 = b0 + bl;
        file_length = T.duration * T.rate;

        if isnan(T.time);
            r0 = n0;
            r1 = n0 + bl;
            mb = 'new';
            b0 = r0;            
        elseif n0>=b0 & n1<=b1;
            status = 1;
            varargout = {status};
            return;
        elseif n1>b1+bl
            r0 = n1 - bl;
            r1 = n1;
            mb  = 'new';
            b0 = r0;
        elseif n0>=b0;
            r0 = b1;
            r1 = n1;
            mb = 'back';
            b0 = r1 - bl;
        elseif n0<b0-bl;
            r0 = n0;
            r1 = n0+bl;
            mb = 'new';
            b0 = r0;
        else
            r0 = n0;
            r1 = b0;
            mb = 'front';
            b0 = r0;
        end;

        r0 = max(r0, 0) * S.decimate;
        r1 = min(r1, file_length) * S.decimate;

        if S.decimate==1;
            lpad = 0;
            rpad = 0;
        else
            lpad = min (5*S.decimate, n0);
            rpad = min (5*S.decimate, file_length*S.decimate - r1);
        end;

        r0 = r0 - lpad;
        r1 = r1+rpad;
        npts = r1-r0;
        
        try
            data = feval (S.file.reader, 'load', S.file.info, S.channelRange, r0, npts);
            status = 1;
        catch
            data = [];
            status = 0;
        end;
 
        if status
            if S.decimate > 1;
     %           for i=1:size(data,2);
     %               x = double(data(:,i));
     %               data(:,i) = lpfilt (x, S.nyquist/S.rate);
     %           end
                data = data (lpad+1: S.decimate: end-rpad, :);
            end;

            l = size(data,1);
            if(l>0)
                switch lower(mb)
                    case 'new'
                        EMG.thread(ithread).buffer = data;
                    case 'front'
                        EMG.thread(ithread).buffer = [data; EMG.thread(ithread).buffer(1:end-l,:)];
                    case 'back'
                        EMG.thread(ithread).buffer = [EMG.thread(ithread).buffer(l+1:end,:); data];
                end
            end
            EMG.thread(ithread).time = b0 / S.rate + S.start;

        end;
        varargout = {status};
        
    end;
       
    
    function data = import (opt, info, channelRange, start, count)
        data = info (start+1:start+count, channelRange(1):channelRange(end));
