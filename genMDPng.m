%% generate md string for png figures
function [allMDStr] = genMDPng(varargin)
% function for generating MD strings for logging
% Wentao, April 2017
p = inputParser;
p.addParameter('rootDir',...
    'ftp://166.111.141.159/S308/website/Measurement/PPMS/', @isstr);
p.addParameter('subDir','',@ischar);
p.addParameter('width', 350, @isnumeric);
p.addParameter('imageformat', 'png', @isstr);
p.parse(varargin{:});
expandStructure(p.Results);

if ~isempty(subDir)
    rootDir = [rootDir subDir '/'];
end

% if nargin < 1
%     rootStr = 'ftp://166.111.141.159/S308/website/Measurement/PPMS/';
% end

allMDStr = genMDPngRecur(rootDir, width, imageformat);
for i=1:length(allMDStr)
    fprintf([allMDStr{i} '\n']);
end

end

%%
function [allMDStr] = genMDPngRecur(rootStr, width, imageformat)
dirStr = ls;
tmp = size(dirStr);
nrow = tmp(1);
allMDStr = {};
tmpPngStrs = filefun(['*.' imageformat]);
for j = 1:length(tmpPngStrs)
    tmpPngStr = tmpPngStrs{j};
    allMDStr{end+1} = ['![' tmpPngStr(1:(end-4)) ']('...
        rootStr tmpPngStr ' =' num2str(width) 'x*)' ];
end
for i = 3:nrow
    if isdir(dirStr(i,:))
        cd(dirStr(i,:));
        tmpInds = strfind(dirStr(i,:),' ');
        if isempty(tmpInds)
            tmpDir = [rootStr dirStr(i,:) '/'];
        else            
            tmpDir = [rootStr dirStr(i,1:(tmpInds(1)-1)) '/'];
        end
        tmpAllMDStr = genMDPngRecur(tmpDir,  width, imageformat);
        for j = 1:length(tmpAllMDStr)
            allMDStr{end+1} = tmpAllMDStr{j};
        end
        cd ..;
    end
end

end