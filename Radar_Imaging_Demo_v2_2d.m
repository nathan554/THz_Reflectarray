%Radar_Imaging_Demo_v2_2d.m
%Nathan Monroe
%monroe@mit.edu
%9/1/2021
%Generates and collects correct set of signals for FMCW imaging
%radar demo.
 
%Assume chip array is programmed, in the correct mode, and on pixel 1.
%Assume N5173B as function generator for RF and LO, with analog modulation input from the
%AFG3102 signal generator to EXT2. Connected to  wilkinson to output to both
%RF and LO ports of VDI VNAX729.
%May be different if we use the harmonic mixer and/or the high power
%source, they have different input power requirements. N number should be
%the same though. Might need attenuator.
%if extender, take output from IF(M) port.
%Tek AFG3102. Ch1 connected to chip clock, CH2 to modulation input of RF fx
%gen.
%PXI sampler. Ch1 connected to ch1 of afg3102. ch2 connected to ch2 of
%afg3102. ch8 connected to vdi output.
 
%make sure modulations settings are right on the RF source. DC coupled 50
%ohms, ext2, 80MHz.
%pxi box. fx gen clock goes to chan 1, fmcw sig to chan 2, IF to chan 7.
%10MHz ref to PFI1.
 
integration_bit_reduction = 15; %how many integrations before flipping in BPSK. Saves bits in the memory.
image_resolution_x = 90; %in both dimensions
image_resolution_y = 90;
num_integrations = 150; %number of fmcw integrations to do, per beam state.
num_frames = 1;
acq_per_row = 3; %number of acquisitions per row. Limited by PXI memory.
show_fft = 0;
do_scaling = 0; %applies a filter to whiten the noise and eliminate phase noise skirt.
max_range = 6;
min_range = 1.3;
fmcw_chirp_rate = 0.3*625e6; %MHz/us.
Fs = 15e6; %Valid options are 60, 30, 20, 15, 12, 10, and lower. It will round to the nearest valid without warning you.
nfft = 2^12;
do_thresholding = 1;
return_threshold_db = 10; %was 55. Set low for saving data.
 
 
theta = pi/180*[-image_resolution_x/2:1:(image_resolution_x/2)-1];
center_freq = 264e9;
Mult_factor_in = 24;
RF_pow_dBm = 13;
rangech0 = 1; %range for the pxi quantizers. ch7 is the IF.
rangech1 = 3;
rangech7 = 0.1; %0.1
do_24mhz_lpf = 1; %turn on the built in LPF.
 
 
%%%%%%%%%%%%%%%%%%%%%%%%
%Script starts here
rangevecs = [];
returnvecs = [];
 
chirp_ramp_freq = 1/((80e6)/(fmcw_chirp_rate*1e6/Mult_factor_in)); %gives the frequency of the ramp wave used to modulate the FMCW.
 
%This alters the chirp ramp freq so that it is an even number of samples,
%no fractional sample.
chirp_ramp_freq = Fs/(round(Fs/chirp_ramp_freq));
chirp_ramp_freq = round(chirp_ramp_freq,5);
fmcw_chirp_rate = chirp_ramp_freq*Mult_factor_in*80e6/1e6; %update to the new effective chirp ramp freq.
 
clock_freq = chirp_ramp_freq / num_integrations;
integration_period = 1/clock_freq;
disp(strcat('integration time:',num2str(integration_period*1000),'ms'));
%set up equipment.
 
clock_freq = clock_freq * num_integrations / integration_bit_reduction;
 
 
freq_vec = [0:Fs/nfft:Fs/2];
range_vec = freq_vec * 3e8/(2*fmcw_chirp_rate*1e6);
range_vec = range_vec / 2;
 
[a, max_ind] = min(abs(range_vec-max_range));
[a, blanking_ind] = min(abs(range_vec-min_range));
 
disp(strcat('clock freq:',num2str(clock_freq),'Hz'));
pause;
 
 
disp('configuring Fx gen');
fx_gen = visa('ni','GPIB0::11::INSTR');
configure_fx_gen(fx_gen,clock_freq,chirp_ramp_freq,image_resolution_x,num_integrations,acq_per_row,integration_bit_reduction,1);
 
 
disp('configuring PXI sampler')
niscopeobj = icdevice('niscope.mdd','Dev1'); %this is the new name with the 8301 box.
 
