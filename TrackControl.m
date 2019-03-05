function varargout = TrackControl(varargin)
% TRACKCONTROL M-file for TrackControl.fig
% Last Modified by GUIDE v2.5 13-Jan-2011 15:49:28
%	Control window for running tracking experiments via
% separate subject interaction windows (e.g. TRACKSUBJECT).
%
% Version history.
%	01/14/2011: Created by Steven M. Bierer
%	01/24/2011: Improved checking of text fields for valid entries.
%	02/05/2011: Added "Speech" mode  
%	02/12/2011: Added display of results via text and data plotting
%	03/02/2011: Adding a "practice" mode which will require the following:
%		- the habitual rate will be measured from the first M trials
%		- the scaled rates (e.g. x2 and x3) will be computed automatically from the
%			measured habitual rate
%		- the final N scaled trials will be presented in order (e.g. x2 then x3)
%		- the feedback graph won't display until after the first M habitual-rate trials,
%			but every time for the last N scaled-rate trials
%		- when displayed, the feedback graph will stay up until a button is pressed
%		- the feedback graph after the first M trials will display the appropriate lines
%			and labels
%		- the practice mode will be selected from a new "conditions" pulldown menu, which
%			fills the "conditions" text box
% 

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TrackTest_OpeningFcn, ...
                   'gui_OutputFcn',  @TrackTest_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


% -- Executes just before TrackTest is made visible -- %
function TrackTest_OpeningFcn(hObject, eventdata, handles, varargin)

%%%% Runtime options %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FEEDBACK_DISPLAYTIME = 7;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

									% force calls to the mode and conditions popup menus
popupmenu_mode_Callback(handles.popupmenu_mode, [], handles);
popupmenu_target_Callback(handles.popupmenu_target,[],handles);

handles.savingpath = '';			% set some defaults
handles.fbtime = FEEDBACK_DISPLAYTIME;

handles.output = hObject;
guidata(hObject, handles);
									% another forced call (GUIDATA() is called in it)
popupmenu_conditions_Callback(handles.popupmenu_conditions,[],handles);
setappdata(hObject,'DisplayWindow',[]);


% -- Outputs from this function are returned to the command line -- %
function varargout = TrackTest_OutputFcn(hObject, eventdata, handles)

varargout{1} = handles.output;



%%%% AUXILIARY FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -- This is called by the subject interaction window to display each trial's results -- %
function TrackControl_ReportResults(hctrl,resultStruct,trialnum,varargin)

handles = guidata(hctrl);	% 'hctrl' and 'handles.ctrlwindow' should be the same
mode = getappdata(handles.ctrlwindow,'Mode');
target = getappdata(handles.ctrlwindow,'Target');
hwin = getappdata(handles.ctrlwindow,'DisplayWindow');

oldStr = get(handles.text_results,'String');

if resultStruct.plottime(trialnum)
	pstr = '*';
else pstr = ' ';
end;

tlabel = resultStruct.condname{trialnum};
ttaken = resultStruct.timetaken(trialnum);
if resultStruct.condtime(trialnum) <= 0
	tdiff = NaN;			% (a neg. value can occur only if the base time wasn't properly
else						  % calculated in target GUI [i.e. for "practice" run])
	tdiff = ttaken - resultStruct.condtime(trialnum);
end;

switch mode
case 'Mouse Motion'
	err = resultStruct.rmserror(trialnum);
	newStr = {sprintf('%02d %s        %3s        TIME/DIFF: %5.0f   %+7.1f        RMS: %.3f', ...
	  trialnum,pstr,tlabel,ttaken,tdiff,err)};
case 'Speech'
	energy = resultStruct.energy(trialnum);
	if resultStruct.timedout(trialnum)
		toutstr = '--TIMED OUT--';
	else toutstr = '';
	end;
	newStr = {sprintf('%02d %s        %3s        TIME/DIFF: %5.0f   %+7.1f        RMS: %.3f %20s', ...
	  trialnum,pstr,tlabel,ttaken,tdiff,energy,toutstr)};
end;
							% display the formatted results strings in the text panel
set(handles.text_results,'String',cat(1,oldStr,newStr));

