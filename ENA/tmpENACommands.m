% temp script for ENA matlab control test
%% FOR TEST & DEVELOPMENT OF E5071C CLASS, DO NOT USE THIS FILE

%% initialization
e5071c = visa('agilent','GPIB0::6::INSTR');

set(e5071c,'inputBufferSize', 20000);
set(e5071c,'TimeOut', 20);

fopen(e5071c);
fprintf(e5071c,'*IDN?');
idn = fscanf(e5071c)
%% 
% Set byte order to swapped (little-endian) format
fprintf(e5071c, 'FORM:BORD SWAP');

% Set data type to real 64 bit binary block
fprintf(e5071c, 'FORM:DATA REAL');

%% fetch & plot freq sweep trace
fprintf(e5071c, ':sens:freq:star?');
freqStart = fscanf(e5071c, '%f');
fprintf(e5071c, ':sens:freq:stop?');
freqStop = fscanf(e5071c, '%f');
fprintf(e5071c, ':sens:freq:cent?');
freqCent = fscanf(e5071c, '%f');
fprintf(e5071c, ':sens:freq:span?');
freqSpan = fscanf(e5071c, '%f');

fprintf(e5071c, ':sens:swe:poin?');
numOfPoints = fscanf(e5071c, '%f');

fprintf(e5071c, ':SENSe:AVERage:COUNt?');
avg = fscanf(e5071c, '%f');

fprintf(e5071c,':SOURce:POWer:LEVel:IMMediate:AMPLitude?');
outp = fscanf(e5071c, '%f');

freqs = freqStart:((freqStop - freqStart)/numOfPoints):freqStop;
freqs = freqs(1:end-1);

% fetch formatted data
% fprintf(e5071c,':CALCulate:SELected:DATA:FDATa?');
% [data, count, msg] = binblockread(e5071c, 'double');
% data1 = data(1:2:end);

% fetch both real & imag parts
fprintf(e5071c, 'CALC1:DATA:SDAT?'); 
[data, count, msg] = binblockread(e5071c, 'double'); 
inphase = data(1:2:end); 
quadrature = data(2:2:end); 
IQData = inphase + 1i*quadrature; 

hfig = figure;
plot(freqs/1e9, 20*log10(abs(IQData)));
xlabel freq/GHz
ylabel SParameter/dB
title(['start_' num2str(freqStart/1e9)...
    'GHz_stop_'  num2str(freqStop/1e9)...
    'GHz_outp_' num2str(outp)...
    'dBm_AVGSET_' num2str(avg)], 'interpreter','none');



%% clear

% Flush the buffer 
clrdevice(e5071c); 

% Disconnect gpib object. 
fclose(e5071c); 

% Clean up all objects. 
delete(e5071c);