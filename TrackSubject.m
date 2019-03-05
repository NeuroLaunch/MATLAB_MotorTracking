function varargout = TrackSubject(varargin)
% TRACKSUBJECT M-file for TrackSubject.fig
% Last Modified by GUIDE v2.5 12-Jan-2011 13:39:18
%	Interaction window for the test subject, opened from the main
% GUI control window TRACKCONTROL.
%
% Version history.
%	01/10/2011: Created by Steven M. Bierer
%	01/19/2011: Added the following functionalities: feedback interval,
% "flashing" data points when added, figure handle visibility in
% context menu (for getting position vector)
%	01/23/2011: Added computer-specific settings for figure position.
%


%%%% Begin initialization code - DO NOT EDIT %%%%%%%%%%%%%%%%%%
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TrackSubject_OpeningFcn, ...
                   'gui_OutputFcn',  @TrackSubject_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
%%%% End initialization code - DO NOT EDIT %%%%%%%%%%%%%%%%%%%%%


% -- Executes just before the GUI figure is made visible -- %
function TrackSubject_OpeningFcn(hObject, eventdata, handles, varargin)

%%%% Runtime options %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
POSITION = [1923 5 1274 989];		% Spencer Lab
% POSITION = [400 100 1000 800];	% Steve Home

SQXX = 0.03; SQYY = 0.05;
H_XLIM = [-.3 1.25]; H_YLIM = [-.76 .76];
V_XLIM = [-1 1]; V_YLIM = [-.1 1.1];	% X = 9", Y = 7" at Spencer Lab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if length(POSITION) == 4			% adjust figure position
	set(hObject,'Position',POSITION);
elseif length(POSITION) == 2
	pos = get(hObject,'Position');
	pos(1) = POSITION(1); pos(2) = POSITION(2);
	set(hObject,'Position',pos);
end;								% must reset position later (unclear why)
handles.position = get(hObject,'Position');

if nargin < 4						% default to horizontal sinusoid target type ..
	handles.type = 'Horiz Sine';
else								% .. or interpret first argument as target type
	handles.type = varargin{1};
end;
if nargin < 5						% set up a "demo run" if no conditions given
	handles.conditions.labels = {'2x'};
	handles.conditions.colors = {'r'};
	handles.conditions.times = 2400;
	handles.conditions.order = 1;
	handles.conditions.feedback = 5;
elseif ~isstruct(varargin{2}) && isscalar(varargin{2})
	nCond = varargin{2};
	handles.conditions.labels = {'2x'};
	handles.conditions.colors = {'r'};
	handles.conditions.times = 2400;
	handles.conditions.order = 1:nCond;
	handles.conditions.feedback = 5 * ones(1,nCond); 
else
	handles.conditions = varargin{2};
end;

axes(handles.axis_track);			% make the tracking pane current, and clear it
cla;								  % (in case GUI called previously)

switch handles.type					% set up tracking target and other cues
case 'Horiz Sine'
	xvec = [0:0.01:1]; xrng = H_XLIM; xdir = 'normal';
	yvec = 0.5 * sin(2*pi*xvec); yrng = H_YLIM; ydir = 'normal';
	htarget = plot(xvec,yvec);		% plot target and set axes limits

	mousetrig = [0 1 ; NaN NaN];	% motion trigger points (row1 = x, row2 = y)

	hline1 = line([0 0],[-1 1]); hline2 = line([1 1],[-1 1]);

	hsq1 = fill([-SQXX -SQXX SQXX SQXX],[-SQYY SQYY SQYY -SQYY],[1 1 .2]);
	hsq2 = fill(1+[-SQXX -SQXX SQXX SQXX],[-SQYY SQYY SQYY -SQYY],[1 1 .2]);

	htext = handles.text_instructx;	% position of prompt depends on target type
	set(handles.text_instructy,'Visible','Off');

case 'Vert Sine'
	yvec = [0:0.01:1]; yrng = V_YLIM; ydir = 'reverse';
	xvec = 0.5 * sin(2*pi*yvec); xrng =  V_XLIM; xdir = 'normal';
	htarget = plot(xvec,yvec);		% plot target and set axes limits

	mousetrig = [NaN NaN ; 0 1];	% motion trigger points (row1 = x, row2 = y)

	hline1 = line([-1 1],[0 0]); hline2 = line([-1 1],[1 1]);

	hsq1 = fill([-SQYY SQYY SQYY -SQYY],[-SQXX -SQXX SQXX SQXX],[1 1 .2]);
	hsq2 = fill([-SQYY SQYY SQYY -SQYY],1+[-SQXX -SQXX SQXX SQXX],[1 1 .2]);

	htext = handles.text_instructy;	% position of prompt depends on target type
	set(handles.text_instructx,'Visible','Off');

