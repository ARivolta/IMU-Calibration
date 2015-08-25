%% IMU_Calibration         %
% Author: Mattia Giurato   %
% Last review: 2015/07/31  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
close all 
% clc

%% Parameters definition
Parameters

%% Import logged data
RAW = dlmread('log_raw_3.txt');
acc = RAW(:,1:3);
gyro = RAW(:,4:6);
mag = RAW(:,7:9);

%% Getting information from logged data
fs = 50;                   %[Hz]
dt = 1/fs;

flag = 0;
sstart = 0;
sstop = length(RAW);
    
t = 0 : dt : (length(RAW)*dt - dt);

%% Plot RAW data
% figure('name','Accelerometer')
% plot(t, acc(:,1))
% hold on
% plot(t, acc(:,2))
% plot(t, acc(:,3))
% hold off
% legend('X_{body}', 'Y_{body}', 'Z_{body}')
% title('Accelerometer RAW data')
% grid
% 
% figure('name','Gyroscope')
% plot(t, gyro(:,1))
% hold on
% plot(t, gyro(:,2))
% plot(t, gyro(:,3))
% hold off
% legend('p', 'q', 'r')
% title('Gyroscope RAW data')
% grid
% 
% figure('name','Magnetometer')
% plot(t, mag(:,1))
% hold on
% plot(t, mag(:,2))
% plot(t, mag(:,3))
% hold off
% legend('X_{body}', 'Y_{body}', 'Z_{body}')
% title('Magnetometer RAW data')
% grid

%% Filtering RAW data
LPF = designfilt('lowpassfir','PassbandFrequency',0.10, ...
      'StopbandFrequency',0.15,'PassbandRipple',0.1, ...
      'StopbandAttenuation',65,'DesignMethod','kaiserwin');
% fvtool(LPF)

acc_f = filtfilt(LPF,acc);

gyro_f = filtfilt(LPF,gyro);
 
% figure('name', 'test')
% plot(t, acc)
% hold on
% plot(t, acc_f)
% hold off
% grid minor

% figure('name','Accelerometer')
% plot(t, acc_f(:,1))
% hold on
% plot(t, acc_f(:,2))
% plot(t, acc_f(:,3))
% hold off
% title('Accelerometer filtered data')
% legend('X_{body}', 'Y_{body}', 'Z_{body}')
% grid
% 
% figure('name','Gyroscope')
% plot(t, gyro_f(:,1))
% hold on
% plot(t, gyro_f(:,2))
% plot(t, gyro_f(:,3))
% hold off
% legend('p', 'q', 'r')
% title('Gyroscope filtered data')
% grid

%% Calibrating accelerometer

% Find gains and biases
bias_a_guess = .5;
gain_a_guess = 9.81/1000;

optionsOpt = optimset('LargeScale', 'off', 'Display', 'off', 'TolX', 1E-21, 'TolFun', 1E-21, 'HessUpdate', 'bfgs', 'MaxIter', 128);  
optVal = [ones(1,3)*bias_a_guess ones(1,3)*gain_a_guess];  	% vector of initial guess for optimal value
optValScaler = 1 ./ optVal;                                 % individual scalers unit optimal values
optVal = optVal .* optValScaler;                            % initial guess for optimal values = unity
optVal = fminunc('objFunAccelMag', optVal, optionsOpt, optValScaler, acc_f, 9.81);
optVal = optVal ./ optValScaler;                            % rescale optimal values to original units
bias_a = optVal(1:3);
gain_a = optVal(4:6);

% Plot calibrated data
figure('name','Accelerometer Calibration');
subplot(3,1,1:2)
    hold on;    
    acc_c(:,1) = gain_a(1) * acc_f(:,1) - bias_a(1);
    acc_c(:,2) = gain_a(2) * acc_f(:,2) - bias_a(2);
    acc_c(:,3) = gain_a(3) * acc_f(:,3) - bias_a(3);
    plot(1:length(acc_c), acc_c(:,1), 'b');
    plot(1:length(acc_c), acc_c(:,2), 'r');
    plot(1:length(acc_c), acc_c(:,3), 'g');
    legend('X', 'Y', 'Z');
    title('Accelerometer calibration');
    ylabel('Sensor units');
