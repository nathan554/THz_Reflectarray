function [numSamples,channelList,waveformInfo] = configure_pxi(niscopeobj,rangech0,rangech1,rangech7,Fs,integration_period,image_resolution_x,acq_per_row,do_24mhz_lpf)
        connect(niscopeobj)
        disp(niscopeobj);
        configuration = niscopeobj.Configuration;
        invoke(configuration, 'autosetup');
        clocking = niscopeobj.Clocking;
        clocking.Input_Clock_Source = 'NISCOPE_VAL_PFI_1';
        clocking.Reference_Clock_Rate = 10e6;
        Offset = 0;
        Coupling = 1;
        ProbeAttenuation = 1;
        invoke(niscopeobj.Configurationfunctionsvertical, 'configurevertical', '0', rangech0, Offset, Coupling, ProbeAttenuation, true);
        invoke(niscopeobj.Configurationfunctionsvertical, 'configurevertical', '1', rangech1, Offset, Coupling, ProbeAttenuation, true);
        invoke(niscopeobj.Configurationfunctionsvertical, 'configurevertical', '7', rangech7, Offset, Coupling, ProbeAttenuation, true);
        invoke(niscopeobj.Configurationfunctionsvertical, 'configurechancharacteristics', '7', 50, Fs); %50 ohms, Fs sample rate.
        numSamples = round(((integration_period*image_resolution_x/acq_per_row))*Fs); %one row length. Don't add anything because it makes later processing harder.
        %numSamples = round(((integration_period))*Fs); %one row length. Don't add anything because it makes later processing harder.
        RefPosition = 0;
        NumRecords = 1;
        invoke(niscopeobj.Configurationfunctionshorizontal,'configurehorizontaltiming',Fs, numSamples, RefPosition, NumRecords, true);
 
        %numChannels = 3;
        %channelList = '0,1,7';
        %numChannels = 2;
        %channelList = '0,7';
        numChannels = 1;
        channelList = '7';
 
        for i = 1:numChannels
            waveformInfo(i).absoluteInitialX = 0;
            waveformInfo(i).relativeInitialX = 0;
            waveformInfo(i).xIncrement = 0;
            waveformInfo(i).actualSamples = 0;
            waveformInfo(i).offset = 0;
            waveformInfo(i).gain = 0;
            waveformInfo(i).reserved1 = 0;
            waveformInfo(i).reserved2 = 0;
        end
        invoke(niscopeobj.Configurationfunctionstrigger, 'configuretriggeredge', '0', 0.1, 0,1,0,0); %start recording on falling edge of chan 0 (clock), no holdoff or delay.
        if(do_24mhz_lpf)
           vert = niscopeobj.Vertical;
            vert.Maximum_Input_Frequency = 24e6; 
        end
 
end
