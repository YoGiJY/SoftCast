close all;
fclose all;
clear;
%%
% PSNR_avg = zeros(16,4);
% for S_round = 1:16  %用于S的小数位宽选择
%      fprintf('S_rouand = %d\n', S_round)
% LineChunkNumVec = [1 5 10 30 50 150 300]; % for test.yuv
% LineChunkNumVec = [1 5 10 25 50]; % for foreman.yuv
% PSNR_avg = zeros(length(LineChunkNumVec),4);

global fix_point;
global sim_options;
global digi_sat_count;
global llr_sat_count;
global LineChunkNum;
global ifft_overflow_all;
global fft_overflow_all;
global last_correct_y;
global last_correct_uv;
global errorStats;
global H_set;

% for l = 1:length(LineChunkNumVec)  %用于平均chunk数选择
% 
%     LineChunkNum = LineChunkNumVec(l);
%     fprintf('Chunk Number per Avg Line = %d\n', LineChunkNum)

sim_options = set_sim_options
digi_sat_count = zeros(sim_options.TotalFrameNum,1);
llr_sat_count = zeros(sim_options.TotalFrameNum,1);

CodeBlkNum = ceil((LineChunkNum*sim_options.DcWidth + sum(sim_options.LambdaWidth))/sim_options.CodeLength);
last_correct_y = zeros(sim_options.CodeLength,CodeBlkNum);
last_correct_uv = zeros(sim_options.CodeLength,CodeBlkNum);

psnr_y = zeros(sim_options.TotalFrameNum, numel(sim_options.SNR));
psnr_yuv = zeros(sim_options.TotalFrameNum, numel(sim_options.SNR));

%%
imginfo.H       = sim_options.FrameHeight;
imginfo.W       = sim_options.FrameWidth;
imginfo.cH      = imginfo.H / 2;
imginfo.cW      = imginfo.W / 2;
imginfo.blkH    = sim_options.chunkH;
imginfo.blkW    = sim_options.chunkW;
imginfo.Ysz     = imginfo.H * imginfo.W;
imginfo.Usz     = imginfo.cH * imginfo.cW;
imginfo.Vsz     = imginfo.cH * imginfo.cW;

blockNumW       = imginfo.W/imginfo.blkW;
blockNumH       = imginfo.H/imginfo.blkH;

rng default

%%
% Create a turbo encoder and decoder pair, where the interleaver indices
% are supplied by an input argument to the |step| function.
ModLength = ((sim_options.CodeLength+sim_options.CRCLength)*3+12)/4;
% intrlvrIndices = randperm(sim_options.CodeLength+sim_options.CRCLength);
intrlvrIndices = load('interleaverIndex_216bit.txt').'+1;
hTEnc = comm.TurboEncoder('TrellisStructure',poly2trellis(4, ...
    [13 15],13),'InterleaverIndices',intrlvrIndices);

hTDec = comm.TurboDecoder('TrellisStructure',poly2trellis(4, ...
    [13 15],13),'InterleaverIndices',intrlvrIndices, ...
    'NumIterations',6);

% Create a QPSK modulator and demodulator pair, where the demodulator
% outputs soft bits determined by using a log-likelihood ratio method. The
% modulator and demodulator objects are normalized to use an average power
% of 1 W.
hMod = comm.RectangularQAMModulator('ModulationOrder',sim_options.M, ...
    'BitInput',true, ...
    'NormalizationMethod','Average power');

pMod = comm.QPSKModulator;
pDemod = comm.QPSKDemodulator;

crcGen = comm.CRCGenerator([16 15 2 0],'ChecksumsPerFrame',CodeBlkNum);
crcDet = comm.CRCDetector([16 15 2 0]);

%% 信道模型参数
Ts = sim_options.Ts;
tau = sim_options.tau;
pl = sim_options.pl;
dopshift = sim_options.dopshift;
kfactor = sim_options.kfactor;
Nfft = sim_options.FFTLen;
S_round = 9;      %S的小数位宽
S_intbits = 6;    %S的整数部分
[chan,pathgains] = matlab_InitChan(1/Ts, tau, pl, 0, dopshift, 'Rician', kfactor, 1, 2, 'Low', 0, 1);

     hfft = dsp.FFT('FFTLengthSource', 'Property', ...
    'FFTLength', 4096,...
    'RoundingMethod','floor',...
    'OverflowAction','Wrap',...
    'SineTableDataType','Custom',...
    'CustomSineTableDataType',numerictype([],9),...
    'AccumulatorDataType','Same as input',...
    'OutputDataType','Same as input');

hifft = dsp.IFFT('FFTLengthSource', 'Property', ...
    'FFTLength', 4096,...
    'RoundingMethod','floor',...
    'OverflowAction','Wrap',...
    'SineTableDataType','Custom',...
    'CustomSineTableDataType',numerictype([],9),...
    'AccumulatorDataType','Same as input',...
    'OutputDataType','Same as input');

L_Nrows = length(sim_options.L_rows)-1;
maxDC = zeros(sim_options.TotalFrameNum,1);
maxS = zeros(sim_options.TotalFrameNum,1);
maxL = zeros(sim_options.TotalFrameNum,L_Nrows);
ChunkEnergyAverage = zeros(sim_options.TotalFrameNum,1);
errorStats = zeros(3,length(sim_options.SNR),sim_options.TotalFrameNum);
IFFT_SNR = zeros(sim_options.TotalFrameNum,1);
FFT_SNR = zeros(sim_options.TotalFrameNum,1);
ifft_overflow_all = zeros(sim_options.TotalFrameNum,1);
fft_overflow_all = zeros(sim_options.TotalFrameNum,1);
% lambda_avg = ones(L_Nrows,sim_options.TotalFrameNum+1);

