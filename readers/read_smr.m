function [varargout] = read_smr (opt,varargin)
% Custom reader for Spike 2 data files
%
%[varargout] = READ_SMR (opt,varargin)
%
% status:   1 ==> OK.  0 ==> error.
%The function uses the SON Library
%http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=13932&objectType=FILE

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

persistent saved_info

switch lower(opt)
    case 'open'
        %Initialize the output variables
        chan = [];
        info=[];
        status = 0;  % Initialize status to Error.
        varargout = {chan, info, status};
        
        %smr filename
        smr_filename=varargin{1};

        %creating the son library path
        ePath=which('read_smr');
        [ePath,name,ext,versn]=fileparts(ePath);
        sonDir=fullfile(ePath,'son','');

        %add the son directory to the search path
        addpath(sonDir);


        %try if it is pc by deafult
        byte_order='PC';
        fid=fopen(smr_filename, 'r','ieee-le');

        %throw error if it cannot open the file
        if fid<=0;
            errordlg(['Cannot open file.', 'EMGlab read_smr']);
            return;
        end;

        %get the file header of the smr file
        file_header=SONFileHeader(fid);

        %do not question the format
        formatQ=0;

        %if the field does not exists or the osformat is not 0
        if(isfield(file_header,'osFormat'))
            if(file_header.osFormat~=0)
                formatQ=1;
            end
        else
            formatQ=2;
        end

        %if the format is big-endian
        if(formatQ==1)
            fclose(fid);
            byte_order='Unix';
            fid=fopen(smr_filename, 'r','ieee-be');
            %throw error if it cannot open the file
            if fid<=0;
                errordlg(['Cannot open file.', 'EMGlab read_smr']);
                return;
            end;
        end

        %if there is no osFormat in the header ask for byte order
        if(formatQ==2)
            fclose(fid);
            [user_info, status] = getparams (saved_info);
            if ~status; return; end;
            saved_info = user_info;
            byte_order=user_info.byte_order;
            switch byte_order
                case 'PC';  format = 'ieee-le';
                case 'Unix'; format = 'ieee-be';
            end;

            fid=fopen(Rname, 'r',format);

            %throw error if it cannot open the file
            if fid<=0;
                errordlg(['Cannot open file.', 'EMGlab read_smr']);
                return;
            end;
        end

        %get list of valid channels
        chanList=SONChanList(fid);


        chanSMR=[];
        infoSMR=[];
        sampIntArray=[];

        info.fileName=smr_filename;
        info.fileHeader=file_header;
        info.byte_order=byte_order;

        %for every channel get the sample interval and number of points
        for i=1:length(chanList)

            smr_chan=chanList(i).number;

            %get the info of the channel
            Info=SONChannelInfo(fid,smr_chan);
            %get the header of the channel
            header=SONGetBlockHeaders(fid,smr_chan);
            %get the sampling interval of the channel
            chSampleInterval=getSampleInterval(file_header,Info);


            if(chSampleInterval>0)

                totalSamples=0;
                if(~isempty(header))
                    %compute the total samples for the channel
                    totalSamples=sum(header(5,1:Info.blocks));
                end

                %if the total samples is > than 0
                if(totalSamples>0)
                    %check if the data is triggerd
                    if(~checkTriggeredData(Info,header))
                        scaleFactor=1;
                        %get the units
                        units='A/D units';

                        if(isfield(Info,'units'))
                            %delete the trailing whitespaces
                            %units=strtrim(header.units);
                            units=deblank(Info.units);
                            indexW=isspace(units);
                            if(~isempty(indexW))
                                firstCh=find(indexW==0);
                                if(~isempty(firstCh))
                                    units=units(firstCh(1):end);
                                end
                            end

%                             switch lower(units)
%                                 case 'volt'
%                                     scaleFactor=10^6;
%                                     units='uV';
%                                 case 'volts'
%                                     scaleFactor=10^6;
%                                     units='uV';
%                                 case 'mvolt'
%                                     scaleFactor=10^3;
%                                     units='uV';
%                                 case 'mvolts'
%                                     scaleFactor=10^3;
%                                     units='uV';
%                             end

                        end

                        %scaling factor
                        if(isfield(Info,'scale'))
                            scaleFactor=6553.6/(Info.scale*scaleFactor);
                        end


                        %channel name
                        chName='';
                        if(isfield(Info,'title'))
                            chName=Info.title;
                        end


                        rate=1/chSampleInterval*10^6;
                        %save the default information for the channel
                        index=length(chanSMR)+1;
                        chanSMR(index).name=chName;
                        chanSMR(index).rate=rate;
                        chanSMR(index).start=0;
                        chanSMR(index).gain=scaleFactor;
                        chanSMR(index).units=units;
                        chanSMR(index).length=totalSamples;


                        %setting the info fields
                        infoSMR(index).chanNum=smr_chan;
                        infoSMR(index).format=16;
                        infoSMR(index).rate=rate;
                        infoSMR(index).header=header;
                        infoSMR(index).totalSamples=totalSamples;
                        infoSMR(index).sampleInterval=chSampleInterval;
                        infoSMR(index).chanInfo=Info;
                        
                        sampIntArray(index)=chSampleInterval;

                    end
                end
            end
        end

        %remove son directory from the search path
        rmpath(sonDir);


        %close the fid
        fclose(fid);

        %sort the chanels so the one with the highest rate first
        [ch,indexCh]=sort(sampIntArray);

        chan=chanSMR(indexCh);
        info.chan=infoSMR(indexCh);

        status=2;
        varargout = {chan, info, status};

	case 'load'
        
        [info, sigrange, start, count] = deal (varargin{:});
        nchans = sigrange(end) - sigrange(1) + 1;
        %initialize the output
        try
 %           data = zeros (count, nchans, 'int16');
            data(count,nchans) = int16(0);
        catch
            try
                data = int16 (zeros(count, nchans));
            catch
                data = zeros (count, nchans);
            end;
        end;
        varargout{1} = data;
       
        
		switch info.byte_order;
			case 'PC';  format = 'ieee-le';
			case 'Unix'; format = 'ieee-be';
		end;
        
		fid=fopen(info.fileName, 'r',format);
		if(fid<0); return; end;
        
		smrStruct=struct(...
			'data',[]);

	



		%Import the data channel by channel
		for i=sigrange(1):sigrange(end)
            row=i-sigrange(1)+1;
			try
                emgrange=[start,start+count];
				[smrStruct(row).data,status]=readChannel(fid,info.chan(i),emgrange);
				smrStruct(row).data=reshape(smrStruct(row).data,1,[]);	
			catch
				errordlg(['Problem reading channel.', 'EMGlab read_smr']);
				fclose(fid);
				return;
			end
		end

        if(~isempty(smrStruct))
            if(~isempty(smrStruct(1).data))
                %initialize data            
                actualChan=0;
                for i=1:length(smrStruct)
                    actualChan=actualChan+1;
                    data(1:length(smrStruct(i).data),actualChan)=smrStruct(i).data';
                end
            end
        end
		%done reading, close the fid
		fclose(fid);
        varargout{1} = data;
        return;


