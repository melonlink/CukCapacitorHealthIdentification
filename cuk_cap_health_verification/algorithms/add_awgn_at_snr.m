function noisy = add_awgn_at_snr(signal, snrDb, seed)
%ADD_AWGN_AT_SNR Add deterministic white Gaussian noise at measured RMS SNR.

rng(seed, "twister");
signalRms = rms(signal);
noiseRms = signalRms / 10^(snrDb/20);
noisy = signal + noiseRms * randn(size(signal));
end