if ~isempty(hwin) && ismember(hwin,findall(0,'Tag','DisplayWindow'));
	figure(hwin);
	cla;
else						% open or create a window for plotting the tracking data
	hwin = figure('Menubar','none','Tag','DisplayWindow','NumberTitle','Off','Color',[0.5 0.5 0.5]);
	set([hwin handles.ctrlwindow],'Units','pixels');
	cpos = get(handles.ctrlwindow,'Position');
	wpos = [cpos(1) cpos(2)-440 cpos(3) 400];
	set(hwin,'Position',wpos);
	setappdata(handles.ctrlwindow,'DisplayWindow',hwin);
end;

switch mode					% plot of tracking data depends on the experiment mode
case 'Mouse Motion'
	xt = resultStruct.xytarget(1,:);
	yt = resultStruct.xytarget(2,:);
	xx = resultStruct.xytdata{trialnum}(1,:);
	yy = resultStruct.xytdata{trialnum}(2,:);
	plot(xt,yt,'Color',[.4 .4 .4],'Linewidth',2);
	hold on;
	plot(xx,yy,'bo','MarkerSize',4);

	set(gca,'XLimMode','auto','YLimMode','auto');
	if strcmp(target,'Horiz Sine')
		set(gca,'XLim',[-.05 1.05],'YDir','normal');
	else
		set(gca,'YLim',[-.05 1.05],'YDir','reverse');
	end;

	figstr = sprintf('Motion Trajectory, Trial # %d',trialnum);
	set(hwin,'Name',figstr);
case 'Speech'
	samprate = varargin{1};
	time = [0:length(resultStruct.wavdata{trialnum})-1]/samprate;
	plot(time,resultStruct.wavdata{trialnum},'k');
	hold on;

	endpts = (resultStruct.endpts{trialnum}-1)/samprate;
	line([endpts(1) endpts(1)],ylim,'Color','r','LineStyle',':');
	line([endpts(2) endpts(2)],ylim,'Color','r','LineStyle',':');

	set(gca,'XLimMode','auto','YLimMode','auto');

	figstr = sprintf('Speech Waveform -- Trial %d',trialnum);
	set(hwin,'Name',figstr);
end;


% -- This is called by the subject interaction window to write to the results pane -- %
% 'infoStr' is a cell array of strings to write to the text field.
function TrackControl_ReportNews(hctrl,infoStr)

handles = guidata(hctrl);

oldStr = get(handles.text_results,'String');
set(handles.text_results,'String',cat(1,oldStr,infoStr));



%%%% CALLBACK ROUTINES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -- This calls up the subject interaction window and begins the tracking run -- %
function pushbutton_start_Callback(hObject, eventdata, handles)

% Get and display info about experiment setup %
subjstr = get(handles.edit_subject,'String');
runstr = get(handles.edit_run,'String');

targStr = get(handles.popupmenu_target,'String');
if ~iscell(targStr), targStr = {targStr}; end;
val = get(handles.popupmenu_target,'Value');
target = targStr{val};

modeStr = get(handles.popupmenu_mode,'String');
if ~iscell(modeStr), modeStr = {modeStr}; end;
val = get(handles.popupmenu_mode,'Value');
mode = modeStr{val};

setappdata(handles.ctrlwindow,'Target',target);
setappdata(handles.ctrlwindow,'Mode',mode);

ival = get(handles.popupmenu_interval,'Value');
switch ival
case 1, interval = 1;
case 2, interval = 5;
case 3, interval = 10;
case 4, interval = inf;
end;

runInfo.subject = subjstr;
runInfo.run = runstr;
runInfo.date = datestr(date,'mmm dd, yyyy');
runInfo.time = datestr(now,'HH:MM:SS PM');
runInfo.mode = mode;
runInfo.target = target;
runInfo.interval = interval;

conditions = handles.condStruct;

% Refresh the results display %
oldStr = get(handles.text_results,'String');
newStr = sprintf('****  SUBJECT: %s   RUN: %s      MODE: %s  -  "%s"       %s  ****', ...
  subjstr,runstr,mode,target,runInfo.time);
if ~isempty(oldStr)				% display beneath last series, if any
	newStr = cat(1,oldStr,{' ';' '},newStr);
