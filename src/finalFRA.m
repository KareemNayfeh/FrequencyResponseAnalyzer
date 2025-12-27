function [A, B, optimalNumSamples] = collectData(varargin)
    p = inputParser;
    
    addParameter(p,'fmin',100);
    addParameter(p,'fmax',10000);
    addParameter(p,'npts',100);
    addParameter(p,'numPeriods',15);
    addParameter(p,'A0',200);
    addParameter(p,'A1',800);
    addParameter(p,'numSamplesPerWave',8);
    addParameter(p,'minIntUs',10);
    addParameter(p,'numSamples',256);
    
    parse(p,varargin{:});
    S = p.Results;
    
    freq = logspace(log10(S.fmin),log10(S.fmax),S.npts);
    ampList = S.A0 + (S.A1-S.A0)*(freq-S.fmin)/(S.fmax-S.fmin);
    optimalNumSamples = zeros(1, length(freq));
    A = zeros(1, length(S.numSamples));
    B = zeros(1, length(S.numSamples));
    try    
        PS2000Config;
        ps2000 = icdevice('picotech_ps2000_generic.mdd');
    
        connect(ps2000);

        signalGenerator = get(ps2000, 'Signalgenerator');
        blockGroup = get(ps2000, 'Block');

        for kk = 1:length(freq)

            set(signalGenerator, 'peakToPeakVoltage', ampList(kk)); 
            set(signalGenerator, 'startFrequency', freq(kk));
            period = 1/freq(kk);

            blockIntUs = 1e6/freq(kk)/S.numSamplesPerWave;

            fprintf("collect %f Hz\n",freq(kk));
            disp(blockIntUs)

            invoke(signalGenerator,'setSigGenBuiltInSimple', ps2000Enuminfo.enPS2000WaveType.PS2000_SINE);
    
            [samplingIntervalUs,~] = invoke(blockGroup,'setBlockIntervalUs',blockIntUs);
    
            optimalNumSamples(kk) = round((S.numPeriods*period/samplingIntervalUs)*1e6 );
    
            set(ps2000,'numberOfSamples', S.numSamples);
    
            [A, B] = autoRange(ps2000);

        end

        disconnect(ps2000);
        delete(ps2000);
    catch E
        disconnect(ps2000);
        delete(ps2000);
        disp(E)
        [A,B] = deal(0);
    end
end

function n = numToMv(input)
    mv = [10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000];
    n = mv(input+1);
end

function [chA, chB] = autoRange(obj)

    [aGood, bGood, nA, nB] = deal(false, false, 3, 3);

    while ~(aGood && bGood)

        invoke(obj,'ps2000SetChannel',0,1,1,nA);
        invoke(obj,'ps2000SetChannel',1,1,1,nB);

        [~, A, B] = invoke(get(obj, 'Block'), 'getBlockData');

        [maxA, maxB] = deal(max(abs(A)), max(abs(B)));
        dA = (((nA < 10) && (maxA >= numToMv(nA))) - ((nA > 2) && (maxA <= numToMv(nA-1))));
        dB = (((nB < 10) && (maxB >= numToMv(nB))) - ((nB > 2) && (maxB <= numToMv(nB-1))));
        nA = nA + dA;
        nB = nB + dB;
        [aGood, bGood] = deal(~dA, ~dB);
        [chA, chB] = deal(A, B);
    end
end
