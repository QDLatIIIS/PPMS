%% connect VNA and PPMS
addpath(genpath(pwd))
NET.addAssembly('C:\Users\IIIS\Documents\MATLAB\PPMS\QDInstrument.dll');
ppms = PPMS;

vna = E5071C;

%% Normal temperature sweep and then cool down.
[freqs, trace] = vna.manualSweep('start',1e9,'stop',10e9,'res',1e5, 'points',1601,'pow',-10,'avg',1,'notes','_normal_temp');
ppms.setTemp(10,'tempRate',10,'tempApproach','FastSettle');
pause(20*60);

%10K sweep and 2K sweep
while ~strcmp(ppms.tempStatusStr,'Stable')
    pause(10);
end
disp('Temperature is stable now.');
[freqs, trace] = vna.manualSweep('start',5e9,'stop',7e9,'res',500e3, 'points',1000,'pow',-10,'avg',10,'notes','_temp_10K');

ppms.setTemp(2,'tempRate',1,'tempApproach','NoOvershoot');
while ~strcmp(ppms.tempStatusStr,'Stable')
    pause(10);
end
disp('Temperature is stable now.');
[freqs, trace] = vna.manualSweep('start',1e9,'stop',10e9,'res',1e5, 'points',1601,'pow',-10,'avg',1,'notes','_temp_2K');

pause(1);

[freqs, trace] = vna.manualSweep('center',4.2121e9,'span',4e6,'res',4e3, 'points',1000,'pow',-10,'avg',1);
vna.fit('fitall',true);

pause(1);
[freqs, trace] = vna.manualSweep('center',4.6502e9,'span',4e6,'res',4e3, 'points',1000,'pow',-10,'avg',1);
vna.fit('fitall',true);

pause(1);
[freqs, trace] = vna.manualSweep('center',5.0992e9,'span',4e6,'res',4e3, 'points',1000,'pow',-10,'avg',1);
vna.fit('fitall',true);

pause(1);
[freqs, trace] = vna.manualSweep('center',5.5419e9,'span',20e6,'res',20e3, 'points',1000,'pow',-10,'avg',1);
vna.fit('fitall',true);

pause(1);
[freqs, trace] = vna.manualSweep('center',5.9722e9,'span',4e6,'res',4e3, 'points',1000,'pow',-10,'avg',1);
vna.fit('fitall',true);

pause(1);
[freqs, trace] = vna.manualSweep('center',6.4017e9,'span',4e6,'res',4e3, 'points',1000,'pow',-10,'avg',1);
vna.fit('fitall',true);

pause(1);
%
% [freqs, trace] = vna.manualSweep('center',6.638e9,'span',8e6,'res',8e3, 'points',1000,'pow',-10,'avg',1);
% vna.fit('fitall',true);
%
% pause(1);
%
% [freqs, trace] = vna.manualSweep('center',5.717e9,'span',30e6,'res',30e3, 'points',1000,'pow',-10,'avg',1);
% vna.fit('fitall',true);

%% temp sweep
pause(1);
config =vna.getConfig;

[tempStableTmr,setTempTmr] = TempSweep(ppms,vna,[linspace(2,10,50),linspace(10,2,50)]);

while ~(strcmp(tempStableTmr.Running,'off')&&strcmp(setTempTmr,'off'))
    pause(10);
end


delete(tempStableTmr)
delete(setTempTmr)
clear tempStableTmr
clear setTempTmr
%% field sweep

pause(1);
config = vna.getConfig;

[fldStableTmr, setFldTmr] = FieldSweep(ppms,vna,[linspace(0,25000,30),linspace(25000,0,30)]);
while ~(strcmp(fldStableTmr.Running,'off')&&strcmp(setFldTmr,'off'))
    pause(10);
end


delete(tempStableTmr)
delete(setTempTmr)
clear tempStableTmr
clear setTempTmr

%warm up and cool down
t1=clock;
disp('Temperature is changing.');
ppms.setTemp(30,'tempRate',20,'tempApproach','FastSettle');
while ~strcmp(ppms.tempStatusStr,'Near')
    pause(10);
end
disp('Temperature is 30K now.');
pause(60);%wait for the system to be stable
disp('Temperature is changing.');
ppms.setTemp(2,'tempRate',5,'tempApproach','NoOvershoot');
while ~strcmp(ppms.tempStatusStr,'Stable')
    pause(10);
end
disp('Temperature is 2K now.');
pause(60);%wait for the system to be stable
t2=clock;
timecost=etime(t2,t1)/60;
%% high/middle/low power


[freqs, trace] = vna.manualSweep('center',6.5725e9,'span',5e6,'res',5e3, 'points',1000,'pow',-60,'avg',500);
vna.fit('fitall',true);

pause(1);

[freqs, trace] = vna.manualSweep('center',5.717e9,'span',30e6,'res',30e3, 'points',1000,'pow',5,'avg',1);
vna.fit('fitall',true);

pause(1);

[freqs, trace] = vna.manualSweep('center',5.717e9,'span',30e6,'res',30e3, 'points',1000,'pow',-30,'avg',50);
vna.fit('fitall',true);

pause(1);

[freqs, trace] = vna.manualSweep('center',5.717e9,'span',30e6,'res',30e3, 'points',1000,'pow',-70,'avg',500);
vna.fit('fitall',true);