otherwise
	warndlg('Target type is not known','Unrecognized input','modal');
	handles.output = []; guidata(hObject, handles);
	return;
end;
									% set guide object properties and hide them
set(htarget,'Color',[.8 .8 .8],'LineWidth',30,'Visible','Off');
set([hline1 hline2],'Color',[1 1 .2],'LineStyle',':','LineWidth',2,'Visible','Off');
set([hsq1 hsq2],'Visible','Off');
									% store all of the object handles
handles.target = htarget; %handles.bounds = hbounds;
handles.line1 = hline1; handles.line2 = hline2;
handles.square1 = hsq1; handles.square2 = hsq2;
handles.text_instruct = htext;
									% common axes properties
set(handles.axis_track,'XLim',xrng,'YLim',yrng,'XDir',xdir,'YDir',ydir);
set(handles.axis_track,'XTick',[],'YTick',[],'UserData',mousetrig);
htrace = plot(0,0,'LineStyle','none','Marker','o','MarkerSize',8,'Color',[.2 .2 .2]);
set(htrace,'Xdata',[],'Ydata',[]);	% create an empty plot object for the track trace
handles.trace = htrace;
									% set up the feedback plot
TrackControl_PlotFeedback(handles.axis_feedback,handles.conditions,'Setup');

axes(handles.axis_track);			% return control to main tracking axes
set(handles.axis_feedback,'Visible','On');

handles.output = hObject;			% default command line output
guidata(hObject, handles);			% update the handles

setappdata(hObject,'External','False');


% -- Outputs from this function are returned to the command line -- %
function varargout = TrackSubject_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;

set(hObject,'Position',handles.position);

if isempty(handles.output)			% terminate without going through '_CloseFcn()'
	delete(hObject);				  % if opening function failed
end;



%%%% AUXILIARY FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -- Run a series of tracking trials -- %
% Can be called externally (e.g. by the main "control" GUI) or internally
% to initiate tracking trials and their collection and analysis.
function TrackSubject_RunSeries(hfigure)

handles = guidata(hfigure);
setappdata(hfigure,'StopNow',false); % flag for control GUI to stop after current trial
hctrl = findall(0,'Tag','ctrlwindow');
if isempty(hctrl)					% 'hctrl' is the handle for the control window, if open
	setappdata(hfigure,'External',false);
end;

hbutton = handles.square1;			% choose this object as the "GO" button

htext = handles.text_instruct;		% adjust size and font of text box
posb = get(htext,'Position'); set(htext,'UserData',posb,'Visible','Off');
posb(3) = 0.08; set(htext,'Position',posb,'FontSize',60);

nTrial = length(handles.conditions.order);	% set up a storage structure
resultStruct = struct('condname',[],'condtime',zeros(1,nTrial), ...
  'timetaken',zeros(1,nTrial),'timeviewing',zeros(1,nTrial),...
  'rmserror',zeros(1,nTrial),'xytdata',[]);
resultStruct.condname = cell(1,nTrial);		% set up the results structure
resultStruct.xytdata = cell(1,nTrial);
resultStruct.xytarget = [get(handles.target,'XData') ; get(handles.target,'YData')];

plotnow = logical(handles.conditions.feedback);
resultStruct.plottime = handles.conditions.feedback;     

calcgroup = find(handles.conditions.times==0);
if ~isempty(calcgroup)
	calcidx = find(handles.conditions.order==calcgroup);
	calcnow = calcidx(end);					% tells when/if to calculate the base time
else
	calcnow = 0;
end;