subplot(3,1,3)    
    hold on;
    plot(1:length(acc_c), sqrt((acc_c(:,1).^2) + (acc_c(:,2).^2) + (acc_c(:,3).^2)), 'Color', [0.6, 0.6, 0.6]);
    plot([0 length(acc_c)], [9.81 9.81], 'k:');
    legend('Measured g', 'g');
    ylabel('[m/s^2]');
    xlabel('Sample');
drawnow;

%Print gains and biases
disp('The estimated Accelerometer biases are:')
disp(['X:', num2str(bias_a(1))])
disp(['Y:', num2str(bias_a(2))])
disp(['Z:', num2str(bias_a(3))])
disp('The estimated Accelerometer scale factors are:')
disp(['X:', num2str(gain_a(1))])
disp(['Y:', num2str(gain_a(2))])
disp(['Z:', num2str(gain_a(3))])

%% Calibrating magnetometer

% Find gains and biases
bias_m_guess = 0.2;
gain_m_guess = 1/360;

optionsOpt = optimset('LargeScale', 'off', 'Display', 'off', 'TolX', 1E-21, 'TolFun', 1E-21, 'HessUpdate', 'bfgs', 'MaxIter', 128);  
optVal = [ones(1,3)*bias_m_guess ones(1,3)*gain_m_guess];  	% vector of initial guess for optimal value
optValScaler = 1 ./ optVal;                                 % individual scalers unit optimal values
optVal = optVal .* optValScaler;                            % initial guess for optimal values = unity
optVal = fminunc('objFunAccelMag', optVal, optionsOpt, optValScaler, mag, 1);
optVal = optVal ./ optValScaler;                            % rescale optimal values to original units
bias_m = optVal(1:3);
gain_m = optVal(4:6);

% Plot calibrated data
figure('name','Magnetometer Calibration');
subplot(3,1,1:2)
    hold on;    
    mag_c(:,1) = gain_m(1) * mag(:,1) - bias_m(1);
    mag_c(:,2) = gain_m(2) * mag(:,2) - bias_m(2);
    mag_c(:,3) = gain_m(3) * mag(:,3) - bias_m(3);
    plot(1:length(mag_c), mag_c(:,1), 'b');
    plot(1:length(mag_c), mag_c(:,2), 'r');
    plot(1:length(mag_c), mag_c(:,3), 'g');
    legend('X', 'Y', 'Z');
    title('Magnetometer calibration');
    ylabel('Sensor units');
subplot(3,1,3)    
    hold on;
    plot(1:length(mag_c), sqrt((mag_c(:,1).^2) + (mag_c(:,2).^2) + (mag_c(:,3).^2)), 'Color', [0.6, 0.6, 0.6]);
    plot([0 length(mag_c)], [1 1], 'k:');
    legend('Measured field', 'field');
    ylabel('[]');
    xlabel('Sample');
drawnow;

%Print gains and biases
disp('The estimated Magnetometer biases are:')
disp(['X:', num2str(bias_m(1))])
disp(['Y:', num2str(bias_m(2))])
disp(['Z:', num2str(bias_m(3))])
disp('The estimated Magnetometer scale factors are:')
disp(['X:', num2str(gain_m(1))])
disp(['Y:', num2str(gain_m(2))])
disp(['Z:', num2str(gain_m(3))])

%% 3D PLOT
% figure('name','Accelerometer')
% plot3(acc_c(:,1), acc_c(:,2), acc_c(:,3))
% axis equal
% grid
% 
% figure('name','Magnetometer')
% plot3(mag_c(:,1), mag_c(:,2), mag_c(:,3))
% axis equal
% grid

%% End of code