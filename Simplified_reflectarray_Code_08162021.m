%Simplified_reflectarray_Code_08162021.m
%Nathan Monroe
%monroe@mit.edu
%August 16 2021
%Simplified version of phase calculation for 1 bit reflectarray.
 
 
Fc = 265e9; %center frequ1ency of array, Hz.
beam_angle_phi = 90; %desired beam angle, degrees in phi (for two dimensional array).90 for E plane, 0 for H.
beam_angle_theta = -30; 
elem_dist_x =  5.73048e-04; %distance between elements within a chip, meters.
elem_dist_y =  5.958e-04; %distance between elements within a chip, meters.
fixed_phase_offset = 0; %in degrees. add a fixed phase offset before quantizing, as in kamoda et al. Used for time dithering model.
horn_distance = .058; %distance to horn antenna.
 
phase_accuracy = 180; %msb phase resolution, degrees.
chip_spacing_x = .003924+.000087336; %die width in X plus spacing between dies. Meters.
chip_spacing_y = .004084+.0000866; %die width in in Y plus spacing between dies. Meters.
 
antennas_per_chip = 7; %number of antennas on one edge of the chip.
number_of_chips = 14; %number of chips in one dimension.
 
 c = physconst('LightSpeed');
lambda = c/Fc; %wavelengh, meters.
 
 
n=number_of_chips*antennas_per_chip; %number of antennas.
%generating array of antenna locations.
dist_array_x = elem_dist_x*[0:1:antennas_per_chip-1]; %distances for each element within a chip.
dist_array_y = elem_dist_y*[0:1:antennas_per_chip-1]; %distances for each element within a chip.
elem_pos_x = repmat(dist_array_x,antennas_per_chip*number_of_chips,number_of_chips) - (antennas_per_chip*elem_dist_x/2);
elem_pos_y = repmat(dist_array_y,antennas_per_chip*number_of_chips,number_of_chips) - (antennas_per_chip*elem_dist_y/2);
elem_pos_y = elem_pos_y';
elem_pos_z = zeros(n);
 
chip_offsets_x = ([1:number_of_chips]*chip_spacing_x); %distance offsets due to chip spacing.
chip_offsets_x = chip_offsets_x - mean(chip_offsets_x); %zero centers it.
 
chip_offsets_expanded_x = repelem(chip_offsets_x,antennas_per_chip);
chip_offsets_expanded_x = repmat(chip_offsets_expanded_x,antennas_per_chip*number_of_chips,1);
 
chip_offsets_y = ([1:number_of_chips]*chip_spacing_y); %distance offsets due to chip spacing.
chip_offsets_y = chip_offsets_y - mean(chip_offsets_y); %zero centers it.
 
chip_offsets_expanded_y = repelem(chip_offsets_y,antennas_per_chip);
chip_offsets_expanded_y = repmat(chip_offsets_expanded_y,antennas_per_chip*number_of_chips,1);
chip_offsets_expanded_y = chip_offsets_expanded_y';
 
%final antenna locations based on chip positioning.
elem_pos_x = elem_pos_x + chip_offsets_expanded_x;
elem_pos_y = elem_pos_y + chip_offsets_expanded_y;
 
elem_pos_x = elem_pos_x + (elem_dist_x/2); %fix the positioning so that we're in the center of the array.
elem_pos_y = elem_pos_y + (elem_dist_y/2);
 
%feed phase model.
elem_center_dist = sqrt((elem_pos_x.*elem_pos_x)+(elem_pos_y.*elem_pos_y)); %distance to center element
feed_distance_error_m = sqrt((horn_distance*horn_distance)+(elem_center_dist.*elem_center_dist))-horn_distance; %extra distance incurred by the path length from the horn.
feed_distance_error_lambda = feed_distance_error_m/lambda; %number of wavelengths of error.
feed_phase_error = (feed_distance_error_lambda*360); %degrees of error.
 
%calculation of phases, ignoring feed error.
phases = ((-360/lambda)*((elem_pos_x*sind(beam_angle_theta)*cosd(beam_angle_phi))+(elem_pos_y*sind(beam_angle_phi)*sind(beam_angle_theta))));
phases = phases + feed_phase_error; %add in the feed error for phase calculation.
 
phases = phases+fixed_phase_offset; %add in the fixed phase offset.
 
%round the phases, undo the wrapping.
phases_rounded = wrapTo360(round(phases/(phase_accuracy))*phase_accuracy);
phases_rounded = phases_rounded - 360*(phases_rounded==360);
 
figure();
imshow(mat2gray(phases_rounded))
title('Quantized Phases')
 
 
phases_rounded_total = phases_rounded - feed_phase_error; %Physical model, to emulate the feed's phase distribution due to setup geometry.
phases_rad = phases_rounded_total*pi/180; %radians.
 
phases_weights = exp(1i*phases_rad); %This is a voltage.
 
%this is an approximation of aperture taper. 
elem_ang_x_deg = atand(horn_distance./elem_pos_x);
elem_ang_y_deg = atand(horn_distance./elem_pos_y);
cos_taper = abs(((cosd(elem_ang_x_deg-90)).^2.1)).*abs(((cosd(elem_ang_y_deg-90)).^2.1)); %Pretty close to our real system.
 
phases_weights = phases_weights .* cos_taper;
phases_weights = phases_weights/sqrt(numel(phases_weights)); %The amount of energy shouldn't change based on the number of antennas. This is a quirk in matlab's phased array toolbox.


%calculating radiation pattern. 
 
elemantenna = phased.CosineAntennaElement('FrequencyRange',[0.5*Fc 2*Fc],'CosinePower',[0.8 0.8]); %more closely matches our antenna's directivity of 7dbi.
 
%massage element locations to fit it into the toolbox functions.
elem_pos_shaped = [reshape(elem_pos_z,1,numel(elem_pos_z));reshape(elem_pos_x,1,numel(elem_pos_x));reshape(elem_pos_y,1,numel(elem_pos_y))];
phases_weights = reshape(phases_weights,1,numel(phases_weights));
%build array.
array_steered = phased.ConformalArray('Element',elemantenna,'ElementPosition',elem_pos_shaped,'Taper',phases_weights);
 
 
ang = [-90:0.25:90]; %angles to sample.
 
array_steered_response = phased.ArrayResponse('SensorArray',array_steered);
 
if(beam_angle_phi)
%phi response
    a = array_steered_response(Fc,[ang;0*ones(1,numel(ang))]);
else
%theta response
    a = array_steered_response(Fc,[0*ones(1,numel(ang));ang]);
end
 
a_power_db = pow2db(abs(a.^2)); %E field is coming out, need to square it to get power.
f = figure(100);
hold on
plot(ang,a_power_db - max(a_power_db),'linewidth',2);
xlabel("Azimuth Angle (degrees)");
ylabel('Relative Power (dB)')
title('Radiation Pattern Magnitude')
 
ylim([-50,0]);
xlim([-80 80]);
 
figure(101); %plot phases.
hold on;
radiated_phases_deg = wrapTo360((angle(a)*180/pi)- 180 - fixed_phase_offset);
plot(ang,(radiated_phases_deg)-180);
xlabel('Azimuth (deg)')
ylabel('Phase (deg)')
title('Radiation Pattern Phase')
 
xlim([-80 80]);
ylim([-200 200]);
 
