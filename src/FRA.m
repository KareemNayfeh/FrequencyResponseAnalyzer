runname = 'closed'

set(0,'defaultlinelinewidth',2)
fmin = 100;
fmax = 10000;
npts = 100;
freqList = logspace(log10(fmin),log10(fmax),npts);
A0 = 200;
A1 = 800;
ampList = A0 + (A1-A0)*(freqList-fmin)/(fmax-fmin);

try    
    PS2000Config;
    % disp 'gooing'
    ps2000 = icdevice('picotech_ps2000_generic.mdd');
    disp 'connecting'
    connect(ps2000);
    
    signalGenerator = get(ps2000, 'Signalgenerator');
    signalGenerator = signalGenerator(1);
    
    blockGroup = get(ps2000, 'Block');
    blockGroup = blockGroup(1);
    
    %set(signalGenerator, 'startFrequency', 1000);
    
    
    
  %  set(signalGenerator, 'peakToPeakVoltage', 1000);
    
    numPeriods = 15;
    
    %set(ps2000, 'numberOfSamples', numSamples);
    
    %actual function is bufferTimes on the X | bufferChA on the Y
    
    %[bufferTimes, bufferChA, bufferChB, numDataValues, timeIndisposedMs] = invoke(blockGroup, 'getBlockData');
    
    %[A,B] = getAB(double(bufferChB), double(bufferTimes), get(signalGenerator, 'startFrequency'));
    

    blah = invoke(blockGroup, 'getTimebases');

    a = figure("Name","Bode Plot", "Position",[20, 20, 400, 800]);
    
    nA = 3;
    nB = 3;
    b = figure("Name", "Time Plot", "Position",[520, 20, 800, 800]);
    c = figure("Name", "Abs Mag", "Position",[1420, 20, 400, 800]);
    plot1 = plot(nan, nan);
    for kk = 1:length(freqList)
        freq(kk) = freqList(kk);
        set(signalGenerator, 'peakToPeakVoltage', ampList(kk)); 
        set(signalGenerator, 'startFrequency', freq(kk));
        period = 1/freq(kk);
        numSamplesPerWave = 16;
        blockIntUs = 1e6/freq(kk)/numSamplesPerWave;
        [status.sigGenSimple] = invoke(signalGenerator, 'setSigGenBuiltInSimple', ps2000Enuminfo.enPS2000WaveType.PS2000_SINE);
        [samplingIntervalUs, maxBlockSamples] = invoke(blockGroup, 'setBlockIntervalUs', blockIntUs);
        numSamples = round(((numPeriods*period/samplingIntervalUs)*1e6));
        set(ps2000, 'numberOfSamples', numSamples)
        actualns = get(ps2000, 'numberOfSamples');
        disp(sprintf("collect %f",freq(kk) ));
        rangeANoGood = true;
        rangeBNoGood = true;
        while(rangeANoGood | rangeBNoGood)
            [status.setChA] = invoke(ps2000, 'ps2000SetChannel', 0, 1, 1, nA)
            [status.setChB] = invoke(ps2000, 'ps2000SetChannel', 1, 1, 1, nB)
            [bufferTimes, bufferChA, bufferChB, numDataValues, timeIndisposedMs] = invoke(blockGroup, 'getBlockData');
            maxA = max(abs(bufferChA));
            maxB = max(abs(bufferChB));
            disp( ['A range=' num2str(numToMv(nA)) ' maxA=' num2str(maxA) ] );
            if (maxA <= numToMv(nA-1) & nA>2)
                nA = nA-1;
                disp(['ranging A down to ' num2str(numToMv(nA))]);
            elseif (maxA==numToMv(nA) & nA<10)
                nA = nA+1;
                disp(['ranging A up to ' num2str(numToMv(nA))]);
            else
                disp('range A fixed');
                rangeANoGood = false;
            end
            disp( ['B range=' num2str(numToMv(nB)), ' maxB=' num2str(maxB) ] );
            if (maxB <= numToMv(nB-1) & nB>2)
                nB = nB-1;
                disp(['ranging B down to ' num2str(numToMv(nB))]);
            elseif (maxB==numToMv(nB) & nB<10)
                nB = nB+1;
                disp(['ranging B up to ' num2str(numToMv(nB))]);
            else
                disp('range B fixed');
                rangeBNoGood = false;
            end
        end
        

        t = [0: length(bufferChA)-1]'*samplingIntervalUs*1e-6;
        figure(b);
        yyaxis left
        plot(t, bufferChB)
        ylabel('channel B [mV]')
        yyaxis right
        plot(t, bufferChA)
        ylabel('channel A [mV]')
        xlabel('time [sec]')
        drawnow;
        
        AB(kk) = 2*trapz(t, double(bufferChB).*cos(2*pi*freqList(kk)*t))/t(end);
        BB(kk) = 2*trapz(t, double(bufferChB).*sin(2*pi*freqList(kk)*t))/t(end);
        AA(kk) = 2*trapz(t, double(bufferChA).*cos(2*pi*freqList(kk)*t))/t(end);
        BA(kk) = 2*trapz(t, double(bufferChA).*sin(2*pi*freqList(kk)*t))/t(end);
        %timesUnits = timeunits(get(blockGroup, 'timeUnits'));
        %timeLabel = strcat('Time (', timesUnits, ')');
        %figure1 = figure('Name', 'test', 'NumberTitle', 'off');
        %plot(t, [bufferChA bufferChB]);
        %title(num2str(freqList(kk)))
        
        magA = sqrt(AA.^2+BA.^2);
        magB = sqrt(AB.^2+BB.^2);
        
        phaseA = (atan2(BA, AA));
        phaseB = (atan2(BB, AB));

        Ac(kk) = AA(kk)+i*BA(kk);
        Bc(kk) = AB(kk)+i*BB(kk);

        figure(c);
        subplot(2,1,1);
        loglog(freq, magA)
        subplot(2,1,2);
        loglog(freq, magB)
        magBA = magB./magA;
        phaseBA = 180/pi*unwrap(phaseA-phaseB);

        figure(a);
        subplot(2, 1, 1);
    %    hold all;
        loglog(freq, magBA);
        subplot(2, 1, 2);
   %     hold all;
        semilogx(freq,phaseBA);

    end
    
    
    disp(ps2000Enuminfo.enPS2000Range)
    stopStatus = invoke(ps2000, 'ps2000Stop');
    
    disconnect(ps2000);
    delete(ps2000);
