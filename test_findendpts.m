
AUDIO_SAMPLINGRATE = 44100;
AUDIO_CHECKPERIOD = 0.25;
AUDIO_CHECKRMSUP = .005;
AUDIO_MINEVENT = .05;

wavdata = filter([0.998933 -0.998933],[1 -0.997865],wavdata);

ethr = AUDIO_CHECKRMSUP;			% initial energy threshold
eskip = 0.1 * AUDIO_SAMPLINGRATE;	% ignore first 100 msec of data
fdur = 0.01 * AUDIO_SAMPLINGRATE;
mindur = AUDIO_MINEVENT * AUDIO_SAMPLINGRATE;

fwin = ones(1,fdur) / fdur;			% a 10-msec averaging filter
fdata = sqrt( filter(fwin,1,wavdata.^2) );

if ~any(fdata>ethr)
	endpts = [1 length(wavdata)];
	return;
end;

pt0 = find(fdata(eskip+1:end)>ethr);
pt0 = pt0(1) + eskip;				% establish a noise baseline
fsub = fdata(eskip:pt0-1);
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
upstarts = upidxd(updiff>1);
upends = upstarts - updiff(updiff>1);
upstarts = [upidx(1) ; upstarts];
upends = [upends ; upidx(end)];
									% find starting point
pt1idx = find(upends-upstarts > mindur);
pt1a = upstarts(pt1idx); pt1a = pt1a(pt1a>eskip); pt1a = pt1a(1);
pt1 = find(fdata(1:pt1a-1)<2*rmsbase);
pt1 = pt1(end);
									% find ending point
pt2idx = find(upends-upstarts > mindur);
pt2a = upends(pt2idx); pt2a = pt2a(end);
pt2 = find(fdata(pt2a+1:end)<2*rmsbase);
if ~isempty(pt2)
	pt2 = pt2(1) + pt2a;
else
	pt2 = length(wavdata);
end;

endpts = [pt1 pt2];					% length in samples of speech (cut) portion
% endpts = endpts + round(fdur/2);	% (correcting for rms filter length)

figure;
plot(wavdata); hold;
plot(fdata,'r:');
line([endpts(1) endpts(1)],ylim,'Color','r','LineStyle',':');
line([endpts(2) endpts(2)],ylim,'Color','r','LineStyle',':');
