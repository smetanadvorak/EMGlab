function figHandle = eafscreen(fnc,opt)
% Main handler for eaf_view.

% Copyright (c) 2007. Kevin C. McGill, Zhelyasko Tumbev and others.
% Part of EMGlab version 0.9.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net


figHandle=0;
if(nargin==0)
    fnc='newWindow';
    figHandle=feval(fnc);
    return;
end;
if (nargin==2)
    if(strcmp(fnc,'quit'))
         figHandle=gcbf;
         delete(figHandle);
     else
          feval(fnc,opt);
     end
else

    feval(fnc);
end



%  ************************************************************************
%  *
%  *  MOUSE EVENTS
%  *
%  *************************************************************************


% **************************************************************************
% *MOUSEMOTION
% **************************************************************************
function mouseMotion
figHandle=gcbf;
windowData=get(figHandle,'UserData');
mouseAction=windowData.tabs.mouse.mouseAction;

switch  mouseAction
    case 'resize'

        set(figHandle,'Units','pixels');
        currentPoint=get(figHandle,'CurrentPoint');
        set(figHandle,'Units','normalized');
        %windowData.tabs.mouse.mouseAction='none';
        set(figHandle,'UserData',windowData);
        tabData=get(windowData.tabs.currtab,'UserData');
        %tab window height
        tabWH=windowData.windowLayout.tabWindow_Height;
        %tab file bar height
        tabFH=tabData.tabLayout.fileBar_Height;
        %tab resize bar height
        tabRH=tabData.tabLayout.resizeBar_Height;
        %maximum y for the resize bar
        maxResize_y=tabWH-tabFH-tabRH;
        if(currentPoint(2)>maxResize_y)
            currentPoint(2)=maxResize_y;
        elseif(currentPoint(2)<0)
            currentPoint(2)=0;
        end;

        tabData.tabLayout.resizeBar_y=currentPoint(2);
        tabData.tabLayout.ratioFPvSP=tabData.tabLayout.resizeBar_y/maxResize_y;
        set(windowData.tabs.currtab,'UserData',tabData);
        drawTabWindow(windowData.tabs.currtab);

    case 'grab'

        %the mouse has been moved after it is been pressed
        windowData.tabs.mouse.mouseMoved='true';
        pointXY=get(0,'PointerLocation');
        % if(abs(pointXY(1)-tabs.mouse.rootX)>30)

        factorX=pointXY(1)/windowData.tabs.mouse.rootX;
        factorY=pointXY(2)/windowData.tabs.mouse.rootY;


        %updateAxes( tabs.mouse.actionAxesH,tabs.mouse.actionAxesX,tabs.mouse.actionAxesX*factorX);
        updateAxes( windowData.tabs.mouse.actionAxesH,windowData.tabs.mouse.rootX, pointXY(1));
        windowData.tabs.mouse.rootX=pointXY(1);
        windowData.tabs.mouse.rootY=pointXY(2);
        windowData.tabs.mouse.actionAxesX=windowData.tabs.mouse.actionAxesX*factorX;
        windowData.tabs.mouse.actionAxesY=windowData.tabs.mouse.actionAxesY*factorY;
        set(figHandle,'UserData',windowData);
        %end
    case 'none'
        if(windowData.tabs.numtabs>0)
        set(figHandle,'Units','pixels');
        currentPoint=get(figHandle,'CurrentPoint');
        set(figHandle,'Units','normalized');
        tabData=get(windowData.tabs.currtab,'UserData');
        zoomInButton=findobj(figHandle,'tag','zoominIcon');
        zoomOutButton=findobj(figHandle,'tag','zoomoutIcon');
        valueZoomIn=get(zoomInButton,'Value');
        valueZoomOut=get(zoomOutButton,'Value');
        if(valueZoomIn==0)&(valueZoomOut==0)
        if(currentPoint(2)>tabData.tabLayout.resizeBar_y)&(currentPoint(2)<tabData.tabLayout.resizeBar_y+tabData.tabLayout.resizeBar_Height)
            %change the pointer to resize pointer
            guiData=load('guiData.mat');
            cursor=guiData.gui.pointer.resizeUD;
            set(figHandle,'Pointer','custom','PointerShapeCData',cursor,'PointerShapeHotSpot',[8,8]);
            
        else
            set(figHandle,'Pointer','arrow');
        end
        end
        end

end


function updateAxes(axesH,xOld,xNew)


axesData=get(axesH,'UserData');
set(axesH,'units','pixels');
pos=get(axesH,'pos');
axesWidth=pos(3);

xLim=get(axesH,'Xlim');
fac=(xLim(2)-xLim(1))/axesWidth;
timeDifference=(xNew-xOld)*fac;


% axesData=get(axesH,'UserData');
% difference=xNew-xOld;
%
% axesData.time=axesData.time-difference;
axesData.time=axesData.time-timeDifference;


if(axesData.time+axesData.right*axesData.timebase>axesData.timeLength)
    axesData.time=axesData.timeLength-axesData.right*axesData.timebase;
end
axesData.time=max(0,axesData.time);
redrawAxes(axesH,axesData);

% **************************************************************************
% *BUTTONUP
% **************************************************************************
function buttonUp
figHandle=gcbf;
windowData=get(figHandle,'UserData');

mouseAction=windowData.tabs.mouse.mouseAction;

switch mouseAction
    case 'resize'
        set(figHandle,'Units','pixels');
        currentPoint=get(figHandle,'CurrentPoint');
        set(figHandle,'Units','normalized');
        %windowData.tabs.mouse.mouseAction='none';
        set(figHandle,'UserData',windowData);
        tabData=get(windowData.tabs.currtab,'UserData');
        %tab window height
        tabWH=windowData.windowLayout.tabWindow_Height;
        %tab file bar height
        tabFH=tabData.tabLayout.fileBar_Height;
        %tab resize bar height
        tabRH=tabData.tabLayout.resizeBar_Height;
        %maximum y for the resize bar
        maxResize_y=tabWH-tabFH-tabRH;
        if(currentPoint(2)>maxResize_y)
            currentPoint(2)=maxResize_y;
        elseif(currentPoint(2)<0)
            currentPoint(2)=0;
        end;

        tabData.tabLayout.resizeBar_y=currentPoint(2);
        tabData.tabLayout.ratioFPvSP=tabData.tabLayout.resizeBar_y/maxResize_y;
        set(windowData.tabs.currtab,'UserData',tabData);
        drawTabWindow(windowData.tabs.currtab);

        windowData.tabs.mouse.mouseAction='none';
        set(figHandle,'UserData',windowData);
        resetZoomButtons;
        %change the pointer to resize pointer
        set(figHandle,'Pointer','arrow');
 

    case 'grab'
		 if(strcmp(windowData.tabs.mouse.mouseMoved,'true'))
              windowData.tabs.mouse.mouseMoved='false';
		 else
              zoomAxes(windowData.tabs.mouse.otherAxesH,...
				  [windowData.tabs.mouse.actionAxesX,windowData.tabs.mouse.actionAxesY],...
				  'display');
          end
      
        windowData.tabs.mouse.mouseAction='none';
        set(figHandle,'UserData',windowData);
        
    case 'scroll'
        windowData.tabs.mouse.mouseAction='none';
        tabData=get(windowData.tabs.currtab,'UserData');
        tabLayout=tabData.tabLayout;
        for i=2:3:11
        set(tabLayout.tabObjects(i),'Value',0);
        end
        
        set(figHandle,'UserData',windowData);
        
    case 'none'
        tabData=get(windowData.tabs.currtab,'UserData');
        tabLayout=tabData.tabLayout;
        set(figHandle,'Units','pixels');
        currentPoint=get(figHandle,'CurrentPoint');
        p_x=currentPoint(1);
        p_y=currentPoint(2);

        set(figHandle,'Units','normalized');
        if(p_y>tabLayout.fileBar_y)&(p_y<tabLayout.fileBar_y+tabLayout.fileBar_Height)

            if(p_x>tabLayout.fileBarText_Width)

                p_x1=p_x-tabLayout.fileBarText_Width;
                openFiles=tabData.openFiles;
                if(openFiles.numFiles>1)
                    pos_width=tabLayout.fileBar_Width/openFiles.numFiles;
                else
                    pos_width=tabLayout.fileBar_Width;
                end;
                if(pos_width>150)
                    pos_width=150;
                end

                if(p_x1<openFiles.numFiles*pos_width)
                    buttonIndex=floor(p_x1/pos_width)+1;
                    targetButton=openFiles.buttonH(buttonIndex);

                    selection=get(figHandle,'SelectionType');
                    switch selection
                        case 'normal'
                            updateFiles(targetButton);
                        case 'alt'
                            %menuH=get(targetButton,'UicontextMenu');
                            %set(menuH,'pos',[p_x,p_y],'vis','on');

                    end


                end

            end
        end

end

% **************************************************************************
% *BUTTONDOWN
% *************************************************************************

function buttonDown

figHandle=gcbf;

set(figHandle,'Units','pixels');
currentPoint=get(figHandle,'CurrentPoint');
p_x=currentPoint(1);
p_y=currentPoint(2);

set(figHandle,'Units','normalized');
windowData=get(figHandle,'UserData');
tabData=get(windowData.tabs.currtab,'UserData');
tabLayout=tabData.tabLayout;

%if the current point is over the resize bar
if(p_y> tabLayout.resizeBar_y)
    posL=get(tabLayout.tabObjects(8),'pos');
    posR=get(tabLayout.tabObjects(11),'pos');

    if(posL(1)<p_x)&(p_x<posL(1)+posL(3))&( posL(2)<p_y)&(p_y<posL(2)+posL(4))
        set(tabLayout.tabObjects(8),'Value',1);
        scroll(tabLayout.tabObjects(8));
    elseif(posR(1)<p_x)&(p_x<posR(1)+posR(3))&( posR(2)<p_y)&(p_y<posR(2)+posR(4))
        set(tabLayout.tabObjects(11),'Value',1);
        scroll(tabLayout.tabObjects(11));
    end




else
    posL=get(tabLayout.tabObjects(2),'pos');
    posR=get(tabLayout.tabObjects(5),'pos');

    if(posL(1)<p_x)&(p_x<posL(1)+posL(3))&( posL(2)<p_y)&(p_y<posL(2)+posL(4))
        set(tabLayout.tabObjects(2),'Value',1);
        scroll(tabLayout.tabObjects(2));
    elseif(posR(1)<p_x)&(p_x<posR(1)+posR(3))&( posR(2)<p_y)&(p_y<posR(2)+posR(4))
        set(tabLayout.tabObjects(5),'Value',1);
        scroll(tabLayout.tabObjects(5));

    end

end

% **************************************************************************
% *Scroll
% **************************************************************************
function scroll(buttonH)
t=clock;
opt=get(buttonH,'tag');
axesH=get(buttonH,'UserData');
% while (etime(clock,t)<0.1);
%     if ~get(buttonH, 'value')
%         eafbutton (opt, axesH);
%         return;
%     end;
%     
% 	drawnow;
%     
% end;
while get(buttonH, 'value')
	pause(0.1);
    eafbutton (opt, axesH);
        
    end;
    
% 	drawnow;
%     
% end;
% if(strcmp(get(gcf,'SelectionType'),'open'))
%     buttonUp;
% end;

% 
% while get(buttonH, 'value')
%     t = clock;
%     eafbutton (opt, axesH);
%    
%     while (etime(clock,t)<0.25);drawnow;end;
% 	
% end;

% **************************************************************************
% *RESIZEBUTTONDOWN
% **************************************************************************
function resizeButtonDown

figHandle=gcf;
windowData=get(figHandle,'UserData');
windowData.tabs.mouse.mouseAction='resize';
set(figHandle,'UserData',windowData);

%change the pointer to resize pointer
guiData=load('guiData.mat');
cursor=guiData.gui.pointer.resizeUD;
set(figHandle,'Pointer','custom','PointerShapeCData',cursor,'PointerShapeHotSpot',[8,8]);


% **************************************************************************
% *SCROLLWHEEL
% **************************************************************************
function scrollWheel(src,evnt)

figHandle=gcf;
windowData=get(figHandle,'UserData');
tabs=windowData.tabs;
if(tabs.numtabs>0)
tabData=get(tabs.currtab,'UserData');

currAxes=gca;
if(currAxes==tabData.tabLayout.signalAxes)|(currAxes==tabData.tabLayout.firingAxes)
% set(figHandle,'Units','pixels');
% currentPoint=get(figHandle,'CurrentPoint');
% set(figHandle,'Units','normalized');
% if(currentPoint(2)>tabData.tabLayout.resizeBar_y)
%     currAxes=tabData.tabLayout.signalAxes;
% else
%     currAxes=tabData.tabLayout.firingAxes;
% end
zoomInButton=findobj(figHandle,'tag','zoominIcon');
zoomOutButton=findobj(figHandle,'tag','zoomoutIcon');

valueZoomIn=get(zoomInButton,'Value');
valueZoomOut=get(zoomOutButton,'Value');

point=[];

if valueZoomIn
   point=get(zoomInButton,'UserData');
end;

if valueZoomOut
    point=get(zoomOutButton,'UserData');
end


if (valueZoomIn==1 | valueZoomOut==1)&(~isempty(point))
    zoom=1;
else
    zoom=0;
end



    if(strcmp(get(currAxes,'vis'),'on'))
        
       if(zoom==0)
        if(evnt.VerticalScrollCount==1)
            eafbutton('>',currAxes);
        else
            eafbutton('<',currAxes);
        end
       else
           
           if(evnt.VerticalScrollCount==1)
            zoomAxes(currAxes,point,'in');
           else
            zoomAxes(currAxes,point,'out');
           end
       end
        
    end
end
end

% **************************************************************************
% *KEYSCROLL
% **************************************************************************
function keyScroll
figHandle=gcf;
key=abs(get(gcf,'CurrentCharacter'));
windowData=get(figHandle,'UserData');
tabs=windowData.tabs;
tabData=get(tabs.currtab,'UserData');
% 
%     set(figHandle,'Units','pixels');
%     currentPoint=get(figHandle,'CurrentPoint');
%     set(figHandle,'Units','normalized');
%     if(currentPoint(2)>tabData.tabLayout.resizeBar_y)
%         currAxes=tabData.tabLayout.signalAxes;
%     else
%         currAxes=tabData.tabLayout.firingAxes;
%     end

currAxes=gca;
if(currAxes==tabData.tabLayout.signalAxes)|(currAxes==tabData.tabLayout.firingAxes)

    if(key==29)
        eafbutton('>',currAxes);
    elseif(key==28)
        eafbutton('<',currAxes);
    end
end
%********************************************************************
% NEWWINDOW
%*******************************************************************

function figHandle=newWindow

%setting the figure position
figure_position=[0.20,0.30,0.60,0.40];

%creating the figure
figHandle = figure ( ...
    'Name','Annotation Viewer',...
    'NumberTitle','off',...
    'integerhandle', 'off', ...
    'menubar','none',...
    'tag', 'Annotation Viewer', ...
    'Color',[0.8708,0.8786,0.8935],...
    'units', 'normalized', ...
    'DoubleBuffer','on',...
    'Render','zbuffer',...
    'pos',figure_position,...
    'defaultuicontrolunits', 'pixels',...
    'WindowButtonDownFcn','',...
    'WindowButtonUpFcn','',...
    'WindowButtonMotionFcn','',...
    'KeyPressFcn','eafscreen(''keyScroll'');',...
    'ResizeFcn','eafscreen(''resize'');',...
    'WindowButtonDownFcn','eafscreen(''buttonDown'');',...
    'WindowButtonUpFcn','eafscreen(''buttonUp'');',...
    'WindowButtonMotionFcn','eafscreen(''mouseMotion'');',...
    'defaultaxesxtick', [], ...
    'defaultaxesytick', [],...
    'Interruptible','on');

% the File Menu
m = uimenu (figHandle, 'label', 'File');


uimenu (...
    m,...
    'label', 'Open Annotation File',...
    'Accelerator','O',...
    'callback','eafscreen(''openFile'');');

uimenu (...
    m, ...
    'label', 'Open Multiple Annotation Files',...
    'Accelerator','M',...
    'callback','eafscreen(''openMultipleFiles'');');

