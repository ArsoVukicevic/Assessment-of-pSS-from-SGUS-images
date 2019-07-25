%% KORACI KOJI SE IZVRSAVAJU U FAJLU
% #1 - Ucitaj bazu (podaci su razvrstani po gradeovima, svaki grade ima svoju bazu)
% #2 - Preprocesiranje slike
% #3 - Izdvajanje atributa
% #4 - Cuvanje atributa u fajl  save(['bazaPacijenataGrade' num2str(iBaze)  'RawFeatures.mat'], 'rezFeatures');

%% INPUTS 
    % NazivBaze - putanja do baze
        % Opis strukture podataka baza
        %baza.dicomName     - Naziv DICOMa
        %baza.dicomath      - Putanja do DICOMa
        %baza.FullDicomPath - Kompletna putanja na HDD
        %baza.img           - 2D slika ucitana iz DICOMa
        %baza.path2D        - Segmentirana kontura (polyline [x,y,z])
        %baza.grade         - Grade/skor (ground truth) za dati primer u bazi
%% OUTPUT DATA STRUCTIRE
        %rezFeatures.rezGlcmFeatures             
        %rezFeatures.rezLBPHistogram         
        %rezFeatures.rezGaborHistogram         
        %rezFeatures.rezHistGradijentSobel     
        %rezFeatures.rezHistGradijent          
        %rezFeatures.rezR_mean_std              
        %rezFeatures.rezCxCy                    
        %rezFeatures.rezGradeLabel              
          %nazivi kolona - da bi posle znao tokom feature selection sta je sta
            %rezFeatures.rezGlcmFeaturesNazivi                 
            %rezFeatures.rezLBPHistogramNazivi      
            %rezFeatures.rezGaborHistogramNazivi    
            %rezFeatures.rezHistGradijentSobelNaziv 
            %rezFeatures.rezCxXyNaziv               
            %rezFeatures.rezR_mean_std              
            %rezFeatures.rezR_mean_stdNaziv         
function rez = Skripta_0_FeatureExtraction(nazivBaze)
close  all      ;
global debugMode; 
debugMode    = 1;

if nargin == 0
    nazivBaze = 'HarmonicSS_bazaPacijenata';
end

% Pretpostavka je da baza podeljena na gradeove, zato koristim for petlju
for iBaze = 0:3 %Za svaku od (pod)baza - iBaze odgovara Gradeu
%% #1 UCITAVANjE SLIKA/primera
    baza     = load([nazivBaze num2str(iBaze) '.mat']);
    baza     = baza.rez                                           ;
    %%
    % Odsecanje nepotrebnog dela slike (da bi se smanjilo racunanje)
%     odsecanje = baza(1).odsecanje(1,:); %pogledaj slike koje se ucitavaju... moguce je da se potrebno razlicito odsecanje za razlicite uredjaje!  za ITA bazu odsecanje = [189, 83, 0];
    for iPrimera = 1:numel(baza)% Za svaku od slika u bazi
