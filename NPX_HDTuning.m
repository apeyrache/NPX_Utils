
%exploEp = 2;
%epochTS = csvread('Epoch_TS.csv');

load(fullfile('Analysis','SpikeData'),'S','depth');
load(fullfile('Analysis','Angle'),'ang','goodTrackingEp');

wakeT = Range(ang);
wakeEp = intervalSet(wakeT(1),wakeT(end));
wakeEp = intersect(wakeEp,goodTrackingEp);

%angVel = gaussFilt(abs(dA)/median(diff(wakeT)),100,0);
%angMove = thresholdIntervals(angVel,.1

Sw = Restrict(S,wakeEp);
nbC = length(Sw);

AngHisto = [];
meanAng = zeros(nbC,1);
pVal = zeros(nbC,1);
kappa  = zeros(nbC,1);
peakFr = zeros(nbC,1);
hdStability = zeros(nbC,1);

for ii=1:nbC
    if any(Range(Restrict(Sw{ii},wakeEp)))
        [AngHisto(:,end+1),B,meanAng(ii),pVal(ii),kappa(ii)] = HeadDirectionField_Norm(Sw{ii},ang,wakeEp);
        
        pks = LocalMinima(-AngHisto(:,end),60,-1);
        [peakFr(ii),mxIx] = max(AngHisto(:,end)); 

        epHalf          = regIntervals(wakeEp,2);
        h1              = HeadDirectionField_Norm(S{ii},ang,epHalf{1});
        h2              = HeadDirectionField_Norm(S{ii},ang,epHalf{2});        
        hdS             = corrcoef(h1,h2);
        hdStability(ii)  = hdS(1,2);

        if length(pks)>1
            if sum(AngHisto(pks,end)/peakFr(ii) > 0.25)>1
                multiPks(ii) = 1;
            end
        end

    else
        AngHisto(:,end+1) = zeros(length(B),1);
    end
end


meanAng = mod(meanAng,2*pi);
hdIndex = [];
phdIndex = [];
hdScore = [];

%%
[hdIndex,phdIndex] = HDIndex(S,ang,wakeEp);
%hdScore = HDScore(AngHisto,meanAng,B(1:end-1));

%hdIx = pVal<0.001 & kappa>1 & peakFr>1;

hdIx = pVal<0.001 & peakFr>1 & kappa>1;% & hdStability>0.75;
disp(['Total # of HD cells:' num2str(sum(hdIx))])
hdCellStats = [meanAng phdIndex kappa peakFr hdIx];

%% Display result as a function of depth

selectCells = depth<2200;
selectDepth = depth(selectCells);
mxDp = max(selectDepth);

[~,sortIx] = sort(selectDepth);
hdMean = gaussFilt(movmean(hdIndex(sortIx),30),10);

ixPoS = find(hdIndex>0.8 & depth<500);
ixRSC = find(hdIndex>0.25 & hdIndex<0.4 & depth>1000);
ixPoS = ixPoS(1);
ixRSC = ixRSC(5);

figure(1),clf
subplot(2,3,[1 2 4 5])
plot(mxDp - selectDepth,hdIndex(selectCells),'k.')
hold on
plot(mxDp - selectDepth(sortIx),hdMean,'LineWidth',2)
ylabel('HD index')
xlabel('Depth (um)')
plot(mxDp - depth(ixPoS),hdIndex(ixPoS),'ro','MarkerFaceColor','r')
plot(mxDp - depth(ixRSC),hdIndex(ixRSC),'bo','MarkerFaceColor','b')

subplot(2,3,3)
    polar(B,AngHisto(:,ixPoS));
subplot(2,3,6)
    polar(B,AngHisto(:,ixRSC));
