%% << Sta skripta radi >>
% Prethodno je pozvan fajl "Skripta_1_napraviMatricuOdBaze", koji je obradjene podatke upakovao u matrice pogodne za AI.
% U okviru ovog fajla se vrsi podela podataka na training i validation
%% Koraci
% #1 Ucitaj bazu [nazivBaze '_baza1FeatureVsGradeZaAI.mat']
% #2 Koliki procenat ide na train (obicno 70%)
% #3 Selekcija primera
% #4 Stratifikacija podataka
%% DATA
%%INPUTS
    % nazivBaze
%% OUTPUTS
    % bazaTrain [nazivBaze '_baza1FeatureVsGradeZaAI_TrainNebalansirano.mat']
    % bazaTest  [nazivBaze '_baza1FeatureVsGradeZaAI_Test.mat'              ]
    % Organizacija strutkura - podaci su spakovani u matrice i spremni za AI
        % rez.sviAtriubti       - matrica[brPrimera x brAtributa]
        % rez.SviAtributiNazivi - struktura {brAtribtua} naziva atributa  
        % rez.rezGradeLabel     - Grade/outcome
function Skripta_2_NapraviTestValidationSets(nazivBaze)
if nargin  == 0
    nazivBaze = 'HarmonicSS_bazaPacijenata_baza1FeatureVsGradeZaAI.mat';
    baza          = load(nazivBaze); baza=baza.rez;
else
    % #1 Ucitaj bazu [nazivBaze '_baza1FeatureVsGradeZaAI.mat']
    baza          = load([nazivBaze '_baza1FeatureVsGradeZaAI.mat']); baza=baza.rez;
end

brPrimeraBaze = numel(baza.rezGradeLabel)                                  ;

% #2 Koliki procenat ide na train (obicno 70%)
trainRatio        = 0.7                                                    ;
ModSelektujRandom = 1;
% #3 Selekcija primera (trainRatio od svakog gradea ide u bazaTrain)
for iGrade = 0 : 3
    id = find(baza.rezGradeLabel == iGrade);
    if (ModSelektujRandom)        
        % U radu napisi da je koriscen random sampling https://www.mathworks.com/help/stats/randsample.html
        if iGrade == 0        
            idTrain = randsample(id,round(numel(id)*trainRatio));
            idTest  = setdiff(id, idTrain)                      ;
        else
            idTrain = [idTrain; randsample(id,round(numel(id)*trainRatio))];
            idTest  = [idTest ; setdiff(id, idTrain)                      ];
        end
    else
        
        if iGrade == 0        
            idTrain = id(                            1 : round(numel(id)*trainRatio));
            idTest  = id(round(numel(id)*trainRatio)+1 : end                        );
        else
            idTrain = [idTrain; id(                            1 : round(numel(id)*trainRatio))];
            idTest  = [idTest ; id(round(numel(id)*trainRatio)+1 : end                        )];
        end
    end
end
idTrain = sort(idTrain);
idTest  = sort(idTest );
% #4 Stratifikacija podataka
%% TRAIN SET
bazaTrain                   = baza;
bazaTrain.sviAtriubti       = bazaTrain.sviAtriubti(idTrain,:)    ;
bazaTrain.rezGradeLabel     = bazaTrain.rezGradeLabel(idTrain)    ;
bazaTrain.rezDataSetID      = bazaTrain.rezDataSetID(idTrain)     ;
bazaTrain.rezDataSetName    = bazaTrain.rezDataSetName(idTrain)   ;
bazaTrain.idPrimeraURawBazi = bazaTrain.idPrimeraURawBazi(idTrain);

save([nazivBaze '_baza1FeatureVsGradeZaAI_TrainNebalansirano.mat'], 'bazaTrain');
%% TEST SET
bazaTest                    = baza;
bazaTest.sviAtriubti        = bazaTest.sviAtriubti(idTest,:)    ;
bazaTest.rezGradeLabel      = bazaTest.rezGradeLabel(idTest)    ;
bazaTest.rezDataSetID       = bazaTest.rezDataSetID(idTest)     ;
bazaTest.rezDataSetName     = bazaTest.rezDataSetName(idTest)   ;
bazaTest.idPrimeraURawBazi  = bazaTest.idPrimeraURawBazi(idTest);
save([nazivBaze '_baza1FeatureVsGradeZaAI_Test.mat'], 'bazaTest');

if nargin  == 0
    nazivBaze = 'baza1FeatureVsGradeZaAI_TrainNebalansirano.mat';
end 

% Konvertuj iz Matlaba u Weka format - ovo nije neophodno ako je Weka integrisana sa Matlab
baza                = bazaTest ;
featureNames        = baza.SviAtributiNazivi; % Atributi
featureNames{end+1} = 'Grade Score'         ; % Outcome
data                = [num2cell(baza.sviAtriubti), num2cell(baza.rezGradeLabel(:))];
classindex          = numel(featureNames)                                          ;%Poslednja kolona je outcome
wekaOBJ             = matlab2weka(nazivBaze,featureNames,data,classindex);
saveARFF([nazivBaze '_baza1FeatureVsGradeZaAI_Test.arff'],wekaOBJ);    
%% sacuvaj i train set
end