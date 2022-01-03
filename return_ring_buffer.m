function return_ring_buffer(fx_gen,image_resolution_x,image_resolution_y,num_integrations,clock_freq,chirp_ramp_freq,acq_per_row,bit_reduction)
    %returns the reflectarray’s ring buffer to the start.
    reset_freq = 30e3;
    fprintf(fx_gen,'SOUR1:FREQ %f',reset_freq); %clock reset at 30KHz.
    fprintf(fx_gen,'SOUR2:FREQ %f',3e6);
    num_return_cycles = 81919-(image_resolution_x*image_resolution_y*num_integrations/bit_reduction);
    disp(strcat('num return cycles:',num2str(num_return_cycles)));
    fprintf(fx_gen,'SOUR1:BURS:NCYC %d',num_return_cycles);
    fprintf(fx_gen,'SOUR2:BURS:NCYC %d',num_return_cycles);
    fprintf(fx_gen,'TRIG:SEQ:IMM'); %this actually triggers the clock etc.
    pause(num_return_cycles/reset_freq);
    
    fprintf(fx_gen,'SOUR1:FREQ %f',clock_freq);
    fprintf(fx_gen,'SOUR2:FREQ %f',chirp_ramp_freq);
 
    fprintf(fx_gen,'SOUR2:PHAS:ADJ 0 DEG'); %Makes everything align. 
    fprintf(fx_gen,'SOUR1:PHAS:INIT'); %make sure they're synced in phase
    fprintf(fx_gen,'SOUR2:PHAS:INIT'); %make sure they're synced in phase
    fprintf(fx_gen,'SOUR1:BURS:NCYC %f',image_resolution_x*num_integrations/(acq_per_row*bit_reduction)); %number of clock cycles and fmcw cycles
    fprintf(fx_gen,'SOUR2:BURS:NCYC %f',image_resolution_x*num_integrations/acq_per_row);
 
end