for indFrame = 1:sim_options.TotalFrameNum
    
    %% 图像帧提取
    [Pic,Pic_u,Pic_v] = fx_LoadNFrm (sim_options.fid, imginfo, 1); %从fid指向的视频文件load 1帧，352*288（只含Y分量）
    Pic_yuv = cat(1,Pic,cat(2,Pic_u,Pic_v));
    [Mblocks_yuv,Mblocks_y,Mblocks_uv] = pic2blocks_yuv(Pic,Pic_u,Pic_v,imginfo); %将Pic转换成32x32的宏块组
    
    blockNum = size(Mblocks_yuv,3);
    blockNum_y = size(Mblocks_y,3);
    blockNum_uv = size(Mblocks_uv,3);
    
    %% DCT变换并计算lambda
    [DC_coef_y,lambda_y,blockC_y] = dct_lambda_calc(Mblocks_y,blockNum_y);
    [DC_coef_uv,lambda_uv,blockC_uv] = dct_lambda_calc(Mblocks_uv,blockNum_uv);
        
    lineNum = blockNum_uv/LineChunkNum;

    %% lambda求平均并为伪模拟数据进行功率分配
    [lambda_y_avg, S_y,  G_y, g_y, L_y] = softcast_avg(lambda_y,blockC_y,lineNum*2);
    [lambda_uv_avg, S_uv, G_uv, g_uv, L_uv] = softcast_avg(lambda_uv,blockC_uv,lineNum);
    
    %% 合并YUV
    for i = 1:size(S_uv,3)
        S(:,:,(i-1)*3+1) = S_y(:,:,(i-1)*2+1);
        S(:,:,(i-1)*3+2) = S_y(:,:,(i-1)*2+2);
        S(:,:,(i-1)*3+3) = S_uv(:,:,i);
        G(:,:,(i-1)*3+1) = G_y(:,:,(i-1)*2+1);
        G(:,:,(i-1)*3+2) = G_y(:,:,(i-1)*2+2);
        G(:,:,(i-1)*3+3) = G_uv(:,:,i);
        g(:,(i-1)*3+1) = g_y(:,(i-1)*2+1);
        g(:,(i-1)*3+2) = g_y(:,(i-1)*2+2);
        g(:,(i-1)*3+3) = g_uv(:,i);
        L(:,:,(i-1)*3+1) = L_y(:,:,(i-1)*2+1);
        L(:,:,(i-1)*3+2) = L_y(:,:,(i-1)*2+2);
        L(:,:,(i-1)*3+3) = L_uv(:,:,i);
        DC_coef((i-1)*3+1) = DC_coef_y((i-1)*2+1);
        DC_coef((i-1)*3+2) = DC_coef_y((i-1)*2+2);
        DC_coef((i-1)*3+3) = DC_coef_uv(i);
    end
    
    lambda_avg = cat(2,lambda_y_avg,lambda_uv_avg);
    
    %% 统计DC系数、Lambda和模拟数据的最大值
    maxDC(indFrame) = max(abs(DC_coef));
    for i = 1 : L_Nrows
        maxL(indFrame,i) = max(lambda_avg(i,:));
    end
    maxS(indFrame) = max(abs(S(:)));
    ChunkEnergyAverage(indFrame) = mean(sum(sum(S.^2)));
    
    %% 组行数据
    [data_y_lines,S_y_complex,crcdata_y,code_data_y,encodedData_y,modSignal_y] = form_data_line(DC_coef_y,lambda_y_avg,S_y,LineChunkNum,lineNum*2,crcGen,hTEnc,hMod,pMod,indFrame);
    [data_uv_lines,S_uv_complex,crcdata_uv,code_data_uv,encodedData_uv,modSignal_uv] = form_data_line(DC_coef_uv,lambda_uv_avg,S_uv,LineChunkNum,lineNum,crcGen,hTEnc,hMod,pMod,indFrame);
    
    data_line_size = size(data_y_lines,1);
    data_lines = zeros(data_line_size,lineNum*3);
    
    for i = 1:lineNum
        data_lines(:,(i-1)*3+1) = data_y_lines(:,(i-1)*2+1);
        data_lines(:,(i-1)*3+2) = data_y_lines(:,(i-1)*2+2);
        data_lines(:,(i-1)*3+3) = data_uv_lines(:,i);
    end
    
    %% 组无线帧
    % generate preamble
    preamble = tx_gen_preamble_linecast(sim_options);

    % genrate pilot
