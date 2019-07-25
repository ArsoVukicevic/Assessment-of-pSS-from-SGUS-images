%% SKRIPTA RADI BALANSIRANjE TRAINING SETa

%KORACI
% #1 Ucitaj training set nebalansiran
% #2 Konvertuj nebalansiran set iz Matlaba u Weka format [nazivBaze '_baza1FeatureVsGradeZaAI_TrainNebalansirano.mat']
% #3 Sacuvaj Weka format                                 [nazivBaze '_baza1FeatureVsGradeZaAI_arff_nebalansirano.arff']
% #4 Balansiraj training set upotrebom ADASYN 

%INPUTS
%OUTPUTS
    % wekaOBJ saveARFF([nazivBaze '_baza1FeatureVsGradeZaAI_arff_nebalansirano.arff'],wekaOBJ)
function Skripta_3_BalansiranjeTrainingSeta(nazivBaze)
% https://www.mathworks.com/matlabcentral/fileexchange/38830-smote--synthetic-minority-over-sampling-technique-

% #1 Ucitaj training set nebalansiran
if nargin  == 0
    nazivBaze = 'HarmonicSS_bazaPacijenata_baza1FeatureVsGradeZaAI.mat_baza1FeatureVsGradeZaAI_TrainNebalansirano.mat';
    baza = load(nazivBaze);
else
    baza = load([nazivBaze '_baza1FeatureVsGradeZaAI_TrainNebalansirano.mat']); 
end 

baza = baza.bazaTrain                                                     ;

% #2 Konvertuj iz Matlaba u Weka format
featureNames        = baza.SviAtributiNazivi; % Atributi
featureNames{end+1} = 'Grade Score'         ; % Outcome

data   = [baza.sviAtriubti, baza.rezGradeLabel(:)];

%%
classindex = numel(featureNames)                                          ;%Poslednja kolona je outcome

%Prepare test and training sets. 
% train = data(1:120-1,:);
% test  = data(121:end,:);

%Convert to weka format
%sacuvajMatlabKaoWeka(data, nazivBaze, featureNames, classindex, [nazivBaze '_baza1FeatureVsGradeZaAI_arff_nebalansirano.arff']);
save([nazivBaze '_baza1FeatureVsGradeZaAI_arff_nebalansirano.mat'],'baza');

.... DALjE SE RADI U WEKAi, koristi se SMOTE ALGORITAM ZA NEBALANSIRANE KLASE
data = arsStatistika.izbalansirajKlaseUpotrebomADASYN(data);  
%sacuvajMatlabKaoWeka(data, nazivBaze, featureNames, classindex, [nazivBaze '_baza1FeatureVsGradeZaAI_arff_balansiranoADASYN.arff']);
baza.sviAtriubti   = data(:,1:end-1);
baza.rezGradeLabel = data(:,end)    ;
save([nazivBaze '_baza1FeatureVsGradeZaAI_arff_balansiranoADASYN.mat'],'baza');
end

function sacuvajMatlabKaoWeka(data, nazivBaze, featureNames, classindex, nazivFajla)
    data     = num2cell(data)                                                     ;
    wekaOBJ  = matlab2weka(nazivBaze, featureNames, data, classindex)             ;
    saveARFF(nazivFajla, wekaOBJ);
end