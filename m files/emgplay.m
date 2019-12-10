function emgplay (opt, interval)
% EMGlab function for the Play command

% Copyright (c) 2006-2009. Kevin C. McGill and others.
% Part of EMGlab version 1.0.
% This work is licensed under the Aladdin free public license.
% For copying permissions see license.txt.
% email: emglab@emglab.net


    global SETS SCREEN EMG CURR
    S = SETS.signal;

    if isempty(EMG.data); return; end;
    
    switch opt
  
        case 'start'    
            if ~isfield (SCREEN, 'play');
                SCREEN.play = struct ('running', 0, 'audio', 0, 'player', []);
            else
                if SCREEN.play.running;
                    emgplay ('stop');
                    return;
                end;
            end;
            if nargin==1; interval = 0.01; end;
              
            audio = emgsignal (S.time, S.time + EMG.buffer_length);
            audio = audio.sig / S.sensitivity (CURR.chan, CURR.band) * 5;
            audio(audio>1) = 1;
            audio(audio<-1) = -1;
            
            try
                SCREEN.play.player = audioplayer (audio, EMG.rate, 16);
                SCREEN.play.audio = 1;
            catch
                SCREEN.play.audio = 0;
            end;

            set (SCREEN.timer, 'Period', interval, 'executionmode', 'fixedspacing', ...
                'startdelay', interval, 'busymode', 'drop', ...
                'timerfcn', 'emgplay(''time'');');

            SCREEN.play.clock = clock;
            SCREEN.play.interval = interval;
            SCREEN.play.start = S.time;
            SCREEN.play.trace_duration = (S.right - S.left)*S.timebase;
            SCREEN.play.count = 0;
            SCREEN.play.lag = 0;
            SCREEN.play.running = 1;
            SCREEN.play.list = [0,0,0];

            kp ('setup');
            if SCREEN.play.audio
                play (SCREEN.play.player);
            end;
            while strcmp(get(SCREEN.play.player, 'running'), 'off');
            end;
            start (SCREEN.timer);
            
        case 'time'
            SCREEN.play.count = SCREEN.play.count+1;
            P = SCREEN.play;
            if P.audio;
                if strcmp(get(P.player, 'running'), 'off');
                    t = EMG.duration;
                else
                    t = P.start + get (P.player, 'currentsample')/EMG.rate;
                end;
            else
                t = P.start + etime(clock, P.clock);
            end;
            lag = (t-P.start)/P.count - P.interval;
            if ~P.running;
                SCREEN.play.list(end+1,:) = [0, t, lag];
            elseif t>= EMG.duration | t<S.time;
                SCREEN.play.running = 0;
                if S.time  < EMG.duration - P.trace_duration;
                    t0 = EMG.duration - P.trace_duration;
                    SCREEN.play.list(end+1,:) = [1, t0, lag];
                    kp ('trace', t0);
                end;
                SCREEN.play.list(end+1,:) = [2, t, lag];
                emgplay ('stop');
            elseif P.trace_duration <= P.interval;
                t0 = P.start +  floor((t - P.start) / P.trace_duration)*P.trace_duration;
                t0 = min (t0, EMG.duration - P.trace_duration);
                kp ('trace', t0);
                kp ('segment', t0 + P.trace_duration); 
                SCREEN.play.list(end+1,:) = [3, t0, lag];
           elseif t < S.time + P.trace_duration - lag;
                kp ('segment', t);
                SCREEN.play.list(end+1,:) = [4, t, lag];
           elseif t < S.time + P.trace_duration + P.interval/2;
                kp ('segment', S.time + P.trace_duration);
                SCREEN.play.list(end+1,:) = [5, t, lag];
           else
                t0 = P.start +  floor((t - P.start) / P.trace_duration)*P.trace_duration;
                t0 = min (t0, EMG.duration - P.trace_duration);
                kp ('trace', t0);
                SCREEN.play.list(end+1,:) = [6, t0, lag];
                S = SETS.signal;
                if P.audio;
                    t = P.start + get (P.player, 'currentsample')/EMG.rate;
                else
                    t = P.start + etime(clock, P.clock);
                end;
                if t < S.time + P.trace_duration - lag;
                    kp ('segment', t);
                else
                    kp ('segment', S.time + P.trace_duration);
                end;
                SCREEN.play.list(end+1,:) = [7, t, lag];
            end;
            
        case 'stop'
            SCREEN.play.running = 0;
            if SCREEN.play.audio;
                stop (SCREEN.play.player);
            end;
            stop (SCREEN.timer);
            kp ('done');
    end;
           


