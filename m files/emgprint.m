function emgprint
% EMGlab function that prints the screen.

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net

    global SCREEN
    
    print_margin = 0.25;
    
    printFigure = figure('Name','EMGlabPrint',...
        'Position',get(SCREEN.figure,'Position'),...
        'PaperOrientation','landscape',...
        'PaperUnits','inches',...
        'PaperPosition',[0.2 0.25 10.6 8.0],...
        'PaperPositionMode','manual',...
        'vis','off');
  
    paper_size = get (printFigure, 'papersize');
    print_width = max(paper_size) - 2*print_margin;
    print_height = min(paper_size) - 2*print_margin;
    
    set (printFigure, 'PaperPosition', ...
        [print_margin, print_margin, print_width, print_height]);
    
    h  = findobj (SCREEN.figure, 'type', 'axes');
    tags = get (h, 'tag');
	%exclude the map axes
    i1 = find (strcmp(tags, 'map'));
	%exclude the sprite axes
    i2 = find (strcmp(tags, 'sprite'));
	%exclude the tempcursor axes
	i3=find(strcmp(tags,'tempcursor'));
    h([i1,i2,i3]) = [];

    c = copyobj (h, printFigure);
    set (c, 'units', 'norm');

    p = get (SCREEN.figure, 'position');
    p = [0, 0, p(3), p(4)];
    fs = get (SCREEN.figure,'defaultuicontrolfontsize');

    a = axes ('units', 'pix', 'pos', p, 'vis', 'off', ...
        'xlim', [0, p(3)], 'ylim', [0, p(4)], ...
        'defaulttextFontsize', fs);

    h = findobj (printFigure, 'type', 'patch');
    set (h, 'facecolor', 'none');

    h = findobj (SCREEN.figure, 'style', 'popupmenu','vis','on');
    for i=1:length(h);
        s = get (h(i), 'string');
        v = get (h(i), 'value');
        p = get (h(i), 'pos');
        t = text (p(1), p(2), s(v,:), 'vert', 'base');
    end;

    h = findobj (SCREEN.figure, 'style', 'text','vis','on');
    for i=1:length(h);
        s = get(h(i), 'string');
        p = get(h(i), 'pos');
        t = text (p(1), p(2)+4, s, 'vert', 'base');
    end;

    set (a, 'units', 'norm');


    set (printFigure, 'units', 'in', 'pos', [0, 0, print_width, print_height]);

    printdlg (printFigure);
    delete (printFigure);
    return;
        
        
    ax  = findobj (SCREEN.figure, 'type', 'axes');
    pop = findobj (SCREEN.figure, 'style', 'popup');
    txt = findobj (SCREEN.figure, 'style', 'text');

    % copies all the axes that a currently on the screen
    % for printing
    copyobj (ax, printFigure);

    % position of the navigation panel
    %used to set how much the left margin to be for the printout text
    position = get (SCREEN.navigation.axes, 'pos');
    positionText = get (txt(2),'pos');
    position(2)=positionText(2);
    position(4)=positionText(4);

    strFil=get(pop(1),'String');
    i=get(pop(1),'Value');

    strChan=get(pop(2),'String');
    p=get(pop(2),'Value');

    defaultFontsize=get(SCREEN.figure,'defaultuicontrolfontsize');

    h = axes('units','pix','Position',position,'Visible','off');
    str(1) = {get(txt(2),'String')};
    str(2)={get(txt(1),'String')};
    text(1,.6,str(2),...
        'Fontsize',defaultFontsize,...
        'HorizontalAlignment','right' );
    text(.30,.6,str(1),...
        'Fontsize',defaultFontsize,...
        'HorizontalAlignment','left');
    text(0.15, 0.6,strFil(i,:),...
        'Fontsize',defaultFontsize,...
        'HorizontalAlignment','left');
    text(0.00, 0.6,strChan(p,:),...
        'Fontsize',defaultFontsize,...
        'HorizontalAlignment','left');


    %Show print dilogue box
    PRINTDLG(printFigure);
    %print -depsc2 proba;
    delete(printFigure);








