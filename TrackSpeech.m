function varargout = TrackSpeech(varargin)
% TRACKSPEECH M-file for TrackSpeech.fig
% Last Modified by GUIDE v2.5 12-Jan-2011 13:39:18
%	Interaction window for the test subject, opened from the main
% GUI control window TRACKCONTROL.
%
% Version history.
%	02/06/2011: Created by Steven M. Bierer, using TRACKSUBJECT
% GUI code as a template.
%	04/10/2011: Adjusted start/end final calculation to avoid
% transient "blips".
%


%%%% Begin initialization code - DO NOT EDIT %%%%%%%%%%%%%%%%%%
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TrackSpeech_OpeningFcn, ...
                   'gui_OutputFcn',  @TrackSpeech_OutputFcn, ...
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
function TrackSpeech_OpeningFcn(hObject, eventdata, handles, varargin)

%%%% Runtime options %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
POSITION = [1933 5 1266 985];		% Spencer Lab
AUDIO_CHECKRMSUP = .003;
AUDIO_CHECKRMSDOWN = .002;
% POSITION = [400 100 1165 850];	% Steve Home (normally keep these commented)
% AUDIO_CHECKRMSUP = .08;
% AUDIO_CHECKRMSDOWN = .05;

TRIAL_TIMEOUT = 25;					% for stopping a trial, in seconds
AUDIO_SAMPLINGRATE = 44100;
AUDIO_CHECKPERIOD = 0.25;			% criteria for automatically ending a trial
AUDIO_CHECKDWELL = 1.5;
AUDIO_MINEVENT = .05;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if length(POSITION) == 4			% adjust figure position
	set(hObject,'Position',POSITION);
elseif length(POSITION) == 2
	pos = get(hObject,'Position');
	pos(1) = POSITION(1); pos(2) = POSITION(2);
	set(hObject,'Position',pos);
end;								% must reset position later (unclear why)
handles.position = get(hObject,'Position');

set(handles.uipanel_background,'Units','normalized');
set(handles.uipanel_background,'Position',[0.01 0.01 .99 .99]);
set(handles.axis_feedback,'Units','normalized');
set(handles.axis_feedback,'Position',[0.10 0.10 .80 .80]);

handles.gobutton = [];				% handle to the "GO" button (probably in control GUI)
handles.timeout = TRIAL_TIMEOUT;
handles.samprate = AUDIO_SAMPLINGRATE;

handles.checkrules.period = AUDIO_CHECKPERIOD * AUDIO_SAMPLINGRATE;
handles.checkrules.rmsdwell = ceil(AUDIO_CHECKDWELL /  AUDIO_CHECKPERIOD);
handles.checkrules.rmsup = AUDIO_CHECKRMSUP;
handles.checkrules.rmsdown = AUDIO_CHECKRMSDOWN;
handles.checkrules.mindur = AUDIO_MINEVENT * AUDIO_SAMPLINGRATE;

handles.durationrules = [];
 
if nargin < 4						% default to horizontal sinusoid target type ..
	handles.type = 'Buy Bobby A Poppy';
else
	handles.type = varargin{1};		% .. or interpret first argument as target type
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

% switch handles.type					% set up tracking target and other cues
% case 'Buy Bobby A Poppy'
% 	sntstr = 'Buy Bobby A Poppy';
% otherwise
% 	warndlg('Target sentence is not known','Unrecognized input','modal');
% 	handles.output = []; guidata(hObject, handles);
% 	return;
% end;
sntstr = handles.type;
set(handles.text_sentence,'String',sntstr,'Visible','Off');
									% set up the feedback plot
TrackControl_PlotFeedback(handles.axis_feedback,handles.conditions,'Setup');

set(handles.axis_feedback,'Visible','On');
uistack(handles.uipanel_background,'top');

handles.output = hObject;			% default command line output
guidata(hObject, handles);			% update the handles

setappdata(hObject,'External','False');



% -- Outputs from this function are returned to the command line -- %
function varargout = TrackSpeech_OutputFcn(hObject, eventdata, handles) 

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
% Much of the code here should be identical to the code in TRACKSUBJECT.
function TrackSpeech_RunSeries(hfigure)

handles = guidata(hfigure);
setappdata(hfigure,'StopNow',false); % flag for control GUI to stop after current trial
hctrl = findall(0,'Tag','ctrlwindow');
if isempty(hctrl)					% 'hctrl' is the handle for the control window, if open
	setappdata(hfigure,'External',false);
end;

hsentence = handles.text_sentence;
htext = handles.text_instruct;		% adjust size and font of instruction text
set(htext,'Visible','Off');
hbutton = htext;					% for this GUI, the text IS the button

ai = analoginput('winsound');		% set up the audio sampling
addchannel(ai,1);
maxsamples = handles.timeout * handles.samprate;
checkperiod = handles.checkrules.period;
set(ai,'SampleRate',handles.samprate,'SamplesPerTrigger',maxsamples);

