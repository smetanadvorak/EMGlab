function [data, samprate] = getdata (emg_file)
%GETDATA Read an EMG data file
%    data = getdata (EMG_FILE) returns the data from an EMG file 
%    as an NxM array, where N is the signal length and M is the
%    number of channels. EMG_FILE is the full path to the file.
%
%    [data, samprate] = getdata (EMG_FILE) additionally returns the
%    sampling rates of each channel in a 1xM array.
%
%    This function reads all the types of data files that can be
%    read by the emglab program. This includes files with WFDB 
%    headers. For those files you can specify either the name
%    of the file itself ('myemg.dat') or the name of the header
%    file ('myemg.hea').



%check if the file name is a string
if ~ischar(emg_file);
    error('The file path has to be a string!');

end;
%check if the file exists
if ~exist(emg_file,'file');
    error('The file does not exist!');
end;

%check if emglab is installed
emglabPath=fileparts(which('emglab'));
if isempty(emglabPath)
    error('EMGLab is not installed(emglab directory is not on the search path)!');
end

reader_dir=fullfile(emglabPath,'readers');

%add the readers and the m files directories to the search path
addpath (reader_dir);
addpath (fullfile(emglabPath,'m files'));



[path, barename, extension] = fileparts (emg_file);
if strcmp (lower(extension), '.hea');%#ok
    reader = 'read_wfdb';
elseif exist (fullfile (path, [barename, '.hea']),'file');
    reader = 'read_wfdb';
    emg_file = fullfile (path, [barename, '.hea']);
elseif exist (fullfile (reader_dir, ['read_', lower(extension(2:end)), '.m']),'file')
    reader = ['read_', lower(extension(2:end))];
else
    reader = 'read_generic';
end;
[chan, info, status] = feval (reader, 'open', emg_file);

%if it could not open the file
if ~status;
    error('Error opening the file!'); 
end;

%return the results in double-precision 
data =double(feval (reader, 'load',info,[1,length(chan)] ,0,max([chan.length])));
%sampling rate 
samprate=[chan.rate];

%divide the data by the gain
for i=1:size(data,2)
    if i<=length(chan)
        if isstruct(chan(i))
            if isfield(chan(i),'gain')
                if ~isempty(chan(i).gain)
                    data(:,i)=data(:,i)/chan(i).gain;
                end
            end
        end
    end
end
