% TRACKCONTROL_PLOTFEEDBACK.M
%

function varargout = TrackControl_PlotFeedback(haxis,condStruct,action,timetaken,lastplot)

% ColorOrder = {[.17 .50 .34],'r','b','m','k'};

if nargin < 4, timetaken = []; end;
if nargin < 5, lastplot = 0; end;

nTrial = length(condStruct.order); nGroup = length(condStruct.labels);
fbgoal = condStruct.times;

switch action
case 'Setup'
	yrng = [min(fbgoal)*0.5 max(fbgoal)*1.5];
	xrng = [0.2 max(nTrial+0.2,5.2)];
	if nTrial < 20						% set the x-axis tick spacing approp  riately
		xticks = 1:max(nTrial,5);
	elseif nTrial < 50
		xticks = 1:2:nTrial;
	elseif nTrial < 100
		xticks = 1:5:nTrial;
	else
		xticks = 1:10:nTrial;
	end;

	set(haxis,'Visible','Off');
	set(haxis,'XLim',xrng,'XTick',xticks,'YLim',yrng,'YTick',[]);
	axes(haxis);						% change to and clear the feedback pane
	cla;

case 'Lines'
	axes(haxis); 
	xrng = xlim; yrng = ylim;

	hgoal = zeros(1,length(fbgoal));	% .. and plot lines at each condition time
	hgoal_text = zeros(1,length(fbgoal));
	for i = 1:length(fbgoal)
	  if fbgoal>0
% 		if i <= length(ColorOrder), col = ColorOrder{i}; else col = 'k'; end;
		col = condStruct.colors{i};
		hgoal(i) = line([xrng(1) xrng(2)],[fbgoal(i) fbgoal(i)],'Color',col);
		str = condStruct.labels{i};
		hgoal_text(i) = text(0.3,fbgoal(i),str,'Color',col);

		idx = find(condStruct.order == i);
	  end;
	end;

	set(hgoal(find(hgoal)),'LineStyle',':','LineWidth',1.5);
	set(hgoal_text(find(hgoal_text)),'VerticalAlignment','Bottom','FontSize',24);

	yrng(2) = max([yrng(2) fbgoal*1.10]);
	set(haxis,'YLim',yrng);

	varargout{1} = hgoal; varargout{2} = hgoal_text;

case 'Data'
	axes(haxis);					% current trial is the last non-zero one
	tr = find(timetaken); tr = tr(end);

	for gg = 1:nGroup
									% overwrite just the points for the current group
	  idx = find(condStruct.order(1:tr)==gg);
	  if ~isempty(idx)				% color depends on the trial condition
% 		if gg <= length(ColorOrder), col = ColorOrder{gg}; else col = 'k'; end;
		col = condStruct.colors{gg};
		hnew = plot(idx,timetaken(idx),'Marker','s','LineStyle','none');
		set(hnew,'MarkerSize',14,'MarkerFaceColor',col,'MarkerEdgeColor','none');
	  end; % if ~isempty %

	end; % for gg %

	idx = lastplot+1:tr;				% highlight the latest data points (regardless of group)
	hlast = plot(idx,timetaken(idx),'Marker','o','LineStyle','none');
	set(hlast,'MarkerSize',18,'MarkerFaceColor','none','MarkerEdgeColor','k');

	yrng = get(haxis,'YLim');		% adjust y-axis range, if necessary
	if max(timetaken(1:tr)) > max(yrng)
		yrng(2) = 1.05*max(timetaken(1:tr));
	end;
	if min(timetaken(1:tr)) < min(yrng)
		yrng(1) = 0.95*min(timetaken(1:tr));
	end;
	set(gca,'YLim',yrng);

	varargout{1} = hlast;

end;