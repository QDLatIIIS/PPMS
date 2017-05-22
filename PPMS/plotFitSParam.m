% this script plots all VNA data inside current directory

%% parameters
issave = false;

%% read file list within current folder
dataFiles = filefun('*.csv');

%% plot
if issave
    mkdir fig
end
for i=1:length(dataFiles)
    [freq, SParam] = importVNAData(dataFiles{i});
    hfig = figure;
    plot(freq/1e9, SParam);
    title(dataFiles{i},'Interpreter','none')
    xlabel frequency/GHz
    ylabel S/dB
    if issave
        saveas(hfig, ['fig/'  dataFiles{i}(1:(end-4)) '.png']);
    end
end


%% fit
% fileToFit = [3 4 5 6 9 10 11];    % chip3, 20170420Hanger
fileToFit = [1 3 4];                % chip1, 20170421Hanger

f_rs = [];
Q_is = [];
Q_cs = [];
Q_ls = [];
for fileNum = fileToFit
    % import data, S parameter assumed in dB
    [freq, SParam] = importVNAData(dataFiles{fileNum});
    freq0 = getparam(dataFiles{fileNum}, 'CENTER_');
    x0 = [freq0, 10, 10, 0, 0, 0];
    [ f_r,Q_i,Q_c,Q_l ] = HongyiFit(freq,...
                            10.^(SParam/20),... convert dB to linear
                            x0,...              initial guess
                            true,...            do save plot to file
                            ['Fit_' dataFiles{fileNum}(1:(end-4))]);
    f_rs(end+1) = f_r;
    Q_is(end+1) = Q_i;
    Q_cs(end+1) = Q_c;
    Q_ls(end+1) = Q_l;
    
end

%% generate MD string
% this part of code generate MD string for including png files onto the
% webpage

mdStr = [];
sizeFormat = ' =350x*';
dir = 'ftp://166.111.141.159//S308/website/Users/Wentao-Jiang/log/figures/April2017/';
fileFormat = 'png';
for fileNum = fileToFit
    tmpName = ['Fit_' dataFiles{fileNum}(1:(end-4))];
    tmpStr = ['![' tmpName '](' dir tmpName '.' fileFormat sizeFormat ')\n'];
    mdStr = [mdStr tmpStr];
end
sprintf(mdStr)







