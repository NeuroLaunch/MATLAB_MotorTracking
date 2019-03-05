
% Choose a file to process %
if ~exist('filepath','var') || filepath(1)==0,
	filepath = pwd; filepath_last = pwd;
else filepath_last = filepath;
end;
[inputfile,filepath] = uigetfile('*.mat', 'Choose a Spike2-generated MATLAB file to open.',filepath);

if ~inputfile					% stop execution if no file chosen
	filepath = filepath_last;
	return;
end;
wLoad = load(fullfile(filepath,inputfile),'runInfo','resultStruct');

if ~isfield(wLoad,'runInfo') || ~isfield(wLoad,'resultStruct')
	error('Error loading speech tracking data: one or more MATLAB variables not found.');
end;
runInfo = wLoad.runInfo;
resultStruct = wLoad.resultStruct;
clear wLoad;

% Prompt user for which trial or trials to convert %
nTrial = length(resultStruct.wavdata);
listStr = cell(1,nTrial);
for i = 1:nTrial				% make a list of all available trials
	listStr{i} = sprintf('%d: %s',i,resultStruct.condname{i});
end;
if nTrial < 10					% tailor message window size to # of trials
	sizevec = [160 150];
elseif nTrial < 20
	sizevec = [160 150];
else
	sizevec = [160 300];
end;
								% prompt the user for the trials to convert
qtrials = listdlg('PromptString','Choose one or more trials to convert',...
  'ListString',listStr,'ListSize',sizevec);

if isempty(qtrials)
	fprintf(1,'No trials chosen. Conversion cancelled.\n');
	return;
end;

% Convert the chosen trial or trials %
dirstr = sprintf('wav_%s',runInfo.run);
savepath = fullfile(filepath,dirstr,[]);
if ~exist(savepath,'dir')		% determine the name of the directory for writing
	dirstatus = mkdir(savepath);
else
	query = questdlg('The directory exists. Overwrite previous .wav files?','','Yes');
	if ~strcmp(query,'Yes')
		fprintf(1,'No directory chosen. Conversion cancelled.\n');
		return;
	end;
end;

wstatus = true;					% write the actual .wav file or files
for q = qtrials
	savefile = sprintf('trial%02d',q);
	wavwrite(resultStruct.wavdata{q},44100,fullfile(savepath,savefile));
	if max(abs(resultStruct.wavdata{q})>1) && wstatus
		warning('Some data points were clipped for one or more trials.');
		wstatus = false;
	end;
end;

fprintf(1,'%d wav files written to directory %s\n',length(qtrials),savepath);