lastplot = 0;
timetaken = zeros(1,nTrial); rmserror = zeros(1,nTrial);
for i = 1:nTrial						% loop through the trials
	% Show the text instruction = trial's condition "label" %
	condidx = handles.conditions.order(i);
	str = sprintf('%s',handles.conditions.labels{condidx});
	col = handles.conditions.colors{condidx};
	set(htext,'String',str,'ForeGroundColor',col,'Visible','On');
	motion_Callback_trigger(hfigure,'reveal');

	% Arm the "GO" button and wait for it to be pushed %
	set(hbutton,'buttondownfcn',{@pushbutton_Callback,hfigure});
	uiwait(hfigure);				% the UIRESUME occurs in 'pushbutton_Callback()'

	% Wait for the mouse motion to end, and collect and interpret the tracking data %
	xytdata = TrackSubject_RunTrial(handles);
	timetaken(i) = TrackSubject_RunSeries_GetTime(handles,xytdata);
	rmserror(i) = TrackSubject_RunSeries_GetError(handles,xytdata);

	% Plot or not, store the results %
	resultStruct.condname{i} = handles.conditions.labels{condidx};
	resultStruct.condtime(i) = handles.conditions.times(condidx);
	resultStruct.timetaken(i) = timetaken(i);
	resultStruct.rmserror(i) = rmserror(i);
	resultStruct.xytdata{i} = xytdata;
									% update to the workspace on every trial
	assignin('base','resultStruct',resultStruct);
	if getappdata(handles.subjwindow,'External')
	  TrackControl('TrackControl_ReportResults',hctrl,resultStruct,i);
	end;

	% Calculate any missing tracking goals (0 and -1 codes for 'conditions.times()') %
	if i == calcnow					% calculate the base time
		newbase = mean(timetaken(calcidx));
									% update all of the target tracking times
		for g = 1:length(handles.conditions.times)
			scale = handles.conditions.times(g);
			if scale==0,			% treat entries = 0 as unity scale
				handles.conditions.times(g) = newbase;
			elseif scale<0			% update all negative entries
				handles.conditions.times(g) = newbase * abs(scale);
			end;					% ignore everything else
		end;
		guidata(hfigure,handles);
									% send result to the main control GUI, as text
		updateString = {sprintf('------>  HABITUAL RATE (10 trials) = %.1f msec',newbase)};
		TrackControl('TrackControl_ReportNews',hctrl,updateString);
	end;

	% Plot next set of results, per feedback interval %
	if plotnow(i)
		set(htext,'Visible','Off');

		[hgoal,hgoal_text] = TrackControl_PlotFeedback(handles.axis_feedback,handles.conditions,'Lines');
		hlast = TrackControl_PlotFeedback(handles.axis_feedback,handles.conditions,'Data', ...
		  timetaken,lastplot);
		lastplot = i;				% keep track of last time the feedback plot was updated

		tic;						% keep track of how long subject views feedback

		if handles.conditions.feedback(i) < 0
			pause(2);				% wait for a button press (and a minimum of 2 sec) ..
			hresume = uicontrol('Style','pushbutton','String','Continue','FontSize',18);
			set(hresume,'Units','normalized','Callback','uiresume(gcf)');
			bsize = get(hresume,'Extent'); % (temporarily create the button)
			set(hresume,'Position',[0.82 0.90 bsize(3)*1.1 bsize(4)*1.1]);
			uiwait(hfigure);
			delete(hresume);
		else						% .. or a set time to expire ..
			pause(handles.conditions.feedback(i));
		end;						% .. before giving control back to the main axes

		resultStruct.timeviewing(i) = toc;
		assignin('base','resultStruct',resultStruct);

		axes(handles.axis_track);
		delete(hlast);
		delete(hgoal(find(hgoal))); delete(hgoal_text(find(hgoal_text)));

	end; % if plotnow %

	if getappdata(hfigure,'StopNow')
		break;						% terminate trials if STOP button was pushed in the control GUI
	end;
end; % for i = 1:nTrial %

posb = get(htext,'UserData');		% set text instruction field to "finished"
set(htext,'ForeGroundColor','r','FontSize',30,'Position',posb);
set(htext,'String','Finished!','Visible','On');

fprintf(1,'** %d of %d trials completed. Results saved to workspace. **\n', ...
  i,nTrial);


% -- Facilitating function to calculate tracking time for one trial -- %
function timeout = TrackSubject_RunSeries_GetTime(handles,xytdata)

mtrig = get(handles.axis_track,'UserData');
if ~isnan(mtrig(1,1))			% find time points when mouse within bounds
	trackidx = find(xytdata(1,:)>mtrig(1,1) & xytdata(1,:)<mtrig(1,2));
else
	trackidx = find(xytdata(2,:)>mtrig(2,1) & xytdata(2,:)<mtrig(2,2));
end;

timeout = xytdata(3,trackidx(end)) - xytdata(3,trackidx(1));
timeout = 1000 * timeout;		% convert time from sec to msec


% -- Facilitating function to calculate rms tracking error for one trial -- %
function errorout = TrackSubject_RunSeries_GetError(handles,xytdata)

mtrig = get(handles.axis_track,'UserData');
x = get(handles.target,'XData');
y = get(handles.target,'YData');

if ~isnan(mtrig(1,1))			% "horizontal" target compares y-axis amplitudes
	trackidx = find(xytdata(1,:)>mtrig(1,1) & xytdata(1,:)<mtrig(1,2));
	data = xytdata(2,trackidx); ref = xytdata(1,trackidx);
	target = interp1(x,y,ref);
else							% "vertical" target compares x-axis amplitudes
	trackidx = find(xytdata(2,:)>mtrig(2,1) & xytdata(2,:)<mtrig(2,2));
	data = xytdata(1,trackidx); ref = xytdata(2,trackidx);
	target = interp1(y,x,ref);
end;

errorout = sqrt(mean((target - data).^2));


% -- Main routine to handle mouse motion and output tracking result -- %
function trackdata = TrackSubject_RunTrial(handles)

hfig = handles.subjwindow; hax = handles.axis_track; htrace = handles.trace;
set(hfig,'Pointer','Circle');	% update graphics for targeted tracking

