function emgscreenshot (panel)
% Copies a panel to a regular matlab figure.

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net
	
global SCREEN SETS DECOMP 

switch lower (panel);
    
    case 'signal panel';
        [f, h] = createNewFigure (SCREEN.signal.axes);
        copystuff (SCREEN.signal.aux, h);
        copystuff (SCREEN.signal.signal, h);
        copystuff (SCREEN.signal.resid, h);
        copystuff (findobj(SCREEN.signal.text, 'vis', 'on'), h);

    case 'template panel';
        [f, h] = createNewFigure (SCREEN.template.axes);
        copystuff (findobj(SCREEN.template.signal, 'vis', 'on'), h);
        copystuff (findobj(SCREEN.template.text, 'vis', 'on'), h);

    case 'firing panel';
        [f, h] = createNewFigure (SCREEN.firing.axes);
        copystuff (SCREEN.firing.aux, h);
        copystuff (findobj (SCREEN.firing.pattern, 'vis', 'on'), h);
        if (strcmp(SETS.firing.style,'toc'))
            ylabel ('unit');
            n = DECOMP.nunits;
            if n <= 20;
                ticks = [1:n];
            elseif n <= 40;
                ticks = [2:2:n];
            else
                ticks = [5:5:n];
            end;
            set (h, 'ytick', ticks);
        else
            ylabel ('firing rate (pps)');
        end

    case 'close-up panel';
        [f, h] = createNewFigure (SCREEN.closeup.axes);
        copystuff (SCREEN.closeup.signal,h);
        copystuff (SCREEN.closeup.resid,h);
        copystuff (SCREEN.closeup.recon,h);
        copystuff (findobj(SCREEN.closeup.temp, 'vis', 'on'), h);
        copystuff (findobj(SCREEN.closeup.text, 'vis', 'on'), h);

    case 'navigation panel';
        [f, h] = createNewFigure(SCREEN.navigation.axes);
        copystuff (SCREEN.navigation.aux, h);
        copystuff (SCREEN.navigation.signal, h);
        copystuff (SCREEN.navigation.firing, h);
        
    otherwise
        return;
    end;
 	
    set (f, 'vis', 'on');
    
       
function [hFigure, hAxes] = createNewFigure (targetAxes)
    global SCREEN EMG CURR

    hFigure = figure ('units','pix',...
    'position', get(SCREEN.figure,'position'),...
    'color', get(SCREEN.figure,'color'), ...
    'visible', 'off');

    h = findobj (SCREEN.figure, 'tag', 'emg file name');
    text_color = get (h,'ForeGroundColor');
    u = get (targetAxes, 'user');
    if isempty(u)
        u = [0,1,0,1];
    end;

    hAxes = axes ('Parent', hFigure, 'units', 'pix',...
        'position', get (targetAxes,'position'),...
        'color',    get (targetAxes,'color'),...
        'XColor',   text_color,...
        'YColor',   text_color,...
        'Ydir',     get (targetAxes,'Ydir'),...
        'XLim',     [u(1), u(2)],...
        'YLim',     [min(u(3:4)), max(u(3:4))],...
        'box',      'on');
    if u(3)>u(4);
        set (hAxes, 'ydir', 'reverse');
    end;

    marginBottom = 40;
    marginTop = 40;
    marginLeft = 60;
    marginRight = 40;


    position = get (hAxes, 'pos');
    position(1) = marginLeft;
    position(2) = 0;
    position(2)  = marginBottom;
    set (hAxes, 'pos', position, 'ticklength', [4/max(position(3:4)), .025]);

    fposition = get (hFigure, 'pos');
    %adjustement from the down left corner of the screen;
    adjustment(1) = fposition(1);
    adjustment(2) = fposition(2);
    fposition(2) = fposition(2)+fposition(4)-position(4)-marginBottom-marginTop;
    fposition(4) = position(4)+marginTop+marginBottom;
    fposition(3) = position(3)+marginRight+marginLeft;


    h = findobj (SCREEN.figure, 'tag', 'channel');
    s = get (h, 'String');
    i = get(h,'Value');
    chan = s(i,:); 
    while chan(end)==' ';
        chan(end)=[];
    end;

    h = findobj (SCREEN.figure, 'tag', 'filter');
    s = get (h, 'String');
    i = get (h, 'Value');
    filt = s(i,:);
    while filt(end)==' ';
        filt(end) = [];
    end;
    if ~strcmp (filt, 'unfiltered');
        filt = ['High-pass: ', filt];
    end;

    
    popupChanPosition = get (h, 'position');
    fposition(1) = popupChanPosition(1)+adjustment(1)+marginLeft;
    fposition(2) = popupChanPosition(2)+adjustment(2)-2*marginTop-fposition(4);
    set (hFigure, 'pos', fposition);


    if ~isempty(EMG.data);
        title ([get(SCREEN.info.filename, 'string'), ';   ', ...
            get(SCREEN.info.annotation(1), 'string'), ...
            get(SCREEN.info.annotation(2), 'string'), ...
            get(SCREEN.info.annotation(3), 'string'), ...
            ';   ', chan, ';   ', filt], ...
            'color', text_color, 'interpreter', 'none');
        xlabel ('time (s)');
        ylabel (['amplitude (', EMG.channel(CURR.chan).units, ')']);
    end;

    set (hFigure, 'units', 'normalize');
    set (hAxes, 'units', 'normalize');

    
function copystuff (handles, targetAxes)
    for i=1:length(handles);
        h = handles(i);
        h1 = copyobj (h, targetAxes);
        p = get(h, 'parent');
        xl = get(p, 'xlim');
        yl = get(p, 'ylim');
        u  = get(p, 'user');
        if isempty(u);
            u = [0,1,0,1];
        end;
        t  = get(h, 'type');
        switch t
            case 'line'
                set (h1, 'xdata', (get(h1,'xdata')-xl(1))/(xl(2)-xl(1))*(u(2)-u(1))+u(1));
                set (h1, 'ydata', (get(h1,'ydata')-yl(1))/(yl(2)-yl(1))*(u(4)-u(3))+u(3));
            case 'text'
                p = get(h1, 'pos');
                p(1) = (p(1)-xl(1))/(xl(2)-xl(1))*(u(2)-u(1))+u(1);
                p(2) = (p(2)-yl(1))/(yl(2)-yl(1))*(u(4)-u(3))+u(3);
                set (h1, 'pos', p);
        end;
    end;