end;

set(handles.text_results,'String',newStr);

% Set which subject interation GUI to open, based on "mode" %
switch mode
case 'Mouse Motion'
	LaunchGUI_Command = 'TrackSubject(target,conditions)';
	StartTrials_Command = 'TrackSubject(''TrackSubject_RunSeries'',hsubj)';

case 'Speech'
	switch target
	case 'Bobby Poppy'	% target type should be the entire sentence
		target = 'Buy Bobby A Poppy';
	case 'Dye Didi'
		target = 'Dye Didi A Tutu';
	end;

	LaunchGUI_Command = 'TrackSpeech(target,conditions)';
	StartTrials_Command = 'TrackSpeech(''TrackSpeech_RunSeries'',hsubj)';
end; % switch mode %

% Open and run the subject interaction GUI %
hsubj = eval(LaunchGUI_Command);	% open the new GUI window
set(hObject,'Enable','Off');		% turn off "Start" button and enable "Stop" button
set(handles.pushbutton_stop,'UserData',hsubj,'Enable','On');
setappdata(hsubj,'External','True');
								
assignin('base','runInfo',runInfo);	% update run information in the workspace
eval(StartTrials_Command);			% commence the trials, displaying results each time

% Read in the results and save as Excel and MATLAB files %
resultStruct = evalin('base','resultStruct');
set(hObject,'Enable','On');
set(handles.pushbutton_stop,'Enable','Off');