trackdata = zeros(3,10000);		% for storing x-y position and time info
set(hfig,'UserData',trackdata);

tic;							% start the timer and record mouse motion
set(hfig,'WindowButtonMotionFcn',{@motion_Callback,hax,htrace});
uiwait(hfig);
								 % save the tracking results
trackdata = get(hfig,'UserData');
idx = find(trackdata(3,:));		% this will include points when mouse was not yet
trackdata = trackdata(:,idx);	  % within the target region (i.e. not triggered)

pause(0.5);						% continue to display the tracking points briefly
set(htrace,'XData',[],'YData',[]);  % before resetting

set(hfig,'Pointer','Arrow');	% also reset the cursor and tracking guides
motion_Callback_trigger(hfig,'reset');



%%%% CALLBACK ROUTINES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -- Start a single trial with the "GO" button -- %
% This callback is not for a uicontrol button, but a 'buttondownfcn' property.
function pushbutton_Callback(src,event,hfig)

set(src,'buttondownfcn',[]);
uiresume(hfig);


% -- Handle mouse motions after "GO" button is pushed -- %
function motion_Callback(src,event,hax,htrace)

cp = get(hax,'CurrentPoint');		% get the current x,y mouse position
tp = toc;							% get the current time since 'tic' (in sec)
trackdata = get(src,'UserData');	% base next entry on >0 time entries
idx = find(trackdata(3,:));
cnt = length(idx) + 1;

trackdata(:,cnt) = [cp(1,1) ; cp(1,2) ; tp];
set(src,'UserData',trackdata);		% store the new x,y,t data

mtrig = get(hax,'UserData');
if cnt==1 || cnt==2
 	trigon = cp(1,1)>=mtrig(1,1);
	trigoff = false;
 	plotpt = cp(1,1)>=mtrig(1,1);
elseif ~isnan(mtrig(1,1))			% on/off triggers for x-axis targets
	trigon = cp(1,1)>=mtrig(1,1) && trackdata(1,idx(end))<mtrig(1,1);
	trigoff = cp(1,1)>=mtrig(1,2) && trackdata(1,idx(end))<mtrig(1,2);
	plotpt = cp(1,1)>=mtrig(1,1);
else								% on/off triggers for y-axis targets
	trigon = cp(1,2)>=mtrig(2,1) && trackdata(2,idx(end))<mtrig(2,1);
	trigoff = cp(1,2)>=mtrig(2,2) && trackdata(2,idx(end))<mtrig(2,2);
	plotpt = cp(1,2)>=mtrig(2,1);
end;
if trigon							% facilitating functions for triggers (below)
	motion_Callback_trigger(src,'on');
elseif tp > 45 || trigoff			% end mouse functionality on trigger or time-out
	set(src,'WindowButtonMotionFcn','');
	motion_Callback_trigger(src,'off');
	uiresume(src);					% UIRESUME allows trial to continue
end;

if plotpt
	xpts = get(htrace,'XData'); ypts = get(htrace,'YData');
	set(htrace,'XData',[xpts cp(1,1)],'YData',[ypts cp(1,2)]);
end;


function motion_Callback_trigger(src,mode)

handles = guidata(src);

switch mode
case 'on'
	set([handles.line1 handles.line2],'Color',[.17 .50 .34]);
	set([handles.square1 handles.square2],'FaceColor',[.17 .50 .34]);
case 'off'
	set([handles.line1 handles.line2],'Color','r');
	set([handles.square1 handles.square2],'FaceColor','r');
case 'reveal'
	set([handles.line1 handles.line2],'Visible','On');
	set([handles.square1 handles.square2],'Visible','On');
	set(handles.target,'Visible','On');
% 	set(handles.bounds,'Visible','On');
case 'reset'
	set([handles.line1 handles.line2],'Color',[1 1 .2],'Visible','Off');
	set([handles.square1 handles.square2],'FaceColor',[1 1 .2],'Visible','Off');
	set(handles.target,'Visible','Off');
% 	set(handles.bounds,'Visible','Off');
end;


% -- Define context menu -- %
% Currently, the only menu entry is 'RunTrial_Callback' (below).
function RunOptions_Callback(hObject, eventdata, handles)

% -- Simply forces a series of trials -- %
function RunTrial_Callback(hObject, eventdata, handles)

TrackSubject_RunSeries(handles.subjwindow);

function Unhide_Callback(hObject, eventdata, handles)

set(handles.subjwindow,'HandleVisibility','On');


% -- Handle an attempt to close the GUI figure -- %
% Prevents accidental closure of the GUI window. 
function TrackSubject_CloseFcn()

% closereq;
query = questdlg('Do you wish to close the Subject Interaction window?', 'Close Request', 'No');
if strcmp(query,'Yes')
	closereq;						% then close the main figure
end;
