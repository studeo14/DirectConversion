

pkg load signal;
pkg load communications;

fs = 32e6;
chip_rate = 1e3;
T = 10e-3;
N = T/(1/fs);

d = randint(1, 10, 4, 0);
y = pskmod(d, 4, 0, "gray");
z = awgn(y, 50, "measured", 0);
ratio = fs/chip_rate;
baseband = repelem(z, ratio);
fc = 7e6;
t = (1/fs)*(0:N-1);
carrier = 0.5*exp(1i*2*pi*fc*t);
upconverted = awgn(carrier, 20, "measured", 0);

downconverted = real(upconverted).*conj(carrier);
samples_quant = int8(round(real(upconverted) * (2^7)));

figure(1);
subplot(2,1,1);
plot(mag2db(abs(fftshift(fft(real(upconverted))))));
subplot(2,1,2);
plot(mag2db(abs(fftshift(fft(samples_quant)))));
%pwelch(upconverted, [], [], 256, fs, 'shift', 'power');
%

ff = fopen("./samples.txt", "w");
fprintf(ff, "%d\n", samples_quant);
fclose(ff);

pause;

ff = csvread("./o_samples.txt");
o_samples = complex(ff(:,1), ff(:,2));
figure(2);
subplot(3,1,1);
fr = linspace(-fs/2, fs/2, length(o_samples));
plot(fr, mag2db(abs(fftshift(fft(o_samples)))));
subplot(3,1,2);
plot(fr, mag2db(abs(fftshift(fft(complex(ff(:,4), ff(:,5)))))));
%pwelch(o_samples, [], [], [], fs, "shift", "power");
subplot(3,1,3);
plot(fr, mag2db(abs(fftshift(fft(ff(:,3)/(2^7))))));

%pwelch(samples_quant/(2^7), [], [], [], fs, "shift", "power");