switch mode						% translate to Excel column format
case 'Mouse Motion'
	ExcelArray1 = resultStruct.condname';
	ExcelArray2 = [resultStruct.condtime' resultStruct.timetaken' resultStruct.rmserror' ...
	  resultStruct.timeviewing'];
	ExcelHeadings = {'Condition','Time Goal','Time Taken','RMS Error','Time Viewing'};
case 'Speech'
	ExcelArray1 = resultStruct.condname';
	ExcelArray2 = [resultStruct.condtime' resultStruct.timetaken' resultStruct.energy' ...
	  resultStruct.timeviewing'];
	ExcelHeadings = {'Condition','Time Goal','Time Taken','RMS Energy','Time Viewing'};
end;

ExcelInfo = {	sprintf('Subject: %s',runInfo.subject) ; 
				sprintf('Run/Type: %s',runInfo.run) ;
				sprintf('Date: %s',runInfo.date) ;
				sprintf('Time: %s',runInfo.time) ;
				''
				sprintf('Mode: %s',runInfo.mode) ;
				sprintf('Target: %s',runInfo.target) ;
				sprintf('Feedback Intvl: %d',runInfo.interval) ;
			};

savingpath = handles.savingpath;
if isempty(savingpath) && ischar(savingpath)
	savingpath = pwd;
end;
						% save results, to last used directory if known
savingxls = [subjstr '_' runstr '.xls'];
savingxls = fullfile(savingpath,savingxls);
[savingxls,savingpath] = uiputfile(savingxls, 'Save the results',savingxls);

saveCell = {'resultStruct','runInfo'};
if ischar(savingxls)
	[junk,savingmat] = fileparts(savingxls);
	savingmat = [savingmat '.mat'];
	save(fullfile(savingpath,savingmat),saveCell{:});
	xlswrite(fullfile(savingpath,savingxls),ExcelInfo,1,'A3');
	xlswrite(fullfile(savingpath,savingxls),ExcelHeadings,1,'C1');
	xlswrite(fullfile(savingpath,savingxls),ExcelArray1,1,'C3');
	xlswrite(fullfile(savingpath,savingxls),ExcelArray2,1,'D3');
	fprintf(1,'Saved tracking results to files %s and %s.\n',savingxls,savingmat);
else
	fprintf(1,'RESULTS NOT SAVED, but ''resultStruct'' is still in the workspace.\n');
end;

if ischar(savingpath)
	handles.savingpath = savingpath;
	guidata(hObject,handles);
end;


% -- As yet determined function to interrupt the interaction window -- %
function pushbutton_stop_Callback(hObject, eventdata, handles)

hsubj = get(hObject,'UserData');
setappdata(hsubj,'StopNow',true);


% -- Mode (e.g. mouse motion ,speech) determines the types of targets available -- %
function popupmenu_mode_Callback(hObject, eventdata, handles)

modeStr = get(hObject,'String');
if ~iscell(modeStr), modeStr = {modeStr}; end;
val = get(hObject,'Value');

switch modeStr{val}			% set target choices based on mode
case 'Mouse Motion'
	targetStr{1} = 'Horiz Sine';
	targetStr{2} = 'Vert Sine';

	tipstr = 'format = < [label] number >';
case 'Speech'
	targetStr{1} = 'Bobby Poppy';
	targetStr{2} = 'Dye Didi';

	tipstr = 'format = < [label] number >';
end;

set(hObject,'ToolTip',tipstr);
set(handles.popupmenu_target,'String',targetStr,'Value',1);

% setappdata(handles.ctrlwindow,'Mode',modeStr{val});
% setappdata(handles.ctrlwindow,'Target',targetStr{1});


% -- Target determines what motion or speech sounds to produce -- %
function popupmenu_target_Callback(hObject, eventdata, handles)

targetStr = get(hObject,'String');
if ~iscell(targetStr), targetStr = {targetStr}; end;
val = get(hObject,'Value');

% setappdata(handles.ctrlwindow,'Target',targetStr{val});


% -- Various uicontrol callbacks - some of these check validity of text entries -- %
function edit_subject_Callback(hObject, eventdata, handles)
							% enable "Start" button only when subject id has been given
set(handles.pushbutton_start,'Enable','On');


function popupmenu_interval_Callback(hObject, eventdata, handles)
									% force the "conditions" text field to update
popupmenu_conditions_Callback(handles.popupmenu_conditions,[],handles);


function checkbox_usebutton_Callback(hObject, eventdata, handles)
									% force the "conditions" text field to update
popupmenu_conditions_Callback(handles.popupmenu_conditions,[],handles);


% -- This contains the "habitual rate", and determines the tracking time objectives -- %
% If the string in this field is 'meas', it indicates that the habitual rate will be
%  obtained during the upcoming tracking experiment.
function edit_basetime_Callback(hObject, eventdata, handles)

str = get(hObject,'String');
if isempty(str2num(str))			% use last valid number if entry is bad
	set(hObject,'String',get(hObject,'UserData'));
else
	set(hObject,'UserData',str);	% store the last valid number
end;								  % (to recall for certain "Conditions" choices)
									% force the "conditions" text field to update
popupmenu_conditions_Callback(handles.popupmenu_conditions,[],handles);


% -- Choose the objective tracking times and the number of trials -- %
function popupmenu_conditions_Callback(hObject, eventdata, handles)

condtype = get(hObject,'Value');

switch condtype
case 1		% 10 practice trials, plus 2 each 2x and 3x trials

	set(handles.edit_basetime,'String','meas','Enable','Off');
	set(handles.popupmenu_interval,'Value',1);	% force feedback every trial .. 
	set(handles.checkbox_usebutton,'Value',1);	% .. and require button to resume
	set([handles.popupmenu_interval handles.checkbox_usebutton],'Enable','Off');

	set(handles.edit_conditions,'String',{'[1x] meas','[2x] calc','[3x] calc'});

 	condStruct = [];				% time codes: 0 = measure, -x = derive by scaling meas.
 	condStruct.times = [0 -2 -3];	 % NOTE: 0 codes MUST come before any negative ones
 	condStruct.labels = {'1x','2x','3x'};
	condStruct.colors = {[.17 .50 .34],'r','b'};
									% trial ordering = index into '.labels'
	condStruct.order = [1 1 1 1 1 1 1 1 1 1 2 2 3 3];
									% feedback codes: -1 = button press, 0 = don't display,
	condStruct.feedback = -1 * ones(1,14); % # = time to keep open in seconds

otherwise	% different numbers of 2x and 3x trials

	basetime = get(handles.edit_basetime,'String');
	basetime = str2num(basetime);
	if isempty(basetime)			% there must be a valid base time
		basetime = get(handles.edit_basetime,'UserData');
		set(handles.edit_basetime,'String',basetime);
		basetime = str2num(basetime);
	end;							% keep interval and button status as is
	set(handles.edit_basetime,'Enable','On');
	set([handles.popupmenu_interval handles.checkbox_usebutton],'Enable','On');

	times2 = sprintf('[2x] %.0f',basetime*2);
	times3 = sprintf('[3x] %.0f',basetime*3);
	set(handles.edit_conditions,'String',{times2,times3});

 	condStruct = [];				% times here are just taken from text box
 	condStruct.times = [basetime*2 basetime*3];
 	condStruct.labels = {'2x','3x'};
	condStruct.colors = {'r','b'};

	switch condtype					% randomize the ordering
	case 2,	nTrialPer = 30;
	case 3, nTrialPer = 10;
	case 4, nTrialPer = 1;
	end;
	alltrials = kron([1 2],ones(1,nTrialPer));
	nTrial = length(alltrials);
	ridx = randperm(nTrial);
	condStruct.order = alltrials(ridx);

	ival = get(handles.popupmenu_interval,'Value');
	switch ival						% get feedback interval (# trials b/w updates)
	case 1, interval = 1;
	case 2, interval = 5;
	case 3, interval = 10;
	case 4, interval = inf;
	end;

	bval = get(handles.checkbox_usebutton,'Value');
	if bval, fbval = -1;			% time to display feedback is either 5 seconds
	else fbval = handles.fbtime;	  % or, if button is required, indefinitely (code = -1)
	end;

	fbind = false(1,nTrial); fbvec = zeros(1,nTrial);
	fbind(mod(1:nTrial,interval)==0) = true;
	if interval ~= inf				% usually plot is made after the very last trial
		fbind(nTrial) = true;
	end;
	fbvec(fbind) = fbval;
	condStruct.feedback = fbvec;
end;

handles.condStruct = condStruct;
guidata(hObject,handles);


% -- Handle an attempt to close the GUI figure -- %
% Prevents accidental closure of the GUI window.
function TrackControl_CloseFcn(hfigure)

query = questdlg('Do you wish to close the Control window?', 'Close Request', 'No');
if strcmp(query,'Yes')
	hwin = getappdata(hfigure,'DisplayWindow');
	if ~isempty(hwin) && ismember(hwin,findall(0,'Tag','DisplayWindow'));
		close(hwin);
	end;
	closereq;						% then close the main figure
end;




%%%% OLD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% function edit_conditions_Callback(hObject,eventdata,handles)
% 
% modeStr = get(handles.popupmenu_mode,'String');
% if ~iscell(modeStr), modeStr = {modeStr}; end;
% val = get(handles.popupmenu_mode,'Value');
% 
% condStr = get(handles.edit_conditions,'String');
% nCond = length(condStr);
% 
% valid = true;				% keep track of each cond entry's validity ..
% 
% switch modeStr{val}		% .. which may depend on the run mode (but doesn't now)
% case {'Mouse Motion','Speech'}
% condvec = zeros(1,nCond);
% labelStr = cell(1,nCond);
% 
% for i = 1:length(condStr)	% parse each condition entry into a label and number
% 	l1 = strfind(condStr{i},'[');
% 	l2 = strfind(condStr{i},']');
% 	if isempty(l1) || isempty(l2)  || l2 < l1
% 		warndlg('Invalid label','Entry error','modal');
% 		valid = false; break;
% 	else
% 		labelStr{i} = condStr{i}(l1+1:l2-1);
% 	end;
% 
% 	c1 = l2 + 1;
% 	c2 = length(condStr{i});
% 	if isempty(c1) || isempty(c2)
% 		warndlg('Invalid value','Entry error','modal');
% 		valid = false;
% 	else
% 		condval = str2num(condStr{i}(c1:c2));
% 		if isempty(condval)
% 			warndlg('Invalid value','Entry error','modal');
% 			valid = false;
% 		else
% 			condvec(i) = condval;
% 		end;
% 	end;
% end; % for i %
% 
% if ~valid					% revert to last valid entry
% 	set(hObject,'String',get(hObject,'UserData'));
% else
% 	handles.condStruct = [];
% 	handles.condStruct.conds = condvec;
% 	handles.condStruct.labels = labelStr;
% 
% 	guidata(hObject,handles);
% end;
% 
% end; % switch modeStr %

