function [varargout]= read_sc1 (opt,varargin)
% Custom reader for MUtools data files.

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

switch lower(opt)
	case 'open'
        %default sampling rate
        DEFAULTRATE =51200;
        %default number of channels
        NCHANNELS=3;
        
        %Initialize the output variables
        chan = [];
        info=[];
      
        
        
        sc_filename = varargin{1};
        
        % Strip any valid file name extension from the file name.
        switch sc_filename(max(end-3,1):end)
            case {'.sc1', '.sc2', '.sc3', '.sc*'}, sc_filename = sc_filename(1:end-4);
        end
        
        
        
        info.byte_order='PC';
        chan(NCHANNELS).name=' ';
        for i=1:NCHANNELS
            chan(i).name=num2str(i);
            chan(i).rate= DEFAULTRATE;
            chan(i).start=0;
            chan(i).gain=1;
            chan(i).units='A/D units';    
            info.chan(i).fileName=[sc_filename,'.sc',num2str(i)];
            info.chan(i).chanName=num2str(i);
            info.chan(i).format=16;
            info.chan(i).rate=51200;
            info.chan(i).gain=1;
            info.chan(i).units='A/D units';           
            fileInfo=dir(info.chan(i).fileName);
            %number of samples in the file
            chan(i).length=(fileInfo.bytes)/2;  
        end
		status=2; 
        varargout = {chan, info, status};

	case 'load'
        
        [info, sigrange, start, count] = deal (varargin{:});
        
        s0=start;
        s1=s0+count;
        
        %initialize data
        nchans = sigrange(end) - sigrange(1) + 1;
        try
            data = zeros (count, nchans, 'int16');
        catch
            try
                data = int16 (zeros(count, nchans));
            catch
                data = zeros (count, nchans);
            end;
        end
    
        varargout{1} = data;
         
		%by default the format is PC
		format='ieee-le';
		switch info.byte_order;
			case 'PC';  format = 'ieee-le';
			case 'Unix'; format = 'ieee-be';
		end;
		
		
        
		% Read the three MUtools EMG files.
		for i = sigrange(1):sigrange(end)
            
            DataName= info.chan(i).fileName;
			%fileInfo
			fileInfo=dir(DataName);
			%if the bytes to read are more than  the filesize
			%number of elements to read
		    count=inf;
			% if the size of the file is bigger than the read range
		    if(fileInfo.bytes >= (s1)*2)
			count=(s1-s0);
            end
            
			fid = fopen(DataName, 'rb', format);  % Little endian.
			if fid<0  % Be sure file opened correctly.
				errordlg(['Can''t open file ' DataName '.'], 'EMGlab read_sc123');
				return;
			end
			%compute and skip the offset
			offset=(s0*2);
            if(fileInfo.bytes<=offset)           
			    fclose(fid);
                return;
            end
            
            s=fseek(fid,offset,'bof');
            
            %if bigger than the end of the file
            if(s==-1)
                fclose(fid);
                return;
            end
            
			% Perform the actual read, sensitive to the MATLAB version.
			try
                A = fread(fid,count, '*int16');  % Newer MATLAB.
            catch
                try
                    A = int16( fread(fid,count, 'int16') );   % 5.3.
                catch
                    A = fread(fid,count, 'int16');            % 5.2.
                end
            end
            %close the file           
			fclose(fid);
            
            col=i-sigrange(1)+1;
			data(1:length(A),col) =  A;
		end

		
        varargout{1} = data;
		return

        
        
end



