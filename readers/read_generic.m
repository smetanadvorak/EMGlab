function [varargout] = read_generic (opt, varargin)
%	Function for reading generic binary data files.
%
% [chan, info, status] = read_generic ('open', filename);
%
% Outputs:
%
% chan: a struct array with one entry for each channel in the file.  Each
%   entry has the following fields:
%	name	name of the channel (char). optional (default = ' ')
%	rate	sampling rate in Hz (double). required.
%	start	starting time of signal in s (double). optional (default = 0)
%	gain	gain: ADC units per physical unit (double). optional (default = 1)
%	units	name of physical units (string). optional (default = 'ADC')
%	length	length of data in samples (integer). required.
%
% info: a reader specific variable containing information related to the format of the file 
%       needed to load data. It is not used by EMGlab.
%
% status:	1 means open was successful, 0 means open was not successful
%
%
% [data] = read_XXX ('load', info, channel_range, start, count];
%
% Inputs:
%
%   info is the information about file format provided by the open call.
%
%   channel_range:  the index of the channel for which data is requested, or a two-element 
%    array containing the indices of the first and last channel for which data is requested. 
%
%   start: the index of the first sample to be read, with 0 being the first sample in the file.
%
%   count: the number of samples to read per channel.
%
% Outputs:
%
%   data: the data read from the file, one column per channel. It should be int16 if possible.

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net


persistent saved_info


switch lower(opt)
	case 'open'
        filename = varargin{1};
        [info, status] = getparams (saved_info);
		if ~status; varargout = {[], [], 0}; return; end;

        saved_info = info;
        info.filename = filename;
        
        [path, name] = fileparts (filename);
        fid = fopen (filename);
        fseek (fid, 0, 'eof');
        databytes = ftell(fid) - info.offset;
        fclose (fid);
        len = databytes / 2 / info.nchannels;
           
        for i=1:info.nchannels;
            chan(i).name = [name, ' ', int2str(i)];
            chan(i).rate = info.rate;
            chan(i).start = info.start;
            chan(i).gain = info.gain;
            chan(i).units = info.units;
            chan(i).length = len;
        end
    
        status = 2;
        varargout = {chan, info, status};

	case 'load'
        [info, chanrange, start, count] = deal (varargin{:});
		
		switch info.byte_order;
			case 'PC';  format = 'ieee-le';
            otherwise; format = 'ieee-be';
		end;
		
		fid = fopen (info.filename, 'r', format);
		if fid<=0; varargout = {[]}; return; end;

    % Move to start of range
        nchannels = info.nchannels;
        offset = info.offset + start * nchannels * 2;
        fseek (fid, offset, 'bof');

        try;
            Data = fread(fid, [nchannels, count], '*int16')';  % Newer MATLAB.
        catch; try
            Data = int16( fread(fid, [nchannels, count], 'int16')' );   % 5.3.
        catch; try
            Data = fread(fid, [nchannels, count], 'int16')';            % 5.2.
        end; end; end;
        fclose (fid);

        Data = Data (:, chanrange(1): chanrange(end));
        
		%close the file
		varargout = {Data};	
		
end

function [params, status] = getparams (params)
	if isempty(params);
		%deafult info structure
		params = struct(...
			'rate', 10000, ...
			'nchannels', 1, ...
			'byte_order', 'non-PC', ...
			'offset', 0, ...
            'start', 0, ...
            'gain', 1, ...
            'units', 'ADC units');	
	end;
    if ~strcmp (params.byte_order, 'PC');
        params.byte_order = 'non-PC';
    end;

    d = [];
    d = clerk ('add', d, 'nchannels', 'int', params.nchannels, {1,2,3,4,5,6,7,8,9,10}, 1, 'Number of channels');
    d = clerk ('add', d, 'byte_order', 'string', params.byte_order, {'PC', 'non-PC'}, 1, 'Byte order');
    d = clerk ('add', d, 'rate', 'double', params.rate, {}, 1, 'Sampling rate (Hz)');
    d = clerk ('add', d, 'offset', 'int', params.offset, {}, 1, 'Byte offset of first sample');

    d = clerk ('add', d, 'start', 'double', params.start, {}, 1, 'Start time (s)', 1);
    d = clerk ('add', d, 'gain', 'double', params.gain, {}, 1, 'Gain (ADC units per Unit)');
    d = clerk ('add', d, 'units', 'string', params.units, {'ADC units', 'mV', 'uV'}, 1, 'Units');

	%create the dialog
    [d, status] = gendialog (d, 'EMG file format', emgprefs('font_size'));

	%get the info values
    params = struct ('rate', d.rate.value, ...
        'nchannels', d.nchannels.value, ...
        'byte_order', d.byte_order.value, ...
        'offset', d.offset.value, ...
        'start', d.start.value, ...
        'gain', d.gain.value, ...
        'units', d.units.value);
            