uimenu (...
    m,...
    'label','New Window',...
    'Accelerator','N',...
    'callback','eafscreen(''newWindow'');');

uimenu (...
    m, ...
    'label', 'New Tab',...
    'Accelerator','T',...
    'callback','eafscreen(''newTab'');');

uimenu (...
    m,...
    'tag','closetab',...
    'label', 'Close Tab',...
    'Accelerator','W',...
    'callback','eafscreen(''deleteTab'');',...
    'enable','on');

uimenu (...
    m,...
    'label', 'Quit',...
    'Accelerator','Q',...
    'callback','eafscreen(''quit'',''program'');');


set(figHandle,'Units','pixels');
figurePosPix=get(figHandle,'pos');
set(figHandle,'Units','normalized');


menuBar_x=0;
menuBar_Height=22;
menuBar_y=figurePosPix(4)-menuBar_Height;
icon_width=25;
menuBar_Width=3*icon_width;
tabBar_x=menuBar_Width;
tabBar_Height=22;
tabBar_Width=figurePosPix(3)-tabBar_x-icon_width;
tabBar_y=menuBar_y;
maxTab_Width=250;
if(tabBar_Width>maxTab_Width)
   tab_Width=maxTab_Width;
else
   tab_Width=tabBar_Width;
end

tabWindow_Width=figurePosPix(3);
tabWindow_Height=figurePosPix(4)-menuBar_Height;

windowLayout=struct('figPosPix',figurePosPix,...
    'menuBar_x',menuBar_x,...
    'menuBar_y',menuBar_y,...
    'menuBar_Height',menuBar_Height,...
    'menuBar_Width',menuBar_Width,...
    'icon_width',icon_width,...
    'tabBar_x',tabBar_x,...
    'tabBar_y',tabBar_y,...
    'tabBar_Height',tabBar_Height,...
    'tabBar_Width',tabBar_Width,...
    'tab_Width',tab_Width,...
    'maxTab_Width',maxTab_Width,...
    'tabWindow_Width',tabWindow_Width,...
    'tabWindow_Height',tabWindow_Height);


mouseData=struct('rootX', 0,...
    'rootY', 0,...
    'actionAxesH',0,...
    'actionAxesX',0,...
    'actionAxesY',0,...
    'otherAxesH',0,...
    'mouseAction','none',...
    'mouseMoved','false');



%creating the struct for keeping track of the tabs
tabs=struct('numtabs',0,...
    'currtab',0,...
    'tabsH',0,...
    'mouse',mouseData);


%load guiData
guiData=load('guiData.mat');

%version data
v=version;
verData.matlabVersion=v;
switch v(1)
    case '6'
        verData.value=0;
        verData.fileBtnEnable='on';
        verData.scrollBtnEnable='off';
        verData.axes_correction=[0,1,-1,-1];
        
    case '7'
        verData.value=1;
        verData.fileBtnEnable='inactive';
        verData.scrollBtnEnable='inactive';
        verData.axes_correction=[0,1,-1,-1];
        
    otherwise
        verData.value=1;
        verData.fileBtnEnable='inactive';
        verData.scrollBtnEnable='inactive';
        verData.axes_correction=[0,0,0,0];
end
        
%windowData struct conatins an information about the window
windowData=struct('windowLayout',windowLayout,...
    'guiData',guiData,...
    'verData',verData,...
    'tabs',tabs);


%save the tabs struct in the figure
set(figHandle,'UserData',windowData);

%create the icons
drawIcons;

%create a new Tab
newTab;


v=version;
if(strcmp(v(1:3),'7.4'))
    eval('set(figHandle,''WindowScrollWheelFcn'',@scrollWheel)');
end
%set the figure HandleVisibility only for the callback functions
%set(figHandle, 'HandleVisibility','callback');

%**************************************************************************
%resize
%**************************************************************************

function resize

figHandle=gcf;
windowData=get(figHandle,'UserData');
tabs=windowData.tabs;


set(figHandle,'Units','pixels');
figurePosPix=get(figHandle,'pos');

resize=0;
% limit the figure size to 100 by 150 pixels
if(figurePosPix(3)<150)
    figurePosPix(3)=150;
    resize=1;
end
if(figurePosPix(4)<100)

    figurePosPix(2)=figurePosPix(2)+figurePosPix(4)-100;
    figurePosPix(4)=100;
    resize=1;
end

if( resize==1)
    set(figHandle,'pos',figurePosPix)
end;

set(figHandle,'Units','normalized');
menuBar_x=0;
menuBar_Height=22;
menuBar_y=figurePosPix(4)-menuBar_Height;
icon_width=25;
menuBar_Width=3*icon_width;
tabBar_x=menuBar_Width;
tabBar_Height=22;
tabBar_Width=figurePosPix(3)-tabBar_x-icon_width;
tabBar_y=menuBar_y;
if(tabs.numtabs>0)
    tab_Width=tabBar_Width/tabs.numtabs;
else
    tab_Width=tabBar_Width;
end
maxTab_Width=250;
if(tab_Width>maxTab_Width)
    tab_Width=maxTab_Width;
end
tabWindow_Width=figurePosPix(3);
tabWindow_Height=figurePosPix(4)-menuBar_Height;

windowLayout=struct('figPosPix',figurePosPix,...
    'menuBar_x',menuBar_x,...
    'menuBar_y',menuBar_y,...
    'menuBar_Height',menuBar_Height,...
    'menuBar_Width',menuBar_Width,...
    'icon_width',icon_width,...
    'tabBar_x',tabBar_x,...
    'tabBar_y',tabBar_y,...
    'tabBar_Height',tabBar_Height,...
    'tabBar_Width',tabBar_Width,...
    'tab_Width',tab_Width,...
    'maxTab_Width',maxTab_Width,...
    'tabWindow_Width',tabWindow_Width,...
    'tabWindow_Height',tabWindow_Height);

windowData.windowLayout=windowLayout;
set(figHandle,'UserData',windowData);
redrawTabs;
drawIcons;
resizeTabWindow(tabs.currtab);

%**************************************************************************
%drawIcons
%**************************************************************************
function drawIcons

figHandle=gcf;
windowData=get(figHandle,'UserData');
windowLayout=windowData.windowLayout;

%load the guiData
guiData=windowData.guiData;

tabAxesH=findobj(figHandle,'tag','tabAxes');
tabAxesPos=[0,windowLayout.menuBar_y,windowLayout.figPosPix(3),windowLayout.menuBar_Height];
if(isempty(tabAxesH))
    %-----tabAxes---
    axes(...
        'tag','tabAxes',...
        'Units','pixels',...
        'pos',tabAxesPos,...
        'Color',[0.8,0.8,0.8]);
else
    set(tabAxesH,'pos',tabAxesPos);
end

if(ishandle(tabAxesH))
adjustAxes(tabAxesH);
end

% curDir=cd;
% cd('icons')


iconsH=findobj(figHandle,'tag','openIcon');
openIconPos=[windowLayout.menuBar_x,windowLayout.menuBar_y+1,windowLayout.icon_width,windowLayout.menuBar_Height-1];
if(isempty(iconsH))
    %---Open Icon----
    openIcon=guiData.gui.icons.openIcon;
    uicontrol(...
        'Style','pushbutton',...
        'tag','openIcon',...
        'Units','pixels',...
        'pos',openIconPos,...
        'CData',openIcon,...
        'callback','eafscreen(''openFile'');');
else
    set(iconsH,'pos',openIconPos);
end

iconsH=findobj(figHandle,'tag','zoominIcon');
zoomInIconPos=[windowLayout.menuBar_x+windowLayout.icon_width,windowLayout.menuBar_y+1,windowLayout.icon_width,windowLayout.menuBar_Height-1];
if(isempty(iconsH))
    %----Zoom in Icon---
    zoominIcon=guiData.gui.icons.zoominIcon;
    uicontrol(...
        'Style','togglebutton',...
        'tag','zoominIcon',...
        'Units','pixels',...
        'pos',zoomInIconPos,...
        'CData',zoominIcon,...
        'callback','eafscreen(''zoomButton'');');
else
    set(iconsH,'pos',zoomInIconPos);
end

iconsH=findobj(figHandle,'tag','zoomoutIcon');
zoomOutIconPos=[windowLayout.menuBar_x+2*windowLayout.icon_width,windowLayout.menuBar_y+1,windowLayout.icon_width,windowLayout.menuBar_Height-1];
if(isempty(iconsH))
    %-----Zoom Out Icon---
    zoomoutIcon=guiData.gui.icons.zoomoutIcon;
    uicontrol(...
        'Style','togglebutton',...
        'tag','zoomoutIcon',...
        'Units','pixels',...
        'pos',zoomOutIconPos,...
        'CData', zoomoutIcon,...
        'callback','eafscreen(''zoomButton'');');
else
    set(iconsH,'pos',zoomOutIconPos);
end

iconsH=findobj(figHandle,'tag','deleteIcon');
deleteIconPos=[windowLayout.figPosPix(3)-windowLayout.icon_width+5,windowLayout.menuBar_y+5,14,14];
if(isempty(iconsH))
    %-----Delete Tab Icon---
    deleteIcon=guiData.gui.icons.deleteIcon;
    uicontrol(...
        'Style','pushbutton',...
        'tag','deleteIcon',...
        'Units','pixels',...
        'pos',deleteIconPos,...
        'CData',deleteIcon,...
        'callback','eafscreen(''deleteTab'');');
else
    set(iconsH,'pos',deleteIconPos);
end




% cd(curDir);

%**************************************************************************
%NEWTAB
%**************************************************************************
function newTab
%get the current figure
figHandle=gcf;

%get the window layout
windowData=get(figHandle,'UserData');

% get the tabs in the window
tabs=windowData.tabs;

if(tabs.numtabs>0)
    windowData.windowLayout.tab_Width=windowData.windowLayout.tabBar_Width/(tabs.numtabs+1);
end;

%Define the tab context menu
tabMenu=uicontextmenu;
uimenu(tabMenu,'tag','tab','Label','Close Tab','callback','eafscreen(''deleteTab'');');
uimenu(tabMenu,'Label','Export Tab','callback','eafscreen(''exportTab'');');



newTabH=uicontrol(...
    'Style','pushButton',...
    'tag','tab',...
    'Units','pixels',...
    'String','Empty Tab',...
    'BackgroundColor',[1,1,1],...
    'callback','eafscreen(''setCurrentTab'');',...
    'UiContextMenu',tabMenu);


%---File Bar-------
fileBar_x=0;
fileBar_Height=25;
fileBarText_Width=50;
fileBar_Width=windowData.windowLayout.tabWindow_Width-fileBarText_Width-25;
fileBar_y=windowData.windowLayout.tabWindow_Height-fileBar_Height;

%---Resize Bar-----
ratioFPvSP=2/3;
resizeBar_Height=10;
resizeBar_Width=windowData.windowLayout.tabWindow_Width;
resizeBar_y=(windowData.windowLayout.tabWindow_Height-fileBar_Height-resizeBar_Height)*ratioFPvSP;

%-----Firing Panel----
firingPanel_x=0;
firingPanel_y=0;
firingPanel_Width=windowData.windowLayout.tabWindow_Width;

%----SignalPanel-----
signalPanel_x=0;
signalPanel_Width=windowData.windowLayout.tabWindow_Width;


tabLayout=struct('fileBar_x',fileBar_x,...
    'fileBar_Height',fileBar_Height,...
    'fileBar_Width',fileBar_Width,...
    'fileBarText_Width',fileBarText_Width,...
    'fileBar_y',fileBar_y,...
    'resizeBar_Height',resizeBar_Height,...
    'resizeBar_Width',resizeBar_Width,...
    'resizeBar_y',resizeBar_y,...
    'firingPanel_x',firingPanel_x,...
    'firingPanel_y',firingPanel_y,...
    'firingPanel_Width',firingPanel_Width,...
    'signalPanel_x',signalPanel_x,...
    'signalPanel_Width',signalPanel_Width,...
    'ratioFPvSP',ratioFPvSP,...
    'button_Width',25,...
    'tabObjects',0,...
    'signalAxes',0,...
    'firingAxes',0  );

%openFiles struct holds the information
%of the open files in the tab
openFiles=struct('numFiles',0,...
    'buttonH',0,...
    'filespath','',...
    'selectedFiles',0);

tabData=struct('tabLayout',tabLayout,...
    'openFiles',openFiles);

set(newTabH,'userData',tabData);
drawTabWindow(newTabH);
drawTabWindow(newTabH);

if(tabs.numtabs==0)
    tabs.numtabs=1;
    tabs.currtab=newTabH;
    tabs.tabsH(1)=newTabH;
else

    for i=1:tabs.numtabs
        tData=get(tabs.tabsH(i),'UserData');
        set(tData.tabLayout.tabObjects,'vis','off');
        set(tabs.tabsH(i),'BackgroundColor',[0.8,0.8,0.8]);
    end
    tabs.numtabs=tabs.numtabs+1;
    tabs.currtab=newTabH;
    tabs.tabsH(end+1)=newTabH;

end

windowData.tabs=tabs;
deleteIcon=findobj(figHandle,'tag','deleteIcon');
if(ishandle(deleteIcon))
  set(deleteIcon,'vis','on');
end
closetabH=findobj(figHandle,'tag','closetab');
if(ishandle(closetabH))
    set(closetabH,'enable','on');
end
set(figHandle,'UserData',windowData);
redrawTabs;
setCurrentTab(newTabH);

%**************************************************************************
%resizeTabWindow
%**************************************************************************
function resizeTabWindow(tabHandle)

%get the current figure
figHandle=gcf;

%get the window layout
windowData=get(figHandle,'UserData');

%get the tab layout
tabData=get(tabHandle,'UserData');




%---File Bar-------
fileBar_x=0;
fileBar_Height=25;
fileBar_Width=windowData.windowLayout.tabWindow_Width-tabData.tabLayout.fileBarText_Width-25;
fileBar_y=windowData.windowLayout.tabWindow_Height-fileBar_Height;

%---Resize Bar-----
resizeBar_Height=10;
resizeBar_Width=windowData.windowLayout.tabWindow_Width;
resizeBar_y=(windowData.windowLayout.tabWindow_Height-fileBar_Height-resizeBar_Height)*tabData.tabLayout.ratioFPvSP;

%-----Firing Panel----
firingPanel_x=0;
firingPanel_y=0;
firingPanel_Width=windowData.windowLayout.tabWindow_Width;

%----SignalPanel-----
signalPanel_x=0;
signalPanel_Width=windowData.windowLayout.tabWindow_Width;


tabData.tabLayout.fileBar_y=fileBar_y;
tabData.tabLayout.fileBar_Width=fileBar_Width;
tabData.tabLayout.resizeBar_Width=resizeBar_Width;
tabData.tabLayout.resizeBar_y=resizeBar_y;
tabData.tabLayout.firingPanel_Width=firingPanel_Width;
tabData.tabLayout.signalPanel_Width=signalPanel_Width;

% set the new tab layout
set(tabHandle,'UserData',tabData);

drawTabWindow(tabHandle);
drawFiles(tabHandle);




%**************************************************************************
%drawTabWindow
%**************************************************************************
function drawTabWindow(tabHandle)
% global tA
tabData=get(tabHandle,'userData');
layout=tabData.tabLayout;
figHandle=get(tabHandle,'parent');
windowData=get(figHandle,'UserData');
verData=windowData.verData;

%load the gui Data
guiData=windowData.guiData;

%default button color
btnCol=[0.8708,0.8786,0.8935];

%------Firing Panel positions------
%firing panel height
fpanelH=layout.resizeBar_y;
%firing panel width
fpanelW=layout.firingPanel_Width;
%firing axes height
faxesHeight=fpanelH;
%firing button width
fbtnW=layout.button_Width;
%firing button height
fbtnH=faxesHeight/3;
%firing axes width
faxesWidth=fpanelW-2*fbtnW;

faxesPos=[fbtnW+20,0,faxesWidth-40,faxesHeight]+ verData.axes_correction;
pos1=[0,0,fbtnW,fbtnH];
pos2=[0,fbtnH,fbtnW,fbtnH];
pos3=[0,2*fbtnH,fbtnW,fbtnH];
pos4=[fpanelW-fbtnW,0,fbtnW,fbtnH];
pos5=[fpanelW-fbtnW,fbtnH,fbtnW,fbtnH];
pos6=[fpanelW-fbtnW,2*fbtnH,fbtnW,fbtnH];



