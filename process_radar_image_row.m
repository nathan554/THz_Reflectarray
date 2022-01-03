%process_radar_image_row.m
%5/19/2021
%Nathan Monroe
%takes in radar IF data and produces a row of image.
 
%right now the windowing is off but can turn it on and precompute it.
function [ind, IF_fft,range_vec return_vec,ind_unthres] = process_radar_image_row(IF_signal,num_integrations,n,image_resolution,blanking_ind,max_ind,do_bpsk,do_scaling,show_fft,range_vec,Fs,do_thresholding,return_threshold_db)
    %reshape into a cube of integrations, clock edge, and sample. It's one
    %of these two, not sure which one. One will mix samples from adjacent
    %clock edges based on the reshaping.
    IF_signal_shaped = reshape(IF_signal,[],num_integrations,image_resolution);
    if(do_bpsk==1)
        [siglen1 siglen2 siglen3] = size(IF_signal_shaped);
       matrix_flipper = [ones(1,siglen1);-1*ones(1,siglen1)]';
       matrix_flipper = repmat(matrix_flipper,1,num_integrations/2,image_resolution); 
       IF_signal_shaped = IF_signal_shaped.*matrix_flipper;
    end
    if(do_bpsk==10)
        [siglen1 siglen2 siglen3] = size(IF_signal_shaped);
        matrix_flipper = [ones(1,siglen1);ones(1,siglen1);ones(1,siglen1);ones(1,siglen1);ones(1,siglen1);ones(1,siglen1);ones(1,siglen1);ones(1,siglen1);ones(1,siglen1);ones(1,siglen1);-1*ones(1,siglen1);-1*ones(1,siglen1);-1*ones(1,siglen1);-1*ones(1,siglen1);-1*ones(1,siglen1);-1*ones(1,siglen1);-1*ones(1,siglen1);-1*ones(1,siglen1);-1*ones(1,siglen1);-1*ones(1,siglen1)]';
        matrix_flipper = repmat(matrix_flipper,1,num_integrations/(2*10),image_resolution); 
       IF_signal_shaped = IF_signal_shaped.*matrix_flipper;
 
    end
    if(do_bpsk==50)
        [siglen1 siglen2 siglen3] = size(IF_signal_shaped);
        matrix_flipper = [ones(siglen1,do_bpsk),-1*ones(siglen1,do_bpsk)];
        matrix_flipper = repmat(matrix_flipper,1,num_integrations/(2*do_bpsk),image_resolution); 
       IF_signal_shaped = IF_signal_shaped.*matrix_flipper;
    end
    [siglen1, ~, ~] = size(IF_signal_shaped);
    IF_signal_shaped = IF_signal_shaped(round(40*Fs/60e6):end,:,:); %%cut off the first bit. May need to adjust this. Based on Fs.
 
    [siglen1, ~, siglen3] = size(IF_signal_shaped);
 
    IF_Signal_averaged = squeeze(sum(IF_signal_shaped,2)); %sum it, take out the unneccesary dimension.
    %now it's ready for FFT.
    
    %may need some transposing for the below.
    IF_Signal_averaged = IF_Signal_averaged.*(hamming(siglen1)*ones(1,siglen3)); %apply hamming to all of them.
    IF_fft = abs(fft(IF_Signal_averaged,n));
    
 
    IF_fft = IF_fft(1:n/2+1,:); %blank out the leakage part of it.
 
    if(do_scaling)
        %-7dB dip from 0 to 10m,flat after.
        
            [a, scaling_ind_10m] = min(abs(range_vec-10));
            [sza, ~] = size(IF_fft);
            scaling = ([-7:7/scaling_ind_10m:0]);
            scaling = db2pow([scaling zeros(1,sza-scaling_ind_10m-1)]);
        if(range_vec(end) < 10) %chop it off if it's below 10m.
            scaling = scaling(1:sza);
        end
        IF_fft = IF_fft.*repmat(scaling,[image_resolution 1])';
    end
    IF_fft = IF_fft(blanking_ind:max_ind,:);
    range_vec = range_vec(blanking_ind:max_ind);
    [return_vec,ind] = max(IF_fft);
    return_vec = pow2db(return_vec);
    ind_unthres = ind;
    if(do_thresholding)
       ind(return_vec < return_threshold_db) = max_ind-blanking_ind +1; 
    end
    if(show_fft)
        figure; plot(range_vec,pow2db(IF_fft));
    end    
end
