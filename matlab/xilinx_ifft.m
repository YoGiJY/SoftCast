function [ ifft_out ] = xilinx_ifft( ifft_in,indFrame )
%XILINX_FFT 调用xilinx的FFT model
%   此处显示详细说明
global ifft_overflow_all;

%% Xilinx FFT参数
generics.C_NFFT_MAX = 12;
generics.C_ARCH = 1;
generics.C_HAS_NFFT = 0;
generics.C_USE_FLT_PT = 0;
generics.C_INPUT_WIDTH = 16; % Must be 32 if C_USE_FLT_PT = 1
generics.C_TWIDDLE_WIDTH = 16; % Must be 24 or 25 if C_USE_FLT_PT = 1
generics.C_HAS_SCALING = 1; % Set to 0 if C_USE_FLT_PT = 1
generics.C_HAS_BFP = 0; % Set to 0 if C_USE_FLT_PT = 1
generics.C_HAS_ROUNDING = 1; % Set to 0 if C_USE_FLT_PT = 1

    %% Xilinx IFFT
    if generics.C_USE_FLT_PT == 0
    % Set up quantizer for correct twos's complement, fixed-point format: one sign bit, C_INPUT_WIDTH-1 fractional bits
    q = quantizer([generics.C_INPUT_WIDTH, generics.C_INPUT_WIDTH-1], 'fixed', 'convergent', 'saturate');
    % Format data for fixed-point input
    input = quantize(q,ifft_in);
    else
    % Floating point interface - use data directly
    input = ifft_in;
    end
  
    % Set point size for this transform
    nfft = generics.C_NFFT_MAX;
  
    % Set up scaling schedule: scaling_sch[1] is the scaling for the first stage
    % Scaling schedule to 1/N: 
    %    2 in each stage for Radix-4/Pipelined, Streaming I/O
    %    1 in each stage for Radix-2/Radix-2 Lite
    if generics.C_ARCH == 1 || generics.C_ARCH == 3
    scaling_sch = ones(1,floor(nfft/2)) * 1;
    if mod(nfft,2) == 1
      scaling_sch = [scaling_sch 1];
    end
    else
      scaling_sch = ones(1,nfft);
    end

    ifft_out = zeros(size(input));
    % Set FFT (1) or IFFT (0)
    direction = 0;
    
    ifft_overflow = zeros(1,size(ifft_in,2));
    
    for i = 1:size(ifft_in,2)
    % Run the MEX function
    [ifft_out(:,i), ifft_blkexp, ifft_overflow(i)] = xfft_v9_0_bitacc_mex(generics, nfft, input(:,i), scaling_sch, direction);
    end
    
    ifft_overflow_all(indFrame) = ifft_overflow_all(indFrame) + sum(ifft_overflow);
    
    if (ifft_overflow_all(indFrame) ~= 0)
        warning('IFFT have overflow!');
    end     

    ifft_out = ifft_out*2^(sum(scaling_sch)-12);
end