%---SignalPanel position---

%signal panel height
spanelH=layout.fileBar_y-(layout.resizeBar_y+layout.resizeBar_Height);
%signal Panel Width
spanelW=layout.signalPanel_Width;
%signal button height
sbtnH=spanelH/3;
%signal button width
sbtnW=layout.button_Width;
%signal Axes Height
saxesH=spanelH;
%signal axes Width
saxesW=spanelW-2*sbtnW;

%fileBar y position
fileBar_y=layout.fileBar_y;

saxesPos=[sbtnW,fileBar_y-spanelH,saxesW,saxesH]+ verData.axes_correction;
pos7=[0,fileBar_y-3*sbtnH,sbtnW,sbtnH];
pos8=[0,fileBar_y-2*sbtnH,sbtnW,sbtnH];
pos9=[0,fileBar_y-1*sbtnH,sbtnW,sbtnH];
pos10=[spanelW-sbtnW,fileBar_y-3*sbtnH,sbtnW,sbtnH];
pos11=[spanelW-sbtnW,fileBar_y-2*sbtnH,sbtnW,sbtnH];
pos12=[spanelW-sbtnW,fileBar_y-1*sbtnH,sbtnW,sbtnH];

%File text Pos
pos13=[0,layout.fileBar_y+1,50,layout.fileBar_Height-6];
%Resize Bar Position---
pos14=[0,layout.resizeBar_y,layout.resizeBar_Width,layout.resizeBar_Height]+ verData.axes_correction;

%Empty axes in the file bar
pos15=[0,layout.fileBar_y,layout.resizeBar_Width,layout.fileBar_Height]+ verData.axes_correction;




%axesHidePos
axesHidePos=[sbtnW,pos14(2),saxesW,pos14(4)]+ verData.axes_correction;


if(layout.tabObjects==0)
          %---Drawing Firing Panel-----
    %Firing axes
    layout.firingAxes=axes (...
        'Units','pixels',...
        'pos',faxesPos,...
        'vis','on',...
        'Ydir','reverse',...
        'color',[1 1 1],...
        'ButtonDownFcn','');


    %create the firing struct
    firingData=struct('left',0,...
        'right',10,...
        'bottom',0,...
        'top',1,...
        'tbase_list',[0.0500 0.1000 0.2000 0.5000 1 2 5],...
        'sens_list',[10.5 20.5 40.5 60.5 100.5],...
        'timebase', 0.5,...
        'sensitivity', 20.5,...
        'time', 0,...
        'time_step',5,...
        'style','toc',...
        'timeLength',0,...
        'selectedFiles',-1,...
        'cursor',[],...
        'a1',0,...
        'a2',0,...
        'grat1','' ,...
        'grat2','' ,...
        'gratnum','');
    set(layout.firingAxes,'UserData',firingData);
    
%     curDir=cd;
%     cd('icons');
    %icon=imread('out.png','png','BackgroundColor',btnCol);
    icon=guiData.gui.icons.zoomOutBtn;
    layout.tabObjects(1)= uicontrol (...
        'pos', pos1,...
        'tag', '| |',...
        'tool', 'zoom out',...
        'Enable','inactive',...
        'callback','eafscreen(''eafbutton'');',...
        'BackgroundColor',btnCol,...
        'Cdata',icon,...
        'UserData',layout.firingAxes);

   %icon=imread('left.png','png','BackgroundColor',btnCol);
   icon=guiData.gui.icons.leftBtn;
    layout.tabObjects(2)=uicontrol (...
        'Style','togglebutton',...
        'pos', pos2,...
        'tag', '<', ...
        'tool', 'scroll left',...
        'Enable',verData.scrollBtnEnable,...
        'Cdata',icon,...
        'BackgroundColor',btnCol,...
        'UserData',layout.firingAxes);
    %icon=imread('in.png','png','BackgroundColor',btnCol);
    icon=guiData.gui.icons.zoomInBtn;
    layout.tabObjects(3)=uicontrol (...
        'pos', pos3,...
        'tag', '||', ...
        'tool', 'zoom in',...
        'Enable','inactive',...
        'callback','eafscreen(''eafbutton'');',...
        'BackgroundColor',btnCol,...
        'CData',icon,...
        'UserData',layout.firingAxes);

    %icon=imread('minus.png','png','BackgroundColor',btnCol);
    icon=guiData.gui.icons.minusBtn;
    layout.tabObjects(4)=uicontrol (...
        'pos', pos4,...
        'tag', '-',...
        'tool', 'scale down',...
        'Enable','inactive',...
        'callback','eafscreen(''eafbutton'');',...
        'CData',icon,...
        'BackgroundColor',btnCol,...
        'UserData',layout.firingAxes);
    
   %icon=imread('right.png','png','BackgroundColor',btnCol);
   icon=guiData.gui.icons.rightBtn;
    layout.tabObjects(5)=uicontrol (...
        'Style','togglebutton',...
        'pos', pos5,...
        'tag', '>', ...
        'tool', 'scroll right',...
        'Enable',verData.scrollBtnEnable,...
        'BackgroundColor',btnCol,...
        'Cdata',icon,...
        'UserData',layout.firingAxes);
    
    %icon=imread('plus.png','png','BackgroundColor',btnCol);
    icon=guiData.gui.icons.plusBtn;
    layout.tabObjects(6)=uicontrol (...
        'pos',pos6 ,...
        'tag', '+', ...
        'tool', 'scale up',...
        'Enable','inactive',...
        'callback','eafscreen(''eafbutton'');',...
        'Cdata',icon,...
        'BackgroundColor',btnCol,...
        'UserData',layout.firingAxes);
%     cd(curDir);

   
    %---Drawing Signal Panel-----
    layout.signalAxes=axes (...
        'Units','pixels',...
        'pos',saxesPos,...
        'vis','on',...
        'Clipping','off',...
        'color',[1 1 1],...
        'ButtonDownFcn','');

    %create the signal struct
    signalData=struct('left',0,...
        'right',10,...
        'bottom',0,...
        'top',1,...
        'tbase_list',[0.0010 0.0020 0.0050 0.0100 0.0200 0.0500 0.1000 0.2 0.5 1],...
        'sens_list',[10 20 40 60 100],...
        'timebase',0.01,...
        'sensitivity',1,...
        'time',0,...
        'time_step',5,...
        'style','toc',...
        'timeLength',0,...
        'selectedFiles',-1,...
        'cursor',[],...
        'a1',0,...
        'a2',0,...
        'grat1'  , '',...
        'grat2',   '',...
        'gratnum','',...
        'rText',[],...
        'rTextPos',[],...
        'bText',[],...
        'bTextPos',[],...
        'cLine','',...
        'displayT','1');

    %save the signal Data structure in the signal axes
    set(layout.signalAxes,'UserData',signalData);
    
%     curDir=cd;
%     cd('icons');
    %icon=imread('out.png','png','BackgroundColor',btnCol);
    icon=guiData.gui.icons.zoomOutBtn;
    layout.tabObjects(7)=uicontrol (...
        'pos',pos7,...
        'tag', '| |',...
        'tool', 'zoom out',...
        'callback','eafscreen(''eafbutton'');',...
        'Enable','inactive',...
        'BackgroundColor',btnCol,...
        'CData',icon,...
        'UserData',layout.signalAxes);
    %icon=imread('left.png','png','BackgroundColor',btnCol);
    icon=guiData.gui.icons.leftBtn;
    layout.tabObjects(8)=uicontrol (...
        'Style','togglebutton',...
        'pos', pos8,...
        'tag', '<',...
        'tool', 'scroll left',...
        'Enable',verData.scrollBtnEnable,...
        'Cdata',icon,...
        'BackgroundColor',btnCol,...
        'UserData',layout.signalAxes);
    %icon=imread('in.png','png','BackgroundColor',btnCol);
    icon=guiData.gui.icons.zoomInBtn;
    layout.tabObjects(9)=uicontrol (...
        'pos', pos9,...
        'tag', '||',...
        'tool', 'zoom in',...
        'Enable','inactive',...
        'callback','eafscreen(''eafbutton'');',...
        'Cdata',icon,...
        'BackgroundColor',btnCol,...
        'UserData',layout.signalAxes);

    %icon=imread('previouserror.png','png','BackgroundColor',btnCol);
    icon=guiData.gui.icons.previousErrBtn;
    layout.tabObjects(10)=uicontrol (...
        'Style','togglebutton',...
        'pos', pos10,...
        'tag', '<<',...
        'tool', 'previous error',...
        'Enable','inactive',...
        'callback','eafscreen(''eafbutton'');',...
        'Cdata',icon,...
        'BackgroundColor',btnCol,...
        'UserData',layout.signalAxes);
    
    %icon=imread('right.png','png','BackgroundColor',btnCol);
    icon=guiData.gui.icons.rightBtn;
    layout.tabObjects(11)=uicontrol (...
        'Style','togglebutton',...
        'pos', pos11, ...
        'tag', '>',...
        'tool', 'scroll right',...
        'Enable',verData.scrollBtnEnable,...
        'BackgroundColor',btnCol,...
        'Cdata',icon,...
        'UserData',layout.signalAxes);
   
   %icon=imread('nexterror.png','png','BackgroundColor',btnCol);
   icon=guiData.gui.icons.nextErrBtn;
    layout.tabObjects(12)=uicontrol (...
        'Style','togglebutton',...
        'pos',pos12 ,...
        'tag','>>',...
        'tool', 'next error',...
        'Enable','inactive',...
        'callback','eafscreen(''eafbutton'');',...
        'BackgroundColor',btnCol,...
        'CData',icon,...
        'UserData',layout.signalAxes);
%     cd(curDir);
    
    %----File Bar--------
    layout.tabObjects(13)=uicontrol(...
        'style','text',...
        'Units','pixels',...
        'pos',pos13,...
        'vis','on',...
        'String','Files:',...
        'BackgroundColor',[0.8708,0.8786,0.8935]);

    %----Resize Bar-----
    layout.tabObjects(14)=axes('Units','pixels',...
        'pos',pos14,...
        'vis','on',...
        'color',[0.8708,0.8786,0.8935],...
        'ButtonDownFcn','eafscreen(''resizeButtonDown'');');

    
    layout.tabObjects(15)=axes('Units','pixels',...
        'pos',pos15,...
        'vis','on',...
        'color',[0.8708,0.8786,0.8935]);
   

else
    if(fpanelH>3)
        set(layout.tabObjects(1),'pos',pos1,'vis','on');
        set(layout.tabObjects(2),'pos', pos2,'vis','on');
        set(layout.tabObjects(3),'pos', pos3,'vis','on');
        set(layout.tabObjects(4),'pos', pos4,'vis','on');
        set(layout.tabObjects(5),'pos',pos5,'vis','on');
        set(layout.tabObjects(6),'pos', pos6,'vis','on');
        set(layout.firingAxes,'pos', faxesPos,'vis','on');

    else
        set(layout.tabObjects(1),'vis','off');
        set(layout.tabObjects(2),'vis','off');
        set(layout.tabObjects(3),'vis','off');
        set(layout.tabObjects(4),'vis','off');
        set(layout.tabObjects(5),'vis','off');
        set(layout.tabObjects(6),'vis','off');
        set(layout.firingAxes,'pos',axesHidePos,'vis','off');


    end

    if(spanelH>3)
        set(layout.tabObjects(7),'pos',pos7,'vis','on');
        set(layout.tabObjects(8),'pos', pos8,'vis','on');
        set(layout.tabObjects(9),'pos',pos9,'vis','on');
        set(layout.tabObjects(10),'pos', pos10,'vis','on');
        set(layout.tabObjects(11),'pos', pos11,'vis','on');
        set(layout.tabObjects(12),'pos', pos12,'vis','on');
        set(layout.signalAxes,'pos', saxesPos,'vis','on');

    else
        set(layout.tabObjects(7),'vis','off');
        set(layout.tabObjects(8),'vis','off');
        set(layout.tabObjects(9),'vis','off');
        set(layout.tabObjects(10),'vis','off');
        set(layout.tabObjects(11),'vis','off');
        set(layout.tabObjects(12),'vis','off');
        set(layout.signalAxes,'pos',axesHidePos,'vis','off')

    end
    %---File Text----
    set(layout.tabObjects(13),'pos', pos13,'vis','on');
    set(layout.tabObjects(14),'pos',pos14,'vis','on');
    set(layout.tabObjects(15),'pos',pos15,'vis','on');
end


%adjustAxes(layout.signalAxes);
%adjustAxes(layout.firingAxes);
redrawAxes(layout.signalAxes,get(layout.signalAxes,'UserData'));
redrawAxes(layout.firingAxes,get(layout.firingAxes,'UserData'));
%adjustAxes(layout.tabObjects(14));
%adjustAxes(layout.tabObjects(15));

tabData.tabLayout=layout;
set(tabHandle,'UserData',tabData);


%**************************************************************************
%redrawTabs
%**************************************************************************

function redrawTabs

%get the current figure
figHandle=gcf;

%get the window layout
windowData=get(figHandle,'UserData');
% get the tabs in the window
tabs=windowData.tabs;

tab_width=windowData.windowLayout.tabBar_Width/tabs.numtabs;
if(tab_width>windowData.windowLayout.maxTab_Width)
    tab_width=windowData.windowLayout.maxTab_Width;
end
tabBar_x=windowData.windowLayout.tabBar_x;
tabBar_y=windowData.windowLayout.tabBar_y;
tabBar_Height=windowData.windowLayout.tabBar_Height;

if(tabs.numtabs>0)

    for i=1:tabs.numtabs
        newTabPos=[(i-1)*tab_width+tabBar_x,tabBar_y,tab_width,tabBar_Height];
        set(tabs.tabsH(i),'pos',newTabPos);
    end

end

windowData.windowLayout.tab_Width=tab_width;
%save the windowData in the figure UserData
set(figHandle,'UserData',windowData);


%**************************************************************************
%SETCURRENTTAB
%**************************************************************************

function setCurrentTab(obj)

resetZoomButtons;

if(nargin==0)
    obj=gco;
end;

figHandle=gcf;
% get the tabs structure
windowData=get(figHandle,'UserData');
tabs=windowData.tabs;

windowData.tabs.currtab=obj;
for i=1:tabs.numtabs
    set(tabs.tabsH(i),'BackgroundColor',[0.8,0.8,0.8]);
    tabData=get(tabs.tabsH(i),'UserData');
    tabLayout=tabData.tabLayout;
    set(tabLayout.signalAxes,'vis','off');
    axesChildren=get(tabLayout.signalAxes,'children');
    set(axesChildren,'vis','off');
    set(tabLayout.firingAxes,'vis','off');
    axesChildren=get(tabLayout.firingAxes,'children');
    set(axesChildren,'vis','off');
    set(tabLayout.tabObjects,'vis','off');
    openFiles=tabData.openFiles;
    if(tabData.openFiles.numFiles>0)
        set(tabData.openFiles.buttonH,'vis','off');
    end;

end
set(windowData.tabs.currtab,'BackgroundColor',[1,1,1]);


tabData=get(windowData.tabs.currtab,'UserData');
if(tabData.openFiles.numFiles>0)
    set(tabData.openFiles.buttonH,'vis','on');
end;
%resize the tab to fit the window
resizeTabWindow(windowData.tabs.currtab);
tabLayout=tabData.tabLayout;
set(tabLayout.signalAxes,'vis','on');
axesChildren=get(tabLayout.signalAxes,'children');
sigAxesData=get(tabLayout.signalAxes,'UserData');    
set(axesChildren,'vis','on');
if(sigAxesData.displayT==1)
    if(~isempty(sigAxesData.cLine))
        if(ishandle(sigAxesData.cLine{5}))
            set(sigAxesData.cLine{5},'vis','off');
        end
        if(ishandle(sigAxesData.cLine{6}))
            set(sigAxesData.cLine{6},'vis','off');
        end
    end
else
    if(ishandle(sigAxesData.bText))
        set(sigAxesData.bText,'vis','off');
    end
     if(ishandle(sigAxesData.rText))
        set(sigAxesData.rText,'vis','off');
     end