[numSamples,channelList,waveformInfo] = configure_pxi(niscopeobj,rangech0,rangech1,rangech7,Fs,integration_period,image_resolution_x,acq_per_row,do_24mhz_lpf);
 
 
TimeOut = 10; % seconds
    
disp('Configuring RF source');
N5173B = visa('ni','GPIB0::18::INSTR'); %may need to change GPIB interface number here, based on NI tool (NI-488.2 ver 17.6 and NI-VISA ver 19.0).
configure_N5173B(N5173B,center_freq,Mult_factor_in,RF_pow_dBm);
fprintf(N5173B,'OUTP:STAT ON'); %turn it on.
 
range_image_out_tosave = zeros(image_resolution_y,image_resolution_x,num_frames);
return_image_out_tosave = zeros(image_resolution_y,image_resolution_x,num_frames);
 
 
fig=figure(400);
 
for frame = [1:1:num_frames]
 %while(1)
    full_arrayout = zeros(2,numSamples*acq_per_row);
    range_image_out = 2.5*ones(image_resolution_y,image_resolution_x);
    return_image_out = 50*ones(image_resolution_y,image_resolution_x);
 
    for i=1:1:image_resolution_y %eventually put image_resolution here at the end.
        array_out = zeros(1,numSamples*acq_per_row);
        waveformArray = zeros(numSamples, 1);
 
        for t = 1:acq_per_row         
            disp(strcat('recording row ',num2str(i)));
            invoke(niscopeobj.Acquisition, 'initiateacquisition');

            fprintf(fx_gen,'TRIG:SEQ:IMM'); %this actually triggers the clock etc.
            [waveformArray, ~] = invoke(niscopeobj.Acquisition, 'fetchbinary16', channelList,...
    TimeOut, numSamples, waveformArray, waveformInfo); %can also do just 'fetch', the binary16 isn't really any faster.
            
            %put all the channels together.
            array_out(((t-1)*numSamples)+1:((t)*numSamples)) = waveformArray;
            
        end
        
        [range_ind, IF_fft, range_vec_cut, return_vec,ind_unthres] = process_radar_image_row(array_out,num_integrations,nfft,image_resolution_x,blanking_ind,max_ind,integration_bit_reduction,do_scaling,show_fft,range_vec,Fs,do_thresholding,return_threshold_db);
        range_image_out(i,:) = range_vec_cut(range_ind);
        return_image_out(i,:) = return_vec;
        fig = figure(400);
        %imagesc(image_out);
        ax(1) = subplot(121);
        imagesc(fliplr(flipud(range_image_out)));
 
        colormap(ax(1),flipud(parula))
        cb1 = colorbar;
        cb1.Label.String = 'Range (m)';
 
        title('Range')
                    set(gca,'FontSize', 22);
 
        axis tight
        axis equal
        ax(2) = subplot(122);
        imagesc(fliplr(flipud(return_image_out)))
        title('Return')
        set(gca,'FontSize', 22);
 
        cb2 =  colorbar;
        cb2.Label.String = 'Return (dB)';
        colormap(ax(2),(parula))
        %colormap(fig,flipud(parula))
 
        axis tight
        axis equal
       
        
        drawnow;
        
    end
    disp('Done. Returning ring buffer to beginning.')
 
    return_ring_buffer(fx_gen,image_resolution_x,image_resolution_y,num_integrations,clock_freq,chirp_ramp_freq,acq_per_row,integration_bit_reduction);
    pause(3);
    range_image_out_tosave(:,:,frame) = range_image_out;
    return_image_out_tosave(:,:,frame) = return_image_out;
    
end
 
 
fprintf(N5173B,'OUTP:STAT OFF'); %turn off the RF source.
disp('cleaning up...')
disconnect(niscopeobj);
delete(niscopeobj);
clear niscopeobj;
clear waveformInfo;
 
instrreset;
 
disp('Done.');
