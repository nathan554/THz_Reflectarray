function configure_N5173B(N5173B,center_freq,Mult_factor_in,RF_pow_dBm)
    N5173B.ByteOrder = 'bigEndian'; %data format
    %Connect to the instrument 
    fopen(N5173B);
    %Configure property values
    N5173B.EOSMode = 'read&write';
    N5173B.EOSCharCode = 'LF';
    fprintf(N5173B,'SOUR:POW %d dBm',RF_pow_dBm); %set to 10dBm
    fprintf(N5173B,'SOUR:FREQ %d Hz',center_freq / Mult_factor_in); %initial frequency value of test
    fprintf(N5173B,'SOUR:FM:SOUR EXT2'); %Get modulation from ext2.
    fprintf(N5173B,'SOUR:STAT ON'); %turn on modulation.
    fprintf(N5173B,'SOUR:FM:DEV 80 MHz'); %varies by 80MHz.
 
end