end
        
set(tabLayout.firingAxes,'vis','on');
axesChildren=get(tabLayout.firingAxes,'children');
set(axesChildren,'vis','on');

%set(tabLayout.tabObjects,'vis','on');
set(figHandle,'UserData',windowData);

%**************************************************************************
%deleteTab
%**************************************************************************

function deleteTab

figHandle=gcf;
% get the tabs structure
windowData=get(figHandle,'UserData');
tabs=windowData.tabs;

tag=get(gco,'tag');
if(strcmp(tag,'tab'))
    currTabH=gco;
else
    % get the current tab
    currTabH=tabs.currtab;
end


if(tabs.numtabs>0)

    
    % get the current tab data
    tabData=get(currTabH,'UserData');

    delete(tabData.tabLayout.signalAxes);
    delete(tabData.tabLayout.firingAxes);

    %delete all the objects in the current tab
    delete(tabData.tabLayout.tabObjects);
    if(tabData.openFiles.numFiles>0)
        delete(tabData.openFiles.buttonH)
    end;
    if(tabs.numtabs>1)
    %delete the object form the tab Handles array
    indexTab=find(tabs.tabsH==currTabH);
    nTabsH(1:indexTab-1)=tabs.tabsH(1:indexTab-1);
    nTabsH(indexTab:tabs.numtabs-1)=tabs.tabsH(indexTab+1:tabs.numtabs);
    delete(currTabH);
    tabs.tabsH=nTabsH;
    tabs.numtabs=tabs.numtabs-1;
    if(tabs.currtab==currTabH)
    tabs.currtab=tabs.tabsH(end);
    end
       
    else
        delete(currTabH);
        tabs.numtabs=0;
        tabs.currtab=0;
        tabs.tabsH=0;
        deleteIcon=findobj(figHandle,'tag','deleteIcon');
        if(ishandle(deleteIcon))
            set(deleteIcon,'vis','off');
        end
        closetabH=findobj(figHandle,'tag','closetab');
        if(ishandle(closetabH))
            set(closetabH,'enable','off');
        end
        
        
        
    end
  

end

%save the new tabs info in the figure UserData
windowData.tabs=tabs;
set(figHandle,'UserData',windowData);

if(tabs.numtabs>0)
% set the current tab to the last open tab
setCurrentTab(tabs.currtab);

% redraw the tabs
redrawTabs;
end

%**************************************************************************
%EXPORTTAB
%**************************************************************************
function exportTab
    targetTab=gco;
    tabDataExport=get(targetTab,'UserData');
    figHandle=newWindow;
    set(figHandle,'HandleVisibility','on');
    windowData=get(figHandle,'UserData');
    tabData=get(windowData.tabs.currtab,'UserData');
    tabData.openFiles=tabDataExport.openFiles;
    tabData.tabLayout.ratioFPvSP=tabDataExport.tabLayout.ratioFPvSP;
    set(windowData.tabs.currtab,'String',get(targetTab,'String'));
    if(tabDataExport.openFiles.numFiles>0)
        for i=1:tabDataExport.openFiles.numFiles
            %crete a uicontext menu for the file button
             fileMenu=uicontextmenu('parent',figHandle);
             %uimenu(fileMenu,'Label','Close File','callback','eafscreen(''deleteFile'');');
             tFileMenuH=get(tabDataExport.openFiles.buttonH(i),'uicontextmenu');
             uimenusH=get(tFileMenuH,'children');
             for k=1:length(uimenusH)
                 p=length(uimenusH)-k+1;
                 h=uimenu(...
                     fileMenu,...
                     'tag',get(uimenusH(p),'tag'),...
                     'Label',get(uimenusH(p),'Label'),...
                     'UserData',get(uimenusH(p),'UserData'),...
                     'checked',get(uimenusH(p),'checked'),...
                     'callback',get(uimenusH(p),'callback'));
                 
             end

            %Create the file button
            % save the annotation in the user data of the file button
            tabData.openFiles.buttonH(i)=uicontrol( 'parent',figHandle,...
                'Style','togglebutton',...
                'Tag',get(tabDataExport.openFiles.buttonH(i),'Tag'),...
                'BackgroundColor',[0.87,0.87,0.89],...
                'Units','pixels',...
                'Uicontextmenu',fileMenu,...
				'Enable',get(tabDataExport.openFiles.buttonH(i),'Enable'),...
                'String',get(tabDataExport.openFiles.buttonH(i),'String'),...
                'callback',get(tabDataExport.openFiles.buttonH(i),'callback'),...
                'ForeGroundColor',get(tabDataExport.openFiles.buttonH(i),'ForeGroundColor'),...
                'Value',get(tabDataExport.openFiles.buttonH(i),'Value'),...
                'UserData',get(tabDataExport.openFiles.buttonH(i),'UserData'));
        end
       
    end
    set(windowData.tabs.currtab,'UserData',tabData);
    drawFiles(windowData.tabs.currtab);
    plotFiles(windowData.tabs.currtab);
    
    set(figHandle,'HandleVisibility','callback');
    
    

%**************************************************************************
%openFile
%**************************************************************************
function openFile(file1,figHandle,opt,selected)

resetZoomButtons;






if(nargin==0)
    figHandle=gcf;
    opt=1;
    selected=0;
    v = version;
    if v(1)>='6';
        [file1, path1] = uigetfile ('*.eaf;*.ann', 'Choose  annotation.');
    else
        [file1, path1] = uigetfile ('*', 'Choose  annotation.');
    end;
    file1= fullfile(path1,file1);
end
if(~exist(file1,'file'))
    return;
end
[pathstr, fileName, ext, versn] = fileparts(file1);



% get form the window the current tab
windowData=get(figHandle,'UserData');
verData=windowData.verData;
% check if there is no tabs
if(windowData.tabs.numtabs<1)
    %if there is no tabs create one
    newTab;
    windowData=get(figHandle,'UserData');
end
tabs=windowData.tabs;
tabData=get(tabs.currtab,'UserData');
openFiles=tabData.openFiles;



tabName=get(tabs.currtab,'String');
if(strcmp(tabName,'Empty Tab'))
    tabName=fileName;
else
    tabName=[tabName,', ',fileName];
end;

set(tabs.currtab,'String',tabName);

%Define the file context menu
fileMenu=uicontextmenu('parent',figHandle,'vis','off');
uimenu(fileMenu,'Label','Close File','callback','eafscreen(''deleteFile'');');
[pathstr,name,ext,versn] = fileparts(file1);

ann=[];

try
    switch lower(ext)
        case '.ann'
             ann=load_ann(file1);
        case '.eaf'
             ann=load_eaf(file1);
        case '.tim'
             ann=load_tim(file1);
        otherwise
            ann=[];
    end
        
catch
    errordlg ({'Error reading file.', lasterr});
    return;
end;



if(isfield(ann,'chan'))
  chan=unique(ann.chan);
  chan=sort(chan);
 
  for i=1:length(chan)
	  chanIndex=find(ann.chan==chan(i));
	  chanAnn.time=ann.time(chanIndex);
	  chanAnn.unit=ann.unit(chanIndex);
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
    chanStr='';
	chanAnn1=ann;
end;

newFileH=uicontrol( 'parent',figHandle,...
    'Style','togglebutton',...
    'Tag',fileName,...
    'BackgroundColor',[0.87,0.87,0.89],...
    'Units','pixels',...
    'Uicontextmenu',fileMenu,...
    'String',[fileName,' ',chanStr],...
    'Enable',verData.fileBtnEnable,...
    'callback','eafscreen(''updateFiles'');');

set(newFileH,'UserData',chanAnn1);


if(openFiles.numFiles==0)
    openFiles.buttonH(1)=newFileH;
    openFiles.filespath{1}=file1;
    openFiles.selectedFiles(1)=1;
    openFiles.numFiles=1;
    set(newFileH,'foregroundColor',[0,0,1],'Value',1);
else
    
    openFiles.buttonH(end+1)=newFileH;
    openFiles.filespath{end+1}=file1;
    blueFileIndex=find(openFiles.selectedFiles==1);
    redFileIndex=find(openFiles.selectedFiles==2);
    if(opt==1)&(selected==0)
    if(isempty(blueFileIndex))
        openFiles.selectedFiles(end+1)=1;
        set(newFileH,'foregroundColor',[0,0,1],'Value',1);
    else
        if (isempty(redFileIndex))
            openFiles.selectedFiles(end+1)=2;
        else
            openFiles.selectedFiles(end+1)=2;
            openFiles.selectedFiles(redFileIndex)=0;
            set(openFiles.buttonH(redFileIndex),'foregroundColor',[0,0,0],'Value',0);
        end

        set(newFileH,'foregroundColor',[1,0,0],'Value',1);
    end
    elseif(opt==2) & (selected==1)
        if(~isempty( blueFileIndex))
        set(openFiles.buttonH(blueFileIndex),'foregroundColor',[0,0,0],'Value',0)
        openFiles.selectedFiles(blueFileIndex)=0;
        end
        openFiles.selectedFiles(end+1)=1;
        set(newFileH,'foregroundColor',[0,0,1],'Value',1);
   elseif(opt==2) & (selected==2)
           if(~isempty( redFileIndex))
           set(openFiles.buttonH(redFileIndex),'foregroundColor',[0,0,0],'Value',0)
           openFiles.selectedFiles(redFileIndex)=0;
           end
           openFiles.selectedFiles(end+1)=2;
           set(newFileH,'foregroundColor',[1,0,0],'Value',1);
    elseif(opt==2) & (selected==0)
            openFiles.selectedFiles(end+1)=0; 
        
    end

    openFiles.numFiles=openFiles.numFiles+1;
end;




tabData.openFiles= openFiles;
set(tabs.currtab,'UserData',tabData);

drawFiles(tabs.currtab);
plotFiles(tabs.currtab);
%**************************************************************************
%deleteFile
%**************************************************************************
function deleteFile
targetFile=gco;
menuH=get(targetFile,'Uicontextmenu');
delete(menuH);
figHandle=gcf;
%get form the window the current tab
windowData=get(figHandle,'UserData');
tabs=windowData.tabs;
tabData=get(tabs.currtab,'UserData');
openFiles=tabData.openFiles;

indexF=find(openFiles.buttonH~=targetFile);
if(~isempty(indexF))
openFiles.buttonH=openFiles.buttonH(indexF);
openFiles.filespath=openFiles.filespath(indexF);
openFiles.selectedFiles=openFiles.selectedFiles(indexF);
openFiles.numFiles=openFiles.numFiles-1;
tabStr=get(openFiles.buttonH(1),'String');
for i=2:openFiles.numFiles
    tabStr=[tabStr,', ',get(openFiles.buttonH(i),'String')];
end

set(tabs.currtab,'String',tabStr);  
else
openFiles.buttonH=0;
openFiles.filespath='';
openFiles.selectedFiles=0;
openFiles.numFiles=0;
set(tabs.currtab,'String','Empty Tab');
end
delete(targetFile);
tabData.openFiles= openFiles;
set(tabs.currtab,'UserData',tabData);

drawFiles(tabs.currtab);
plotFiles(tabs.currtab);

%**************************************************************************
%drawFiles
%**************************************************************************
function drawFiles(tabHandle)

tabData=get(tabHandle,'UserData');
tabLayout=tabData.tabLayout;
openFiles=tabData.openFiles;


if(openFiles.numFiles>1)
    pos_width=tabLayout.fileBar_Width/openFiles.numFiles;
else
    pos_width=tabLayout.fileBar_Width;
end;
if(pos_width>150)
    pos_width=150;
end
pos_x=tabLayout.fileBarText_Width;
pos_y=tabLayout.fileBar_y+3;
pos_height=tabLayout.fileBar_Height-6;
for i=1:openFiles.numFiles
    newPos=[pos_x,pos_y,pos_width,pos_height];
    set(openFiles.buttonH(i),'pos',newPos);
    pos_x=pos_x+pos_width;
end;


%**************************************************************************
%plotFiles
%**************************************************************************

function plotFiles(tabHandle)
resetZoomButtons;

tabData=get(tabHandle,'UserData');
figHandle=get(tabHandle,'parent');
windowData=get(figHandle,'UserData');
verData=windowData.verData;
tabLayout=tabData.tabLayout;
firingAxesData=get(tabLayout.firingAxes,'UserData');
signalAxesData=get(tabLayout.signalAxes,'UserData');

