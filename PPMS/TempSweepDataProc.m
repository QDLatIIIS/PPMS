% scripts for temperature sweep plot & data process
%
% For running by section (shortcut: Ctrl + Enter) as needed
%
% Wentao, May 2017
%

%% clear timer
delete(setTempTmr);
delete(tempStableTmr);
clear setTempTmr;
clear tempStableTmr;

%% load data
fname = uigetfile;
load(fname);

%% colormap
hfig_clmp = figure;
[~,maxInd] = max(setTemps);
double_direction_sweep=1;
if double_direction_sweep
contourf(freqs/1e9,[linspace(actualTemps(1),actualTemps(maxInd),maxInd),...
            linspace(actualTemps(maxInd+1),2*actualTemps(maxInd+1)-actualTemps(end),...
            length(actualTemps) - maxInd)],...
        20*log10(abs(SParams)),20,'edgecolor','none');
else
    contourf(freqs/1e9,actualTemps,...
        20*log10(abs(SParams)),20,'edgecolor','none');
end
xlabel frequency/GHz;
ylabel(sprintf('Temperature, from %.1f K to %.1f K to %.1f K',...
                actualTemps(1), max(actualTemps),actualTemps(end)));
title(sprintf('Temperature Sweep %s', datestr(timeStamps(1),30) ) );
colorbar('location','eastoutside')

hold off;
saveas(hfig_clmp,sprintf('Temperature_Sweep_%s.png',datestr(timeStamps(end),30)));
% saveas(hfig_clmp,sprintf('Temperature_Sweep_%s.fig',datestr(timeStamps(end),30)));


%% line plot
% parameter
lineIndStep = 20;

%
hfig_lp = figure;
hold all
lgds = {};
for ii = 1:lineIndStep:length(setTemps)
    plot(freqs, 20*log10(abs(SParams(ii,:) ) ) );
    lgds{end+1} = sprintf('field = %.1f', actualTemps(ii));
end
xlabel frequency/GHz;
ylabel S21/dB;
title(sprintf('Temperature Sweep Horizontal Line plot %s', datestr(timeStamps(1),30) ) ); 
legend(lgds{:});
hold off;

%% vertical line plot (i.e., S parameter vs field)
% parameter
lineIndStep = 100;

%
hfig_vlp = figure;
hold all;
lgds = {};
[~,maxInd] = max(setTemps);
for ii = 1:lineIndStep:length(freqs)
    plot([linspace(actualTemps(1),actualTemps(maxInd),maxInd),...
            linspace(actualTemps(maxInd+1),2*actualTemps(maxInd+1)-actualTemps(end),...
                length(actualTemps) - maxInd)],...
            20*log10(abs(SParams(:,ii) ) ) );
    lgds{end+1} = sprintf('frequency = %.4f', freqs(ii)/1e9);
end
xlabel field/Oe;
ylabel S21/dB;
title(sprintf('Temperature Sweep Vertical Line plot %s', datestr(timeStamps(1),30) ) );
legend(lgds{:});
hold off;
saveas(hfig_vlp,sprintf('Temperature_Sweep_Vertical_Line_plot_%s.png', datestr(timeStamps(1),30)))

%% fit