%     refC = constellation(pMod);
%     pilot = refC(randi(4, 840, 1));
%     
%     if (fix_point == 1)
%         pilot = round(pilot*2^10)/2^10;
%     end
    
    pilot0 = load('pilot_slot0.txt');
    pilot0 = complex(pilot0(:,1),pilot0(:,2));
    pilot4 = load('pilot_slot4.txt');
    pilot4 = complex(pilot4(:,1),pilot4(:,2));
    pilot = cat(1,pilot0,pilot4)/1024;
    
    ifft_in = FrameTrans(data_lines,pilot.',preamble,sim_options.FrameLineNum); %组帧

    ifft_in_scale = ifft_in/2^S_intbits; %scale down to (-1,1)
    
    %% IFFT
    if ((strcmp(sim_options.FFTsel, 'Xilinx') == 1) && (fix_point == 1))
    ifft_out = xilinx_ifft(ifft_in_scale,indFrame);
    ifft_out = ifft_out.*sqrt(sim_options.FFTLen)*2^S_intbits; %scale up back
    
    ifft_out_ref = ifft(ifft_in_scale).*sqrt(sim_options.FFTLen)*2^S_intbits;
    IFFT_SNR(indFrame) = 10*log10(mean(mean(abs(ifft_out_ref).^2))/mean(mean(abs(ifft_out-ifft_out_ref).^2)));
    noise_ifft = 10^(-IFFT_SNR(indFrame)/10);
    else
    ifft_out = ifft(ifft_in_scale).*sqrt(sim_options.FFTLen)*2^S_intbits; %scale up back
    end

    % add CP
    ifft_cp = cat(1,ifft_out(4097-sim_options.CPLength:4096,:),ifft_out);
    
    %% 产生信道
    CIR = zeros(2*sim_options.FFTLen,2,length(ifft_cp(:))/length(ifft_cp));
    Hideal = zeros(4096,length(ifft_cp(:))/length(ifft_cp));
    receive = zeros(length(ifft_cp),2,length(ifft_cp(:))/length(ifft_cp));

    for yy = 1:size(ifft_cp,2)
        
        [receive(1:sim_options.FFTLen + sim_options.CPLength,:,yy), CIR(:,:,yy)] = matlab_ChanFilter1(chan, ifft_cp(1:sim_options.FFTLen + sim_options.CPLength,yy));
        CIRideal = CIR(1:Nfft,1,:) * sqrt(Nfft);
        Hideal(:,yy) = fft(CIRideal(:,yy))./sqrt(sim_options.FFTLen);
    end
    
    %% 接收
    rxsig = zeros(size(ifft_cp));
    fft_out = zeros(sim_options.FFTLen,size(ifft_cp,2) + 1);
%     fft_out_ref = zeros(sim_options.FFTLen,size(ifft_cp,2));
    fre_offset = zeros(40,1);
    SNR = zeros(40,1);
    x_compensate_tmp = zeros(sim_options.FFTLen,size(ifft_cp,2));
    x_compensate = zeros(sim_options.AvailSymCa,size(ifft_cp,2));
    Hmmse_est = zeros(sim_options.AvailSymCa,size(ifft_cp,2));
    crc_err_y = zeros(length(sim_options.SNR),60);
    crc_err_uv = zeros(length(sim_options.SNR),30);
    
    for i = 1:length(sim_options.SNR)
        hError = comm.ErrorRate;
        EsN0dB = sim_options.SNR(i);
        noise_n = 10^(-EsN0dB/10);
        sigma_n = sqrt(noise_n/2);
%% 接收加噪
        for j = 1:size(ifft_cp,2)
            if(strcmp(sim_options.channel_option ,'awgn_chan') == 0)
                rxsig(:,j) = receive(1:sim_options.FFTLen + sim_options.CPLength,1,j) + ...
                    sigma_n*(randn(size(receive(1:sim_options.FFTLen + sim_options.CPLength,1,yy)))+1i*randn(size(receive(1:sim_options.FFTLen + sim_options.CPLength,1,yy))));
                                
            else
                rxsig(:,j) = ifft_cp(1:sim_options.FFTLen + sim_options.CPLength,j) + ...
                    sigma_n*(randn(size(ifft_cp(1:sim_options.FFTLen + sim_options.CPLength,yy)))+1i*randn(size(ifft_cp(1:sim_options.FFTLen + sim_options.CPLength,yy))));
            end
        end
        
        
        %% 接收FFT
        fft_start = sim_options.CPLength+1;
                        
        fft_in = rxsig(fft_start:fft_start+4095,:);
        fft_in_scale = fft_in/2^S_intbits; 
            
        if ((strcmp(sim_options.FFTsel, 'Xilinx') == 1) && (fix_point == 1))
            fft_out = xilinx_fft(fft_in_scale,indFrame);
            fft_out = fft_out./sqrt(sim_options.FFTLen)*2^S_intbits;%2^ceil(log2(maxRxsig(indFrame))); %scale up back

            fft_out_ref = fft(fft_in_scale)./sqrt(sim_options.FFTLen)*2^S_intbits;%2^ceil(log2(maxRxsig(indFrame)));
            FFT_SNR(indFrame) = 10*log10(mean(mean(abs(fft_out_ref).^2))/mean(mean(abs(fft_out(:,1:size(fft_in_scale,2))-fft_out_ref).^2)));
            noise_ifft = 10^(-FFT_SNR(indFrame)/10);
        else
            fft_out = fft(fft_in_scale)./sqrt(sim_options.FFTLen)*2^S_intbits;%2^ceil(log2(maxRxsig(indFrame))); %scale up back
        end
                
        fft_out(:,size(ifft_cp,2) + 1) = fft_out(:,1);
        
        %% 信道估计与解帧
        if(strcmp(sim_options.channel_option ,'awgn_chan') == 0)
             for j = 1: length(ifft_cp(1,:))/30
                    [mse(i,(j-1)*5 + 1),fre_offset((j-1)*5+1),x_compensate(:,(j-1)*30+1:(j-1)*30+6),Hmmse_est(:,(j-1)*30+1:(j-1)*30+6)] = Channel_estimation_func(Hideal(:,(j-1)*30+1:(j-1)*30+6),fft_out(:,(j-1)*30+1:(j-1)*30+7),reshape(pilot,[420,2]),sim_options.SNR(i));
                    [mse(i,(j-1)*5 + 2),fre_offset((j-1)*5+2),x_compensate(:,(j-1)*30+7:(j-1)*30+12),Hmmse_est(:,(j-1)*30+7:(j-1)*30+12)] = Channel_estimation_func(Hideal(:,(j-1)*30+7:(j-1)*30+12),fft_out(:,(j-1)*30+7:(j-1)*30+13),reshape(pilot,[420,2]),sim_options.SNR(i));
                    [mse(i,(j-1)*5 + 3),fre_offset((j-1)*5+3),x_compensate(:,(j-1)*30+13:(j-1)*30+18),Hmmse_est(:,(j-1)*30+13:(j-1)*30+18)] = Channel_estimation_func(Hideal(:,(j-1)*30+13:(j-1)*30+18),fft_out(:,(j-1)*30+13:(j-1)*30+19),reshape(pilot,[420,2]),sim_options.SNR(i));
                    [mse(i,(j-1)*5 + 4),fre_offset((j-1)*5+4),x_compensate(:,(j-1)*30+19:(j-1)*30+24),Hmmse_est(:,(j-1)*30+19:(j-1)*30+24)] = Channel_estimation_func(Hideal(:,(j-1)*30+19:(j-1)*30+24),fft_out(:,(j-1)*30+19:(j-1)*30+25),reshape(pilot,[420,2]),sim_options.SNR(i));
                    [mse(i,(j-1)*5 + 5),fre_offset((j-1)*5+5),x_compensate(:,(j-1)*30+25:(j-1)*30+30),Hmmse_est(:,(j-1)*30+25:(j-1)*30+30)] = Channel_estimation_func(Hideal(:,(j-1)*30+25:(j-1)*30+30),fft_out(:,(j-1)*30+25:(j-1)*30+31),reshape(pilot,[420,2]),sim_options.SNR(i));
             end
%              [rmodSignal,rS_complex] = DeFrames(x_compensate(:,1:size(ifft_cp,2)),ModLength*CodeBlkNum,sim_options.chunkSize/2*LineChunkNum,lineNum*3,sim_options.FrameSymNum);
%              [rmodSignal1,~] = DeFrames(Hmmse_est(:,1:size(ifft_cp,2)),ModLength*CodeBlkNum,sim_options.chunkSize/2*LineChunkNum,lineNum*3,sim_options.FrameSymNum);
             if(strcmp(H_set ,'ideal') == 0)
                 [rmodSignal,rS_complex] = DeFrames(x_compensate(:,1:size(ifft_cp,2)),ModLength*CodeBlkNum,sim_options.chunkSize/2*LineChunkNum,lineNum*3,sim_options.FrameSymNum);
                 [rmodSignal1,~] = DeFrames(Hmmse_est(:,1:size(ifft_cp,2)),ModLength*CodeBlkNum,sim_options.chunkSize/2*LineChunkNum,lineNum*3,sim_options.FrameSymNum);
             else
                 x_compensate_ideal = fft_out([1:1260 2837:4096],1:240)./Hideal([1:1260 2837:4096],1:240);
                 [rmodSignal,rS_complex] = DeFrames(x_compensate_ideal(:,1:size(ifft_cp,2)),ModLength*CodeBlkNum,sim_options.chunkSize/2*LineChunkNum,lineNum*3,sim_options.FrameSymNum);
                 [rmodSignal1,~] = DeFrames(Hideal([1:1260 2837:4096],1:size(ifft_cp,2)),ModLength*CodeBlkNum,sim_options.chunkSize/2*LineChunkNum,lineNum*3,sim_options.FrameSymNum);
%                  [~,rmodSignal1,~] = DeFrames(Hideal([1:1260 2837:4096],1:240),ModLength,sim_options.chunkSize/2,blockNum,sim_options.FrameChunkNum);
%                  [Frm_num,rmodSignal,rS_complex] = DeFrames(x_compensate_ideal(:,1:length(ifft_cp(:))/length(ifft_cp)),ModLength,sim_options.chunkSize/2,blockNum,sim_options.FrameChunkNum);
             end

        else
            [rmodSignal,rS_complex] = DeFrames(fft_out([1:1260 2837:4096],1:size(ifft_cp,2)),ModLength*CodeBlkNum,sim_options.chunkSize/2*LineChunkNum,lineNum*3,sim_options.FrameSymNum);
        end
        
        %% 拆分Y、UV
        rmodSignal_y_tmp = zeros(ModLength*CodeBlkNum,lineNum*2);
        rmodSignal_uv_tmp = zeros(ModLength*CodeBlkNum,lineNum);
        rmodSignal1_y_tmp = zeros(ModLength*CodeBlkNum,lineNum*2);
        rmodSignal1_uv_tmp = zeros(ModLength*CodeBlkNum,lineNum);
        rS_complex_y = zeros(size(S_y_complex));
        rS_complex_uv = zeros(size(S_uv_complex));
        
        for k = 1:lineNum
        rmodSignal_y_tmp(:,(k-1)*2+1) = rmodSignal(:,(k-1)*3+1);
        rmodSignal_y_tmp(:,(k-1)*2+2) = rmodSignal(:,(k-1)*3+2);
        rmodSignal_uv_tmp(:,k) = rmodSignal(:,(k-1)*3+3);
        if(strcmp(sim_options.channel_option ,'awgn_chan') == 0)
            rmodSignal1_y_tmp(:,(k-1)*2+1) = rmodSignal1(:,(k-1)*3+1);
            rmodSignal1_y_tmp(:,(k-1)*2+2) = rmodSignal1(:,(k-1)*3+2);
            rmodSignal1_uv_tmp(:,k) = rmodSignal1(:,(k-1)*3+3);
        end
        rS_complex_y(:,(k-1)*2+1) = rS_complex(:,(k-1)*3+1);
        rS_complex_y(:,(k-1)*2+2) = rS_complex(:,(k-1)*3+2);
        rS_complex_uv(:,k) = rS_complex(:,(k-1)*3+3);
        end
        
        rmodSignal_y = reshape(rmodSignal_y_tmp,ModLength,[]);
        rmodSignal_uv = reshape(rmodSignal_uv_tmp,ModLength,[]);
        if(strcmp(sim_options.channel_option ,'awgn_chan') == 0)
            rmodSignal1_y = reshape(rmodSignal1_y_tmp,ModLength,[]);
            rmodSignal1_uv = reshape(rmodSignal1_uv_tmp,ModLength,[]);
        else
            rmodSignal1_y = ones(size(rmodSignal_y));
            rmodSignal1_uv = ones(size(rmodSignal_uv));
        end
        
        
        S_y_rec = complex2real(rS_complex_y);
        S_uv_rec = complex2real(rS_complex_uv);
        S_rec = zeros(size(S));
        
        for k = 1:size(S_uv_rec,3)
            S_rec(:,:,(k-1)*3+1) = S_y_rec(:,:,(k-1)*2+1);
            S_rec(:,:,(k-1)*3+2) = S_y_rec(:,:,(k-1)*2+2);
            S_rec(:,:,(k-1)*3+3) = S_uv_rec(:,:,k);
        end
        
        if (fix_point == 1)
            if (sim_options.no_digi_err == 0)
            noise_total = noise_n;% + noise_fft + noise_ifft;
        EbNo = floor(10*log10(1/noise_total)) - 6;
        noiseVar = 10^(-EbNo/10)*(1/log2(sim_options.M));
%% 数字部分解调+译码
    [ receivedBits_y, llr_all_y(:,:,indFrame) ] = decode_digi( rmodSignal_y, rmodSignal1_y, modSignal_y,crcdata_y, hTDec, hError, lineNum*CodeBlkNum*2, i, indFrame );
    [ receivedBits_uv,llr_all_uv(:,:,indFrame) ] = decode_digi( rmodSignal_uv, rmodSignal1_uv, modSignal_uv,crcdata_uv, hTDec, hError, lineNum*CodeBlkNum, i, indFrame );
        
    % Display the error statistics.
    fprintf('Bit error rate = %5.2e\nNumber of errors = %d\nTotal bits = %d\n', ...
    errorStats(:,i,indFrame));

            end
    %% 将解调译码后的二进制数组恢复成lambda和DC系数
    crcdet_rbits_y = zeros(sim_options.CodeLength,size(crcdata_y,2));
    crcdet_rbits_uv = zeros(sim_options.CodeLength,size(crcdata_uv,2));
    
    for ii = 1:size(crcdata_y,2)
        if (sim_options.no_digi_err == 1)
            [crcdet_rbits_y(:,ii),~] = step(crcDet,crcdata_y(:,ii));
        else
            [crcdet_rbits_y(:,ii),crc_err_y(i,ii)] = step(crcDet,receivedBits_y(:,ii));
            if (sim_options.CRCCheck == true)
            if (crc_err_y(i,ii) == 1)
                if (mod(ii,3)==1)
                    crcdet_rbits_y(:,ii) = last_correct_y(:,1);
                elseif (mod(ii,3)==2)
                    crcdet_rbits_y(:,ii) = last_correct_y(:,2);
                else
                    crcdet_rbits_y(:,ii) = last_correct_y(:,3);
                end
            else
                if (mod(ii,3)==1)
                    last_correct_y(:,1) = crcdet_rbits_y(:,ii);
                elseif (mod(ii,3)==2)
                    last_correct_y(:,2) = crcdet_rbits_y(:,ii);
                else
                    last_correct_y(:,3) = crcdet_rbits_y(:,ii);
                end
            end
            end
        end
    end
    
    for ii = 1:size(crcdata_uv,2)
        if (sim_options.no_digi_err == 1)
            [crcdet_rbits_uv(:,ii),~] = step(crcDet,crcdata_uv(:,ii));
        else
            [crcdet_rbits_uv(:,ii),crc_err_uv(i,ii)] = step(crcDet,receivedBits_uv(:,ii));
            if (sim_options.CRCCheck == true)
            if (crc_err_uv(i,ii) == 1)
                if (mod(ii,3)==1)
                    crcdet_rbits_uv(:,ii) = last_correct_uv(:,1);
                elseif (mod(ii,3)==2)
                    crcdet_rbits_uv(:,ii) = last_correct_uv(:,2);
                else
                    crcdet_rbits_uv(:,ii) = last_correct_uv(:,3);
                end
            else
                if (mod(ii,3)==1)
                    last_correct_uv(:,1) = crcdet_rbits_uv(:,ii);
                elseif (mod(ii,3)==2)
                    last_correct_uv(:,2) = crcdet_rbits_uv(:,ii);
                else
                    last_correct_uv(:,3) = crcdet_rbits_uv(:,ii);
                end
            end
            end
        end
    end
    
    rbits_y = reshape(crcdet_rbits_y,size(code_data_y));
    rbits_uv = reshape(crcdet_rbits_uv,size(code_data_uv));
    
    rbits_lambda_y = rbits_y(1:sum(sim_options.LambdaWidth),:);
    rbits_dc_y = rbits_y(sum(sim_options.LambdaWidth)+1:sum(sim_options.LambdaWidth)+LineChunkNum*sim_options.DcWidth,:);
    
    rbits_lambda_uv = rbits_uv(1:sum(sim_options.LambdaWidth),:);
    rbits_dc_uv = rbits_uv(sum(sim_options.LambdaWidth)+1:sum(sim_options.LambdaWidth)+LineChunkNum*sim_options.DcWidth,:);
    
    recdata_dc_y = DigiCodeBlkRec(rbits_dc_y,ones(1,LineChunkNum),ones(1,LineChunkNum)*sim_options.DcWidth);
    DC_coef_y_rec = reshape(recdata_dc_y,2,[]);
    recdata_dc_uv = DigiCodeBlkRec(rbits_dc_uv,ones(1,LineChunkNum),ones(1,LineChunkNum)*sim_options.DcWidth);
    DC_coef_uv_rec = reshape(recdata_dc_uv,1,[]);
    lambda_y_avg_rec = DigiCodeBlkRec(rbits_lambda_y,zeros(size(sim_options.LambdaWidth)),sim_options.LambdaWidth);
    lambda_uv_avg_rec = DigiCodeBlkRec(rbits_lambda_uv,zeros(size(sim_options.LambdaWidth)),sim_options.LambdaWidth);

    DC_coef_rec = reshape(cat(1,DC_coef_y_rec,DC_coef_uv_rec),1,[]);
    
    for m = 1:lineNum
    lambda_y_rec_tmp(:,(2*m-2)*LineChunkNum+1:(2*m-1)*LineChunkNum) = repmat(lambda_y_avg_rec(:,(m-1)*2+1),1,1,LineChunkNum);
    lambda_y_rec_tmp(:,(2*m-1)*LineChunkNum+1:(2*m)*LineChunkNum) = repmat(lambda_y_avg_rec(:,(m-1)*2+2),1,1,LineChunkNum);
    lambda_uv_rec(:,(m-1)*LineChunkNum+1:m*LineChunkNum) = repmat(lambda_uv_avg_rec(:,m),1,1,LineChunkNum);
    end
    
    lambda_y_rec = reshape(lambda_y_rec_tmp,[],size(lambda_uv_rec,2));
    lambda_rec = reshape(cat(1,lambda_y_rec,lambda_uv_rec),size(lambda_uv_rec,1),[]);
    
    L_rec = zeros(size(L));
    G_rec = zeros(size(G));
    g_rec = zeros(size(g));
    
    for ii = 1:blockNum
        L_rec(:,:,ii) = Ltrans(lambda_rec(:,ii));
        [G_rec(:,:,ii),g_rec(:,ii)] = EnergyAllocationMethod(1,lambda_rec(:,ii)); %能量分配算法
       
    end
        end
        
       %% denoise and power de-allocation
        if (fix_point == 1)
            Chat = fx_dec_LLSE(S_rec, G_rec, L_rec, [], sigma_n, 0); %LLSE解码
        else
            Chat = fx_dec_LLSE(S_rec, G, L, [], sigma_n, 0); %LLSE解码
        end
        
        rxPicblocks = zeros(size(Chat));
        
        for j = 1:blockNum
            if (fix_point == 1)
                Chat(1,1,j) = DC_coef_rec(j); %DC系数用数字传输的代替
                rxPicblocks(:,:,j) = idct_fix(Chat(:,:,j)) + 128; %3维IDCT变换
            else
                Chat(1,1,j) = DC_coef(j); %DC系数用数字传输的代替
                rxPicblocks(:,:,j) = IDCT3(Chat(:,:,j)) + 128; %3维IDCT变换
            end
        end
        [rxPic,rxPic_u,rxPic_v] = blocks2pic_yuv( rxPicblocks, imginfo, blockNumH, blockNumW);
        rxPic = myround(rxPic);
        rxPic(rxPic > 255) = 255;
        rxPic(rxPic < 0)   = 0;
        rxPic_u = myround(rxPic_u);
        rxPic_u(rxPic_u > 255) = 255;
        rxPic_u(rxPic_u < 0)   = 0;
        rxPic_v = myround(rxPic_v);
        rxPic_v(rxPic_v > 255) = 255;
        rxPic_v(rxPic_v < 0)   = 0;
        rxPic_yuv = cat(1,rxPic,cat(2,rxPic_u,rxPic_v));
        %% calculate psnr
        psnr_y(indFrame, i) = fx_CalcPSNR(Pic, rxPic); %计算Y分量PSNR
        psnr_yuv(indFrame, i) = fx_CalcPSNR(Pic_yuv, rxPic_yuv); %计算U分量PSNR
        disp([indFrame EsN0dB psnr_y(indFrame, i) psnr_yuv(indFrame, i)]); %display psnr
    end
    
    bler(:,indFrame) = mean(cat(2,crc_err_uv,crc_err_y),2);
%     H_gain_min(:,indFrame) = 20*log10(min(abs(Hideal)));
    H_gain(:,indFrame) = 20*log10(mean(abs(Hideal),2));
%     H_gain_all(:,:,indFrame) = 20*log10(abs(Hideal));
    
    %% Save test vectors for rtl sim
    if (sim_options.dump_tx_testvec == true)
    [file_dct_in_y,~] = save_frame_testvec('TX/dct_in_y',indFrame,Mblocks_y,0,'myround');
    [flie_dct_in_uv,~] = save_frame_testvec('TX/dct_in_uv',indFrame,Mblocks_uv,0,'myround');
    
    [file_dct_out_y,~] = save_frame_testvec('TX/dct_out_y',indFrame,blockC_y,0,'myround');
    [flie_dct_out_uv,~] = save_frame_testvec('TX/dct_out_uv',indFrame,blockC_uv,0,'myround');
    
    [file_lambda_y,~] = save_frame_testvec('TX/lambda_y',indFrame,lambda_y,0,'myround');
    [file_lambda_y_avg,~] = save_frame_testvec('TX/lambda_y_avg',indFrame,lambda_y_avg,0,'myround');
    [flie_lambda_uv,~] = save_frame_testvec('TX/lambda_uv',indFrame,lambda_uv,0,'myround');
    [flie_lambda_uv_avg,~] = save_frame_testvec('TX/lambda_uv_avg',indFrame,lambda_uv_avg,0,'myround'); 
    
    [file_codedata_y,~] = save_frame_testvec('TX/codedata_y',indFrame,code_data_y,0,'myround');
    [file_crcdata_y,~] = save_frame_testvec('TX/crcdata_y',indFrame,crcdata_y,0,'myround');
    [flie_codedata_uv,~] = save_frame_testvec('TX/codedata_uv',indFrame,code_data_uv,0,'myround');
    [flie_crcdata_uv,~] = save_frame_testvec('TX/crcdata_uv',indFrame,crcdata_uv,0,'myround');
    
    [file_encodedata_y,~] = save_frame_testvec('TX/encodedata_y',indFrame,encodedData_y,0,'myround');
    [flie_encodedata_uv,~] = save_frame_testvec('TX/encodedata_uv',indFrame,encodedData_uv,0,'myround');
    
    [file_moddata_y_real,~] = save_frame_testvec('TX/moddata_y_real',indFrame,real(modSignal_y),9,'myround');
    [file_moddata_y_imag,~] = save_frame_testvec('TX/moddata_y_imag',indFrame,imag(modSignal_y),9,'myround');
    [flie_moddata_uv_real,~] = save_frame_testvec('TX/moddata_uv_real',indFrame,real(modSignal_uv),9,'myround');
    [flie_moddata_uv_imag,~] = save_frame_testvec('TX/moddata_uv_imag',indFrame,imag(modSignal_uv),9,'myround');
    
    [file_s_y,~] = save_frame_testvec('TX/s_y',indFrame,S_y,9,'myround');
    [flie_s_uv,~] = save_frame_testvec('TX/s_uv',indFrame,S_uv,9,'myround');
    [file_s_y_complex_real,~] = save_frame_testvec('TX/s_y_complex_real',indFrame,real(S_y_complex),9,'myround');
    [file_s_y_complex_imag,~] = save_frame_testvec('TX/s_y_complex_imag',indFrame,imag(S_y_complex),9,'myround');
    [flie_s_uv_complex_real,~] = save_frame_testvec('TX/s_uv_complex_real',indFrame,real(S_uv_complex),9,'myround');
    [flie_s_uv_complex_imag,~] = save_frame_testvec('TX/s_uv_complex_imag',indFrame,imag(S_uv_complex),9,'myround');
    [file_g,~] = save_frame_testvec('TX/gi',indFrame,g,16,'myround');
   
    [file_ifft_in_real,~] = save_frame_testvec('TX/ifft_in_real',indFrame,real(ifft_in),9,'convergent');
    [file_ifft_in_imag,~] = save_frame_testvec('TX/ifft_in_imag',indFrame,imag(ifft_in),9,'convergent');
    [file_ifft_out_real,~] = save_frame_testvec('TX/ifft_out_real',indFrame,real(ifft_out),9,'convergent');
    [file_ifft_out_imag,~] = save_frame_testvec('TX/ifft_out_imag',indFrame,imag(ifft_out),9,'convergent');
    [file_ifft_cp_real,~] = save_frame_testvec('TX/ifft_cp_real',indFrame,real(ifft_cp),9,'convergent');
    [file_ifft_cp_imag,~] = save_frame_testvec('TX/ifft_cp_imag',indFrame,imag(ifft_cp),9,'convergent');
    
    fprintf('Frame%d TX testvec dumped!\n',indFrame);
    end
    
    if (sim_options.dump_rx_testvec == true)
    dir_rx = sprintf('RX/%s_snr%d/',sim_options.ChanProfile,sim_options.SNR);
    [s,mess,messid] = mkdir(['../simdata/' dir_rx]);
    [file_rx_sig_real,~] = save_frame_testvec([dir_rx 'rx_sig_real'],indFrame,real(rxsig),9,'convergent');
    [file_rx_sig_imag,~] = save_frame_testvec([dir_rx 'rx_sig_imag'],indFrame,imag(rxsig),9,'convergent');
    [flie_fft_in_real,~] = save_frame_testvec([dir_rx 'fft_in_real'],indFrame,real(fft_in),9,'convergent');
    [flie_fft_in_imag,~] = save_frame_testvec([dir_rx 'fft_in_imag'],indFrame,imag(fft_in),9,'convergent');
    
    [file_fft_out_real,~] = save_frame_testvec([dir_rx 'fft_out_real'],indFrame,real(fft_out),9,'convergent');
    [file_fft_out_imag,~] = save_frame_testvec([dir_rx 'fft_out_imag'],indFrame,imag(fft_out),9,'convergent');
    [flie_pilot_real,~] = save_frame_testvec([dir_rx 'pilot_real'],indFrame,real(pilot),10,'myround');
    [flie_pilot_imag,~] = save_frame_testvec([dir_rx 'pilot_imag'],indFrame,imag(pilot),10,'myround');
    
    [file_x_compensate_real,~] = save_frame_testvec([dir_rx 'x_compensate_real'],indFrame,real(x_compensate),10,'myround');
    [file_x_compensate_imag,~] = save_frame_testvec([dir_rx 'x_compensate_imag'],indFrame,imag(x_compensate),10,'myround');
    [file_hmmse_est_real,~] = save_frame_testvec([dir_rx 'Hmmse_est_real'],indFrame,real(Hmmse_est),10,'myround');
    [file_hmmse_est_imag,~] = save_frame_testvec([dir_rx 'Hmmse_est_imag'],indFrame,imag(Hmmse_est),10,'myround');
    
    [flie_rmodSignal_real,~] = save_frame_testvec([dir_rx 'rmodSignal_real'],indFrame,real(rmodSignal),10,'myround');
    [flie_rmodSignal_imag,~] = save_frame_testvec([dir_rx 'rmodSignal_imag'],indFrame,imag(rmodSignal),10,'myround');
    [flie_rmodSignal_y_real,~] = save_frame_testvec([dir_rx 'rmodSignal_y_real'],indFrame,real(rmodSignal_y),10,'myround'); 
    [flie_rmodSignal_y_imag,~] = save_frame_testvec([dir_rx 'rmodSignal_y_imag'],indFrame,imag(rmodSignal_y),10,'myround'); 
    [flie_rmodSignal_uv_real,~] = save_frame_testvec([dir_rx 'rmodSignal_uv_real'],indFrame,real(rmodSignal_uv),10,'myround'); 
    [flie_rmodSignal_uv_imag,~] = save_frame_testvec([dir_rx 'rmodSignal_uv_imag'],indFrame,imag(rmodSignal_uv),10,'myround'); 
    
    [flie_rmodH_real,~] = save_frame_testvec([dir_rx 'rmodH_real'],indFrame,real(rmodSignal1),10,'myround');
    [flie_rmodH_imag,~] = save_frame_testvec([dir_rx 'rmodH_imag'],indFrame,imag(rmodSignal1),10,'myround');
    [flie_rmodH_y_real,~] = save_frame_testvec([dir_rx 'rmodH_y_real'],indFrame,real(rmodSignal1_y),10,'myround'); 
    [flie_rmodH_y_imag,~] = save_frame_testvec([dir_rx 'rmodH_y_imag'],indFrame,imag(rmodSignal1_y),10,'myround'); 
    [flie_rmodH_uv_real,~] = save_frame_testvec([dir_rx 'rmodH_uv_real'],indFrame,real(rmodSignal1_uv),10,'myround');
    [flie_rmodH_uv_imag,~] = save_frame_testvec([dir_rx 'rmodH_uv_imag'],indFrame,imag(rmodSignal1_uv),10,'myround');
    
    [flie_rS_complex_real,~] = save_frame_testvec([dir_rx 'rS_complex_real'],indFrame,real(rS_complex),10,'myround');
    [flie_rS_complex_imag,~] = save_frame_testvec([dir_rx 'rS_complex_imag'],indFrame,imag(rS_complex),10,'myround');
    [flie_rS_complex_y_real,~] = save_frame_testvec([dir_rx 'rS_complex_y_real'],indFrame,real(rS_complex_y),10,'myround'); 
    [flie_rS_complex_y_imag,~] = save_frame_testvec([dir_rx 'rS_complex_y_imag'],indFrame,imag(rS_complex_y),10,'myround'); 
    [flie_rS_complex_uv_real,~] = save_frame_testvec([dir_rx 'rS_complex_uv_real'],indFrame,real(rS_complex_uv),10,'myround');
    [flie_rS_complex_uv_imag,~] = save_frame_testvec([dir_rx 'rS_complex_uv_imag'],indFrame,imag(rS_complex_uv),10,'myround');
    
    [file_S_rec,~] = save_frame_testvec([dir_rx 'S_rec'],indFrame,S_rec,10,'myround');
    [file_S_y_rec,~] = save_frame_testvec([dir_rx 'S_y_rec'],indFrame,S_y_rec,10,'myround');
    [flie_S_uv_rec,~] = save_frame_testvec([dir_rx 'S_uv_rec'],indFrame,S_uv_rec,10,'myround');
    [flie_sigma_n,~] = save_frame_testvec([dir_rx 'sigma_n'],indFrame,sigma_n,8,'myround');
    
    [file_llr_all_y,~] = save_frame_testvec([dir_rx 'llr_all_y'],indFrame,llr_all_y(:,:,indFrame),5,'myround');
    [file_llr_all_uv,~] = save_frame_testvec([dir_rx 'llr_all_uv'],indFrame,llr_all_uv(:,:,indFrame),5,'myround');
    
    [file_receivedBits_y,~] = save_frame_testvec([dir_rx 'receivedBits_y'],indFrame,receivedBits_y,0,'myround');
    [flie_receivedBits_uv,~] = save_frame_testvec([dir_rx 'receivedBits_uv'],indFrame,receivedBits_uv,0,'myround');
    
    [file_rbits_y,~] = save_frame_testvec([dir_rx 'rbits_y'],indFrame,rbits_y,0,'myround');
    [flie_rbits_uv,~] = save_frame_testvec([dir_rx 'rbits_uv'],indFrame,rbits_uv,0,'myround');
    [file_rbits_lambda_y,~] = save_frame_testvec([dir_rx 'rbits_lambda_y'],indFrame,rbits_lambda_y,0,'myround');
    [flie_rbits_lambda_uv,~] = save_frame_testvec([dir_rx 'rbits_lambda_uv'],indFrame,rbits_lambda_uv,0,'myround');
    [file_rbits_dc_y,~] = save_frame_testvec([dir_rx 'rbits_dc_y'],indFrame,rbits_dc_y,0,'myround');
    [flie_rbits_dc_uv,~] = save_frame_testvec([dir_rx 'rbits_dc_uv'],indFrame,rbits_dc_uv,0,'myround');
    
    [file_DC_coef_rec,~] = save_frame_testvec([dir_rx 'DC_coef_rec'],indFrame,DC_coef_rec,0,'myround');
    [file_DC_coef_y_rec,~] = save_frame_testvec([dir_rx 'DC_coef_y_rec'],indFrame,DC_coef_y_rec,0,'myround');
    [flie_DC_coef_uv_rec,~] = save_frame_testvec([dir_rx 'DC_coef_uv_rec'],indFrame,DC_coef_uv_rec,0,'myround');
    
    [file_lambda_rec,~] = save_frame_testvec([dir_rx 'lambda_rec'],indFrame,lambda_rec,0,'myround');
    [file_lambda_y_rec,~] = save_frame_testvec([dir_rx 'lambda_y_rec'],indFrame,lambda_y_rec,0,'myround');
    [file_lambda_uv_rec,~] = save_frame_testvec([dir_rx 'lambda_uv_rec'],indFrame,lambda_uv_rec,0,'myround');
    [file_lambda_y_avg_rec,~] = save_frame_testvec([dir_rx 'lambda_y_avg_rec'],indFrame,lambda_y_avg_rec,0,'myround');
    [flie_lambda_uv_avg_rec,~] = save_frame_testvec([dir_rx 'lambda_uv_avg_rec'],indFrame,lambda_uv_avg_rec,0,'myround');
    
    [file_g_rec,~] = save_frame_testvec([dir_rx 'g_rec'],indFrame,g_rec,16,'myround');
   
    [file_idct_in,~] = save_frame_testvec([dir_rx 'idct_in'],indFrame,Chat,16,'myround');
    [file_idct_out,~] = save_frame_testvec([dir_rx 'idct_out'],indFrame,rxPicblocks,0,'myround');
    [file_rxPic_y,~] = save_frame_testvec([dir_rx 'rxPic_y'],indFrame,rxPic,0,'myround');
    [file_rxPic_u,~] = save_frame_testvec([dir_rx 'rxPic_u'],indFrame,rxPic_u,0,'myround');
    [file_rxPic_v,~] = save_frame_testvec([dir_rx 'rxPic_v'],indFrame,rxPic_v,0,'myround');
    
    fprintf('Frame%d RX testvec dumped!\n',indFrame);
    end
end

%% save simulation result
if (sim_options.save_sim_result == true)
if (fix_point == 1)
    ber = mean(errorStats(1,:,:),3);
    
    ber_file = sprintf('ber_H%s_%s_cp%d_%s_%s_turbo%s.mat',H_set,sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video,sim_options.turbo_set);
    bler_file = sprintf('bler_H%s_%s_cp%d_%s_%s_turbo%s.mat',H_set,sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video,sim_options.turbo_set);
    errStats_file = sprintf('errorStats_H%s_%s_cp%d_%s_%s_turbo%s.mat',H_set,sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video,sim_options.turbo_set);
        
    llr_sat_count_file = sprintf('llr_sat_count_%s_cp%d_%s_%s.mat',sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);
    digi_sat_count_file = sprintf('digi_sat_count_%s_cp%d_%s_%s.mat',sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);
    fft_overflow_file = sprintf('fft_overflow_%s_cp%d_%s_%s.mat',sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);
    ifft_overflow_file = sprintf('ifft_overflow_%s_cp%d_%s_%s.mat',sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);
    
    save(ber_file,'ber');
    save(bler_file,'bler');
    save(errStats_file,'errorStats');
    save(llr_sat_count_file,'llr_sat_count');
    save(digi_sat_count_file,'digi_sat_count');
    save(fft_overflow_file,'fft_overflow_all');
    save(ifft_overflow_file,'ifft_overflow_all');
    
    if (sim_options.no_digi_err == 1)
        psnr_y_file = sprintf('psnr_y_fix_H%s_%s_noerr_cp%d_%s_%s.mat',H_set,sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);
        psnr_uv_file = sprintf('psnr_uv_fix_H%s_%s_noerr_cp%d_%s_%s.mat',H_set,sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);
        sim_options_file = sprintf('sim_options_fix_%s_noerr_cp%d_%s_%s.mat',sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);
    elseif (sim_options.CRCCheck == true)
        psnr_y_file = sprintf('psnr_y_fix_H%s_%s_CRC_cp%d_%s_%s.mat',H_set,sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);
        psnr_uv_file = sprintf('psnr_uv_fix_H%s_%s_CRC_cp%d_%s_%s.mat',H_set,sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);
        sim_options_file = sprintf('sim_options_fix_%s_CRC_cp%d_%s_%s.mat',sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);
    else
        psnr_y_file = sprintf('psnr_y_fix_H%s_%s_cp%d_%s_%s.mat',H_set,sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);
        psnr_uv_file = sprintf('psnr_uv_fix_H%s_%s_cp%d_%s_%s.mat',H_set,sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);
        sim_options_file = sprintf('sim_options_fix_%s_cp%d_%s_%s.mat',sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);
    end   
else
    psnr_y_file = sprintf('psnr_y_float_H%s_%s_cp%d_%s_%s.mat',H_set,sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);
    psnr_uv_file = sprintf('psnr_uv_float_H%s_%s_cp%d_%s_%s.mat',H_set,sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);
    sim_options_file = sprintf('sim_options_float_%s_cp%d_%s_%s.mat',sim_options.channel_option,sim_options.CPLength,sim_options.ChanProfile,sim_options.Video);      
end

save(psnr_y_file,'psnr_y');
save(psnr_uv_file,'psnr_yuv');
save(sim_options_file,'sim_options');

if(strcmp(sim_options.channel_option ,'awgn_chan') == 0)
    H_gain_file = sprintf('H_gain_cp%d_%s.mat',sim_options.CPLength,sim_options.ChanProfile);
    save(H_gain_file,'H_gain');
%     H_gain_min_file = sprintf('H_gain_min_cp%d_%s.mat',sim_options.CPLength,sim_options.ChanProfile);
%     save(H_gain_min_file,'H_gain_min');
%     H_gain_all_file = sprintf('H_gain_all_cp%d_%s.mat',sim_options.CPLength,sim_options.ChanProfile);
%     save(H_gain_all_file,'H_gain_all');
end
end

fclose('all');