end




%-------------------------------------------------------------------------
%[params,status]=getparams(params)
%-------------------------------------------------------------------------
function [params, status] = getparams(params)
if isempty(params);
	params = struct(...
		'rate', 10000, ...
		'nchannels', 1, ...
		'byte_order', 'Unix', ...
		'header', 0, ...
		'gain', 1, ...
		'units', 'A/D units');
end;
if strcmp ('params.byte_order', 'Mac');
	params.byte_order = 'Unix';
end;

d = [];
d = clerk ('add', d, 'byte_order', 'string', params.byte_order, {'PC', 'Unix'}, 1, 'Byte order');

[d, status] = gendialog (d, 'EMG file format', emgprefs('font_size'));

params = struct (...
	'byte_order', d.byte_order.value);

%-------------------------------------------------------------------------
%[chData,chHeader,status]=readChannel(fid,chan);
%-------------------------------------------------------------------------
function [data,status] = readChannel(fid,channelInfo,range)

s0=range(1);
s1=range(2);

%initialize data
try
    data = zeros (1, s1-s0, 'int16');
catch
    try
        data = int16 (zeros(1, s1-s0));
    catch
        data = zeros (1, s1-s0);
    end; 
end;

status=0; %Initialize status to error
SizeOfHeader=20;    % Block header is 20 bytes long

%Info=SONChannelInfo(fid,chan);
Info=channelInfo.chanInfo;


if(Info.kind==0)
	return;
end;



header=channelInfo.header;
totalSamples=channelInfo.totalSamples;


if(s0>totalSamples)
    status=1;
    return;
end

s0=min(max(s0,0),totalSamples);
s1=min(max(s1,0),totalSamples);
    


%go thru the number of blocks and determine wich blocks we need
sampBlock=header(5,1);
%starting block
startBlock=floor(s0/sampBlock)+1;
%ending block
endBlock=ceil(s1/sampBlock);

if(isinf(endBlock))
	endBlock=Info.blocks;
	s1=(endBlock-1)*header(5,1)+header(5,endBlock);
end


if(startBlock<=Info.blocks)&(endBlock<=Info.blocks)
	pointer=1;
	for i=startBlock:endBlock

		%skip the header on every block
		fseek(fid,header(1,i)+SizeOfHeader,'bof');

		if(i==startBlock)
			%how many we need to read from the first block
			remBlock=(startBlock)*header(5,1)-s0;
			fseek(fid,(header(5,i)-remBlock)*2,'cof');
			count=min(remBlock,s1-s0);
		elseif(i==endBlock)
			%how manu we need to read from the last block
			remToRead=(i-1)*header(5,1)+header(5,i)-s1;
			count=header(5,i)-remToRead;
		else
			count=header(5,i);
		end

		data(pointer:pointer+count-1)=fread(fid,count,'int16');
		pointer=pointer+count;
	end
end

%--------------------------------------------------------------------------
%[sampleInterval]=GETSAMPLEINTERVAL(fid,chan,fileHeader,channelInfo,channelHeader);
%-------------------------------------------------------------------------
function sampleInterval=getSampleInterval(fileHeader,channelInfo)

sampleInterval=[];
rChanKinds=[1,6,7,9];
%check if the channel kind is one of the real channels kind
index=find(rChanKinds==channelInfo.kind);
if(~isempty(index))
	%check if it it before version 6
	if(fileHeader.systemID<6)
		if(isfield(channelInfo,'divide'))
			sampleInterval=channelInfo.divide*fileHeader.usPerTime*fileHeader.timePerADC;
		end
	else
		sampleInterval=channelInfo.lChanDvd*fileHeader.usPerTime*(1e6*fileHeader.dTimeBase);
	end
end


%--------------------------------------------------------------------------
%status=checkTriggeredData(Info,header)
%Checks for triggered data
%Returns
%status=1 - Triggered data
%status=0 - Continuous data
%-------------------------------------------------------------------------

function status=checkTriggeredData(Info,header)

%initialize status to 0
status=0;

%Sample interval in clock ticks
SampleInterval=(header(3,1)-header(2,1))/(header(5,1)-1);
%Check for triggered data
for i=1:Info.blocks-1
	IntervalBetweenBlocks=header(2,i+1)-header(3,i);
	if IntervalBetweenBlocks>SampleInterval
		status=1;
		return
	end;
end




