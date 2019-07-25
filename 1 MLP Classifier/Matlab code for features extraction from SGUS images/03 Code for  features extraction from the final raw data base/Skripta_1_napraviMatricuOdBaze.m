%% << Sta skripta radi >>
% Prethodno je pozvan fajl "Skripta_0_FeatureExtraction", koji je izvadio atribute iz slika i napakovao u odovarajucu matricu.
% U okviru ovog fajla se vrsi pravljenje matrice od prikupljenih atributa - tako da ta matrica moze biti koriscena za Machine learning.
%% Koraci
% #1 Ucitaj bazu pacijenta
% #2 Dimensionality reduction - Principal Component Analysis
% #3 Napravi jedinstvenu matricu
% #4 Normalizacija
% #5 Brisanje OUTLIERa
% #6 Sacuvaj mat fajl u matrix koji moze da se koristi za AI

%% DATA
%%INPUTS
    % NazivBaze - putanja do baze
    % baza - struktura u kojoj su spakovani atributi slike
        % baza.rezGlcmFeatures 
        % baza.rezLBPHistogram 
        % baza.rezGaborHistogram 
        % baza.rezHistGradijentSobel 
        % baza.rezHistGradijent 
        % baza.rezCxCy 
        % baza.rezR_mean_std 
        % baza.rezGradeLabel
%OUTPUTS
    % podaci spakovani u matrice i spremni za AI
        % rez.sviAtriubti       - matrica[brPrimera x brAtributa]
        % rez.SviAtributiNazivi - struktura {brAtribtua} naziva atributa  
        % rez.rezGradeLabel     - Grade/outcome
function [rez] = Skripta_1_napraviMatricuOdBaze(NazivBaze)
if nargin > 0
    debugMode = 0 ; % ukljuceno radi kontrole obrade podataka
else
    debugMode = 1 ;
    NazivBaze      = 'bazaPacijenataGrade';
end
%% #1 Ucitaj default bazu pacijenta
 for iBaze = 0 : 3
    baza     = load([NazivBaze num2str(iBaze)  '_RawFeatures.mat']);
    baza     = baza.rezFeatures                                    ;
    %
    if iBaze == 0
        rezBaza = baza;
    else
        rezBaza.rezGlcmFeatures       = [rezBaza.rezGlcmFeatures      ; baza.rezGlcmFeatures      ];
        rezBaza.rezLBPHistogram       = [rezBaza.rezLBPHistogram      ; baza.rezLBPHistogram      ];
        rezBaza.rezGaborHistogram     = [rezBaza.rezGaborHistogram    ; baza.rezGaborHistogram    ];
        rezBaza.rezHistGradijentSobel = [rezBaza.rezHistGradijentSobel; baza.rezHistGradijentSobel];
        rezBaza.rezHistGradijent      = [rezBaza.rezHistGradijent     ; baza.rezHistGradijent     ];        
        rezBaza.rezCxCy               = [rezBaza.rezCxCy              ; baza.rezCxCy              ];
        rezBaza.rezR_mean_std         = [rezBaza.rezR_mean_std        ; baza.rezR_mean_std        ];
        rezBaza.rezGradeLabel         = [rezBaza.rezGradeLabel(:)     ; baza.rezGradeLabel(:)     ];
        rezBaza.rezDataSetID          = [rezBaza.rezDataSetID(:)      ; baza.rezDataSetID(:)      ];
        rezBaza.rezDataSetName        = [rezBaza.rezDataSetName(:)    ; baza.rezDataSetName(:)    ];
    end
 end
 
%% #2 PCA redukcija dimenzionalnosti?
%     smapcaplot([rezBaza.rezGlcmFeatures rezBaza.rezLBPHistogram rezBaza.rezGaborHistogram rezBaza.rezHistGradijent ], rezBaza.rezGradeLabel);
%     mapcaplot(rezBaza.rezGlcmFeatures, rezBaza.rezGradeLabel);
%     mapcaplot(rezBaza.rezLBPHistogram, rezBaza.rezGradeLabel);
%     mapcaplot(rezBaza.rezGaborHistogram, rezBaza.rezGradeLabel);
%     mapcaplot(rezBaza.rezHistGradijentSobel, rezBaza.rezGradeLabel);
%     mapcaplot(rezBaza.rezHistGradijent, rezBaza.rezGradeLabel);

%% #3 Napravi jedinstvenu matricu
sviAtriubti       = [rezBaza.rezGlcmFeatures       rezBaza.rezLBPHistogram       rezBaza.rezGaborHistogram       rezBaza.rezHistGradijentSobel        rezBaza.rezCxCy      rezBaza.rezR_mean_std     ];
SviAtributiNazivi = [rezBaza.rezGlcmFeaturesNazivi rezBaza.rezLBPHistogramNazivi rezBaza.rezGaborHistogramNazivi rezBaza.rezHistGradijentSobelNaziv   rezBaza.rezCxXyNaziv rezBaza.rezR_mean_stdNaziv];    
rezGradeLabel     =  rezBaza.rezGradeLabel  ;
rezDataSetID      =  rezBaza.rezDataSetID   ;
rezDataSetName    =  rezBaza.rezDataSetName ;


%% #4 Normalizacija
for i = 1:numel(sviAtriubti(1,:))
    if i==320
        aaa=1
    end
    Mean = mean(sviAtriubti(:,i));
    Min  = min(sviAtriubti(:,i));
    Max  = max(sviAtriubti(:,i));
    pom  = sviAtriubti(:,i);    
    sviAtriubti(:,i) = (pom-Min) / (Max-Min); %bilo je pom/Max i radilo je ok
end
pom = isnan(sviAtriubti);
pom = find(pom==1);
sviAtriubti(pom) = 0;
%izbaci kolone gde je zbir = 0;
pom = sum(sviAtriubti);
idZaBrisanje = find(pom==0);
sviAtriubti(:,idZaBrisanje) = [];
SviAtributiNazivi(idZaBrisanje) = [];

%% #5 Brisanje OUTLIERa
idOutliera = 0;
for iKlase = 0 : 3
    [idPrimera]                = find(rezGradeLabel == iKlase)         ;
    brAtributa                 = numel(sviAtriubti(1,:))               ;    
    [pomOutlier idOutlieraORG] = isoutlier(sviAtriubti(idPrimera,:))   ;
    pomOutlier                 = sum(pomOutlier')                      ;
    pom                        = find(pomOutlier>round(brAtributa*0.05));
    idOutliera                 = union(idOutliera, idPrimera(pom))     ;
end    
%Osvezi info o bazi - tako da kasnije moze da se pogleda koji primer odgovara kojoj slici itd.
%Misli se na bazu load([NazivBaze num2str(iBaze)  '_RawFeatures.mat']);
idOutliera(1)                 = []                    ;
idPrimeraURawBazi             = 1:numel(rezGradeLabel);
idPrimeraURawBazi(idOutliera) = []                    ; 
sviAtriubti(idOutliera,:)     = []                    ;
rezGradeLabel(idOutliera)     = []                    ;
rezDataSetID(idOutliera)      = []                    ;
rezDataSetName(idOutliera)    = []                    ;

%% #6 Sacuvaj mat fajl
rez.sviAtriubti       = sviAtriubti       ;
rez.SviAtributiNazivi = SviAtributiNazivi ;
rez.rezGradeLabel     = rezGradeLabel     ;
rez.idPrimeraURawBazi = idPrimeraURawBazi ;
rez.rezDataSetID      = rezDataSetID      ;
rez.rezDataSetName    = rezDataSetName    ;
save([NazivBaze '_baza1FeatureVsGradeZaAI.mat'],'rez');
end