classdef E5071C < handle
    % E5071C describe and control the agilent E5071C ENA
    %
    % EXAMPLES (assume instance named 'vna'):
    %   initialization:
    %       vna = E5071C;
    %       vna = E5071C('address',8,'InputBufferSize',100000);
    %   set & get parameters
    %       % fetch & return the start frequency:
    %       freq = vna.freqStart;
    %       % fetch & return the IFBW:
    %       bw = vna.ifbw;
    %       % set the stop frequency to 5GHz:
    %       vna.freqStop = 5e9;
    %       % set the number of average and turn on averaging:
    %       vna.avg = 999;
    %   fetch trace:
    %       % fetch the trace data, return a structure
    %       trace = vna.trace
    %
    %   See E5071C/plotTrace, E5071C/fit and E5071C/manualSweep for detail usage
    %
    %   Wentao, April 2017
    %
    
    properties (Constant)
        MAX_POINTS = 1601;
        MAX_AVG = 999;
        
    end

    properties
        visa
        InputBufferSize
        TimeOut
        
        address
        
        % properties with set & get methods
        freqStart
        freqStop
        freqSpan
        freqCenter        
        avg
        numOfPoints
        ifbw
        meas        
        outp
        power
        trigMode
        
        trace
        
        freqs
        h_fig       % figure handle
    end
    
    methods
        
        function obj = E5071C(varargin)
            % Initialize E5071C object
            %
            p = inputParser;
            p.addParameter('address',6, @isnumeric);        % GPIB address
            p.addParameter('InputBufferSize',30000, @isnumeric);
            p.addParameter('TimeOut',20, @isnumeric);
            p.parse(varargin{:});
            expandStructure(p.Results);
            
            obj.address = address;
            obj.TimeOut = TimeOut;
            obj.InputBufferSize = InputBufferSize;
            
            obj.visa = visa('agilent',sprintf('GPIB::%d::INSTR',obj.address));
            fprintf('%s\nConnected.\n',obj.read('*IDN?','%s'));
            set(obj.visa,'InputBufferSize', obj.InputBufferSize);
            set(obj.visa,'TimeOut', obj.TimeOut);
            % Set byte order to swapped (little-endian) format  
            fprintf('Set byte order to little-endian...');
            obj.write(':FORMAT:BORD SWAP');
            fprintf('Done.\n')
            % Set data type to real 64 bit binary block 
            fprintf('Set data type to real 64 bit binary block...');
            obj.write(':FORMAT:DATA REAL');
            fprintf('Done.\n');
        end
        
        function delete(obj)
            delete(obj.visa);
        end
        
        %% frequency set & get
        function value = get.freqStart(obj)
            value = obj.read(':sens:freq:star?', '%f');
        end
        function set.freqStart(obj,val)
            obj.write(':sens:freq:star %f',val);
        end
        function value = get.freqStop(obj)
            value = obj.read(':sens:freq:stop?', '%f');
        end
        function set.freqStop(obj,val)
            obj.write(':sens:freq:stop %f',val);
        end
        function value = get.freqCenter(obj)
            value = obj.read(':sens:freq:cent?', '%f');
        end
        function set.freqCenter(obj,val)
            obj.write(':sens:freq:cent %f',val);
        end
        function value = get.freqSpan(obj)
            value = obj.read(':sens:freq:span?','%f');
        end
        function set.freqSpan(obj,val)
            obj.write(':sens:freq:span %f', val);
        end
        
        %% sweep setup: measurement parameter, points, average, ifbw
        function value = get.meas(obj)
            value = obj.read(':CALC:PAR:DEF?', '%s');
        end
        function set.meas(obj, val)
            obj.write(':CALC:PAR:DEF %s', val);
        end
        function value = get.numOfPoints(obj)
            value = obj.read(':sens:swe:poin?', '%f');
        end
        function set.numOfPoints(obj, val)
            obj.write( ':sens:swe:poin %d', val);
        end
        
        function value = get.avg(obj)
            value = obj.read( ':sens:aver:count?', '%f');
        end
        function set.avg(obj, val)
            obj.write( ':sens:aver:count %d', val);
            obj.write(':SENSe:AVERage:STATe 1');
        end        
        function clearAvg(obj)
            obj.write(':SENSe:AVERage:CLE');
        end
        
        function value = get.ifbw(obj)
            value = obj.read(':sens:BWID:RES?', '%f');
        end
        function set.ifbw(obj, val)
            obj.write( ':sens:BWID:RES %f', val);
        end
        
        function val = sweepTime(obj)
            val = obj.read('SENS:SWE:TIME:DATA?','%f');
        end
        
        
        %% output & trigger
        function value = get.power(obj)
            value = obj.read(':SOURce:POWer:LEVel:IMMediate:AMPLitude?', '%f');
        end
        function set.power(obj, val)
            obj.write(':SOURce:POWer:LEVel:IMMediate:AMPLitude %d', val);
        end
        function value = get.outp(obj)
            value = obj.read(':OUTP:STATe?', '%f');
        end
        function set.outp(obj, val)
            obj.write(':OUTP:STATe %d', val);
        end
        function value = get.trigMode(obj)
            value = obj.read(':TRIG:SEQ:SOUR?','%s');
        end
        function set.trigMode(obj, val)
            % set.trigMode sets trigger mode
            %   available options: 'INT', 'EXT', 'MAN', 'BUS'
            %     Internal Trigger
            %     Uses the internal trigger to generate continuous triggers automatically.
            % 
            %     External Trigger
            %     Generates a trigger when the trigger signal is inputted externally via the Ext Trig connector or the handler interface.
            % 
            %     Manual Trigger
            %     Generates a trigger when the key operation of Trigger > Trigger is executed from the front panel.
            % 
            %     Bus Trigger
            %     Generates a trigger when the SCPI.IEEE4882.TRG object is executed.

            obj.write(':TRIG:SEQ:SOUR %s',val);
        end
        
        %% set & get configurations
        function setConfig(obj, config)
            % setConfig apply parameters to E5071C
            % config should have same or less fields as E5071C properties
            % with set & get methods
            flds = fieldnames(config);
            for ii = 1:length(flds)
                fld = flds{ii};
                obj.(fld) = config.(fld);
            end
        end
        
        function params = getConfig(obj)
            % getConfig returns E5071C object parameters for saving
            % configuration
            flds = {'freqStart',...
                'freqStop',...
                'freqSpan',...
                'freqCenter',...
                'avg',...
                'numOfPoints',...
                'ifbw',...
                'meas',...
                'outp',...
                'power',...
                'trigMode'};            
            for ii = 1:length(flds)
                fld = flds{ii};
                params.(fld) = obj.(fld);
            end
        end
        
        
        %% get & plot trace
        function autoScale(obj)
            % autoScale auto-scales the y axis
            % for viewing the image via web server
            obj.write(':DISP:WIND:TRAC:Y:SCAL:AUTO');
        end
        function value = get.freqs(obj)            
            value = obj.freqStart:((obj.freqStop...
                - obj.freqStart)/obj.numOfPoints):obj.freqStop;
            value = value(1:end-1);
        end
        function value = get.trace(obj)
            % adopted from https://community.keysight.com/thread/22342
            fopen(obj.visa);
            fprintf(obj.visa, 'CALC:DATA:SDAT?'); 
            [data, count, msg] = binblockread(obj.visa, 'double'); 
            fclose(obj.visa);
            value.count = count;
            value.msg = msg;
            value.X = data(1:2:end); 
            value.Y = data(2:2:end);
        end
        
        function titleStr = plotTrace(obj, varargin)
            % plotTrace fetch & plot trace data
            % EXAMPLE (assume the object is named 'vna'):
            %   vna.plotTrace;
            %   vna.plotTrace('issavefig', true);
            %   vna.plotTrace('issavefig', true,'filename','test');
            %
            % See the inputParser below for more options
            %   
            
            p = inputParser;
            p.addParameter('issavedata',false,@islogical);
            p.addParameter('issavefig',false,@islogical);
            p.addParameter('avg',1,@isnumeric);
            p.addParameter('filename','',@ischar);
            p.addParameter('format','png',@ischar);
            p.parse(varargin{:});
            expandStructure(p.Results);
            
            if avg > 1
                pause(round(avg*obj.sweepTime + 1));
            end
            
            hfig = figure;
            obj.h_fig = hfig;
            trace = obj.trace;
            
            plot(obj.freqs/1e9,...
                20*log10(abs(trace.X + 1i*trace.Y)));
            xlabel freq/GHz
            ylabel SParameter/dB
            titleStr = ['start_' num2str(obj.freqStart/1e9)...
                'GHz_stop_'  num2str(obj.freqStop/1e9)...
                'GHz_pow_' num2str(obj.power)...
                'dBm_AVG_' num2str(avg)];
            title(titleStr, 'interpreter','none');
            
            if issavefig
                if ~isempty(filename)
                    titleStr = filename;
                end
                saveas(hfig, [titleStr format]);
            end
            
            if issavedata  
                str = titleStr;
                freqs = obj.freqs;
                config = obj.getConfig;
                save([str '.mat'],'freqs','trace','str','config');
            end      
            
        end
        
        function [freqs, trace] = manualSweep(obj, varargin)
            % manualSweep defines and does a manual frequency sweep
            % main purpose is for wide sweep with high resolution for
            % finding modes
            %
            % EXAMPLE:
            %   [freqs, trace] = vna.manualSweep('start',1e9,'stop',9e9,'res',1e5);
            %   [freqs, trace] = vna.manualSweep('start',3.5e9,'stop',3.6e9,'res',1e4, 'avg',999);
            %   [freqs, trace] = vna.manualSweep('center',4.9655e9,'span',1e6,'res',0.001e6,'avg',2,'ifbw',100,'pow',-10);
            %
            %
            % See the inputParser below for more options
            %
            
            p = inputParser;
            p.addParameter('start',1e9,@isnumeric); % start frequency
            p.addParameter('stop',8e9,@isnumeric);  % stop frequency
            p.addParameter('res',1e6,@isnumeric);   % frequency resolution
            p.addParameter('avg', 1, @isnumeric);       % number of average
            p.addParameter('ifbw', 100, @isnumeric);    % ifbw of vna
            p.addParameter('points', obj.MAX_POINTS, @isnumeric); % number of points of vna
            p.addParameter('pow', -100, @isnumeric); % power of vna, default below
                                                        % the lowest power of E5071C,
                                                        % hence this
                                                        % parameter only
                                                        % takes effect if it
                                                        % is given a valid
                                                        % value
            p.addParameter('center', 0, @isnumeric);  % frequency sweep can also be defined
                                                      % by center and span,
                                                      % if they are given a
                                                      % valid value
            p.addParameter('span',0, @isnumeric);
            p.addParameter('issavedata',true,@islogical);
            p.addParameter('hfig',233,@isnumeric);      % figure handle
            p.addParameter('notes','',@ischar);         % notes to add in file name
            
            p.parse(varargin{:});
            expandStructure(p.Results);
            
            freqSectionSpan = res * points;
            freqSectionSpan = 1e6 * round(freqSectionSpan/1e6);
            if span ~= 0 && center ~= 0
                start = center - span/2;
                stop = center + span/2;
            end
            numOfSections = ceil((stop - start)/freqSectionSpan);
            stop = start + numOfSections * freqSectionSpan;
            totalPoints = points * numOfSections;
            
            % initialize
            freqs = NaN(1, totalPoints);
            trace.X = freqs;
            trace.Y = freqs;
            
            % apply parameters
            obj.ifbw = ifbw;
            if pow > -85
                obj.power = pow;
            end
            obj.numOfPoints = points;
            obj.freqSpan = freqSectionSpan;
            obj.avg = obj.MAX_AVG;
            
            sweepTime = obj.sweepTime;
            waitTime = ceil(avg * sweepTime) + 1;
            
            figure(hfig);
            xlabel freq/GHz
            ylabel SParameter/dB
            str = sprintf('start_%.2fGHz_stop_%.2fGHz_res_%.2fMHz_pow_%ddBm_AVG_%d',...
                start/1e9,stop/1e9,res/1e6,obj.power,avg);
            title(str,'interpreter','none');
            
            fprintf('\tsweep from %.2fGHz to %.2fGHz, %d sections, %ds per section\n\ttotal points: %d, total time: %ds.\n',...
                start/1e9,stop/1e9, numOfSections,waitTime,totalPoints, waitTime * numOfSections);
            for i = 1:numOfSections
                obj.freqCenter = start + freqSectionSpan/2 +  freqSectionSpan* (i-1);
                fprintf('sweeping %.2fGHz to %.2fGHz...\n',obj.freqStart/1e9,obj.freqStop/1e9);
                pause(waitTime);
                tmptrace = obj.trace;
                tmpfreqs = obj.freqs;
                freqs((1 + (i-1)*points):(i*points)) = tmpfreqs;
                trace.X((1 + (i-1)*points):(i*points)) = tmptrace.X';
                trace.Y((1 + (i-1)*points):(i*points)) = tmptrace.Y';
                figure(hfig);
                plot(freqs/1e9, 20*log10(abs(trace.X + 1i*trace.Y)));
            end
            fprintf('Sweep finished!\n');
            
            figure(hfig);
            xlabel freq/GHz
            ylabel SParameter/dB
            str = sprintf('start_%.2fGHz_stop_%.2fGHz_res_%.2fMHz_pow_%ddBm_AVG_%d%s',...
                start/1e9,stop/1e9,res/1e6,pow,avg,notes);
            title(str,'interpreter','none');
            
            if issavedata
                config = obj.getConfig;
                save([str '.mat'],'freqs','trace','str','config');
            end      
            obj.h_fig = hfig;
            
        end
        
        
        
        function [freqs,totalWaitTime] = manualSweepFreqs(obj, varargin)
            % manualSweepFreqs quickly calculate frequencies of
            % manualSweep, does not do the sweep
            %
            % ATTENTION: this method will modify the vna sweep frequency!
            %
            % See the inputParser below for more options
            %
            
            p = inputParser;
            p.addParameter('start',1e9,@isnumeric); % start frequency
            p.addParameter('stop',8e9,@isnumeric);  % stop frequency
            p.addParameter('res',1e6,@isnumeric);   % frequency resolution
            p.addParameter('avg', 1, @isnumeric);       % number of average
            p.addParameter('ifbw', 100, @isnumeric);    % ifbw of vna
            p.addParameter('points', obj.MAX_POINTS, @isnumeric); % number of points of vna
            p.addParameter('pow', -100, @isnumeric); % power of vna, default below
                                                        % the lowest power of E5071C,
                                                        % hence this
                                                        % parameter only
                                                        % takes effect if it
                                                        % is given a valid
                                                        % value
            p.addParameter('center', 0, @isnumeric);  % frequency sweep can also be defined
                                                      % by center and span,
                                                      % if they are given a
                                                      % valid value
            p.addParameter('span',0, @isnumeric);
            
            % useless, but required for input parser to be identical with input parser for manualSweep; 
            p.addParameter('issavedata',true,@islogical);
            p.addParameter('hfig',233,@isnumeric);      % figure handle
            p.addParameter('notes','',@ischar);         % notes to add in file name
            
            
            p.parse(varargin{:});
            expandStructure(p.Results);
            
            freqSectionSpan = res * points;
            freqSectionSpan = 1e6 * round(freqSectionSpan/1e6);
            if span ~= 0 && center ~= 0
                start = center - span/2;
                stop = center + span/2;
            end
            numOfSections = ceil((stop - start)/freqSectionSpan);
            stop = start + numOfSections * freqSectionSpan;
            totalPoints = points * numOfSections;
            
            % initialize
            freqs = NaN(1, totalPoints);
            
            % apply parameters
            obj.ifbw = ifbw;
            if pow > -85
                obj.power = pow;
            end
            obj.numOfPoints = points;
            obj.freqSpan = freqSectionSpan;
            obj.avg = obj.MAX_AVG;
            
            sweepTime = obj.sweepTime;
            waitTime = ceil(avg * sweepTime) + 1;
            totalWaitTime = waitTime * numOfSections;
            
            for i = 1:numOfSections
                obj.freqCenter = start + freqSectionSpan/2 +  freqSectionSpan* (i-1);

                tmpfreqs = obj.freqs;
                freqs((1 + (i-1)*points):(i*points)) = tmpfreqs;
            end
            
        end
      
        %% fit
        function  [ f_r,Q_i,Q_c,Q_l ] = fit(obj,varargin)
            % select range and fit plot
            % ATTENTION: use vna.plotTrace or vna.manualSweep first and then use vna.fit!
            % EXAMPLE:
            %   vna.plotTrace;
            %   vna.fit('fitall',true);
            % you can also give data to this method:            
            %     [ f_r,Q_i,Q_c,Q_l ] = vna.fit('fitall',true,'issavefig',false,...
            %                                   'xdata',freqs,'ydata',20*log10(abs(SParams)),...
            %                                   'titleNotes','_pow_-10dBm' );
            %
            % See the inputParser below for more options
            %
            
            p = inputParser;
            p.addParameter('issavefig',true,@islogical);% if true, save fig to png file
            p.addParameter('fitall', false,@islogical); % if true, fit all
                                                        % plotted data,
                                                        % else ask two
                                                        % input for the fit
                                                        % range
            p.addParameter('xdata',[],@isnumeric);      % xdata in GHz frequency
            p.addParameter('ydata',[],@isnumeric);      % ydata given in dB
            p.addParameter('titleNotes','',@ischar);    % notes to add to the figure title
            p.addParameter('QGuess',1e5,@isnumeric);
            p.parse(varargin{:});
            expandStructure(p.Results);
            
            dataObj = get(gca,'children');
            if isempty(xdata)
                xdata = get(dataObj,'xdata');
            end
            if isempty(ydata)
                ydata = get(dataObj,'ydata');
            end
            
            if gcf == obj.h_fig
                figure(obj.h_fig);
            else
                figure(obj.h_fig);
                plot(xdata, ydata);
                % assume GHz frequency
                xlabel frequency/GHz;
                ylabel S/dB;
                title([sprintf('start_%.4fGHz_stop_%.4fGHz',...
                    min(xdata)/1e9, max(xdata)/1e9 ) titleNotes],'interpreter','none');
            end
                
            if fitall
                leftInd = 1;
                rightInd = length(xdata);
            else
                fprintf('Select the X range for fitting:');
                tmpPoints = ginput(2);
                leftX = min(tmpPoints(:,1));
                rightX = max(tmpPoints(:,1));
                leftInd = find(leftX < xdata, 1);
                rightInd = find(rightX < xdata, 1);
            end
            t = xdata(:);
            y = ydata(:);
            % assume xdata given in GHz
            t = t(leftInd:rightInd)*1e9;
            % assume ydata given in dB, convert to linear
            y = 10.^(y(leftInd:rightInd)./20);

            % guess initial parameters
            peakInd = find(abs(ydata)>=max(abs(ydata)),1);
            freq0 = xdata(peakInd); % in GHz
            x1 = [freq0, QGuess/1e4, QGuess/1e4, 0, 0, 0];

            % fit with complex S21 deduced theoretically
            % 8 parameter, linear base
            %         F = @(x,xdata)(20.*log10(abs(x(6).*(1+x(5).*(xdata-x(1).*1e9)./(x(1).*1e9)).*(1-(x(2).^2.*1e4.*x(3).^2.*1e4./cos(x(4)))./(x(2).^2.*1e4 + x(3).^2.*1e4./cos(x(4)))./(x(3).^2.*1e4).*(cos(x(4))+1i.*sin(x(4)))./(1+2.*1i.*(x(2).^2.*1e4.*x(3).^2.*1e4./cos(x(4)))./(x(2).^2.*1e4 + x(3).^2.*1e4./cos(x(4))).*(xdata-x(1).*1e9)./(x(1).*1e9)))))+x(7).*xdata.*1e-9+x(8));
            % 7 parameter, constant base
            F = @(x,xdata)(abs(x(6).*(1+x(5).*(xdata-x(1).*1e9)./(x(1).*1e9)).*(1-(x(2).^2.*1e4.*x(3).^2.*1e4./cos(x(4)))./(x(2).^2.*1e4 + x(3).^2.*1e4./cos(x(4)))./(x(3).^2.*1e4).*(cos(x(4))+1i.*sin(x(4)))./(1+2.*1i.*(x(2).^2.*1e4.*x(3).^2.*1e4./cos(x(4)))./(x(2).^2.*1e4 + x(3).^2.*1e4./cos(x(4))).*(xdata-x(1).*1e9)./(x(1).*1e9)))));
            %x(1): f, center frequency, in GHz
            %x(2): Qi, intrinsic Q, Ql = Qi*Qc/(Qi + Qc) =  (x(2).*x(3)./cos(x(4)))./(x(2) + x(3)./cos(x(4))), in 1e4
            %x(3): |Qe|, parameter Q, 1/Qc = Re (1/Qe) = cos(theta)/Qe, in 1e4
            %x(4): theta, phase of parameter Q
            %x(5): alpha
            %x(6): amplitude A

    
            opt=optimset('MaxIter',10000,'MaxFunEvals',10000,'tolx',1e-16,'tolf',1e-9);
            for loop_fit=1:5            
                [x_fit1,resnorm,~,exitflag,output] = lsqcurvefit(F,x1,t,y,[],[],opt);
                x1=x_fit1;
                if ((x1(4)>pi/2)||(x1(4)<-pi/2))
                    tmp = floor(abs(x1(4))./(pi/2));
                    if x1(4)>0
                        x1(4)=x1(4)-tmp.*pi/2;
                    end
                    if x1(4)<0
                        x1(4)=x1(4)+tmp.*pi/2;
                    end
                end
            end
            
            f_r = x1(1)*1e9; % center frequency, in Hz
            Q_i = x1(2).^2.*1e4; % interal Q
            Q_c = x1(3).^2./cos(x1(4)).*1e4;  % coupled Q
            Q_l = Q_i.*Q_c./(Q_i + Q_c);  % loaded Q
            
            figure(obj.h_fig);
            hold on
            plot(t/1E9,20*log10(y),'.',t/1E9,20*log10(F(x_fit1,t)),'LineWidth',2);
            f_text=['f_r = '];
            f_text=[f_text num2str(f_r/1e9)];
            f_text=[f_text 'GHz'];
            Ql_text=['Q_l = ' num2str(round(Q_l))];
            Qi_text=['Q_i = ' num2str(round(Q_i))];
            Qc_text=['Q_c = ' num2str(round(Q_c))];
            text_pos=[(max(20*log10(y))-min(20*log10(y)))/4+min(20*log10(y)),min(20*log10(y))];
            text(t(1)/1E9,text_pos(1),f_text,'FontSize',18);
            text(t(1)/1E9,text_pos(2),Ql_text,'FontSize',18);
            text(t(round(end/1.5))/1E9,text_pos(1),Qi_text,'FontSize',18);
            text(t(round(end/1.5))/1E9,text_pos(2),Qc_text,'FontSize',18);
            hold off
            
            if issavefig
                str = ['Fit_' get(get(gca,'Title'),'String') '.png'];
                saveas(obj.h_fig,str);   
                fprintf(['Image ' str ' saved.\n'])
            end

        end
        
        
    end
    
        
    
    %% private methods
    methods (Access = private)
        function val = read(obj, varargin)
            % varargin{1:(end-1)} are commands to be sent as a formatted
            % string
            % varargin{end} is the read format
            fopen(obj.visa);
            fprintf(obj.visa, varargin{1:(end-1)});
            val = fscanf(obj.visa, varargin{end});
            fclose(obj.visa);
        end
        function write(obj, varargin)
            fopen(obj.visa);
            fprintf(obj.visa, varargin{:});
            fclose(obj.visa);
        end
    end
    
    
end