catch E
    disconnect(ps2000);
    delete(ps2000);
    disp(E);
end
%% convert to units
magBA = magBA*mVpermperssq/mVperN;
magB = magB/mVperN;
magA = magA/mVpermperssq;

%%
figure(100)
plotComparisons
% subplot(3,2,1)
% loglog(freq,magBA.*(2*pi*freq).^2)
% ylabel('N/m')
% hold all
% subplot(3,2,3)
% loglog(freq,magBA.*(2*pi*freq))
% ylabel('N/(m/s)')
% hold all
% subplot(3,2,5)
% semilogx(freq,phaseBA)
% ylabel('phase [deg]')
% hold all
% subplot(3,2,2)
% loglog(freq,magA./(2*pi*freq))
% ylabel('input amp (m/s)')
% hold all
% subplot(3,2,4)
% loglog(freq,magA./(2*pi*freq).^2)
% ylabel('input amp (m)')
% hold all
% subplot(3,2,6)
% loglog(freq,magBA)
% ylabel('N/(m/s^2)')
% hold all
%%
save([ runname ' ' char(datetime('now','Format','yyyyMMd HH mm')) '.mat'],'freq','magA','magB','magBA','phaseBA','A0','A1','ampList','Ac','Bc')
%%
%%
%
function [A, B] = getAB(s, t, f)
    A = 2*trapz(t, s.*cos(2*pi*f*t))/t(end);
    B = 2*trapz(t, s.*sin(2*pi*f*t))/t(end);
end
function n = numToMv(input)
    if input == 0
        n = 10;
    elseif input == 1
        n = 20;
    elseif input == 2
        n = 50;
    elseif input == 3
        n = 100;
    elseif input == 4
        n = 200;
    elseif input == 5
        n = 500;
    elseif input == 6
        n = 1000;
    elseif input == 7
        n = 2000;
    elseif input == 8
        n = 5000;
    elseif input == 9
        n = 10000;
    elseif input == 10
        n = 20000;
    elseif input == 11
        n = 50000;
    end
end

% function n = mvToNum(input)
%     if input == 10
%         n = 0;
%     elseif input == 20
%         n = 1;
%     elseif input == 50
%         n = 2;
%     elseif input == 100
%         n = 3;
%     elseif input == 200
%         n = 4;
%     elseif input == 500
%         n = 5;
%     elseif input == 1000
%         n = 6;
%     elseif input == 2000
%         n = 7;
%     elseif input == 5000
%         n = 8;
%     elseif input == 10000
%         n = 9;
%     elseif input == 20000
%         n = 10;
%     elseif input == 50000
%         n = 11;
%     end
% end
