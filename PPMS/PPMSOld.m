classdef PPMSOld < handle
    % PPMS describe and control QDInstrument DynaCool at IIIS via their
    % LabVIEW generated dll
    %
    % Wentao, March 2017

properties (Constant)
    TEMP_STATUS = containers.Map([0,1,2,5,6,7,10,13,14,15],...
                        {'TemperatureUnknown','Stable','Tracking',...
                        'Near','Chasing','Filling','Standby','Disabled',...
                        'ImpedanceNotFunction','TempFailure'});
    TEMP_MODE = containers.Map({'FastSettle','NoOvershoot'},[0,1]);
    
    FIELD_STATUS = containers.Map([0,1,2,3,4,5,6,7,8,15],...
                        {'MagnetUnknown','StablePersistent','WarmingSwitch',...
                        'CoolingSwitch','StableDriven','Iterating','Charging',...
                        'Discharging','CurrentError','MagnetFailure'});
    FIELD_APPROACH = containers.Map({'Linear','NoOvershoot','Oscillate'},...
                        [0,1,2]);
    FIELD_MODE = containers.Map({'Persistent','Driven'},[0,1]);
    
end

properties
    
    address
    libpath
    libname
    
    temp
    field
    tempStatus
    fieldStatus
    
    tempMode
    tempRate
    fieldMode
    fieldRate
    fieldApproach
end

methods
    function obj = PPMS(varargin)
        % initialize PPMS
        p = inputParser;
        p.addParameter('address','101.6.98.151',@ischar);
        p.addParameter('libpath','D:\LabVIEW4PPMS\builds\PPMSLib',@ischar)
        p.addParameter('libname','PPMSLib',@ischar);
        
        p.parse(varargin{:})
        expandStructure(p.Results);
        
        % assume library having the following functions:
        %         'GetBField'
        %         'GetBFieldStat'
        %         'GetTemp'
        %         'GetTempStat'
        %         'SetBField'
        %         'SetTemp'
        
        addpath(genpath(libpath));
        loadlibrary(libname);
        funcs = libfunctions(libname);
        obj.checkLibFuncs(funcs);
        fprintf('Library %s successfully loaded!\n',libname);
        
        obj.address = address;
        obj.libname = libname;
        obj.libpath = libpath;  
        obj.tempMode = 'Unknown';
        obj.fieldMode = 'Unknown';
        obj.fieldApproach = 'Unknown';
        obj.tempRate = NaN;
        obj.fieldRate = NaN;
        unloadlibrary(libname);
        
    end
    
    function delete(obj)
        if libisloaded(obj.libname)
            unloadlibrary(obj.libname);
        end
    end
    
    %% set & get temperature
    function value = get.temp(obj)
        loadlibrary(obj.libname);
        value = calllib(obj.libname,'GetTemp',char(obj.address));
        unloadlibrary(obj.libname);
    end
    function value = get.tempStatus(obj)
        loadlibrary(obj.libname);
        stat = calllib(obj.libname,'GetTempStat',char(obj.address));
        unloadlibrary(obj.libname);
        value = obj.TEMP_STATUS(stat);
    end
    
    function setTemp(obj,varargin)
        p = inputParser;
        p.addRequired('temperature');
        p.addParameter('tempRate',10,@isnumeric);
        p.addParameter('tempMode','FastSettle',@obj.checkTempMode);
        p.parse(varargin{:});
        expandStructure(p.Results);
        
        obj.tempMode = tempMode;
        obj.tempRate = tempRate;
        
        loadlibrary(obj.libname);
        calllib(obj.libname,'SetTemp',char(obj.address),...
            temperature,obj.TEMP_MODE(tempMode),tempRate);
        unloadlibrary(obj.libname);
        
    end
    
    
    %% set & get field
    function value = get.field(obj)
        loadlibrary(obj.libname);
        value = calllib(obj.libname,'GetBField',char(obj.address));
        unloadlibrary(obj.libname);
    end
    function value = get.fieldStatus(obj)
        loadlibrary(obj.libname);
        stat = calllib(obj.libname,'GetBFieldStat',char(obj.address));
        unloadlibrary(obj.libname);
        value = obj.FIELD_STATUS(stat);
    end
    
    function setField(obj,varargin)
        p = inputParser;
        p.addRequired('b_field');
        p.addParameter('fieldRate',100,@isnumeric);
        p.addParameter('fieldMode','Driven',@obj.checkFieldMode)
        p.addParameter('fieldApproach','Linear',@obj.checkFieldApproach);
        p.parse(varargin{:});
        expandStructure(p.Results);
        
        obj.fieldMode = fieldMode;
        obj.fieldRate = fieldRate;
        obj.fieldApproach = fieldApproach;
        
        loadlibrary(obj.libname);
        calllib(obj.libname,'SetBField',char(obj.address),...
            b_field, fieldRate,...
            obj.FIELD_MODE(fieldMode),obj.FIELD_APPROACH(fieldApproach));
        unloadlibrary(obj.libname);
        
        
    end
    
    
    
end

methods(Access = private)
    function passed = checkLibFuncs(obj, funcs)
        expectedFuncs = {'GetBField','GetBFieldStat','GetTemp','GetTempStat',...
                    'SetBField','SetTemp'};
        passed = false;
        found = false(1,length(expectedFuncs));
        for ii = 1:length(expectedFuncs)
            for jj = 1:length(funcs)
                if strcmp(funcs{jj},expectedFuncs{ii})
                    found(ii) = true;
                    break;
                end
            end
            if found(ii) == false
                error('Not a valid library!');
            end
        end
        passed = true;
    end
    function passed = checkTempMode(obj, tempMode)
        passed = isKey(obj.TEMP_MODE,tempMode);
    end
    function passed = checkFieldMode(obj, fieldMode)
        passed = isKey(obj.FIELD_MODE,fieldMode);
    end
    function passed = checkFieldApproach(obj, fieldApproach)
        passed = isKey(obj.FIELD_APPROACH,fieldApproach);
    end
end



end