pause(1);



%% continuous high power sweep
[freqs, pows, SParams] = VNAPowerSweep(vna,'minPow',-4,'maxPow',5,'numOfPowers',10,'maxAvg',2,'config',config,'notes','_S12');
config.meas = 'S11';
pause(1);
[freqs, pows, SParams] = VNAPowerSweep(vna,'minPow',-4,'maxPow',5,'numOfPowers',10,'maxAvg',2,'config',config,'notes','_S11');
config.meas = 'S12';
vna.meas = 'S12';
pause(1);
%% low power sweep
pause(1);
[freqs, trace] = vna.manualSweep('center',4.2121e9,'span',4e6,'res',4e3, 'points',1000,'pow',-10,'avg',1,'notes','_run_before_power_sweep');
vna.fit('fitall',true);
config =vna.getConfig;
pause(1);

config.ifbw=5;

[freqs, pows, SParams] = VNAPowerSweep(vna,'minPow',-50,'maxPow',-40,'numOfPowers',4,'maxAvg',400,'config',config);

%% continuous power sweep
[freqs, trace] = vna.manualSweep('center',4.2121e9,'span',4e6,'res',4e3, 'points',1000,'pow',-10,'avg',1,'notes','_run_before_power_sweep');
vna.fit('fitall',true);
config =vna.getConfig;
config.ifbw=100;
[freqs, pows, SParams] = VNAPowerSweep(vna,'minPow',-18,'maxPow',-0,'numOfPowers',10,'maxAvg',400,'config',config);

%% B=30000Oe=3T -> B=0T -> wait for 10 minuetes -> T=30K -> T=2K

vna.clearAvg;
[freqs, trace] = vna.manualSweep('center',4.2121e9,'span',4e6,'res',4e3, 'points',1000,'pow',-10,'avg',1,'notes','_before_changing_B');
vna.fit('fitall',true);

pause(1);

ppms.setField(30000,'fieldRate',200,'fieldApproach','Linear');
pause(10);
while ~strcmpi(ppms.fieldStatusStr,'StableDriven')
    pause(10);
end
disp('Field is stable now.');

vna.clearAvg;

[freqs, trace] = vna.manualSweep('center',4.2121e9,'span',4e6,'res',4e3, 'points',1000,'pow',-10,'avg',1,'notes','_3T');
vna.fit('fitall',true);

pause(1);

ppms.setField(0,'fieldRate',200,'fieldApproach','Linear');
pause(10);
while ~strcmpi(ppms.fieldStatusStr,'StableDriven')
    pause(10);
end
disp('Field is stable now.');
vna.clearAvg;
[freqs, trace] = vna.manualSweep('center',4.2021e9,'span',4e6,'res',4e3, 'points',1000,'pow',-10,'avg',1,'notes','_0T');
vna.fit('fitall',true);

pause(600);

vna.clearAvg;

[freqs, trace] = vna.manualSweep('center',4.2021e9,'span',4e6,'res',4e3, 'points',1000,'pow',-10,'avg',1,'notes','_after_waiting');
vna.fit('fitall',true);

pause(1);

ppms.setTemp(30,'tempRate',4,'tempApproach','NoOvershoot');
while ~strcmp(ppms.tempStatusStr,'Stable')
    pause(10);
end
disp('Temperature is stable now.');

vna.clearAvg;
[freqs, trace] = vna.manualSweep('center',4.2021e9,'span',4e6,'res',4e3,'points',1000,'pow',-10,'avg',1,'notes','_20K');
vna.fit('fitall',true);

pause(1);

ppms.setTemp(2,'tempRate',4,'tempApproach','NoOvershoot');
while ~strcmp(ppms.tempStatusStr,'Stable')
    pause(10);
end
disp('Temperature is stable now.');

vna.clearAvg;

[freqs, trace] = vna.manualSweep('center',4.2121e9,'span',4e6,'res',4e3, 'points',1000,'pow',-10,'avg',1,'notes','_recooldown');
vna.fit('fitall',true);

pause(1);


%% sweep at 0 Oe and 200 Oe
fields = [linspace(400,2000,5),linspace(2000,0,6)];

% [freqs, trace] = vna.manualSweep('start',1e9,'stop',10e9,'res',5e5,...
%             'points',1601,'pow',-10,'avg',50);
for ii = 1:length(fields)
    fld = fields(ii);
    ppms.setField(fld,'fieldRate',200,'fieldApproach','Linear');
    while ~strcmpi(ppms.fieldStatusStr,'StableDriven')
        pause(10);
    end
    [freqs, trace] = vna.manualSweep('start',1e9,'stop',10e9,'res',1e6,...
        'points',1601,'pow',-10,'avg',50,'notes',sprintf('_field_%.1fOe',fld));
end
%% plot field large range sweep data
fields = [400,800,1200,1600,2000];
figure;
hold all;
for ii = 1:length(fields)
    load(sprintf('start_1.00GHz_stop_10.61GHz_res_1.00MHz_pow_-10dBm_AVG_50_field_%.1fOe.mat',...
        fields(ii)));
    plot(freqs/1e9,20*log10(abs(trace.X+1i*trace.Y)));
end