% cla(tabLayout.firingAxes);
% cla(tabLayout.signalAxes);
h=get(tabLayout.firingAxes,'children');
delete(h);
h=get(tabLayout.signalAxes,'children');
delete(h);



    blueFileIndex=find(tabData.openFiles.selectedFiles==1);
    redFileIndex=find(tabData.openFiles.selectedFiles==2);
    if (isempty(blueFileIndex)& isempty(redFileIndex))
        % no files selected
        firingAxesData.selectedFiles=-1;
        set(tabLayout.firingAxes,'UserData',firingAxesData);
        signalAxesData.selectedFiles=-1;
        set(tabLayout.signalAxes,'UserData',signalAxesData);
        set(tabLayout.signalAxes,'ButtonDownFcn','');
        set(tabLayout.firingAxes,'ButtonDownFcn','');
        set(tabLayout.tabObjects(1:12),'Enable','inactive');
    elseif(isempty(blueFileIndex))
        set(tabLayout.tabObjects(1:12),'Enable','on');
        for i=2:3:11
        set(tabData.tabLayout.tabObjects(i),'Enable',verData.scrollBtnEnable)
        end
        col=[1,0,0];
        ann1=get(tabData.openFiles.buttonH(redFileIndex(1)),'UserData');
        firingAxesData.a1=ann1;
        firingAxesData.a2=ann1;
        firingAxesData.timeLength=ann1.time(end);
        firingAxesData.selectedFiles=1;

        signalAxesData.a1=ann1;
        signalAxesData.a2=ann1;
        signalAxesData.selectedFiles=1;
        signalAxesData.timeLength=ann1.time(end);
        signalAxesData.a2Errors=[0,ann1.time(end)];

        setLimitsAndPlotScale(tabLayout.signalAxes,signalAxesData,...
            'normal',tabLayout.firingAxes,firingAxesData)

        signalAxesData=get(tabLayout.signalAxes,'UserData');
        setLimitsAndPlotScale(tabLayout.firingAxes,firingAxesData,...
            'reverse',tabLayout.signalAxes,signalAxesData);
        firingAxesData=get(tabLayout.firingAxes,'UserData');
        set(tabLayout.firingAxes,'NextPlot','add');
	    line (...
			'tag','Marker',...
            'parent',tabLayout.firingAxes,...
            'xdata',[0,0],...
            'ydata', [0,0],...
            'marker','none',...
			'LineWidth',10,...
            'markersize', 6,...
            'col', [0.9 0.9 0.9],...
            'lineStyle','-',...
            'ButtonDownFcn','eafscreen(''mousePressed'',''firing'');');
		    
        line (...
            'parent',tabLayout.firingAxes,...
            'xdata',ann1.time,...
            'ydata', ann1.unit,...
            'marker','o',...
            'markersize', 6,...
            'col',col,...
            'lineStyle','none',...
            'ButtonDownFcn','eafscreen(''mousePressed'',''firing'');');
        
        annNums=unique(ann1.unit);
        annNums=sort(annNums);
        for i=1:length(annNums)
            h=text(...
                'tag','numbers',...
                'parent',tabLayout.firingAxes,...
                'Units','normalized',...
                'pos',[0,0],...
                'String',num2str(annNums(i)),...
                'Clipping','off',...
                'HorizontalAlignment','right',...
				'ButtonDownFcn','eafscreen(''underline'');',...
                'Color',[1,0,0]);
            set(h,'Units','data');
            pos=get(h,'pos');
            pos(2)=i;
            set(h,'UserData',pos(2));
            set(h,'pos',pos);
            set(h,'Units','normalized');
			
            
        end;
        set(tabLayout.firingAxes,'NextPlot','replace');
    elseif(isempty(redFileIndex))
        set(tabLayout.tabObjects(1:12),'Enable','on');
        for i=2:3:11
        set(tabData.tabLayout.tabObjects(i),'Enable',verData.scrollBtnEnable)
        end
        col=[0,0,1];
        ann1=get(tabData.openFiles.buttonH(blueFileIndex(1)),'UserData');

        firingAxesData.a1=ann1;
        firingAxesData.a2=ann1;
        firingAxesData.timeLength=ann1.time(end);
        firingAxesData.selectedFiles=0;

        signalAxesData.a1=ann1;
        signalAxesData.a2=ann1;
        signalAxesData.selectedFiles=0;
        signalAxesData.timeLength=ann1.time(end);
        signalAxesData.a2Errors=[0,ann1.time(end)];

        setLimitsAndPlotScale(tabLayout.signalAxes,signalAxesData,...
            'normal',tabLayout.firingAxes,firingAxesData)
        signalAxesData=get(tabLayout.signalAxes,'UserData');
        setLimitsAndPlotScale(tabLayout.firingAxes,firingAxesData,...
            'reverse',tabLayout.signalAxes,signalAxesData);
        firingAxesData=get(tabLayout.firingAxes,'UserData');
        set(tabLayout.firingAxes,'NextPlot','add');
		line (...
			'tag','Marker',...
            'parent',tabLayout.firingAxes,...
            'xdata',[0,0],...
            'ydata', [0,0],...
            'marker','none',...
			'LineWidth',10,...
            'markersize', 6,...
            'col', [0.9 0.9 0.9],...
            'lineStyle','-',...
            'ButtonDownFcn','eafscreen(''mousePressed'',''firing'');');
        line (...
            'parent',tabLayout.firingAxes,...
            'xdata',ann1.time,...
            'ydata', ann1.unit,...
            'marker','o',...
            'markersize', 6,...
            'col', col,...
            'lineStyle','none',...
            'ButtonDownFcn','eafscreen(''mousePressed'',''firing'');');
        
        annNums=unique(ann1.unit);
        annNums=sort(annNums);
        for i=1:length(annNums)
            h=text(...
                'tag','numbers',...
                'parent',tabLayout.firingAxes,...
                'Units','normalized',...
                'pos',[0,0],...
                'String',num2str(annNums(i)),...
                'Clipping','off',...
                'HorizontalAlignment','right',...
				'ButtonDownFcn','eafscreen(''underline'');',...
                'Color',[0,0,1]);
            set(h,'Units','data');
            pos=get(h,'pos');
            pos(2)=i;
            set(h,'UserData',pos(2));
            set(h,'pos',pos);
            set(h,'Units','normalized');
            
        end;
        
        
        
        set(tabLayout.firingAxes,'NextPlot','replace');

    else
        set(tabLayout.tabObjects(1:12),'Enable','on');
        for i=2:3:11
        set(tabData.tabLayout.tabObjects(i),'Enable',verData.scrollBtnEnable);
		end

        ann1=get(tabData.openFiles.buttonH(blueFileIndex(1)),'UserData');
        ann2=get(tabData.openFiles.buttonH(redFileIndex(1)),'UserData');
 		
        t0 = max(ann1.time(1), ann2.time(1));
        t1 = min(ann1.time(end), ann2.time(end));
        if t0>t1;
            fann1 = ann1;
            fann2 = ann2;
        else
            clear fann1 fann2
            ix = find(ann1.time>=t0 & ann1.time<=t1);
            fann1.time = ann1.time(ix);
            fann1.unit = ann1.unit(ix);
            ix = find(ann2.time>=t0 & ann2.time<=t1);
            fann2.time = ann2.time(ix);
            fann2.unit = ann2.unit(ix);
        end;
        ann1 = fann1;
        ann2 = fann2;
        sp = eaf_compare (fann1, fann2, 'Print', 'off');
 		  
        

        firingAxesData.a1=ann1;
        firingAxesData.a2=ann2;
        firingAxesData.sp=sp;
        firingAxesData.timeLength=max(ann1.time(end),ann2.time(end));
        firingAxesData.selectedFiles=2;

        signalAxesData.a1=ann1;
        signalAxesData.a2=ann2;
        signalAxesData.timeLength=max(ann1.time(end),ann2.time(end));
        signalAxesData.sp=sp;
        signalAxesData.selectedFiles=2;
        set(tabLayout.firingAxes,'NextPlot','add');
       
        line (...
			'tag','Marker',...
            'parent',tabLayout.firingAxes,...
            'xdata',[0,0],...
            'ydata', [0,0],...
            'marker','none',...
			'LineWidth',10,...
            'markersize', 6,...
            'col', [0.9 0.9 0.9],...
            'lineStyle','-',...
            'ButtonDownFcn','eafscreen(''mousePressed'',''firing'');');
		
		
         eaf_plot (ann1, ann2, sp,tabLayout.firingAxes,firingAxesData);
		firingAxesData=get(tabLayout.firingAxes,'UserData');
		
      
        setLimitsAndPlotScale(tabLayout.firingAxes,firingAxesData,...
            'reverse',tabLayout.signalAxes,signalAxesData);
        firingAxesData=get(tabLayout.firingAxes,'UserData');
        signalAxesData=get(tabLayout.signalAxes,'UserData');
        setLimitsAndPlotScale(tabLayout.signalAxes,signalAxesData,...
            'normal',tabLayout.firingAxes,firingAxesData);
        firingAxesData=get(tabLayout.firingAxes,'UserData');
        signalAxesData=get(tabLayout.signalAxes,'UserData');
		 annNums=unique(ann1.unit);
        annNums=sort(annNums);
        if(isempty(annNums))
            blueNumbers=0;
        else
            blueNumbers=length(annNums);
        end
        for i=1:length(annNums)
            h=text(...
                'tag','numbers',...
                'parent',tabLayout.firingAxes,...
                'Units','normalized',...
                'pos',[0,0],...
                'String',num2str(annNums(i)),...
                'Clipping','off',...
                'HorizontalAlignment','right',...
				'ButtonDownFcn','eafscreen(''underline'');',...
                'Color',[0,0,1]);
            set(h,'Units','data');
            pos=get(h,'pos');
            pos(2)=i;
            set(h,'UserData',pos(2));
            set(h,'pos',pos);
            set(h,'Units','normalized');
            
        end;
        
        annNums=unique(ann2.unit);
        annNums=sort(annNums);
        counterPos=1;
        for i=1:length(annNums)
            h=text(...
                'tag','numbers',...
                'parent',tabLayout.firingAxes,...
                'Units','normalized',...
                'pos',[1,0],...
                'String',[' ',num2str(annNums(i))],...
                'Clipping','off',...
                'HorizontalAlignment','left',...
				'ButtonDownFcn','eafscreen(''underline'');',...
                'Color',[1,0,0]);
            set(h,'Units','data');
            pos=get(h,'pos');
            %if(length(sp.MUmap)>i)
            if(~isnan(sp.MUmap(i)))
            pos(2)=find(sp.MUidTR==sp.MUmap(i));
            else
                pos(2)=counterPos+blueNumbers;
                counterPos=counterPos+1;
            end
            set(h,'UserData',pos(2));
            set(h,'pos',pos);
            set(h,'Units','normalized');
            
        end;
		set(tabLayout.firingAxes,'NextPlot','replace');
        
    end


%**************************************************************************
%updateFiles
%**************************************************************************
function updateFiles(filePressed)
figHandle=gcf;
windowData=get(figHandle,'UserData');
verData=windowData.verData;
currTab=windowData.tabs.currtab;
tabData=get(currTab,'UserData');

if(nargin==0)
filePressed=gco;
end;
filePressedIndex=find(tabData.openFiles.buttonH==filePressed);

% check if the button is pressed
value=get(filePressed,'Value');
if(value==verData.value);
    tabData.openFiles.selectedFiles(filePressedIndex)=0;
    set(tabData.openFiles.buttonH(filePressedIndex),'ForeGroundColor',[0,0,0],'Value',0);
    
else
    blueFileIndex=find(tabData.openFiles.selectedFiles==1);
    redFileIndex=find(tabData.openFiles.selectedFiles==2);
    if(isempty(blueFileIndex))
        tabData.openFiles.selectedFiles(filePressedIndex)=1;
        set(tabData.openFiles.buttonH(filePressedIndex),'ForeGroundColor',[0,0,1],'Value',1);
    else
        if(~isempty(redFileIndex))
            set(tabData.openFiles.buttonH(redFileIndex),'ForeGroundColor',[0,0,0],'Value',0);
            tabData.openFiles.selectedFiles(redFileIndex)=0;
        end
        tabData.openFiles.selectedFiles(filePressedIndex)=2;
        set(tabData.openFiles.buttonH(filePressedIndex),'ForeGroundColor',[1,0,0],'Value',1);
    end
end
set(currTab,'UserData',tabData);
drawnow;
plotFiles(currTab);



function eafbutton(option,axesH)


resetZoomButtons;

if(nargin<2)
    option=get(gco,'tag');
    axesH=get(gco,'UserData');


end

axesData=get(axesH,'UserData');




switch option
    case '+'
        h=findobj(axesH,'tag','numbers');
        set(h,'Units','data');
        pos=get(h,'pos');
        for i=1:length(h)
        newpos{i}(1)=(pos{i}(1));
		newpos{i}(2)=get(h(i),'UserData');
        end;
        axesData.sensitivity = bump (axesData.sensitivity, axesData.sens_list, -1);
        redrawAxes(axesH,axesData);
        for i=1:length(h)
             set(h(i),'pos',newpos{i});
        end
        
        set(h,'Units','normalized');
		pos=get(h,'pos');
        for i=1:length(h)
        newpos{i}(1)=round(pos{i}(1));
		newpos{i}(2)=(pos{i}(2));
        end;
		for i=1:length(h)
             set(h(i),'pos',newpos{i});
        end
        
        
        
    case '-'
        h=findobj(axesH,'tag','numbers');
        set(h,'Units','data');
        pos=get(h,'pos');
        for i=1:length(h)
        newpos{i}(1)=(pos{i}(1));
		newpos{i}(2)=get(h(i),'UserData');
        end;
        axesData.sensitivity = bump (axesData.sensitivity, axesData.sens_list, +1);
        redrawAxes(axesH,axesData);
        for i=1:length(h)
             set(h(i),'pos',newpos{i});
        end
        set(h,'Units','normalized');
		pos=get(h,'pos');
		for i=1:length(h)
        newpos{i}(1)=round(pos{i}(1));
		newpos{i}(2)=(pos{i}(2));
        end;
		for i=1:length(h)
             set(h(i),'pos',newpos{i});
        end

    case '||'
        ydirection=get(axesH,'ydir');
        if(strcmp(ydirection,'reverse'))
            figHandle=gcf;
            windowData=get(figHandle,'UserData');
            tabData=get(windowData.tabs.currtab,'UserData');
            sigAxesData=get(tabData.tabLayout.signalAxes,'UserData');
            focusPoint=sigAxesData.time+(sigAxesData.timebase*sigAxesData.right)/2;
        else    
            focusPoint= axesData.time+(axesData.timebase*axesData.right)/2;
        end
          axesData.timebase = bump (axesData.timebase, axesData.tbase_list, -1);
          axesData.time= focusPoint-axesData.timebase*axesData.time_step;
          axesData.time=max(0,axesData.time);
          redrawAxes(axesH,axesData);
    case '| |'
        timebaseOld=axesData.timebase;
           timeOld=axesData.time;
        ydirection=get(axesH,'ydir');
        if(strcmp(ydirection,'reverse'))
            figHandle=gcf;
            windowData=get(figHandle,'UserData');
            tabData=get(windowData.tabs.currtab,'UserData');
            sigAxesData=get(tabData.tabLayout.signalAxes,'UserData');
            focusPoint=sigAxesData.time+(sigAxesData.timebase*sigAxesData.right)/2;
        else    
            focusPoint= axesData.time+(axesData.timebase*axesData.right)/2;
        end
        
           axesData.timebase = bump (axesData.timebase, axesData.tbase_list, +1);
           axesData.time= focusPoint-axesData.timebase*axesData.time_step;
           axesData.time=min(axesData.time, axesData.timeLength-axesData.right*axesData.timebase);
           axesData.time=max(0,axesData.time);
           if(axesData.time+axesData.right*axesData.timebase>ceil(axesData.timeLength))
               axesData.timebase=timebaseOld;
               axesData.time=timeOld;
           end
           redrawAxes(axesH,axesData);
    case '>>'
         
          scrollToError(axesH,option,gco);
    case '<<'
          scrollToError(axesH,option,gco);
    case '<'
        
        figHandle=gcf;
        windowData=get(figHandle,'UserData');
        windowData.tabs.mouse.mouseAction='scroll';
        set(figHandle,'UserData',windowData);
        axesData.time = axesData.time - axesData.time_step * axesData.timebase;
        axesData.time=max(0,axesData.time);
        redrawAxes(axesH,axesData);
    case '>'
      
        figHandle=gcf;
        windowData=get(figHandle,'UserData');
        windowData.tabs.mouse.mouseAction='scroll';
        set(figHandle,'UserData',windowData);
        axesData.time = axesData.time + axesData.time_step * axesData.timebase;
        axesData.time=min(axesData.time, axesData.timeLength-axesData.right*axesData.timebase);
        axesData.time=max(0,axesData.time);
        redrawAxes(axesH,axesData);

end






function val = bump (val, list, inc, vmax)
if isnan(val); return; end;
i = find(val==list);
if inc>0;
    if nargin>=4;
        list = list(list<=vmax);
    end;
    i = min(i+inc, length(list));
else
    i = max(i+inc, 1);
end;
val = list(i);


%**************************************************************************
%redrawAxes
%**************************************************************************

function redrawAxes(axesH,axesData)

%if the axes is not empty 
if(axesData.selectedFiles~=-1)
x=[axesData.time,axesData.time+axesData.right*axesData.timebase];
y=[0,axesData.sensitivity];
set(axesH,'Xlim',x,'Ylim',[0,axesData.sensitivity]);
set(axesH,'UserData',axesData);
ydirection=get(axesH,'ydir');
switch ydirection
    case 'reverse'
        plottscale (axesH,axesData.grat1, axesData, 0, -1);
        plottscale (axesH,axesData.grat2, axesData, axesData.sensitivity, +1, 'above', axesData.gratnum);
    case 'normal'



        plotText4(axesH,axesData.a1,axesData.a2,axesData.rText,axesData.rTextPos,axesData.bText,axesData.bTextPos,axesData.cLine,axesData.selectedFiles);

        axesData=get(axesH,'UserData');

        plottscale (axesH,axesData.grat1, axesData, axesData.sensitivity , -1,'none',x,y);
        plottscale (axesH,axesData.grat2, axesData,0, +1, 'above', axesData.gratnum,x,y);
        set(axesData.cursor.leftCursor,'xdata',[x(1),x(1)]);
        set(axesData.cursor.rightCursor,'xdata',[x(2),x(2)]);
end
end
set(axesH,'UserData',axesData);




%**************************************************************************
%mousePressed
%**************************************************************************
function mousePressed(opt)


% get the current figure
figHandle=gcf;

% get the current tatb from the figure data
windowData=get(figHandle,'UserData');
currTab=windowData.tabs.currtab;

% get the current Tab data
tabData=get(currTab,'UserData');



%get the  selection type
selectionType=get(figHandle,'SelectionType');



switch opt

    case 'firing'
        axesH=tabData.tabLayout.firingAxes;
        axesH2=tabData.tabLayout.signalAxes;
        point= get (axesH, 'currentpoint');
    case 'signal'
        axesH=tabData.tabLayout.signalAxes;
        axesH2=tabData.tabLayout.firingAxes;
        point= get (axesH, 'currentpoint');
end


zoomInButton=findobj(figHandle,'tag','zoominIcon');
zoomOutButton=findobj(figHandle,'tag','zoomoutIcon');
valueZoomIn=get(zoomInButton,'Value');
valueZoomOut=get(zoomOutButton,'Value');

if valueZoomIn 
   set(zoomInButton,'UserData',point);
end
if valueZoomOut
    set(zoomOutButton,'UserData',point);
end;

