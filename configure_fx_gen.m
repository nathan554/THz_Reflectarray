function configure_fx_gen(fx_gen,clock_freq,chirp_ramp_freq,image_resolution_x,num_integrations,acq_per_row,bit_reduction,do_2d)
    fopen(fx_gen);
    fprintf(fx_gen,'OUTP1 OFF');
    fprintf(fx_gen,'OUTP2 OFF');
    fprintf(fx_gen,'SOUR1:FUNC SQU'); %square wave.
    fprintf(fx_gen,'SOUR1:VOLT:HIGH 0.5');
    fprintf(fx_gen,'SOUR1:VOLT:LOW 0.0');
    fprintf(fx_gen,'SOUR1:FREQ %f',clock_freq);
 
    fprintf(fx_gen,'SOUR2:FUNC RAMP'); %ramp wave.
    fprintf(fx_gen,'SOUR2:FUNC:RAMP:SYMM 100'); %ramp wave.
 
    if(~do_2d)
        fprintf(fx_gen,'SOUR2:PHAS:ADJ 0 DEG'); %Makes everything align. 
    else
        fprintf(fx_gen,'SOUR2:PHAS:ADJ 180 DEG'); %Makes everything align.
    end
    fprintf(fx_gen,'SOUR2:VOLT:HIGH 1');
    fprintf(fx_gen,'SOUR2:VOLT:LOW -1');
    fprintf(fx_gen,'SOUR2:FREQ %f',chirp_ramp_freq);
    fprintf(fx_gen,'SOUR1:PHAS:INIT'); %make sure they're synced in phase
    fprintf(fx_gen,'SOUR2:PHAS:INIT'); %make sure they're synced in phase
 
    fprintf(fx_gen,'SOUR:ROSC:SOUR EXT');
 
    fprintf(fx_gen,'SOUR1:BURS:STAT ON'); %put them both into burst mode
    fprintf(fx_gen,'SOUR2:BURS:STAT ON');
    
    fprintf(fx_gen,'SOUR1:BURS:NCYC %f',image_resolution_x*num_integrations/(acq_per_row*bit_reduction)); %number of clock cycles and fmcw cycles
    disp(strcat('Number of clock bursts:',num2str(image_resolution_x*num_integrations/(acq_per_row*bit_reduction))));
    fprintf(fx_gen,'SOUR2:BURS:NCYC %f',image_resolution_x*num_integrations/acq_per_row);
    %fprintf(fx_gen,'SOUR2:BURS:NCYC %f',num_integrations);
    
    fprintf(fx_gen,'SOUR1:BURS:TDEL MIN'); %min time delay
    fprintf(fx_gen,'SOUR2:BURS:TDEL MIN');
    
    fprintf(fx_gen,'SOUR1:BURS:MODE TRIG'); %set them both to be triggered not gated.
    fprintf(fx_gen,'SOUR2:BURS:MODE TRIG');
    
    fprintf(fx_gen,'TRIG:SEQ:SOUR EXT'); %external source for the trigger. So that it doesn't trigger on it's own timer
    
    fprintf(fx_gen,'OUTP1 ON');
    fprintf(fx_gen,'OUTP2 ON');
 
end