nTrial = length(handles.conditions.order);	% set up a storage structure
resultStruct = struct('condname',[],'condtime',zeros(1,nTrial), ...
  'timetaken',zeros(1,nTrial),'timeviewing',zeros(1,nTrial),...
  'energy',zeros(1,nTrial),'wavdata',[],'endpts',[]);
resultStruct.condname = cell(1,nTrial);		% set up the results structure
resultStruct.wavdata = cell(1,nTrial);
resultStruct.endpts   = cell(1,nTrial);

plotnow = logical(handles.conditions.feedback);
resultStruct.plottime = handles.conditions.feedback;

timeout = false(1,nTrial);			% indicates whether a trial terminated early
resultStruct.timedout = timeout;
resultStruct.sentence = get(hsentence,'String');

calcgroup = find(handles.conditions.times==0);
if ~isempty(calcgroup)
	calcidx = find(handles.conditions.order==calcgroup);
	calcnow = calcidx(end);					% tells when/if to calculate the base time
else
	calcnow = 0;
end;

lastplot = 0;
timetaken = zeros(1,nTrial); energy = zeros(1,nTrial);
for i = 1:nTrial					% loop through the trials
	% Show the text instruction and the target sentence to be uttered %
	condidx = handles.conditions.order(i);
	str = sprintf('%s',handles.conditions.labels{condidx});
	col = handles.conditions.colors{condidx};
	set(htext,'String',str,'ForeGroundColor',col,'Visible','On');

	% Arm the "GO" button and wait for it to be pushed %
	set(hbutton,'buttondownfcn',{@pushbutton_Callback,hfigure},'Enable','Inactive');
 	uiwait(hfigure);				% the UIRESUME occurs in 'pushbutton_Callback()'
% 	set(htext,'Visible','Off');
	set(handles.uipanel_background,'ShadowColor',[.17 .50 .34])

	% Capture audio and collect and interpret the speech waveform %
	set(ai,'SamplesAcquiredFcnCount',checkperiod,'SamplesAcquiredFcn', ...
	  {@TrackSpeech_CheckAudio,handles.checkrules});
	set(ai,'UserData',[0 0]);		% for keeping track of audio triggers
	[wavdata,tflag] = TrackSpeech_RunTrial(handles,ai,hsentence);

	set(handles.uipanel_background,'ShadowColor',[.078 .169 .549]);
	set(hsentence,'Visible','Off');

	endpts = TrackSpeech_RunSeries_GetInfo(handles,wavdata);
	timetaken(i) = (endpts(2) - endpts(1) + 1) / (handles.samprate/1000);
	energy(i) = std(wavdata(endpts(1):endpts(2)));

	% Plot or not, store and display the results %
	resultStruct.condname{i} = handles.conditions.labels{condidx};
	resultStruct.condtime(i) = handles.conditions.times(condidx);
	resultStruct.timetaken(i) = timetaken(i);
	resultStruct.energy(i) = energy(i);
	resultStruct.wavdata{i} = wavdata;
	resultStruct.endpts{i} = endpts;
	resultStruct.timedout(i) = tflag;
									% update results to the workspace and the control GUI
	assignin('base','resultStruct',resultStruct);
	if getappdata(handles.subjwindow,'External')
	  TrackControl('TrackControl_ReportResults',hctrl,resultStruct,i,handles.samprate);
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
			hresume = uicontrol(hfigure,'Style','pushbutton','String','Continue','FontSize',18);
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

		uistack(handles.uipanel_background,'top');
		delete(hlast);
		delete(hgoal(find(hgoal))); delete(hgoal_text(find(hgoal_text)));

	end; % if plotnow %

	if getappdata(hfigure,'StopNow')
		break;						% terminate trials if STOP button was pushed in the control GUI
	end;
end;

set(htext,'String','Finished!','Visible','On','ForeGroundColor','r');
fprintf(1,'** %d of %d trials completed. Results saved to workspace. **\n', ...
  i,nTrial);


% -- Facilitating function to calculate speech duration for one trial -- %
function endpts = TrackSpeech_RunSeries_GetInfo(handles,wavdata)

wavdata = filter([0.998933 -0.998933],[1 -0.997865],wavdata);

ethr = handles.checkrules.rmsup;	% initial energy threshold
eskip = 0.05 * handles.samprate;

fdur = 0.01 * handles.samprate;
fwin = ones(1,fdur) / fdur;			% a 10-msec averaging filter
fdata = sqrt( filter(fwin,1,wavdata.^2) );
mindur = handles.checkrules.mindur;

if ~any(fdata(eskip+1:end)>ethr)	% reduce default threshold if it's too high
	ethr = ethr/2;
end;
if ~any(fdata(eskip+1:end)>ethr)	% return if minimum threshold isn't reached
	endpts = [1 length(wavdata)];
	return;