function kp (opt, p1)

global SCREEN SETS CURR SLIST EMG
K = SCREEN.signal;
S = SETS.signal;
if isempty(K.axes); return; end;

    switch opt
        
    case 'setup'
        set (K.cursor, 'vis', 'off');
        set (K.bar, 'xdata', nan, 'ydata', nan);
        set (K.signal, 'xdata', nan, 'ydata', nan, 'erase', 'none');
        set (K.resid, 'xdata', nan, 'ydata', nan, 'erase', 'none');
%        set (K.grat, 'xdata', nan, 'ydata', nan, 'erase', 'back');
        set (K.scale, 'str', ' ', 'erase', 'none');
        set (K.text, 'str', ' ', 'erase', 'none');
        set (K.box, 'vis', 'off', 'vis', 'on');
        kp ('trace', SETS.signal.time);
        
    case 'trace'
        t0 = p1;
        emgcursors ('focus', 'signal', 'l', t0, 'play');
        S = SETS.signal;
        t0 = S.time;
        t1 = t0 + S.timebase*(S.right - S.left);
		[sig, t] = emgsignal (t0, t1);
        if isempty (SLIST)
            res = [];
        else
            [res, t] = emgresidual (t0, t1, CURR.band, 1);
        end;
        SCREEN.play.t = t;
        SCREEN.play.sig = sig;
        SCREEN.play.res = res;
        SCREEN.play.last = t0;
       
        mysetup (K, SETS.signal);
        if t0 < EMG.duration - SCREEN.play.trace_duration;
            plotscale (K, SETS.signal, 'major');
        else
            plotscale (K, SETS.signal, 'major', 'medium', ...
                {'x', -1, 1, 'above'}, ...
                {'x', 1, -1, 'none'});
        end;
        set ([K.box, K.frame], 'vis', 'off', 'vis', 'on');
        set (SCREEN.signal.frame, 'vis', 'off', 'vis', 'on');
        set (SCREEN.signal.grat, 'vis', 'off', 'vis', 'on');
        set (SCREEN.signal.scale, 'vis', 'on');  
        
     case 'segment'
        P = SCREEN.play;
        i = find(P.t > P.last & P.t<= p1);
        myplot (K.signal, S, [0,0], P.t(i), P.sig(i));
        if ~isempty(P.res);
            myplot (K.resid, S, [0,-.7], P.t(i), P.res(i));
        end;
        if ~isempty(i);
            SCREEN.play.last = P.t(i(end));
        end;

        if isempty(SLIST); 
			return; 
		end;
		
		sl = emgslist (0, P.last, p1);
		n = size(sl,1);
		for i=1:n;
			unit = sl(i,2);
            x = S.left + (sl(i,1)-S.time)/S.timebase;
			set (K.text(1), 'pos', [x, 0.8], 'string', sprintf ('%i', unit), ...
				'color', pickcolor(unit), 'vis', 'on');
		end;
                
    case 'done'
        if strcmp (CURR.draw_mode, 'smoother');
            set (K.signal, 'erase', 'norm');
            set (K.resid, 'erase', 'norm');
            set (K.grat, 'erase', 'norm');
            set (K.scale, 'erase', 'norm');
            set (K.text, 'erase', 'norm');
        end;
        emgplot ('signal');
    end;

    
function mysetup (K, S)
    global CURR
    t0 = S.time + S.left*S.timebase;
    t1 = S.time + S.right*S.timebase;
    sens = S.sensitivity (CURR.chan, CURR.band);
    set (K.axes, 'user', [t0, t1, S.bottom*sens, S.top*sens]);
        
function myplot (K, S, org, x, y, varargin)
    h = get (K, 'parent');
    a = get (h, 'user');
    x = S.left + org(:,1) + (x-a(1))/(a(2)-a(1))*(S.right - S.left);
    y = S.bottom + org(:,2) + (y-a(3))/(a(4)-a(3))*(S.top - S.bottom);
    set (K, 'xdata', x, 'ydata', y, varargin{:});
            
    
    
function c = pickcolor (unit)
	global DECOMP CURR SETS
    C = SETS.colors;
    if unit==CURR.unit;
		c = C.selection;
	else
		c = C.template;
	end
	if ~DECOMP.UNIT(unit).visible;
		c = .5*c + .5*C.panel;
	end;