switch selectionType
    case 'open'
         windowData.tabs.mouse.mouseAction='none';
         set(figHandle,'UserData',windowData);
        if(valueZoomIn)
            zoomAxes(axesH,point,'in');
        elseif (valueZoomOut)
            zoomAxes(axesH,point,'out');
        else

            zoomAxes(axesH2,point,'display');
        end
    case 'extend'
          zoomAxes(axesH,point,'in');
    case 'alt'
          zoomAxes(axesH,point,'out');
        
    case 'normal'
         if(valueZoomIn)
            zoomAxes(axesH,point,'in');
         elseif (valueZoomOut)
            zoomAxes(axesH,point,'out');
         end
         if ~((valueZoomIn)|(valueZoomOut))
         windowData.tabs.mouse.mouseAction='grab';
         rootXY=get(0,'PointerLocation');
         windowData.tabs.mouse.rootX=rootXY(1);
         windowData.tabs.mouse.rootY=rootXY(2);
         windowData.tabs.mouse.actionAxesX=point(1);
         windowData.tabs.mouse.actionAxesY=point(2);
         windowData.tabs.mouse.actionAxesH=axesH;
         windowData.tabs.mouse.otherAxesH=axesH2;
         set(figHandle,'UserData',windowData);
         end
        
end



%**************************************************************************
%zoomAxes
%**************************************************************************

function zoomAxes(axesH,point,opt)

axesData=get(axesH,'UserData');



switch opt
    
    case 'in'
         ratio = (point(1,1)-axesData.time)/(axesData.timebase*axesData.right);
         axesData.timebase = bump (axesData.timebase, axesData.tbase_list, -1);
         axesData.time= point(1,1)-ratio*(axesData.timebase*axesData.right);
         axesData.time=max(0,axesData.time);
    case 'out'
          timebaseOld=axesData.timebase;
          timeOld=axesData.time;
          ratio = (point(1,1)-axesData.time)/(axesData.timebase*axesData.right);
          axesData.timebase = bump (axesData.timebase, axesData.tbase_list, +1);
          axesData.time= point(1,1)-ratio*(axesData.timebase*axesData.right);
          axesData.time=min(axesData.time, axesData.timeLength-axesData.right*axesData.timebase);
          axesData.time=max(0,axesData.time);
          if(axesData.time+axesData.right*axesData.timebase>axesData.timeLength)
               axesData.timebase=timebaseOld;
               axesData.time=timeOld;
           end
          
    case 'display'
          axesData.time= point(1,1)-axesData.timebase*axesData.time_step;
          axesData.time=min(axesData.time, axesData.timeLength-axesData.right*axesData.timebase);
          axesData.time=max(0,axesData.time);
end

redrawAxes(axesH,axesData);
%**************************************************************************
%zoomButton
%**************************************************************************
function zoomButton

upColor=[0.878, 0.875 ,0.89];
downColor=[0.8,0.8,0.8];
figHandle=gcf;
windowData=get(figHandle,'UserData');
guiData=windowData.guiData;
zoomInButton=findobj(figHandle,'tag','zoominIcon');
zoomOutButton=findobj(figHandle,'tag','zoomoutIcon');



currentButton=get(gcbo,'tag');
if(strcmp(currentButton,'zoominIcon'))
    set(zoomOutButton,'Value',0,'UserData',[],'BackgroundColor',upColor);
    cursor=guiData.gui.pointer.in;
else
    set(zoomInButton,'Value',0,'UserData',[],'BackgroundColor',upColor);
    cursor=guiData.gui.pointer.out;
end



value=get(gcbo,'Value');
if(value==1)
    set(gcbo,'BackgroundColor',downColor,'UserData',[]); 
    set(figHandle,'Pointer','custom','PointerShapeCData',cursor,'PointerShapeHotSpot',[8,8]);
else
    set(gcbo,'BackgroundColor',upColor,'UserData',[]);
    set(figHandle,'Pointer','arrow');
    
end
%**************************************************************************
%scrollToError
%**************************************************************************
function scrollToError(axesH,opt,buttonH)

resetZoomButtons;

figHandle=gcf;
windowData=get(figHandle,'UserData');
verData=windowData.verData;
tabData=get(windowData.tabs.currtab,'UserData');
set(tabData.tabLayout.tabObjects(1:12),'Enable','inactive');
set(buttonH,'Enable','on');
axesData=get(axesH,'UserData');
value=get(buttonH,'value');

if(value==1)
    set(buttonH,'callback','');
else
    set(buttonH,'callback','eafscreen(''eafbutton'');');
end

switch opt
    case '>>'
        errIndex=find(axesData.a2Errors >(axesData.time+((axesData.timebase*axesData.right)/2)));
        if(~isempty(errIndex))
            eIndex=errIndex(1);
		if(axesData.a2Errors(eIndex)-(axesData.time+((axesData.timebase*axesData.right)/2))<1/100000)
			errIndex=find(axesData.a2Errors > axesData.a2Errors(eIndex));
			if(~isempty(errIndex))
               eIndex=errIndex(1);
			end
		end
			
        end;
       
    case '<<'
        errIndex=find(axesData.a2Errors<(axesData.time+((axesData.timebase*axesData.right)/2)));
        if(~isempty(errIndex))
            eIndex=errIndex(end);
        end;
end;
if(~isempty(errIndex))
    if(abs(axesData.a2Errors(eIndex)-axesData.time)>axesData.time_step*axesData.timebase)
        switch opt
             case '>>'
                 while (axesData.time+axesData.time_step*axesData.timebase+(axesData.timebase*axesData.right)/2)<axesData.a2Errors(eIndex)...
                         & (axesData.time+axesData.time_step*axesData.timebase+axesData.right*axesData.timebase < axesData.timeLength)...
                         & value
                        eafbutton('>',axesH);
                        axesData=get(axesH,'UserData');
                        pause(0.1);
                        value=get(buttonH,'value');
                 end;
        
             case '<<'
                  while ((axesData.time-axesData.time_step*axesData.timebase+(axesData.timebase*axesData.right)/2)>axesData.a2Errors(eIndex))&  value
                      
                       eafbutton('<',axesH);
                       axesData=get(axesH,'UserData');
                       pause(0.1);
                       value=get(buttonH,'value');
                 end;
        end
        
        
     
    end
      if(value==1)
       if(axesData.a2Errors(eIndex)+(axesData.right*axesData.timebase)/2>axesData.timeLength)
           axesData.time=axesData.timeLength-axesData.right*axesData.timebase;
       else
           axesData.time=axesData.a2Errors(eIndex)-(axesData.right*axesData.timebase)/2;
           axesData.time=max(0,axesData.time);
       end
       
       
      
      set(axesData.errorCursor.leftCursor,'xdata',[axesData.a2Errors(eIndex),axesData.a2Errors(eIndex)]);
      set(axesData.errorCursor.rightCursor,'xdata',[axesData.a2Errors(eIndex),axesData.a2Errors(eIndex)]);
      redrawAxes(axesH,axesData);
      end
      
      
      
      axesData=get(axesH,'UserData');
      
      
    
end;
set(buttonH,'value',0);
set(buttonH,'callback','eafscreen(''eafbutton'');');
set(tabData.tabLayout.tabObjects(1:12),'Enable','on');
for i=2:3:11
    set(tabData.tabLayout.tabObjects(i),'Enable',verData.scrollBtnEnable);
   
end
set(axesH,'UserData',axesData);  



%**************************************************************************
%resetZoomButtons
%**************************************************************************
function resetZoomButtons
upColor=[0.878, 0.875 ,0.89];
downColor=[0.8,0.8,0.8];
figHandle=gcf;
zoomInButton=findobj(figHandle,'tag','zoominIcon');
zoomOutButton=findobj(figHandle,'tag','zoomoutIcon');
set(zoomInButton,'Value',0,'UserData',[],'BackgroundColor',upColor);
set(zoomOutButton,'Value',0,'UserData',[],'BackgroundColor',upColor);
set(figHandle,'pointer','arrow');
%****************************************
% adjustAxes(axesH)
% axesH- axes handle
% the function adjusts the axes up or down a pix
%****************************************
function adjustAxes(axesH)
%check for the Matlab version
%in order to align the axeses and the buttons
v = version;
switch v(1)
    case {'6', '7'}
        axes_correction  = [0,1,-1,-1];
    otherwise
        axes_correction  = [0,0,0,0];
end;

pos=get(axesH,'pos');
%adjust the axes
set(axesH,'pos',pos+axes_correction);


%**************************************************************************
%ETIME
%**************************************************************************
function t = etime(t1,t0)
%ETIME  Elapsed time.
%   ETIME(T1,T0) returns the time in seconds that has elapsed between
%   vectors T1 and T0.  The two vectors must be six elements long, in
%   the format returned by CLOCK:
%
%       T = [Year Month Day Hour Minute Second]
%
%   Time differences over many orders of magnitude are computed accurately.
%   The result can be thousands of seconds if T1 and T0 differ in their
%   first five components, or small fractions of seconds if the first five
%   components are equal.
%
%     t0 = clock;
%     operation
%     etime(clock,t0)
%
%   See also TIC, TOC, CLOCK, CPUTIME, DATENUM.

%   Copyright 1984-2002 The MathWorks, Inc. 
%   $Revision: 5.9.4.1 $  $Date: 2002/09/30 12:01:19 $

% Compute time difference accurately to preserve fractions of seconds.

t = 86400*(datenummx(t1(:,1:3)) - datenummx(t0(:,1:3))) + ...
    (t1(:,4:6) - t0(:,4:6))*[3600; 60; 1];

function openMultipleFiles(opt)

persistent fileDirectory


if(nargin==0)
     opt='create';
end

figHandle=gcbf;
switch opt
    case 'create'
         createOMFDialog('create');
    case 'add a field'
         createOMFDialog('add a field');
    case 'browse'  
          fieldH=get(gco,'UserData');
          
          %remeber what is the current directory
          curDir=cd;
          
          % check if the persistent variable is empty
          % if it is empty there is no history of browse directory
          if(isstr(fileDirectory))
              if(isdir(fileDirectory))
                  cd(fileDirectory);
              end
          end
          
          %get the file
          v = version;
          if v(1)>='6';
              [fileName, path2File] = uigetfile ('*.eaf;*.ann', 'Choose  annotation.');
          else
              [fileName, path2File] = uigetfile ('*', 'Choose  annotation.');
          end;
          fileDirectory=path2File;
          fileStr= fullfile(path2File,fileName);
          
          %set the coresponding field with the path of the file
          set(fieldH,'string',fileStr);
          
          % set back the current directory
          cd(curDir);
    case 'open'
         dialogHanlde=gcbf;
         fileFields=get(dialogHanlde,'UserData');
         figHandle=fileFields.figHandle;
         
        
         for i=1:fileFields.numFields
         file1= get(fileFields.fieldsH{i},'String');
         if(i<3)
             selected=i;
         else
             selected=0;
         end
         openFile(file1,figHandle,2,selected);
         end;
         
         delete(dialogHanlde);
         
         
          
    case 'cancel'
         %get the handle of the dialog
         dialogH=get(gco,'UserData');
         % delete the dialog
         delete(dialogH);
         
         
          
end;











function createOMFDialog(opt,numberFields)

if nargin==0
    opt='create';
    numberFields=2;
elseif nargin==1
     numberFields=2;
end

file{1}=' ';
 
%Margins
left_margin= 10;
top_margin= 5;


%Browse and Cancel Button
button_width=50;
button_height=25;

%Labels width
labels_width=35;
labels_height=button_height;


switch opt
    case 'create'
        figHandle=gcf;
        %fileFields structure contains
        %the current number of file fields
        %which by default is 2
        %the maximum number of file fields
        %and a cellular array of fields handles
        fileFields=struct('numFields',numberFields,...
            'maxFields',20,...
            'fieldsH',' ',...
            'figHandle',figHandle);
        %the dialog parameters in pixels.
        dialog_width=350;
        dialog_height=100;
        
        % get the Screen Size
        units=get(0,'Units');
        if(~strcmp(units,'pixels'))
            set(0,'Pixels');
        end;
        screenSize=get(0,'ScreenSize');
        set(0,'Units',units);
        
        dialog_x=((screenSize(3)-dialog_width)/2);
        dialog_y=((screenSize(4)-dialog_height)/2);


        %create the dialog figure
        %and save the current fileFields structure in the
        %dialog UserData
        dialogH = figure ( ...
            'Name','Open Multiple Files',...
            'NumberTitle','off',...
            'integerhandle', 'off', ...
            'menubar', 'none', ...
            'tag','OMFDialog', ...
            'units', 'pixels', ...
            'pos',[dialog_x,dialog_y,dialog_width,dialog_height],...
            'resize','off',...
            'UserData',fileFields,...
            'defaultuicontrolunits', 'pixels');
        
        

    case 'add a field'
         dialogH=get(gco,'UserData');
    
         fileFields=get(dialogH,'UserData');
         
         
         % get the Screen Size
        units=get(0,'Units');
        if(~strcmp(units,'pixels'))
            set(0,'Pixels');
        end;
        screenSize=get(0,'ScreenSize');
        set(0,'Units',units);
        
         pos=get(dialogH,'pos');
         set(dialogH,'pos',[pos(1),pos(2)-17.5,pos(3),pos(4)+30]);
         %get the strings form the current fields
         for i=1:fileFields.numFields
             file{i}=get(fileFields.fieldsH{i},'String');     
         end
         dialogChildrenH=get(dialogH,'children');
         %delete all the children in the dialog
         delete(dialogChildrenH);
         
         
         fileFields.numFields=fileFields.numFields+1;

end

pos=get(dialogH,'pos');
%the dialog parameters in pixels.
dialog_width=pos(3);
dialog_height=pos(4);
       






%text field width and height
field_width=dialog_width-2*left_margin-labels_width-button_width;
field_height=button_height;

%current y position over the dialog in pixels cordinates
positionY=dialog_height;

for i=1:fileFields.numFields

    positionY=positionY-top_margin-field_height;

    %---Label-----
    label_pos=[left_margin,positionY, labels_width, labels_height];
    uicontrol ( 'style','text','pos',label_pos, 'string',['File ',num2str(i),':'],'BackGroundColor',[0.8,0.8,0.8]);

    %----Field----
    field_pos=[left_margin+labels_width, positionY, field_width, field_height];
    if(i>length(file))
        fileStr=' ';
    else
        fileStr=file{i};
    end;
    fieldsH{i}=uicontrol ('style','edit','tag',['File',num2str(i)],'pos',field_pos,'String',fileStr,'BackGroundColor',[1,1,1],'HorizontalAlignment','left');

    %---Browse Button---
    button_pos=[left_margin+labels_width+field_width, positionY, button_width, button_height];
    uicontrol('style','push','tag','browse','pos',button_pos,'string','Browse','UserData',fieldsH{i},'callback','eafscreen(''openMultipleFiles'',''browse'');');
   

end;

fileFields.fieldsH=fieldsH;

set(dialogH,'UserData',fileFields);

positionY=positionY-top_margin-field_height;

%----Open Button-----
button_pos=[left_margin, positionY,(labels_width+field_width)/2 , button_height];
uicontrol(...
    'style','push',...
    'tag','Open',...
    'pos',button_pos,...
    'string','Open',...
    'callback','eafscreen(''openMultipleFiles'',''open'');');

%--- Add File Button----
button_pos=[left_margin+(labels_width+field_width)/2, positionY,(labels_width+field_width)/2 , button_height];
buttonH=uicontrol(...
    'style','push',...
    'tag','Another File',...
    'pos',button_pos,...
    'string','Another File',...
    'UserData',dialogH,...
    'callback','eafscreen(''openMultipleFiles'',''add a field'');');

% if the user has reached the maximum number of fields disable the button
if (fileFields.numFields >= fileFields.maxFields)
    set(buttonH,'enable','off');
end;

%---Cancel Button-----
button_pos=[left_margin+(labels_width+field_width), positionY,button_width , button_height];
uicontrol(...
    'style','push',...
    'tag','Cancel',...
    'pos',button_pos,...
    'string','Cancel',...
    'UserData',dialogH,...
    'callback','eafscreen(''openMultipleFiles'',''cancel'');');