%% #2 PREPROCESIRANjE SLIKE     
    %  #2.1 - Odsecanje nepotrebnog dela slike
        crop     = baza(iPrimera).odsecanje ; odsecanje = crop(1,[2 1 3]);
        img      = baza(iPrimera).img       ;%Ucitavanje slike/primera iz baze
        img(1:2) = [0 256]                  ;%Ubaceno zbog normalizacije vrednosti pixela (moze da se desi da neka slika ima npr max=120 umesto 256;
        img      = mat2gray(img)            ;%Normlaizacija vrednosti 0-1
        img      = img(:,:,1)               ;%imshow(img);
        img      = img(crop(1,1):crop(2,1), crop(1,2):crop(2,2));  if debugMode figure; imshow(img); end

    %  #2.2 - Primena Filtera  
        if debugMode figure; imshow(img); end
    %     img = HistogramEqualization(img); if debugMode figure; imshow(img); end
    %     img = WienerFilter(img)         ; if debugMode figure; imshow(img); end
    %     img = MedianFilter(img)         ; if debugMode figure; imshow(img); end

 %% #3 IZDVAJANjE ATRIBUTA - PROCESIRANjE SLIKE
    %% #3.1 Atributi bazirani na histogramu slike filtrirane Gausianom
    % Features
      % rezHistGradijent - parametri histograma dobijenih variranjem sigma u imgaussfilt %ref: https://www.mathworks.com/help/images/ref/imgaussfilt.html
        id = 1;
        for sigma = 0.01 : 2 : 16 %ne moze d akrene od 0, 0.01 približno odgovara histogramu originala slike(nefiltrirane)
            imgGaus             = imgaussfilt(img, sigma)                                                           ; if (exist('debugMode') && debugMode==1) figure;  imshow(imgGaus); end
            [HistGradijent(id,:) HistGradijentNaziv{id}] = odradiHistogram(imgGaus, AngioIvusMath.arsMinus(baza(iPrimera).path2D, odsecanje));
            for i = 1 : numel(HistGradijentNaziv{id})
                HistGradijentNaziv{id}{i} = ['Gausian sigma=' num2str(sigma) ' ' HistGradijentNaziv{id}{i}];
            end
            id                  = id + 1;
        end
        pom                          = HistGradijent'; 
        rezHistGradijent(iPrimera,:) = pom(:)'       ;
        id = 1;
        for i  =  1 : numel(HistGradijentNaziv)
            for j  =  1 : numel(HistGradijentNaziv{1})
                rezHistGradijentNaziv{id} = HistGradijentNaziv{i}{j};
                id = id + 1;
            end
        end
        clear('HistGradijentNaziv');

    %% #3.2 Gradijent slike po X i Y pravcu, kao i korelacija/slicnost histograma gradijenata
    % Features
      % rezHistGradijent - parametri histograma dobijenih racunanjem vertikalnih i horizontalnih histograma
      % rezR_mean_std    - Stepen korelacije izmedju horizontalnih i vertikalnh gradijenata slike 
        d                   = 6; % velicina matrice
        dx                  = [ zeros(d,d*2); ones(d,d*2)];
        dy                  =  dx';
        Cx                  = conv2(img,dx); %konvolucija
        Cy                  = conv2(img,dy);
        Max                 = 1;%max([Cx(:); Cy(:)]);
        Cx                  = Cx/Max;  
        Cy                  = Cy/Max; 
        [rezCx nazivCx]     = odradiHistogram(Cx, AngioIvusMath.arsMinus(baza(iPrimera).path2D, odsecanje));
        [rezCy nazivCy]     = odradiHistogram(Cy, AngioIvusMath.arsMinus(baza(iPrimera).path2D, odsecanje));
        rezCxCy(iPrimera,:) = [rezCx  , rezCy  ];
        for i  = 1:numel(nazivCx)
            nazivCx{i} = ['Gradijent Cx(d=' num2str(d) ') ' nazivCx{i}];
            nazivCy{i} = ['Gradijent Cy(d=' num2str(d) ') ' nazivCx{i}];
        end
        rezCxXyNaziv              = [nazivCx nazivCy];        
        R                         = corrcoef(rezCx,rezCy)                          ; %koeficijent korelacije izmedju gradijenata po x i y pravcu
        rezR_mean_std(iPrimera,:) = [R(2) mean(rezCx)  mean(rezCy) std(rezCx) std(rezCy)];
        if (exist('debugMode') && debugMode==1) figure; imshow(img);figure; imshow(mat2gray(Cx)); figure; imshow(mat2gray(Cy)); end
        rezR_mean_stdNaziv  = {'Korelacija parametara histograma Cx i Cy', 'mean(rezCx)', 'mean(rezCy)', 'std(rezCx)', 'std(rezCy)'};
        
    %% #3.3 Gradijent slike  - Sobel 
    % Features
      % rezHistGradijentSobel - parametri histograma dobijenih primenom Sobel operatora https://www.mathworks.com/help/images/ref/edge.html
         if (exist('debugMode') && debugMode==1) close all; end
        BW                                = double(edge(img,'Sobel'));  if (exist('debugMode') && debugMode==1) figure; imshow(img);  figure; imshow(BW); end
        [rezHistGradijentSobel(iPrimera,:)  rezHistGradijentSobelNaziv] = odradiHistogram(BW, AngioIvusMath.arsMinus(baza(iPrimera).path2D, odsecanje));
        for i = 1 : numel(rezHistGradijentSobelNaziv)
            rezHistGradijentSobelNaziv{i} = ['Sobel ' rezHistGradijentSobelNaziv{i}]; 
        end

    %% #3.4 Wavelet Gabor filter
    % Features    
        % rezGaborHistogram dobijeni filtriranjem slike upotrebom Gabor filter % https://www.mathworks.com/help/images/ref/imgaborfilt.html
        wavelength  = 10;  %parametri koji se variraju
        orientation = 90;
        id          = 1 ;
        for wavelength = 5:10:40
         for orientation = 0 : 45 : 150
            [mag, phase]          = imgaborfilt(img, wavelength, orientation)                                     ;
             [GaborHistogram(id,:) pom]= odradiHistogram(mag, AngioIvusMath.arsMinus(baza(iPrimera).path2D, odsecanje));
             for i = 1 : numel(pom)
                GaborHistogramNaziv{id}{i} = ['Gabor filter, wavelenght = ' num2str(wavelength) ' orientation = ' num2str(orientation) ' ' pom{i}];
             end
             id                   = id +1                                                                         ;
         end
        end
        pom                           = GaborHistogram'; pom = pom(:);
        rezGaborHistogram(iPrimera,:) = pom'                         ;
        id = 1;
        for i  =  1 : numel(GaborHistogramNaziv)
            for j  =  1 : numel(GaborHistogramNaziv{1})
                rezGaborHistogramNazivi{id} = GaborHistogramNaziv{i}{j};
                id = id + 1;
            end
        end
        clear('GaborHistogramNaziv', 'pom'); 

    %% #3.4 Local Binarni Pattern
    % Features 
    %  rezLBPHistogram - parametri histograma LBP , variraju se velicina filtera i br binova po krugu
    id = 1;
       for nFiltSize  = 8:8:32     % br. binova u krugu
        for nFiltRadius = 4:4:16    % radijus LBP
            filtR                  = generateRadialFilterLBP(nFiltSize, nFiltRadius); %kreira kernel za konvoluciju    
            effLBP                 = efficientLBP(img, 'filtR', filtR, 'isRotInv', true, 'isChanWiseRot', false);%LBP
            [LBPHistogram(id,:) pom] = odradiHistogram(effLBP, AngioIvusMath.arsMinus(baza(iPrimera).path2D, odsecanje));
            %
             for i = 1 : numel(pom)
                LBPHistogramNaziv{id}{i} = ['Local Binary Pattern, nFiltSize = ' num2str(nFiltSize) ' nFiltRadius = ' num2str(nFiltRadius) ' ' pom{i}];
             end
            %
            id = id + 1;
        end        
       end
       pom                         = LBPHistogram'; 
       rezLBPHistogram(iPrimera,:) = pom(:);
       id = 1;
        for i  =  1 : numel(LBPHistogramNaziv)
            for j  =  1 : numel(LBPHistogramNaziv{1})
                rezLBPHistogramNazivi{id} = LBPHistogramNaziv{i}{j};
                id = id + 1;
            end
        end
        clear('LBPHistogramNaziv', 'pom'); 

    %% #3.5 Gray-level co-occurrence matrix
    % Features 
    %  rezGlcmFeatures - [stats.autoc; stats.contr; stats.corrm; stats.corrp; stats.cprom; stats.cshad; stats.dissi; stats.energ; stats.entro; stats.homom; stats.homop; stats.maxpr; stats.sosvh; stats.savgh; stats.svarh; stats.senth; stats.dvarh; stats.denth; stats.inf1h; stats.inf2h; stats.indnc; stats.idmnc];
       for NumLevels = 10:10:10
        imgSize  = size(img(:,:,1));
        [rezPikseli idPiksela rezMaska] = arsIMG.selektujPikseleUnutarKonture(img,AngioIvusMath.arsMinus(round(baza(iPrimera).path2D),odsecanje));
        pomMaska  = double(rezMaska(1:imgSize(1),1:imgSize(2))) ; pomMaska(pomMaska<1)=NaN;
        imgPom    = double(img(:,:,1)) .* pomMaska;
    %     imgPom    = mat2gray(imgPom).* pomMaska;
        Offsets   = [5 * [0 1; -1 1; -1 0; -1 -1]; [0 1; -1 1; -1 0; -1 -1]];
    %     NumLevels = 5;
        glcm      = graycomatrix(imgPom, 'Offset', Offsets, 'NumLevels', NumLevels, 'Symmetric', true);
        % GLCM2 = graycomatrix(I,'Offset',[2 0;0 2]);
        stats     = GLCM_Features1(glcm,0);
        GlcmFeatures = [stats.autoc; stats.contr; stats.corrm; stats.corrp; stats.cprom; stats.cshad; stats.dissi; stats.energ; stats.entro; stats.homom; stats.homop; stats.maxpr; stats.sosvh; stats.savgh; stats.svarh; stats.senth; stats.dvarh; stats.denth; stats.inf1h; stats.inf2h; stats.indnc; stats.idmnc];
        pomNazivi =    {     'autoc',     'contr',     'corrm',     'corrp',     'cprom',     'cshad',     'dissi',     'energ',      'entro',     'homom',     'homop',    'maxpr',     'sosvh',     'savgh',     'svarh',     'senth',     'dvarh',     'denth',      'inf1h',     'inf2h',    'indnc',     'idmnc'};
       end
       pom = GlcmFeatures';
       rezGlcmFeatures(iPrimera,:) = pom(:);
       id=1;
       for i = 1 : 1:numel(pomNazivi)
           for j = 1:  numel(GlcmFeatures(1,:)) % br Offsets = 8
             rezGlcmFeaturesNazivi{id} = ['GLCM, Offset=[' num2str(Offsets(j,:)) '] ' pomNazivi{i}];
             id = id +1;
           end
       end
       clear('pomNazivi','pom');
       
       %%
       disp([ 'iBaze = ', num2str(iBaze), '  iPrimera = ', num2str(iPrimera), ' od ', num2str(numel(baza))]);
       rezGradeLabel(iPrimera)  = iBaze                         ;
       rezDataSetID(iPrimera)   = baza(iPrimera).DataSetID      ;
       rezDataSetName{iPrimera} = baza(iPrimera).DataSetName ;
    %% #3.6 Anizotropna difuzija 
    %  brKorakaAnizotropneDifuzije = 4         ;%4
    %  img                         = img(:,:,3);
    %           rez = nldifc(img*1,...
    %                 linspace(0.001, 0.015, brKorakaAnizotropneDifuzije),...lambda  1.5,4
    %                 linspace(0.001, 0.015, brKorakaAnizotropneDifuzije),...sigma 3,0.3
    %                 6,...m 10
    %                 133,...stepsize 1000
    %                 brKorakaAnizotropneDifuzije,...nosteps
    %                 1, 2, 'aos', 'grad', 'dfstep', 2, 'alt1','imscale', 'norm', 1);%varargin
    % imshow(rez);
end

%% CUVANjE za svaku bazu posegno-------------------------------------------
    rezFeatures.rezGlcmFeatures            = rezGlcmFeatures           ;            
    rezFeatures.rezLBPHistogram            = rezLBPHistogram           ;
    rezFeatures.rezGaborHistogram          = rezGaborHistogram         ;
    rezFeatures.rezHistGradijentSobel      = rezHistGradijentSobel     ;
    rezFeatures.rezHistGradijent           = rezHistGradijent          ;
    rezFeatures.rezR_mean_std              = rezR_mean_std             ;
    rezFeatures.rezCxCy                    = rezCxCy                   ;
    rezFeatures.rezGradeLabel              = rezGradeLabel             ;
    rezFeatures.rezDataSetID               = rezDataSetID              ; 
    rezFeatures.rezDataSetName             = rezDataSetName            ; 
    %nazivi kolona
    rezFeatures.rezGlcmFeaturesNazivi      = rezGlcmFeaturesNazivi     ;            
    rezFeatures.rezLBPHistogramNazivi      = rezLBPHistogramNazivi     ;
    rezFeatures.rezGaborHistogramNazivi    = rezGaborHistogramNazivi   ;
    rezFeatures.rezHistGradijentSobelNaziv = rezHistGradijentSobelNaziv;
    rezFeatures.rezGaborHistogramNazivi    = rezGaborHistogramNazivi   ;
    rezFeatures.rezCxXyNaziv               = rezCxXyNaziv              ;
    rezFeatures.rezR_mean_std              = rezR_mean_std             ;
    rezFeatures.rezR_mean_stdNaziv         = rezR_mean_stdNaziv        ;
    %----------------------------------------------------------------------
    clear('rezGradeLabel', 'rezR_mean_std', 'rezHistGradijent', 'rezHistGradijentSobel' , 'rezGaborHistogram', 'rezLBPHistogram' , 'rezGlcmFeatures', 'rezCxCy','rezDataSetID','rezDataSetName');
    save([nazivBaze num2str(iBaze)  '_RawFeatures.mat'], 'rezFeatures');
end
end

% Fja racuna histograma (pomocna fja, koja se racuna za svaki od featurea)
%INPUTS
    %img       - slika koja se procesira (treba da bude normalizovana 0-1)
    %path2D    - putanja (kontura)
    %odsecanje - ako je deo slike nepotreban, treba da se odsce od tog pixela
%OUTPUTS
    %
function [rez nazivParametra] = odradiHistogram(img, path2D, odsecanje)
    debugMode = 0;
    if ~exist('odsecanje')
        odsecanje = [0,0,0];
    end
    [rezPikseli idPiksela rezMaska] = arsIMG.selektujPikseleUnutarKonture(img,.......
                                                                           AngioIvusMath.arsMinus(round(path2D),odsecanje));
    rezPikseli   = double(rezPikseli)     ;                                                                       
    aaa          = rezPikseli             ; % int16(mat2gray(rezPikseli)*100);
    %descriptive statistics https://www.mathworks.com/help/matlab/data_analysis/descriptive-statistics.html
    Min          = min(rezPikseli)        ;
    Max          = max(rezPikseli)        ; 
    Mean         = mean(rezPikseli)       ;
    Median       = median(rezPikseli)     ;
    Mode         = mode(rezPikseli)       ;
    Std          = std(rezPikseli)        ;
    Var          = var(rezPikseli)        ;
    AreaInPiexes = numel(aaa)             ;
    %
    binsRange    = double(Min : (Max-Min)/100 : Max)      ;
    [bincounts]  = histc(aaa(:),binsRange); % histogram za rangeLBP
    bincounts    = bincounts / numel(aaa) ; % izrazi histogram u procentima-ovo se radi zato sto je porvrsina regije proizvoljna(nije fixna)
    if debugMode == 1
        figure; bar(binsRange,bincounts,'histc');
    end
    %Analiza histograma
    stat.skewness = skewness(bincounts);
    stat.kurtosis = kurtosis(bincounts);
    stat.mean     =     mean(bincounts);
    stat.moment   =   moment(bincounts, 3);
    stat.std      =      std(bincounts);
    stat.var      =      var(bincounts);
    stat.cov      =      cov(bincounts);
    stat.corrcoef = corrcoef(bincounts);
    stat.median   =   median(bincounts);
    stat.cumsum   =   cumsum(bincounts);
    stat.diff     =     diff(bincounts);
    stat.prod     =     prod(bincounts);
    stat.entropy  =  entropy(bincounts);
    stat.zscore   =   zscore(bincounts);
    %
    rez            = [stat.skewness , stat.kurtosis, stat.mean, stat.moment , stat.std , stat.var, stat.cov,  stat.median, stat.entropy,  Min ,  Max ,   Mean,  Median,   Mode,   Std,   Var,   AreaInPiexes];
    nazivParametra = {    'skewness',    'kurtosis',     'mean',    'moment',     'std',     'var',    'cov',    'median',    'entropy', 'Min', 'Max', 'Mean', 'Median', 'Mode', 'Std', 'Var', 'AreaInPiexes'};
end

%% Preprocesiranje slike
function imgWnr = WienerFilter(img)
% https://www.mathworks.com/help/images/examples/deblurring-images-using-a-wiener-filter.html
    LEN           =   3                           ;
    THETA         = 333                           ;
    PSF           = fspecial('motion', LEN, THETA);
    estimated_nsr = 1                             ;
    imgWnr        = deconvwnr(img, PSF, 0.3)      ;
    if exist('debugMode') && debugMode==1
        figure; imshow(imgWnr); 
    end
end

function imgWnrHisteq = HistogramEqualization(img)
    % https://www.mathworks.com/help/images/ref/histeq.html
    imgWnrHisteq = histeq(img);
    if exist('debugMode') && debugMode==1
        figure; imhist(imgWnrHisteq,64)
        figure; imshow(imgWnrHisteq);
    end
end

function imgWnrHisteqMedian = MedianFilter(img)
    % https://www.mathworks.com/help/images/ref/medfilt2.html
    imgWnrHisteqMedian = medfilt2(img);
    if exist('debugMode') && debugMode==1
        figure; imshow(imgWnrHisteqMedian);
    end
end

function LBP_bzveze()
    % http://www.cse.oulu.fi/CMV/Downloads/LBPMatlab
    imgWnrHisteqMedianLBP  = cont(imgWnrHisteqMedian,4,16); 
    if exist('debugMode') && debugMode==1
        figure; imshow(imgWnrHisteqMedianLBP/max(imgWnrHisteqMedianLBP(:)));
    end
end