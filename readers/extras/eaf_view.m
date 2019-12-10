function eaf_view(varargin)
% eaf_view(Atrue, Atest,...,....)
%
% EMG annotation comparison viewer.  Performs EMG annotation comparison
% and then displays instant-by-instant results in a scroll window.
% Has look-and-feel similar to EMGlab.
%
% Atrue: Can either be (1) the filename for truth annotations (file must
%     be on the Matlab path and have a format known to eaf_get), or
%     (2) an EMGlab annotation structure with the truth annotations
%     (required fields are "time" and "unit").  If field "annotname"
%     exists, it will be interpreted as a string and used to label
%     the annotations,otherwise the the variable name that you passed is
%     going to be used to label the annotation

% Atest: Test annotations.  Same formats accepted as for Atrue.
% The function acceps unlimited number of structures and files.

% Copyright (c)2006-2009. Kevin C. McGill, Zhelyasko Tumbev and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

figHandle=eafscreen;
set(figHandle,'HandleVisibility','on');
windowData=get(figHandle,'UserData');
tabData=get(windowData.tabs.currtab,'UserData');
openFiles=tabData.openFiles;



  for i=1:length(varargin)
      input=varargin(i);
     
      if(isstruct(input{1}))
          if(isfield(input{1},'time'))
              if(isfield(input{1},'unit'))
                  filename=inputname(i);
                  if(isfield(input{1},'annotname'))
                      filename=input{1}.annotname;
				  end
				  filespath=' ';
				  if(isfield(input{1},'annotpath'))
                      filespath=input{1}.annotpath;
				  end
                  newFileH=createFile(figHandle,input{1},filename);
                  if(openFiles.numFiles==0)
                      openFiles.buttonH(1)=newFileH;
                      openFiles.filespath{1}=filespath;
                      openFiles.selectedFiles(1)=0;
                      openFiles.numFiles=1;
                  else
                      openFiles.buttonH(end+1)=newFileH;
                      openFiles.filespath{end+1}=filespath;
                      openFiles.selectedFiles(end+1)=0;
                      openFiles.numFiles=openFiles.numFiles+1;
                  end
                      
              end
          end
      elseif(isstr(input{1}))
          if(exist(input{1},'file'))
            [ann,status]=load_eaf(input{1});
            if(status==0)
                [pathstr, fileName, ext, versn] = fileparts(input{1});
                newFileH=createFile(figHandle,ann,fileName);
                if(openFiles.numFiles==0)
                      openFiles.buttonH(1)=newFileH;
                      openFiles.filespath{1}=input{1};
                      openFiles.selectedFiles(1)=0;
                      openFiles.numFiles=1;
                  else
                      openFiles.buttonH(end+1)=newFileH;
                      openFiles.filespath{end+1}=input{1};
                      openFiles.selectedFiles(end+1)=0;
                      openFiles.numFiles=openFiles.numFiles+1;
                  end
            end
          end
                
              
      end
  end
  if openFiles.numFiles>0
      set(openFiles.buttonH(1),'foregroundColor',[0,0,1],'Value',1);
      openFiles.selectedFiles(1)=1;
  end
  if openFiles.numFiles>1
      set(openFiles.buttonH(2),'foregroundColor',[1,0,0],'Value',1);
      openFiles.selectedFiles(2)=2;
  end
  
  if openFiles.numFiles>0
      tabName=get(openFiles.buttonH(1),'String');
      for i=2:openFiles.numFiles
          tabName=[tabName,', ',get(openFiles.buttonH(i),'String')];
      end
      set(windowData.tabs.currtab,'String',tabName);
  end
  
  
 
         
  tabData.openFiles=openFiles;
  set(windowData.tabs.currtab,'UserData',tabData);
  eafscreen('drawFiles',windowData.tabs.currtab);
  
  eafscreen('plotFiles',windowData.tabs.currtab);
  set(figHandle, 'HandleVisibility','callback');
  

function  newFileH=createFile(figHandle,ann,filename)

%crete a uicontext menu for the file button
fileMenu=uicontextmenu('parent',figHandle);
uimenu(...
	fileMenu,...
	'Label','Close File',...
	'callback','eafscreen(''deleteFile'');');

if(isfield(ann,'chan'))
  chan=unique(ann.chan);
  chan=sort(chan);
 
  for i=1:length(chan)
	  chanIndex=find(ann.chan==chan(i));
	  chanAnn.time=ann.time(chanIndex);
	  chanAnn.unit=ann.unit(chanIndex);
      ix = sort(chanAnn.time);
      chanAnn.time = chanAnn.time(ix);
      chanAnn.unit = chanAnn.unit(ix);
	  str=['Chan ',num2str(chan(i))];
	  h=uimenu(...
		  fileMenu,...
		  'tag','Chan',...
		  'Label',str,...
		  'UserData',chanAnn,...
		  'callback','eafscreen(''changeChan'');');
	  if(i==1)
		  chanAnn1=chanAnn;
		  set(h,'Checked','on');
          chanStr=str;
	  end
  end
  
  
	

else
	chanAnn1=ann;
    chanStr='';
end;
windowData=get(figHandle,'UserData');
verData=windowData.verData;

%Create the file button
% save the annotation in the user data of the file button
newFileH=uicontrol( 'parent',figHandle,...
    'Style','togglebutton',...
    'tag',filename,...
    'BackgroundColor',[0.87,0.87,0.89],...
    'Units','pixels',...
    'Uicontextmenu',fileMenu,...
    'String',[filename,' ',chanStr],...
    'Enable',verData.fileBtnEnable,...
    'callback','eafscreen(''updateFiles'');',...
    'UserData',chanAnn1);
        
    
 