function  setLimitsAndPlotScale(axesH,axesData,ydirection,otherAxes,otherAxesData)

  xlim=[otherAxesData.time,otherAxesData.time+otherAxesData.right*otherAxesData.timebase];
  x=[axesData.time,axesData.time+axesData.right*axesData.timebase];
  
  
  set(axesH,'Xlim',x,'Ylim',[0,axesData.sensitivity],'ydir',ydirection);
  set(axesH,'units','pixels');
  
  
  
  leftCursor=line('parent',axesH,'xdata',[0,0],'ydata',[0,0]);
  rightCursor=line('parent',axesH,'xdata',[0,0],'ydata',[0,0]);

  cursor= struct ('leftCursor',leftCursor,...
                 'rightCursor',rightCursor);
             
  otherAxesData.cursor=cursor;
  
  set(otherAxes,'UserData',otherAxesData);
  
  
  axesData.grat1   = graticule(axesH);
  axesData.grat2   = graticule(axesH);
  axesData.gratnum = text (zeros(12,1), zeros(12,1), ' ', 'col', [0.1961 0.5882 0.3922],'parent',axesH,'Clipping','on');
  set(axesH,'UserData',axesData);
  set(otherAxes,'UserData',otherAxesData);
  
  
  
  
  switch ydirection
      case 'reverse'
           axesData=get(axesH,'UserData');
           plottscale (axesH,axesData.grat1, axesData, 0, -1);
           plottscale (axesH,axesData.grat2, axesData, axesData.sensitivity, +1, 'above', axesData.gratnum); 
           set(axesH,'ButtonDownFcn','eafscreen(''mousePressed'',''firing'');');
           h=get(axesH,'children');
           set(h,'ButtonDownFcn','eafscreen(''mousePressed'',''firing'');');
           set(otherAxesData.cursor.leftCursor,'xdata',[xlim(1),xlim(1)],'ydata',[axesData.sens_list(end),0],'color',[0.1961 0.5882 0.3922]);
           set(otherAxesData.cursor.rightCursor,'xdata',[xlim(2),xlim(2)],'ydata',[axesData.sens_list(end),0],'color',[0.1961 0.5882 0.3922]);
      case 'normal'
            axesData=get(axesH,'UserData');
            axesData.rText=[];
            axesData.rTextPos=[];
            axesData.bText=[];
            axesData.bTextPos=[];

            set(axesH,'UserData',axesData);    
            axesData=get(axesH,'UserData');  
            cLine{1}=line(...
                'tag','l1',...
                'parent',axesH,...
                'xdata',[0,0],...
                'ydata',[0,0], ...
                'Color',[0.8,0.8,1],...
                'LineWidth', 5, ...
                'ButtonDownFcn',...
                'eafscreen(''mousePressed'',''signal'');');
            
            cLine{4}=line(...
                'tag','l1',...
                'parent',axesH,...
                'xdata',[0,0],...
                'ydata',[0,0],...
                'Color',[1,0.5,0.5],...
                'LineWidth', 5,...
                'ButtonDownFcn',...
                'eafscreen(''mousePressed'',''signal'');');
            
            
            cLine{2}=line(...
                'tag','l1',...
                'parent',axesH,...
                'xdata',[0,0],...
                'ydata',[0,0],...
                'Color',[1,1,1],...
                'LineWidth', 5, ...
                'ButtonDownFcn','eafscreen(''mousePressed'',''signal'');');
            
            cLine{3}=line(...
                'tag','l1',...
                'parent',axesH,...
                'xdata',[0,0],...
                'ydata',[0,0],...
                'Color',[1,1,1],...
                'LineWidth', 5,...
                'ButtonDownFcn','eafscreen(''mousePressed'',''signal'');');
            
            
            cLine{5}=line(...
                'tag','l1',...
                'parent',axesH,...
                'xdata',[0,0],...
                'ydata',[0,0],...
                'Color',[0,0,1],...
                'Marker','square',...
                'LineStyle','none',...
                'MarkerEdgeColor',[1 1 1],...
                'MarkerFaceColor',[0,0,1],...
                'ButtonDownFcn','eafscreen(''mousePressed'',''signal'');');
            
            
            cLine{6}=line(...
                'tag','l1',...
                'parent',axesH,...
                'xdata',[0,0],...
                'ydata',[0,0],...
                'Color',[1,0,0],...
                'Marker','square',...
                'LineStyle','none',...
                'MarkerEdgeColor',[1 1 1],...
                'MarkerFaceColor',[1,0,0],...
                'ButtonDownFcn','eafscreen(''mousePressed'',''signal'');');
            
            axesData.cLine=cLine;
            
            if(axesData.selectedFiles==2)
            plotLine(axesH,axesData.a1,axesData.a2,axesData.sp,axesData.rText,axesData.rTextPos,axesData.bText,axesData.bTextPos,axesData.cLine,[1,0,1],axesData.selectedFiles);
            elseif(axesData.selectedFiles==1)
                y=[];
    
                y(1:length(axesData.a2.time))=0.35;
                set(axesData.cLine{6},'xdata',axesData.a2.time,'ydata',y);
            elseif(axesData.selectedFiles==0)
                y=[];
    
                y(1:length(axesData.a1.time))=0.8;
                set(axesData.cLine{5},'xdata',axesData.a1.time,'ydata',y);
               
                
            end
            plotText4(axesH,axesData.a1,axesData.a2,axesData.rText,axesData.rTextPos,axesData.bText,axesData.bTextPos,axesData.cLine,axesData.selectedFiles);
           
            axesData=get(axesH,'UserData');
            leftCursor=line('parent',axesH,'xdata',[0,0],'ydata',[0,0]);
            rightCursor=line('parent',axesH,'xdata',[0,0],'ydata',[0,0]);

            cursor= struct ('leftCursor',leftCursor,...
                            'rightCursor',rightCursor);
            axesData.errorCursor=cursor;
            if(length(axesData.a2Errors)< 3)
            set(axesData.errorCursor.leftCursor,'xdata',[0,0],'ydata',[0,axesData.sensitivity],'color',[1,0,0]);
            set(axesData.errorCursor.rightCursor,'xdata',[0,0],'ydata',[0,axesData.sensitivity],'color',[1,0,0]);
            else
               set(axesData.errorCursor.leftCursor,'xdata',[axesData.a2Errors(2),axesData.a2Errors(2)],'ydata',[0,axesData.sensitivity],'color',[1,0,0]);
               set(axesData.errorCursor.rightCursor,'xdata',[axesData.a2Errors(2),axesData.a2Errors(2)],'ydata',[0,axesData.sensitivity],'color',[1,0,0]);
            end
            plottscale (axesH,axesData.grat1, axesData, axesData.sensitivity , -1);
            plottscale (axesH,axesData.grat2, axesData,0, +1, 'above', axesData.gratnum); 
            set(axesH,'ButtonDownFcn','eafscreen(''mousePressed'',''signal'');');
            h=get(axesH,'children');
            set(h,'ButtonDownFcn','eafscreen(''mousePressed'',''signal'');');
  end
  
 
  set(axesH,'UserData',axesData);
  
  
  function h = graticule(p)
	
	h(1) = line (0, 0, 'color', [0.1961 0.5882 0.3922],'parent',p);
	h(2) = line (0, 0, 'color',[1 1 1],'parent',p);
	h(3) = line (0, 0, 'color', [0.1961 0.5882 0.3922], 'linestyle', 'none', 'marker', '.', 'markersize', 1,'parent',p);
    
 function plottscale (curr_axes,grat_hndl, panel, y0, direction, text_location, text_hndl,xlim,ylim)
% Plots the time scales for emgplot.

% Copyright (c) 2006. Kevin C. McGill and others.
% Part of EMGlab version 0.9.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.stanford.edu

	
	if ~isstruct(panel); return; end;
    if(nargin < 9)
	ylim = get (curr_axes, 'ylim');
	xlim = get (curr_axes, 'xlim');
    end
	if nargin < 6; text_location = 'none'; end;
    
	%curr_axes = get (grat_hndl(1), 'parent');
	font_size = 9;
	large_tick_height = 8;
	middle_tick_height = 5;
	small_tick_height = 3;
	
		
	right_side_up = strcmp (get(curr_axes,'ydir'), 'normal');
	pos = get (curr_axes, 'position');
    
	units_per_pixel = (ylim(2) - ylim(1)) / pos(4);
	if ~right_side_up;
		units_per_pixel = -units_per_pixel;
	end;
	
	tbase_list = [.001, .002, .005, .01, .02, .05, .1, .2, .5, 1];
	ntick_list = [   5,    5,    2,   5,   5,   2,  5,  5,  2, 5];
	prec_list =	 [   3,    3,    3,   2,   2,   2,  1,  1,  1, 0];

	itb = find (tbase_list == panel.timebase);
	nticks = ntick_list(itb);
	precision = prec_list(itb);
	
	t0 = xlim(1);
	t1 = xlim(2);
	
	division = panel.timebase;
	T0 = ceil(t0/panel.timebase)*panel.timebase;
	T1 = floor(t1/panel.timebase)*panel.timebase;

	t = [T0-panel.timebase: panel.timebase/10: T1+panel.timebase];
	y = ones(size(t)) * direction * small_tick_height * units_per_pixel;
	y(1:nticks:end) = direction * middle_tick_height * units_per_pixel;
	y(1:10:end) = direction * large_tick_height * units_per_pixel;
	i = find (t>=t0 & t<=t1);
	tt = [t(i);t(i);t(i)];
	yy = y0 + [0*y(i);y(i);0*y(i)];
	if any(ylim==y0);
		col = [0.8627 0.8627 0.8627];
	else
		col = [1 1 1];
	end;
	tc = panel.time + [panel.left, panel.right]*panel.timebase;
	set (grat_hndl(1), 'xdata', tt(:), 'ydata', yy(:), 'vis', 'on');
	set (grat_hndl(2), 'xdata', tc, 'ydata', [y0, y0], 'col', col, 'vis', 'on');
	set (grat_hndl(3), 'xdata', t(i), 'ydata', y0*ones(size(i)), ...
		'linestyle', 'none', 'marker', '.', 'vis', 'on');

	if strcmp (text_location, 'none')
	else
		T = [T0: panel.timebase: T1];
		x = (T-panel.time)/panel.timebase;
		p = sprintf('%i', precision);
		tick_height = large_tick_height * units_per_pixel;
		if strcmp (text_location, 'above');
			y = y0 + max(direction,0)*tick_height + 2*units_per_pixel;
			v_align = 'base';
			h_align = 'cen';
		elseif strcmp (text_location, 'below');
			y = y0 + min(0,direction)*tick_height - 2*units_per_pixel;
			if ~right_side_up;
				y = y - large_tick_height * units_per_pixel;
			end;
			v_align = 'top';
			h_align = 'cen';
		else
			y = y0 + direction * tick_height/2;
			v_align = 'base';
			h_align = 'left';
			T = T + 0.05*panel.timebase;
		end;
		n = length(T);
		for i=1:length(T);
			label{i} = sprintf(['%.', p, 'f'], T(i));
		end;
		n = length(T);
		for i=1:n;
			set (text_hndl(i), 'pos', [T(i), y], 'str', label{i}, ...
			'horiz', h_align, 'vert', v_align, 'vis', 'on','Clipping','on');
		end;
		set (text_hndl(n+1:end), 'vis', 'off');
	end;
	
	
	
	
function plotLine(axesH,a1,a2,sp,rText,rTextPos,bText,bTextPos,cLine,tcolor,selectedFiles)


a2Errors(1)=0;
%get the axes Limits
xRange=get(axesH,'Xlim');

%set the first two points of the 
%lineData to the begining of the axes
lineData(1)=0;
lineData(2)=0;
lineData1(1)=0;
lineData1(2)=0;


Itrue = find( a1.time >xRange(1) ...
    &   a1.time< xRange(2));
Itest = find( a2.time >xRange(1) ...
    &   a2.time<xRange(2));
gcount=1;
bcount=1;
maxTime=max(a2.time(end),a1.time(end));
truePaired=zeros(1,length(a1.time));

for i=1:length(sp.TEasn)
    if(~isnan(sp.TEasn(i)))
        truePaired(sp.TEasn(i))=1;
    end
end

 for i=1:length(truePaired)
     if (truePaired(i)==0)
        a2Errors(end+1)=a1.time(i);
    end
end       
        
    
% k=sort(sp.TEasn);
% for i=1:length(a1.time)
%     if isempty(find(k==i))
%         a2Errors(end+1)=a1.time(i);
%     end
% end
        

for i=1:min(length(sp.TEasn),length(a2.time));

    % Set plotting color.
    Ctest = [.7,.7,.9];  % Default: Correct pairing.
    good=1;
    %tcolor(i,:)=[1,0,0];
    Ifind = find(a2.unit((i))==sp.MUidTE); % For elseif.
    if isnan(sp.TEasn((i)) )  % No assignment.
        Ctest = [0.5,1,1];
        %tcolor(i,:)
        a2Errors(end+1)=a2.time(i);
    elseif a1.unit( sp.TEasn((i)) ) ~= sp.MUmap(Ifind)
        Ctest = [1,0.5,0.5];
        a2Errors(end+1)=a2.time(i);
        good=0;
    end


    if ~isnan( sp.TEasn((i)) )

        X1 = a2.time((i));
        X2 = a1.time( sp.TEasn((i)) );
        if(good)

            if(mod(gcount,2)==1)
                lineData(end+1)=X1;
                lineData(end+1)=X2;
            else
                lineData(end+1)=X2;
                lineData(end+1)=X1;
            end;
            gcount=gcount+1;
        else
            if(mod(bcount,2)==1)
                lineData1(end+1)=X1;
                lineData1(end+1)=X2;
            else
                lineData1(end+1)=X2;
                lineData1(end+1)=X1;
            end;
            bcount=bcount+1 ;
        end;
        %cLine{i}= line('tag','l','parent',axesH,'xdata',[X1,X2],'ydata',[0.35 0.8], 'Color', Ctest, 'LineWidth', 5);

    end
end
a2Errors(end+1)=max(a1.time(end),a2.time(end));
yData(1)=0.35;

count=0;
for i=2:length(lineData)

    if(count>3)
        count=0;
    end

    if(count<2)
        yData(i)=0.35;
    else
        yData(i)=0.8;
    end

    count=count+1;


end

yData1(1)=0.35;
count=0;
for i=2:length(lineData1)

    if(count>3)
        count=0;
    end

    if(count<2)
        yData1(i)=0.35;
    else
        yData1(i)=0.8;
    end

    count=count+1;


end

if((isempty(cLine))|(cLine{1}==0)|(cLine{4}==0));
    cLine{1}=line(...
        'tag','l1',...
        'parent',axesH,...
        'xdata',lineData,...
        'ydata',yData,...
        'Color',[0.7,0.7,0.9],...
        'LineWidth', 5);
    cLine{4}=line(...
        'tag','l1',...
        'parent',axesH,...
        'xdata',lineData1,...
        'ydata',yData1,...
        'Color',[1,0.5,0.5],...
        'LineWidth', 5);
    cLine{2}=line(...
        'tag','l1',...
        'parent',axesH,...
        'xdata',[0,maxTime],...
        'ydata',[0.35,0.35],...
        'Color',[1,1,1],...
        'LineWidth', 5);
    
    cLine{3}=line(...
        'tag','l1',...
        'parent',axesH,...
        'xdata',[0,maxTime],...
        'ydata',[0.8,0.8],...
        'Color',[1,1,1],...
        'LineWidth', 5);

else
    if(selectedFiles==0)
    y=[];
    y(1:length(a1.time))=0.8;
    set(cLine{5},'xdata',a1.time,'ydata',y);
    end
    
    if(selectedFiles==1)
    y=[];
    y(1:length(a1.time))=0.35;
    set(cLine{6},'xdata',a1.time,'ydata',y);
    end
    
    
    
    if(selectedFiles==2)
    set(cLine{1},'xdata',lineData,'ydata',yData);
    set(cLine{4},'xdata',lineData1,'ydata',yData1);
    set(cLine{2},'xdata',[0,maxTime],'ydata',[0.35,0.35]);
    set(cLine{3},'xdata',[0,maxTime],'ydata',[0.8,0.8]);
    y=[];
    y(1:length(a1.time))=0.8;
    set(cLine{5},'xdata',a1.time,'ydata',y);
    y=[];
    y(1:length(a2.time))=0.35;
    set(cLine{6},'xdata',a2.time,'ydata',y);
    end
end

axesData=get(axesH,'UserData');
axesData.cLine=cLine;
a2Errors=sort(a2Errors);
axesData.a2Errors=a2Errors;
set(axesH,'UserData',axesData);

