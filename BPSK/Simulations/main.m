%% Main file of BPSK Simulator
% From here, we will script everything.
clear;   %clear workspace
clc;     %clear console
%% Setup
setup.plots   = 1;  %If 1, plot data. In this case, ntrials will be 1.
setup.ntrials = 1000;  %Montecarlo trials in simulation

TXparameters.bits          = 1000;
RRCparameters.sampsPerSym  = 8;   %Upsampling factor
RRCparameters.beta         = 0.5; %Rollof factor
RRCparameters.Nsym         = 6;   %Filter span in symbol durations

TXparameters.Fs = 40e6; %Sampling Rate
TXparameters.time_period = TXparameters.Fs^-1;

H_psk_mod = comm.PSKModulator('ModulationOrder',2,...
    'PhaseOffset',pi);

H_psk_demod = comm.PSKDemodulator ('ModulationOrder',2,...
    'PhaseOffset',pi,...
    'BitOutput',true);

rctFilt = comm.RaisedCosineTransmitFilter(...
    'Shape',                  'Normal', ...
    'RolloffFactor',          RRCparameters.beta, ...
    'FilterSpanInSymbols',    RRCparameters.Nsym, ...
    'OutputSamplesPerSymbol', RRCparameters.sampsPerSym);

rctFiltRX = comm.RaisedCosineReceiveFilter(...
    'Shape',                  'Normal', ...
    'RolloffFactor',          RRCparameters.beta, ...
    'FilterSpanInSymbols',    RRCparameters.Nsym, ...
    'InputSamplesPerSymbol',  RRCparameters.sampsPerSym);

H_awgn = comm.AWGNChannel('NoiseMethod','Signal to noise ratio (SNR)',...
    'SNR',15,...
    'BitsPerSymbol',1,...
    'SignalPower',1,...
    'SamplesPerSymbol',RRCparameters.sampsPerSym);


%Check system to see if there is GPU;
%if GPU set to true
if (gpuDeviceCount)
    setup.GPU = 1;
end
if setup.plots == 1
    setup.ntrials = 1  %Number of MonteCarlo Trials is set to 1 to avoid figure explosion.
end


%% Simulation

%Transmitter
dataBits = randi([0,1], bits, 1);

%Error Correction Code

%Modulate Bits
modulatedData = step(H_psk_mod,dataBits);

%padd with zeros at the end

scatter(real(modulatedData),imag(modulatedData))
grid on;
hold on;

%RRC
filteredData = rctFilt(modulatedData);
scatter(real(filteredData),imag(filteredData));


%AWGN
%There is a GPU version
channelData = step(H_awgn,filteredData);
scatter(real(channelData),imag(channelData));

%Receiver

%RRC - Matched Filter
recivedSignal = step(rctFiltRX,channelData);

%Demodulate
bitsDemod = step(H_psk_demod,recivedSignal);

%OTA BER

%Channel Decoding

%Coded BER


%% Results