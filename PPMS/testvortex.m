%sweep, then rise magnetic field to a max field and change field back to
%zero and sweep again. Warm up then cool down to test another magnetic
%field.
t1=clock;
% maxfield=linspace(0,100,65)+0.7813;
% maxfield=70.7077:0.7813:(0.3907+0.7813*100);
maxfield=linspace(0,15,65);
notes=datestr(now,30);
sweepconfig=struct('center',4.2080e9,'span',20e6,'res',5e3, 'points',1000,'pow',0,'avg',1);
% sweepconfig1=struct('center',4.2017e9,'span',4e6,'res',4e3, 'points',1000,'pow',-10,'avg',1);
[freqs, trace] = vna.manualSweep(sweepconfig,'issavedata',false,'notes','_test');

numfield=numel(maxfield);
SParamsbefore=zeros(numfield,numel(trace.X));
Paramsbefore=zeros(numfield,4);
SParamsafter=zeros(numfield,numel(trace.X));
Paramsafter=zeros(numfield,4);
disp(['estimated time: ',num2str(13.75*numfield/60),'h']);
for i=1:numfield
    %sweep before changing the field
    vna.clearAvg;
    [freqs, trace] = vna.manualSweep(sweepconfig,'issavedata',false,'notes','_before');
    SParamsbefore(i,:) = trace.X+1i*trace.Y;
    [ f_r,Q_i,Q_c,Q_l ] = vna.fit('fitall',true,'issavefig',false,...
        'xdata',freqs/1e9,'ydata',20*log10(abs(SParamsbefore(i,:))),...
        'titleNotes',sprintf('_before_maxfield_%dOe',maxfield(i)) );
    Paramsbefore(i,1) = f_r;
    Paramsbefore(i,2) = Q_i;
    Paramsbefore(i,3) = Q_c;
    Paramsbefore(i,4) = Q_l;
    
    %change the field
    disp('Field is changing.');
    ppms.setField(maxfield(i),'fieldRate',maxfield(i)/10,'fieldApproach','Linear');
    pause(10);
    while ~strcmpi(ppms.fieldStatusStr,'StableDriven')
        pause(2);
    end
    disp(['Field is ', num2str(maxfield(i)) ,'Oe now.']);
    disp('Field is changing.');
    ppms.setField(0,'fieldRate',maxfield(i)/10,'fieldApproach','Linear');
    pause(10);
    while ~strcmpi(ppms.fieldStatusStr,'StableDriven')
        pause(2);
    end
    disp('Field is 0Oe now.');
    pause(60);%wait for the system to be stable
    %sweep after changing the field
    vna.clearAvg;
    [freqs, trace] = vna.manualSweep(sweepconfig,'issavedata',false,'notes','_after');
    SParamsafter(i,:) = trace.X+1i*trace.Y;
    [ f_r,Q_i,Q_c,Q_l ] = vna.fit('fitall',true,'issavefig',false,...
        'xdata',freqs/1e9,'ydata',20*log10(abs(SParamsafter(i,:))),...
        'titleNotes',sprintf('_after_maxfield_%dOe',maxfield(i)) );
    Paramsafter(i,1) = f_r;
    Paramsafter(i,2) = Q_i;
    Paramsafter(i,3) = Q_c;
    Paramsafter(i,4) = Q_l;
    
    %warm up and cool down
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
    pause(30);%wait for the system to be stable
    
end
t2=clock;
timecost=etime(t2,t1)/60;
save(sprintf('Vortexsweep_start_%.4fGHz_stop_%.4fGHz_min_%.3fOe_max_%.3fOe%s.mat',...
                min(freqs)/1e9,max(freqs)/1e9,min(maxfield),max(maxfield),notes),...
    'maxfield','freqs','SParamsbefore','SParamsafter','Paramsbefore','Paramsafter','sweepconfig');

figure;
plot(maxfield,(Paramsafter(:,1)-Paramsbefore(:,1))/1e9);
xlabel maxfield/Oe
ylabel fr/GHz

figure;
plot(maxfield,(Paramsbefore(:,1))/1e9);
xlabel maxfield/Oe
ylabel fr/GHz

figure;
plot(maxfield,(Paramsafter(:,1))/1e9);
xlabel maxfield/Oe
ylabel fr/GHz

figure;
contourf(freqs,maxfield,20*log10(abs(SParamsafter)),'edgecolor','none');
colorbar();