function plotText4(axesH,a1,a2,rText,rTextPos,bText,bTextPos,cLine,selectedFiles)

nRText=[];
nRTextPos=[];
nBText=[];
nBTextPos=[];

%get the axes Limits
xRange=get(axesH,'Xlim');




Itrue = find( a1.time >xRange(1) ...
    &   a1.time< xRange(2));
Itest = find( a2.time >xRange(1) ...
    &   a2.time<xRange(2));

if(xRange(2)-xRange(1)<4)
set(cLine{5},'vis','off');
set(cLine{6},'vis','off');
displayT=1;
if(~isempty(bText))
set(bText,'vis','on');
end
if(~isempty(rText))
set(rText,'vis','on');
end


if(selectedFiles==1) | (selectedFiles==2)
indexInRange= find(rTextPos>xRange(1) & rTextPos<xRange(2));
indexOutRange=find(rTextPos<xRange(1) | rTextPos>xRange(2));

objectsOutOfRange=[];

if(length(indexOutRange)>0)

    for i=1:length(indexOutRange)
        
        objectsOutOfRange(i)=rText(indexOutRange(i));
        %delete(rText(indexOutRange(i)));

    end
end


if(length(indexInRange)>0)
    rText=rText(indexInRange(1):indexInRange(end));
    rTextPos=rTextPos(indexInRange(1):indexInRange(end));
else
    rText=[];
    rTextPos=[];
end

firstIndex=[];
lastIndex=[];
if((~isempty(rTextPos))&(~isempty(Itest)) )
    firstIndex=find(a2.time(Itest(1):Itest(end))< rTextPos(1));
    lastIndex=find(a2.time(Itest(1):Itest(end))>rTextPos(end));
else
    lastIndex=1;
end;



nRText=rText;
nRTextPos=rTextPos;


if(~isempty(lastIndex))
   
    objectsOutOfRangePos=[];
    usedOutOfRangeObj=0;
    usedOutOfRangeObj=min(length(objectsOutOfRange),length(Itest)-lastIndex(1)+1);
   
    for i=1:usedOutOfRangeObj
        textI=sprintf('%d',a2.unit(Itest(i+lastIndex(1)-1)));
        set(objectsOutOfRange(i),'position',[a2.time(Itest(i+lastIndex(1)-1)),0.35],'String',textI,'vis','on');
        objectsOutOfRangePos(i)=a2.time(Itest(i+lastIndex(1)-1));
    end
    if(usedOutOfRangeObj>0)
    nRText=[nRText,objectsOutOfRange(1:usedOutOfRangeObj)];
    nRTextPos=[nRTextPos,objectsOutOfRangePos(1:usedOutOfRangeObj)];
    if(usedOutOfRangeObj<length(objectsOutOfRange))
        objectsOutOfRange=objectsOutOfRange((usedOutOfRangeObj+1):length(objectsOutOfRange));
    else
        objectsOutOfRange=[];
    end
    end
    tempRText=[];
    tempRTextPos=[];
    for i=(lastIndex(1)+usedOutOfRangeObj):length(Itest)

        textI=sprintf('%d',a2.unit(Itest(i)));
        tempRText(i-lastIndex(1)-usedOutOfRangeObj+1)=text('parent',axesH,'tag','l','position',[a2.time(Itest(i)),0.35],'String',textI,'color',[1,0,0],'HorizontalAlignment','center', 'ButtonDownFcn','eafscreen(''mousePressed'',''signal'');','vis','on' );
        tempRTextPos(i-lastIndex(1)-usedOutOfRangeObj+1)=a2.time(Itest(i));

    end;
    nRText=[nRText,tempRText];
    nRTextPos=[nRTextPos,tempRTextPos];
end;
if(~isempty(firstIndex))
    objectsOutOfRangePos=[];
    usedOutOfRangeObj=0;
    usedOutOfRangeObj=min(length(objectsOutOfRange),firstIndex(end));
    for i=1:usedOutOfRangeObj
        textI=sprintf('%d',a2.unit(Itest(i)));
        set(objectsOutOfRange(i),'position',[a2.time(Itest(i)),0.35],'String',textI,'vis','on');
        objectsOutOfRangePos(i)=a2.time(Itest(i));
    end
    
    
    tempRText=[];
    tempRTextPos=[];
    for i=(usedOutOfRangeObj+1):firstIndex(end)

        textI=sprintf('%d',a2.unit(Itest(i)));

        tempRText(i-usedOutOfRangeObj)=text('parent',axesH,'tag','l','position',[a2.time(Itest(i)),0.35],'String',textI,'color',[1,0,0],'HorizontalAlignment','center', 'ButtonDownFcn','eafscreen(''mousePressed'',''signal'');','vis','on'  );
        tempRTextPos(i-usedOutOfRangeObj)=a2.time(Itest(i));
    end;
    nRText=[tempRText,nRText];
    nRTextPos=[tempRTextPos,nRTextPos];
    
    if(usedOutOfRangeObj>0)
    nRText=[objectsOutOfRange(1:usedOutOfRangeObj),nRText];
    nRTextPos=[objectsOutOfRangePos(1:usedOutOfRangeObj),nRTextPos];
    if(usedOutOfRangeObj<length(objectsOutOfRange))
        objectsOutOfRange=objectsOutOfRange((usedOutOfRangeObj+1):length(objectsOutOfRange));
    else
        objectsOutOfRange=[];
    end
    end
end

 for i=1:length(objectsOutOfRange)
     delete(objectsOutOfRange(i));
 end
end

if(selectedFiles==0) | (selectedFiles==2)
indexInRange= find(bTextPos>xRange(1) & bTextPos<xRange(2));
indexOutRange=find(bTextPos<xRange(1) | bTextPos>xRange(2));

objectsOutOfRange=[];

if(length(indexOutRange)>0)

    for i=1:length(indexOutRange)
        objectsOutOfRange(i)=bText(indexOutRange(i));
        %delete(bText(indexOutRange(i)));
    end
end


if(length(indexInRange)>0)
    bText=bText(indexInRange(1):indexInRange(end));
    bTextPos=bTextPos(indexInRange(1):indexInRange(end));
else
    bText=[];
    bTextPos=[];
end

firstIndex=[];
lastIndex=[];
if((~isempty(bTextPos))&(~isempty(Itrue)))
    firstIndex=find(a1.time(Itrue(1):Itrue(end))< bTextPos(1));
    lastIndex=find(a1.time(Itrue(1):Itrue(end))>bTextPos(end));
else
    lastIndex=1;
end;



nBText=bText;
nBTextPos=bTextPos;
if(~isempty(lastIndex))
    objectsOutOfRangePos=[];
    usedOutOfRangeObj=0;
    usedOutOfRangeObj=min(length(objectsOutOfRange),length(Itrue)-lastIndex(1)+1);
   
    for i=1:usedOutOfRangeObj
        textI=sprintf('%d',a1.unit(Itrue(i+lastIndex(1)-1)));
        set(objectsOutOfRange(i),'position',[a1.time(Itrue(i+lastIndex(1)-1)),0.8],'String',textI,'vis','on');
        objectsOutOfRangePos(i)=a1.time(Itrue(i+lastIndex(1)-1));
    end
    if(usedOutOfRangeObj>0)
    nBText=[nBText,objectsOutOfRange(1:usedOutOfRangeObj)];
    nBTextPos=[nBTextPos,objectsOutOfRangePos(1:usedOutOfRangeObj)];
    if(usedOutOfRangeObj<length(objectsOutOfRange))
        objectsOutOfRange=objectsOutOfRange((usedOutOfRangeObj+1):length(objectsOutOfRange));
    else
        objectsOutOfRange=[];
    end
    end
    tempBText=[];
    tempBTextPos=[];
    for i=(lastIndex(1)+usedOutOfRangeObj):length(Itrue)

        textI=sprintf('%d',a1.unit(Itrue(i)));

        tempBText(i-lastIndex(1)-usedOutOfRangeObj+1)=text('parent',axesH,'tag','l','position',[a1.time(Itrue(i)),0.8],'String',textI,'color',[0,0,1],'HorizontalAlignment','center', 'ButtonDownFcn','eafscreen(''mousePressed'',''signal'');','vis','on'  );
        tempBTextPos(i-lastIndex(1)-usedOutOfRangeObj+1)=a1.time(Itrue(i));

    end;
    nBText=[nBText,tempBText];
    nBTextPos=[nBTextPos,tempBTextPos];
end;
if(~isempty(firstIndex))
    objectsOutOfRangePos=[];
    usedOutOfRangeObj=0;
    usedOutOfRangeObj=min(length(objectsOutOfRange),firstIndex(end));
    for i=1:usedOutOfRangeObj
        textI=sprintf('%d',a1.unit(Itrue(i)));
        set(objectsOutOfRange(i),'position',[a1.time(Itrue(i)),0.8],'String',textI,'vis','on');
        objectsOutOfRangePos(i)=a1.time(Itrue(i));
    end
    
    tempBText=[];
    tempBTextPos=[];
    for i=(usedOutOfRangeObj+1):firstIndex(end)

        textI=sprintf('%d',a1.unit(Itrue(i)));

        tempBText(i-usedOutOfRangeObj)=text('parent',axesH,'tag','l','position',[a1.time(Itrue(i)),0.8],'String',textI,'color',[0,0,1],'HorizontalAlignment','center', 'ButtonDownFcn','eafscreen(''mousePressed'',''signal'');','vis','on'  );
        tempBTextPos(i-usedOutOfRangeObj)=a1.time(Itrue(i));
    end;
    nBText=[tempBText,nBText];
    nBTextPos=[tempBTextPos,nBTextPos];
    
     if(usedOutOfRangeObj>0)
    nBText=[objectsOutOfRange(1:usedOutOfRangeObj),nBText];
    nBTextPos=[objectsOutOfRangePos(1:usedOutOfRangeObj),nBTextPos];
    if(usedOutOfRangeObj<length(objectsOutOfRange))
        objectsOutOfRange=objectsOutOfRange((usedOutOfRangeObj+1):length(objectsOutOfRange));
    else
        objectsOutOfRange=[];
    end
    end
end
 for i=1:length(objectsOutOfRange)
     delete(objectsOutOfRange(i));
 end
end
else
   set(cLine{5},'vis','on');
   set(cLine{6},'vis','on');
    nRText=rText;
    nRTextPos=rTextPos;
    nBText=bText;
    nBTextPos=bTextPos;
    set(rText,'vis','off');
    set(bText,'vis','off');
    displayT=0;
end

% h=findobj(axesH,'color',[1,0,0]);
% length(h)
axesData=get(axesH,'UserData');
axesData.cLine=cLine;
axesData.displayT=displayT;
axesData.rText=nRText;
axesData.rTextPos=nRTextPos;
axesData.bText=nBText;
axesData.bTextPos=nBTextPos;
set(axesH,'UserData',axesData);

function underline
	set(gcbo,'Units','data');
	pos=get(gcbo,'pos');
	
	axesH=get(gcbo,'parent');
	h=findobj(axesH,'tag','Marker');
	ydata=get(h,'ydata');
	if(floor(ydata(1))==floor(pos(2)))
		maxT=0;
		y=0;
	else
    axesData=get(axesH,'UserData');
	ann1=axesData.a1;
	ann2=axesData.a2;
	maxT=max(ann1.time(end),ann2.time(end));
	y=floor(pos(2));
	end
	set(h,'xdata',[0,maxT],'ydata',[y,y]);
    pos(2)=get(gcbo,'UserData');
	%set(gcbo,'pos',[pos(1),floor(pos(2))]);
    set(gcbo,'pos',pos);
	set(gcbo,'Units','normalized');
	pos=get(gcbo,'pos');
	set(gcbo,'pos',[round(pos(1)),pos(2)]);
	
function changeChan
	
	targetFile=gco;
	menuH=get(targetFile,'UicontextMenu');
	chanH=gcbo;
    chanStr=get(chanH,'label');
    fileStr=get(targetFile,'Tag');
    fileStr=[fileStr,' ',chanStr];
    set(targetFile,'String',fileStr);
	checked=get(gcbo,'Checked');
	if(~strcmp(checked,'on'))	
	h=findobj(menuH,'checked','on');
	set(h,'Checked','off');
	set(chanH,'checked','on');
	ann=get(chanH,'UserData');
	set(targetFile,'UserData',ann);
	figHandle=gcbf;
	windowData=get(figHandle,'UserData');
	tabs=windowData.tabs;
	tabData=get(tabs.currtab,'UserData');
	openFiles=tabData.openFiles;
	index=find(openFiles.buttonH==targetFile);
	if(~isempty(index))
	if(openFiles.selectedFiles(index)==1)|(openFiles.selectedFiles(index)==2)
   
    plotFiles(tabs.currtab);
	end
	end
	
    end
	
    
function eaf_plot (a1, a2, sp,axesH,axesData);
	m1 = 6;
	m2 = 4;
    vers = version;
    old_matlab = vers(1)=='5';
   
   %axesData=get(axesH,'UserData');
    set(axesH,'NextPlot','add');
    axesData.timeLength=max(a1.time(end),a2.time(end));
    axesData.a1=a1;
    axesData.a2=a2;
    set(axesH,'UserData',axesData);
	line ('parent',axesH,'xdata',0,'ydata',0);
	
	pos = get (axesH, 'pos');
    xlim = get (axesH, 'xlim');
	one_pixel = (xlim(2) - xlim(1)) / pos(3);
	
	
	for ii=1:length(sp.MUidTR);
		i = sp.MUidTR(ii);
		t1 = a1.time(find(a1.unit==i));
		ix = sp.MUidTE(find(sp.MUmap == i)); 
		if isempty(ix);
			cplot (t1, i, [0,0,1],axesH);
		else
			t2 = a2.time(find(a2.unit==ix));
            if length(t2)<2;
                nearest_t2 = ones(size(t1))*1000;
            elseif old_matlab;
                nearest_t2 = interp1 (t2, t2, t1, 'nearest');
            else;
                nearest_t2 = interp1 (t2, t2, t1, 'nearest', 'extrap');
            end;
            offset = t1 - nearest_t2;
            error = abs(offset - median(offset));
			k = find(error>.0005);
			cplot (t1(k), i, [0,0,1],axesH);
			k = find(error<=.0005);
			cplot (t1(k), i, [.7,.7,.9],axesH);
		end;
	end;

	p = length(sp.MUidTR);
     for ii=1:length(sp.MUidTE);
		i = sp.MUidTE(ii);
         ix = sp.MUmap(ii); 
         t2 = a2.time(find(a2.unit==i));
        if isnan(ix);
           p = p + 1;		   
          cplot (t2, p, [1,0,0],axesH);
        else
            irow = find(ix==sp.MUidTR);
            t1 = a1.time(find(a1.unit==ix));
            if length(t1)<2;
                nearest_t1 = ones(size(t2))*1000;
            elseif old_matlab;
                nearest_t1 = interp1 (t1, t1, t2, 'nearest');
            else
                nearest_t1 = interp1 (t1, t1, t2, 'nearest', 'extrap');
            end;
            offset = t2 - nearest_t1;
            med_offset = median(offset);
            error = offset - med_offset;
 			k = find(error >.0005 & error < .005);
           		cplot (max(t2(k), nearest_t1(k)+one_pixel), irow, [1,0,0],axesH);
			k = find(error > -.005 & error<-.0005);
				cplot (min(t2(k), nearest_t1(k)-one_pixel), irow, [1,0,0],axesH);
            k = find(abs(error)>.005);
	          	cplot (t2(k), irow, [1,0,0],axesH);
     	end;
	end;

	axis ([floor(min(a1.time)), ceil(max(a1.time)), 0, p+1]);
    set(axesH,'NextPlot','replace');
   
     
function cplot (t, i, c,axesH) 
   k{i}=t;
	o = i*ones(size(t));
	line('parent',axesH,'xdata',t,'ydata', o,'marker','o', 'markersize', 6, 'col', c,'lineStyle','none','Clipping','on');
	if max(c)==1;
		line('parent',axesH,'xdata',t,'ydata',o, 'marker','o', 'markersize', 5, 'col', .6+.4*c,'lineStyle','none','Clipping','on');
	end;
	
   
   


        
