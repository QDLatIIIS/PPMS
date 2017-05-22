% scripts for field sweep plot & data process
%
% For running by section (shortcut: Ctrl + Enter) as needed
%
% Wentao, May 2017
%

%% clear timer

delete(setFldTmr);
delete(fldStableTmr);
clear setFldTmr;
clear fldStableTmr;

%% load data
fname = uigetfile;
load(fname);

%% colormap
hfig_clmp = figure;
[~,maxInd] = max(setFields);
contourf(freqs/1e9,[linspace(actualFields(1),actualFields(maxInd),maxInd),...
            linspace(actualFields(maxInd+1),2*actualFields(maxInd+1)-actualFields(end),...
            length(actualFields) - maxInd)],...
        20*log10(abs(SParams)),20,'edgecolor','none');
xlabel frequency/GHz;
ylabel(sprintf('B field, from %.1f Oe to %.01f Oe to %.1f Oe',...
                actualFields(1), max(actualFields),actualFields(end)));
title(sprintf('Field Sweep %s', datestr(timeStamps(1),30) ) );
hold off;


%% line plot
% parameter
lineIndStep = 1;

%
hfig_lp = figure;
hold all
lgds = {};
for ii = 1:lineIndStep:length(setFields)
    plot(freqs, 20*log10(abs(SParams(ii,:) ) ) );
    lgds{end+1} = sprintf('field = %.1f', actualFields(ii));
end
xlabel frequency/GHz;
ylabel S21/dB;
title(sprintf('Field Sweep Horizontal Line plot %s', datestr(timeStamps(1),30) ) ); 
legend(lgds{:});
hold off;

%% vertical line plot (i.e., S parameter vs field)
% parameter
lineIndStep = 10;

%
hfig_vlp = figure;
hold all;
lgds = {};
[~,maxInd] = max(setFields);
for ii = 1:lineIndStep:length(freqs)
    plot([linspace(actualFields(1),actualFields(maxInd),maxInd),...
            linspace(actualFields(maxInd+1),2*actualFields(maxInd+1)-actualFields(end),...
            length(actualFields) - maxInd)],...
            20*log10(abs(SParams(:,ii) ) ) );
    lgds{end+1} = sprintf('frequency = %.4f', freqs(ii)/1e9);
end
xlabel field/Oe;
ylabel S21/dB;
title(sprintf('Field Sweep Vertical Line plot %s', datestr(timeStamps(1),30) ) );
legend(lgds{:});
hold off;

%% fit