end;

pt0 = find(fdata(eskip+1:end)>ethr);
pt0 = pt0(1) + eskip;				% establish a noise baseline
fsub = fdata(eskip+1:pt0);
rmsbase = mean(fsub);
rmsbase = mean(fsub(fsub<4*rmsbase));
									% find regions of high energy
upidx = find(fdata(1:end)>6*rmsbase);
if isempty(upidx)					% if response is small, lower the threshold ..
	upidx = find(fdata(1:end)>4*rmsbase);
end;
if isempty(upidx)					% .. or return the default start + end times
	endpts = [1 length(wavdata)];
	return;
end;
updiff = diff(upidx); upidxd = upidx(2:end);
upstarts = upidxd(updiff>1);		% determine start and end time of every segment,
upends = upstarts - updiff(updiff>1);  % where segments are divided by dips below 6*rmsbase
upstarts = [upidx(1) ; upstarts];
upends = [upends ; upidx(end)];

pt1idx = find(upends-upstarts > mindur);
pt1a = upstarts(pt1idx); 
if max(pt1a) > eskip
	pt1a = pt1a(pt1a>eskip);
end;
if isempty(pt1a)					% find starting point ('pt1')
	pt1a = upidx(1);
end;
pt1a = pt1a(1);
pt1 = find(fdata(1:pt1a-1)<2*rmsbase);
pt1 = pt1(end);

pt2idx = find(upends-upstarts > mindur);
if isempty(pt2idx)
	endpts = [pt1 length(wavdata)];
	return;
end;
pt2a = upends(pt2idx); pt2a = pt2a(end);
pt2 = find(fdata(pt2a+1:end)<2*rmsbase);
if ~isempty(pt2)					% find ending point ('pt2')
	pt2 = pt2(1) + pt2a;
else
	pt2 = length(wavdata);
end;

endpts = [pt1 pt2];	


% -- Main routine to handle mouse motion and output tracking result -- %
function [wavdata,tflag] = TrackSpeech_RunTrial(handles,ai,hsentence)

hfig = handles.subjwindow;
set(hfig,'WindowButtonUpFcn','uiresume(gcf)');
uiwait(hfig); pause(0.1);

start(ai); pause(0.1);
set(hsentence,'Visible','On');
wait(ai,handles.timeout+0.2);

npts = get(ai,'SamplesAvailable');
wavdata = getdata(ai,npts);

if npts == get(ai,'SamplesPerTrigger')
	tflag = true;
else
	tflag = false;
end;


 
%%%% CALLBACK ROUTINES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -- Audio function to periodically check for the sentence utterance to stop -- %
% Input argument, 'criteria', contains the requirements for the end of the sentence.
% It arms when energy reaches 'rmsup', triggers when it drops below 'rmsdown', and
% waits 'rmsdwell' to see if the energy remains below this level.
function TrackSpeech_CheckAudio(obj,event,criteria)

nacq = get(obj,'SamplesAcquired');
npts = min(criteria.period,get(obj,'SamplesAvailable'));
rms = std(peekdata(obj,npts));

trigvec = get(obj,'UserData');
trigON = trigvec(1); trigOFF = trigvec(2);

if rms>criteria.rmsup && ~trigON
	disp('Speech started');
	trigON = 1;
elseif rms>criteria.rmsdown && trigON
	trigOFF = 0;				% reset trigOFF if energy goes too high again
elseif rms<criteria.rmsdown && trigON && nacq>2*criteria.rmsdwell
	trigOFF = trigOFF + 1;		% after a minimum rec. time, start counting periods
end;							  % for which the energy remains low
set(obj,'UserData',[trigON trigOFF]);

if trigOFF >= criteria.rmsdwell	% when enough periods have elapsed, the speech is over
	stop(obj);
	set(obj,'SamplesAcquiredFcn',[]);
	disp('Speech ended');
end;


% -- Start a single trial with the "GO" button -- %
% This callback is not for a uicontrol button, but a 'buttondownfcn' property.
function pushbutton_Callback(src,event,hfig)

set(src,'buttondownfcn',[]);	% prevent the button from being active any further
uiresume(hfig);


% -- Define context menu -- %
% Currently, the only menu entry is 'RunTrial_Callback' (below).
function RunOptions_Callback(hObject, eventdata, handles)

% -- Simply forces a series of trials -- %
function RunTrial_Callback(hObject, eventdata, handles)

TrackSpeech_RunSeries(handles.subjwindow);

function Unhide_Callback(hObject, eventdata, handles)

set(handles.subjwindow,'HandleVisibility','On');


% -- Handle an attempt to close the GUI figure -- %
% Prevents accidental closure of the GUI window.
function TrackSpeech_CloseFcn()

query = questdlg('Do you wish to close the Interaction window?', 'Close Request', 'No');
if strcmp(query,'Yes')
	closereq;						% then close the main figure
end;
