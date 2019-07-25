classdef arsStatistika 
    properties(SetAccess = public, GetAccess = public)
    end%properties 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Static=true)
     %% izracunaj Brier Score, ref: http://en.wikipedia.org/wiki/Brier_score
        function [rez] = izcracunajBrierScore(predvidjeneVerovatnoce, targetPodaci)
            N         = numel(predvidjeneVerovatnoce);
            FtMinusOt = targetPodaci - predvidjeneVerovatnoce;
            rez       = sum(FtMinusOt .* FtMinusOt)/ N;
        end
      %% izracunaj Neglerke, ref:http://www.ats.ucla.edu/stat/mult_pkg/faq/general/Psuedo_RSquareds.htm
        function [rez]  = izracunajNagelkerkeR2(predvidjeneVerovatnoce, targetPodaci)
            y_i         = targetPodaci          ; % nezavisna promenljiva, target
            y_hat       = predvidjeneVerovatnoce; % predvidjena verovatnoca
            y_nadvuceno = mean(y_i)             ; % srednja vrednost 
            %
            rez         = 1 - sum((y_i-y_hat) .* (y_i-y_hat)) / sum((y_i-y_nadvuceno) .* (y_i-y_nadvuceno));
        end
    %% izcracunaj trupe/false pozitive
        function [TP FP TN FN] = izracunajTrueFalsePositiveNegative(predvidjeneVerovatnoce_01, targetPodaci, treshold)
            predvidjeneVerovatnoce_01 = predvidjeneVerovatnoce_01(:);
            targetPodaci              = targetPodaci(:)             ;
            treshold                  = treshold(:)                 ;
            if nargin ==3
                predvidjeneVerovatnoce_01 = predvidjeneVerovatnoce_01>=treshold;
            end
            % prebroj true i false positive 
            TP  = sum((predvidjeneVerovatnoce_01 + targetPodaci) == 2);
            FP  = sum(predvidjeneVerovatnoce_01  > targetPodaci)       ;
            TN  = sum((predvidjeneVerovatnoce_01 + targetPodaci) == 0);
            FN  = sum(predvidjeneVerovatnoce_01  < targetPodaci)       ;
        end
        %% izracuna sensitivity i specificity 
        function [sensitivity, specificity, PPV, NPV, F1, Youden, accuracy] = izracunajSensitivitSpecifiti(TP, FP, TN, FN)
            sensitivity = TP / (TP+FN);
            specificity = TN / (TN+FP);
            PPV         = TP / (TP+FP);
            NPV         = TN / (TN+FN);
            accuracy    = (TN + TP) / (TP + FP + TN + FN);
            F1          = 2*TP  / (2*TP + FP + FN);
            Youden      = sensitivity + specificity-1;            
        end
        %% izracunaj likelihood ratio, ref:http://en.wikipedia.org/wiki/Likelihood_ratios_in_diagnostic_testing
        function [LR_plus, LR_minus] = izracunajLikelihoodRatio(sensitivity, specificity)
            LR_plus  = sensitivity     / (1-specificity);
            LR_minus = (1-sensitivity) / specificity    ;            
        end
        %% izracunaj ROC krivu
        function [AUC, x1minusSpecifiti, ySenzitiviti] = ROC(predvidjeneVerovatnoce, targetPodaci, daLiStampatiDijagram)
            predvidjeneVerovatnoce=predvidjeneVerovatnoce(:); targetPodaci=targetPodaci(:);
            [x1minusSpecifitiPom,ySenzitivitiPom,T,AUC] = perfcurve(targetPodaci, predvidjeneVerovatnoce, 1);
            % mora da se interpolira, da bi svaki dijagram imao isti br tacki
            x1minusSpecifiti = [0:1/100:1];
            ySenzitiviti  = interp1q(x1minusSpecifitiPom,ySenzitivitiPom, x1minusSpecifiti(:));
            if daLiStampatiDijagram
                plot(x1minusSpecifiti,ySenzitiviti);
                xlabel('False positive rate'); ylabel('True positive rate');
                title('ROC kriva');
            end
        end
        %% Chi squere test
        %ref:http://www.okstate.edu/ag/agedcm4h/academic/aged5980a/5980/newpage28.htm
        %http://www.geography-site.co.uk/pages/skills/fieldwork/stats/chi.html        
        function [Xc2] = ChiSquereTest(predvidjeneVerovatnoce, targetPodaci)
            Xc2 = (predvidjeneVerovatnoce-targetPodaci).*(predvidjeneVerovatnoce-targetPodaci)./targetPodaci;
            Xc2 = sum(Xc2);
        end
        %% HOSMER LEMERSHOW TEST
        %  http://www.real-statistics.com/logistic-regression/hosmer-lemeshow-test/      
        function [X2HL pVal DF] =.....
      HosmerLemershowChatTest(predvidjeneVerovatnoce, predvidjeneVerovatnoce_01, targetPodaci, opseziVerovatoca)
            if nargin == 3
                opseziVerovatoca = [0,0.25, 0.5, 0.75,   1];
            end
            if numel(opseziVerovatoca)==1%napravi automatski opsege
                pom                       = sort(predvidjeneVerovatnoce)                     ;
                brPredvidjenihVerovatnoca = numel(predvidjeneVerovatnoce)                    ;
                korak                     = round(brPredvidjenihVerovatnoca/opseziVerovatoca);
                br = 0;
                for i = 1:korak:numel(predvidjeneVerovatnoce)
                    br                  = br+1  ;
                    opseziVerovatoca(br)= pom(i);
                end     
                opseziVerovatoca(1)   = pom(1)  ;
                opseziVerovatoca(end) = pom(end);
            end
            %---
            for i = 2:numel(opseziVerovatoca)
                id = find(predvidjeneVerovatnoce>opseziVerovatoca(i-1) & predvidjeneVerovatnoce<=opseziVerovatoca(i) );                
                if ~isempty(id)
                % za keceve
                                        pPred         = mean(predvidjeneVerovatnoce(id));
                                        Total         = numel(id)                       ;                                        
                                        Expected      = Total * pPred                   ;
                                        Observed      = sum(targetPodaci(id))           ; 
                                        HL(i-1)       = ((Observed-Expected)^2)/Expected;
                % za nule
                                        Expected_0    = Total * (1-pPred)                     ;
                                        Observed_0    = sum(1-targetPodaci(id))               ; 
                                        HL_0(i-1)     = ((Observed_0-Expected_0)^2)/Expected_0;
                                        
                else
                    HL(i-1)   = 0;
                    HL_0(i-1) = 0;
                end
            end
            X2HL = sum(HL+HL_0); 
            DF   = numel(HL)-2;
            pVal = 1-chi2cdf(X2HL, DF);
        end
        %% nalazi verovatnocu 
        function [CI plusMinus string]  = confidenceInterval(input, confidenceLevel)
        %reff[1]:http://formulas.tutorvista.com/math/confidence-interval-formula.html
        %reff[2]:http://sph.bu.edu/otlt/MPH-Modules/BS/BS704_Confidence_Intervals/BS704_Confidence_Intervals_print.html
        %reff[3]:http://www.math.unb.ca/~knight/utility/t-table.htm
        %http://www.mathworks.com/help/stats/ztest.html#btqjrxf-2
        %--------------------------------------------------------------------------
        % Z tabela
        z=[ 99.9 3.3;...
            99   2.57;... 
            98.5 2.43;...
            98   2.33;....
            97.5 2.243;...
            96   2.05;....
            95   1.96;...
            92   1.75;...
            90   1.645;...
            85   1.439;....
            75   1.151;....
            80   1.28;....
            75   1.15;... 
            70   1.04;...
            50   0.25];
        %--------------------------------------------------------------------------
        Z = z(find(z(:,1)==confidenceLevel),2);
        if numel(Z)==0
            Z=1.96;
        end
        Xcount        = numel(input);
        Xmean         = mean(input);
        XstdDeviation = std(input);
        % [h,p,ci,zval] = ztest(input,Xmean,XstdDeviation);
        CI        = Xmean;
        plusMinus = Z * (XstdDeviation/sqrt(Xcount));
        string = [ num2str(CI) '+-' num2str(XstdDeviation)];
        end
        %% 
        %INPUTS
            %predvidjeneVerovatnoce - verovatnoce za svaku od klasa (ako je multiclass classification onda je biti vise kolona)
            %
        function [rez  rezPoKlasama] = uradiKompletnuAnalizuKlasifikacija(predvidjeneVerovatnoce, groundTruthOutcome)
            [verovatnocaPredvidjeneKlase predvidjeniOutcome] = max(predvidjeneVerovatnoce'); 
            predvidjeniOutcome=predvidjeniOutcome(:)-1; % verovatnoca predvidjene klase
            [rows       columns]                           = size(predvidjeneVerovatnoce)    ; % brKlasa = columns
            pom                                            = groundTruthOutcome              ;
            targetPodaci                                   = zeros(rows, columns)          ;
            predictedClass_poKlasama                       = zeros(rows, columns)          ;
            for i = 1 : numel(pom)
                predvidjeniOutcome_01PoKlasama(i, predvidjeniOutcome(i)+1) = 1;
                groundtruthOutcome_01PoKlasama(i, groundTruthOutcome(i)+1) = 1;
            end
            %ako je multiclass onda radi za svaku klasu posebno
            for iKlase = 1 : numel (targetPodaci(1,:))
                 rezPoKlasama.predvidjeneVerovatnoce(:,iKlase)                                                                                                                 = predvidjeneVerovatnoce(:,iKlase)   ;
                [rezPoKlasama.performanse.AUC(iKlase), rezPoKlasama.performanse.x1minusSpecifiti{iKlase}, rezPoKlasama.performanse.ySenzitiviti{iKlase}]                       = arsStatistika.ROC(predvidjeneVerovatnoce(:,iKlase), groundtruthOutcome_01PoKlasama(:,iKlase), 0);
                [rezPoKlasama.performanse.TP(iKlase),  rezPoKlasama.performanse.FP(iKlase)  rezPoKlasama.performanse.TN(iKlase) rezPoKlasama.performanse.FN(iKlase)] = arsStatistika.izracunajTrueFalsePositiveNegative(predvidjeneVerovatnoce(:,iKlase), groundtruthOutcome_01PoKlasama(:,iKlase), verovatnocaPredvidjeneKlase);
                [rezPoKlasama.performanse.sensitivity(iKlase), rezPoKlasama.performanse.specificity(iKlase), ...
                     rezPoKlasama.performanse.PPV(iKlase), rezPoKlasama.performanse.NPV(iKlase),  ...
                     rezPoKlasama.performanse.F1(iKlase), rezPoKlasama.performanse.Youden(iKlase),...
                     rezPoKlasama.performanse.accuracy(iKlase)] = arsStatistika.izracunajSensitivitSpecifiti(rezPoKlasama.performanse.TP(iKlase), rezPoKlasama.performanse.FP(iKlase), rezPoKlasama.performanse.TN(iKlase), rezPoKlasama.performanse.FN(iKlase));
                [rezPoKlasama.performanse.kappa(iKlase)       ] = arsStatistika.kappaindex(predvidjeniOutcome_01PoKlasama(:,iKlase)+1, groundtruthOutcome_01PoKlasama(:,iKlase)+1); %ne sme da bude class=0
                rezPoKlasama.mse(iKlase)                        = mean((groundtruthOutcome_01PoKlasama(:,iKlase) - predvidjeniOutcome_01PoKlasama(:,iKlase)).^2);
            end    
            rez.predvidjeniOutcome             = predvidjeniOutcome(:)         ;
            rez.verovatnocaPredvidjeneKlase    = verovatnocaPredvidjeneKlase(:);
            rez.predvidjeniOutcome_01PoKlasama = predvidjeniOutcome_01PoKlasama;
            rez.groundtruthOutcome_01PoKlasama = groundtruthOutcome_01PoKlasama;
            rez.kappa                          = arsStatistika.kappaindex(predvidjeniOutcome+1, groundTruthOutcome+1);
            rez.MatricaKonfuzije               = confusionmat(groundTruthOutcome, predvidjeniOutcome);
            rez.mseUPredvidjanjuKlasa          = mean(((groundTruthOutcome(:)-predvidjeniOutcome(:))).^2);
            rez.preciznostPredvidjanjaKlasa    = sum(groundTruthOutcome==predvidjeniOutcome)/numel(groundTruthOutcome);
            %  Weighted average parametara racunatih za ostale klase
            procenatPrimeraUBazi = sum(groundtruthOutcome_01PoKlasama) / numel(groundTruthOutcome); procenatPrimeraUBazi=procenatPrimeraUBazi(:);
            for iKlase = 1 : numel (procenatPrimeraUBazi(1,:)) 
                rez.wa_AUC      = sum(procenatPrimeraUBazi .* rezPoKlasama.performanse.AUC(:)   );                
                rez.wa_accuracy = sum(procenatPrimeraUBazi .* rezPoKlasama.performanse.accuracy(:));
                rez.wa_TP       = sum(procenatPrimeraUBazi .* rezPoKlasama.performanse.TP(:)    );
                rez.wa_FP       = sum(procenatPrimeraUBazi .* rezPoKlasama.performanse.FP(:)    );
                rez.wa_TN       = sum(procenatPrimeraUBazi .* rezPoKlasama.performanse.TN(:)    );
                rez.wa_FN       = sum(procenatPrimeraUBazi .* rezPoKlasama.performanse.FN(:)    );
                rez.wa_PPV      = sum(procenatPrimeraUBazi .* rezPoKlasama.performanse.PPV(:)   );
                rez.wa_NPV      = sum(procenatPrimeraUBazi .* rezPoKlasama.performanse.NPV(:)   );
                rez.wa_mse      = sum(procenatPrimeraUBazi .* rezPoKlasama.mse(:)               );
                rez.wa_kappa    = sum(procenatPrimeraUBazi .* rezPoKlasama.performanse.kappa(iKlase));
            end            
        end
        %% Funkcija nalazi srendju vrednost 
        function [rez1  rezPoKlasama1] = nadjiSrednjuVrednostOd_uradiKompletnuAnalizuKlasifikacija(rez, rezPoKlasama)
            brFoldova          = numel(rez)           ;
            rez1               = rez{1}               ; 
            rezPoKlasama1      = rezPoKlasama{1}      ;
            %--------------------------------------------------------------            
            rezPoKlasama1.performanse.AUC                      = rezPoKlasama1.performanse.AUC                      /brFoldova;
            for iKlase = 1 : numel(rezPoKlasama1.performanse.x1minusSpecifiti(1,:))
                rezPoKlasama1.performanse.x1minusSpecifiti{iKlase} = rezPoKlasama1.performanse.x1minusSpecifiti{iKlase} /brFoldova;
                rezPoKlasama1.performanse.ySenzitiviti{iKlase}     = rezPoKlasama1.performanse.ySenzitiviti{iKlase}     /brFoldova;
            end
            rezPoKlasama1.performanse.TP                       = rezPoKlasama1.performanse.TP                       /brFoldova;
            rezPoKlasama1.performanse.FP                       = rezPoKlasama1.performanse.FP                       /brFoldova;
            rezPoKlasama1.performanse.TN                       = rezPoKlasama1.performanse.TN                       /brFoldova;
            rezPoKlasama1.performanse.FN                       = rezPoKlasama1.performanse.FN                       /brFoldova;
            rezPoKlasama1.performanse.sensitivity              = rezPoKlasama1.performanse.sensitivity              /brFoldova;
            rezPoKlasama1.performanse.specificity              = rezPoKlasama1.performanse.specificity              /brFoldova;
            rezPoKlasama1.performanse.PPV                      = rezPoKlasama1.performanse.PPV                      /brFoldova;
            rezPoKlasama1.performanse.NPV                      = rezPoKlasama1.performanse.NPV                      /brFoldova;
            rezPoKlasama1.performanse.F1                       = rezPoKlasama1.performanse.F1                       /brFoldova;    
            rezPoKlasama1.performanse.Youden                   = rezPoKlasama1.performanse.Youden                   /brFoldova;
            rezPoKlasama1.performanse.accuracy                 = rezPoKlasama1.performanse.accuracy                 /brFoldova;
            rezPoKlasama1.performanse.kappa                    = rezPoKlasama1.performanse.kappa                    /brFoldova;
            rezPoKlasama1.mse                                  = rezPoKlasama1.mse                                  /brFoldova;
            %
            rez1.predvidjeniOutcome                            = rez1.predvidjeniOutcome                            /brFoldova;            
            rez1.kappa                                         = rez1.kappa                                         /brFoldova;            
            rez1.MatricaKonfuzije                              = rez1.MatricaKonfuzije                              /brFoldova;
            rez1.mseUPredvidjanjuKlasa                         = rez1.mseUPredvidjanjuKlasa                         /brFoldova;
            rez1.wa_AUC                                        = rez1.wa_AUC                                        /brFoldova;
            rez1.wa_accuracy                                   = rez1.wa_accuracy                                   /brFoldova;
            rez1.wa_TP                                         = rez1.wa_TP                                         /brFoldova;
            rez1.wa_FP                                         = rez1.wa_FP                                         /brFoldova;    
            rez1.wa_TN                                         = rez1.wa_TN                                         /brFoldova;
            rez1.wa_FN                                         = rez1.wa_FN                                         /brFoldova;
            rez1.wa_PPV                                        = rez1.wa_PPV                                        /brFoldova;
            rez1.wa_NPV                                        = rez1.wa_NPV                                        /brFoldova;
            rez1.wa_mse                                        = rez1.wa_mse                                        /brFoldova;
            rez1.wa_kappa                                      = rez1.wa_kappa                                      /brFoldova;
            rez1.wa_FN                                         = rez1.wa_FN                                         /brFoldova;       
            %------------------------------------------------------------------------------------------------------------------
            for iFolda = 2:numel(rez)   
                rez2          = rez{iFolda}         ; 
                rezPoKlasama2 = rezPoKlasama{iFolda};
                brKlasa                                    = numel(rezPoKlasama1.predvidjeneVerovatnoce(1,:))                       ;
                rezPoKlasama1.performanse.AUC              = rezPoKlasama1.performanse.AUC              + rezPoKlasama2.performanse.AUC              /brFoldova;
                for iKlase = 1 : brKlasa
                    rezPoKlasama1.performanse.x1minusSpecifiti{iKlase} = rezPoKlasama1.performanse.x1minusSpecifiti{iKlase} + rezPoKlasama2.performanse.x1minusSpecifiti{iKlase} /brFoldova;
                    rezPoKlasama1.performanse.ySenzitiviti{iKlase}     = rezPoKlasama1.performanse.ySenzitiviti{iKlase}     + rezPoKlasama2.performanse.ySenzitiviti{iKlase}     /brFoldova;     
                end
                rezPoKlasama1.performanse.TP               = rezPoKlasama1.performanse.TP               + rezPoKlasama2.performanse.TP               /brFoldova;
                rezPoKlasama1.performanse.FP               = rezPoKlasama1.performanse.FP               + rezPoKlasama2.performanse.FP               /brFoldova;
                rezPoKlasama1.performanse.TN               = rezPoKlasama1.performanse.TN               + rezPoKlasama2.performanse.TN               /brFoldova;
                rezPoKlasama1.performanse.FN               = rezPoKlasama1.performanse.FN               + rezPoKlasama2.performanse.FN               /brFoldova;
                rezPoKlasama1.performanse.sensitivity      = rezPoKlasama1.performanse.sensitivity      + rezPoKlasama2.performanse.sensitivity      /brFoldova;
                rezPoKlasama1.performanse.specificity      = rezPoKlasama1.performanse.specificity      + rezPoKlasama2.performanse.specificity      /brFoldova;
                rezPoKlasama1.performanse.PPV              = rezPoKlasama1.performanse.PPV              + rezPoKlasama2.performanse.PPV              /brFoldova;
                rezPoKlasama1.performanse.NPV              = rezPoKlasama1.performanse.NPV              + rezPoKlasama2.performanse.NPV              /brFoldova;
                rezPoKlasama1.performanse.F1               = rezPoKlasama1.performanse.F1               + rezPoKlasama2.performanse.F1               /brFoldova;
                rezPoKlasama1.performanse.Youden           = rezPoKlasama1.performanse.Youden           + rezPoKlasama2.performanse.Youden           /brFoldova;
                rezPoKlasama1.performanse.accuracy         = rezPoKlasama1.performanse.accuracy         + rezPoKlasama2.performanse.accuracy         /brFoldova;
                rezPoKlasama1.performanse.kappa            = rezPoKlasama1.performanse.kappa            + rezPoKlasama2.performanse.kappa            /brFoldova;
                rezPoKlasama1.mse                          = rezPoKlasama1.mse                          + rezPoKlasama2.mse                          /brFoldova;
    %             rez.predvidjeniOutcome   % ovo nema smisla da se usrednjava?
    %             rez.verovatnocaPredvidjeneKlase
    %             rez.predvidjeniOutcome_01PoKlasama
    %             rez.groundtruthOutcome_01PoKlasama
                rez1.predvidjeniOutcome    = rez1.predvidjeniOutcome    + rez2.predvidjeniOutcome   /brFoldova;
                rez1.kappa                 = rez1.kappa                 + rez2.kappa                /brFoldova;
                rez1.MatricaKonfuzije      = rez1.MatricaKonfuzije      + rez2.MatricaKonfuzije     /brFoldova;
                rez1.mseUPredvidjanjuKlasa = rez1.mseUPredvidjanjuKlasa + rez2.mseUPredvidjanjuKlasa/brFoldova;
                rez1.wa_AUC                = rez1.wa_AUC                + rez2.wa_AUC               /brFoldova;
                rez1.wa_accuracy           = rez1.wa_accuracy           + rez2.wa_accuracy          /brFoldova;
                rez1.wa_TP                 = rez1.wa_TP                 + rez2.wa_TP                /brFoldova;
                rez1.wa_FP                 = rez1.wa_FP                 + rez2.wa_FP                /brFoldova;
                rez1.wa_TN                 = rez1.wa_TN                 + rez2.wa_TN                /brFoldova;
                rez1.wa_FN                 = rez1.wa_FN                 + rez2.wa_FN                /brFoldova;
                rez1.wa_PPV                = rez1.wa_PPV                + rez2.wa_PPV               /brFoldova;
                rez1.wa_NPV                = rez1.wa_NPV                + rez2.wa_NPV               /brFoldova;
                rez1.wa_mse                = rez1.wa_mse                + rez2.wa_mse               /brFoldova;
                rez1.wa_kappa              = rez1.wa_kappa              + rez2.wa_kappa             /brFoldova;
            end
        end
        %%
        function uradiKompletnuAnalizu(predvidjeneVerovatnoce,predvidjeneVerovatnoce_01, targetPodaci)
            %% ANALIZA PODATAKA
            %1 - nadji confidence interval za 95%
            CI95                                  = arsStatistika.confidenceInterval(predvidjeneVerovatnoce, 95)                       ;
            fprintf('#1 CI 95%% = %f\n', CI95);
            CI95 = 0.5;
            %2 - nacrtaj ROC krivu i nadji AUC
            [AUC, x1minusSpecifiti, ySenzitiviti] = arsStatistika.ROC(predvidjeneVerovatnoce, targetPodaci, 1)              ;
            fprintf('#2 AUC = %f\n', AUC);
            %3 - izracunaj brier score
            [BrierScore]                          = arsStatistika.izcracunajBrierScore(predvidjeneVerovatnoce, targetPodaci);
            fprintf('#3 Brier Score = %f\n', BrierScore);
            %4 - izracunaj true false positive negative
            treshold = CI95;
            [TP FP TN FN]                         = arsStatistika.izracunajTrueFalsePositiveNegative(predvidjeneVerovatnoce, targetPodaci, treshold);
            fprintf('#4 TP = %d \n   FP = %d\n   TN = %d\n   FN = %d\n', TP, FP, TN, FN);
            %5 - izracunaj senzitiviti specifiti
            [sensitivity, specificity, PPV, NPV, F1, Youden, accuracy] = arsStatistika.izracunajSensitivitSpecifiti(TP, FP, TN, FN);
            fprintf('#5 sensitivity = %f\n   specificity = %f\n   PPV         = %f\n   NPV         = %f\n   F1          = %f\n   Youden      = %f\n   accuracy    = %f\n', sensitivity, specificity, PPV, NPV, F1, Youden, accuracy);
            %6 - izracunaj NagelkerkeR2
            [NagelkerkeR2]                        = arsStatistika.izracunajNagelkerkeR2(predvidjeneVerovatnoce, targetPodaci)      ;
            fprintf('#6 NagelkerkeR2 = %f\n', NagelkerkeR2);
            %7 - izracunaj Likelihood Ratio
            [LR_plus, LR_minus]                   = arsStatistika.izracunajLikelihoodRatio(sensitivity, specificity)               ;
            fprintf('#7 Likelihood Ratio\n   LR_plus  = %f\n   LR_minus = %f\n', LR_plus, LR_minus);
            %8 - izracunaj Hosmer Lemershow test
            [X2HL X2HL0 DF]     = arsStatistika.HosmerLemershowChatTest(predvidjeneVerovatnoce, predvidjeneVerovatnoce_01, targetPodaci);
            fprintf('#8 Hosmer Lemershow test\n   X2HL  = %f\n   DF             = %f\n   X2HL0  = %f\n', X2HL,DF,X2HL0);
        end
   
%% Intra rater varijabilnost
%ref https://www.mathworks.com/matlabcentral/fileexchange/22308-cohen-s-kappa-with-customizable-weightings
% radi i za binarnu i ordinalnu skalu (moraju da se unesu tezine)
%INPUTS
    %Observer1, Observer2 - predvidjanja observera
    %Weights              - tezinski faktori, bitni su ako ima vise klasa. Nije isto ako umesto 0 stavi 1 ili 3.
%OUTPUTS
    %kappa                - kappa vrednost     - double
    %rez                  - dodatni indikatori - struktura
        function [kappa rez] = kappa(Observer1, Observer2, Weights, SigniicanceLevel)            
            matricaKonfuzije = confusionmat(Observer1, Observer2);
            if nargin<4
                SigniicanceLevel = 0.05;
            end
            if nargin < 3 
                Weights          = diag(ones(1,numel(matricaKonfuzije(:,1))));
            elseif nargin == 3   &   Weights == 1 %linear weighted kappa
%                 [I J] = size(matricaKonfuzije);
%                 for i = 1 : I
%                     for j = 1 : J
%                         Weights(i,j) =  abs(i-j);
%                     end
%                 end
                Weights=1;
            end
            rez = arsStatistika.kappa_od_matrice_konfuzije(matricaKonfuzije, Weights, SigniicanceLevel);
            kappa = rez.kappa;
        end
        
function rez = kappa_od_matrice_konfuzije(varargin)
% KAPPA: This function computes the Cohen's kappa coefficient.
% Cohen's kappa coefficient is a statistical measure of inter-rater
% reliability. It is generally thought to be a more robust measure than
% simple percent agreement calculation since k takes into account the
% agreement occurring by chance.
% Kappa provides a measure of the degree to which two judges, A and B,
% concur in their respective sortings of N items into k mutually exclusive
% categories. A 'judge' in this context can be an individual human being, a
% set of individuals who sort the N items collectively, or some non-human
% agency, such as a computer program or diagnostic test, that performs a
% sorting on the basis of specified criteria.
% The original and simplest version of kappa is the unweighted kappa
% coefficient introduced by J. Cohen in 1960. When the categories are
% merely nominal, Cohen's simple unweighted coefficient is the only form of
% kappa that can meaningfully be used. If the categories are ordinal and if
% it is the case that category 2 represents more of something than category
% 1, that category 3 represents more of that same something than category
% 2, and so on, then it is potentially meaningful to take this into
% account, weighting each cell of the matrix in accordance with how near it
% is to the cell in that row that includes the absolutely concordant items.
% This function can compute a linear weights or a quadratic weights.
%
% Syntax: 	kappa(X,W,ALPHA)
%      
%     Inputs:
%           X - square data matrix = matrica konfuzije izmedju 2 obsrervera
%           W - Weight - If this is -1, 0, 1, or 2 Then the program does:
%                0 = unweighted; 1 = linear weighted; 2 = quadratic weighted; -1 = display all 3
%               If this is a matrix, then the program uses the matrix as a custom weighting matrix 
%               The default value is 0
%           ALPHA - Significance level. default=0.05.
%
%     Outputs:
%           - Observed agreement percentage
%           - Random agreement percentage
%           - Agreement percentage due to true concordance
%           - Residual not random agreement percentage
%           - Cohen's kappa 
%           - kappa error
%           - kappa confidence interval
%           - Maximum possible kappa
%           - k observed as proportion of maximum possible
%           - k benchmarks by Landis and Koch 
%           - z test results
%
%      Example: 
%
%           x=[88 14 18; 10 40 10; 2 6 12];
%
%           Calling on Matlab the function: kappa(x)
%
%           Answer is:
%
% UNWEIGHTED COHEN'S KAPPA
% --------------------------------------------------------------------------------
% Observed agreement (po) = 0.7000
% Random agreement (pe) = 0.4100
% Agreement due to true concordance (po-pe) = 0.2900
% Residual not random agreement (1-pe) = 0.5900
% Cohen's kappa = 0.4915
% kappa error = 0.0549
% kappa C.I. (alpha = 0.0500) = 0.3839     0.5992
% Maximum possible kappa, given the observed marginal frequencies = 0.8305
% k observed as proportion of maximum possible = 0.5918
% Moderate agreement
% Variance = 0.0031     z (k/sqrt(var)) = 8.8347    p = 0.0000
% Reject null hypotesis: observed agreement is not accidental
%
%
% This script originally created by Giuseppe Cardillo
%           giuseppe.cardillo-edta@poste.it
% http://www.mathworks.com/matlabcentral/fileexchange/15365
%
% This version of the kappa file is minorly modified by Ariel Shwayder (shwayder@gmail.com) to
% allow for custom weighting matrices.  Dec. 3 2008.
% 
% Example of custom weighting:
%  x=[70 7 3; 8 350 44; 1 4 5];
%  weights = [ 0 1 .5; 1 0 .5 ; .5 .5 0];
% 
% Calling kappa(x,weights) returns:
% CUSTOM WEIGHTED COHEN'S KAPPA
% --------------------------------------------------------------------------------
% Observed agreement (po) = 0.0833
% Random agreement (pe) = 0.3114
% Agreement due to true concordance (po-pe) = -0.2280
% Residual not random agreement (1-pe) = 0.6886
% Cohen's kappa = -0.3311
% kappa error = 0.0181
% kappa C.I. (alpha = 0.0500) = -0.3666     -0.2957
% Maximum possible kappa, given the observed marginal frequencies = 0.8760
% k observed as proportion of maximum possible = -0.3780
% Poor agreement
% Variance = 0.0003     z (k/sqrt(var)) = -18.2406    p = 0.0000
% Reject null hypotesis: observed agreement is not accidental


%Input Error handling
args=cell(varargin);
nu=numel(args);
if isempty(nu)
    error('Warning: Matrix of data is missed...')
elseif nu>3
    error('Warning: Max three inputs')
end
default.values = {[],0,0.05};
default.values(1:nu) = args;
[x w alpha] = deal(default.values{:});

if isempty(x)
    error('Warning: X matrix is empty...')
end
if isvector(x)
    error('Warning: X must be a matrix not a vector')
end
if ~all(isfinite(x(:))) || ~all(isnumeric(x(:)))
    error('Warning: all X values must be numeric and finite')
end   
if ~isequal(x(:),round(x(:)))
    error('Warning: X data matrix values must be whole numbers')
end

m=size(x);
if ~isequal(m(1),m(2))
    error('Input matrix must be a square matrix')
end
if nu>1 % Check that weight input is ok
    sizew = size(w);
    if ~isscalar(w) && (~isequal(m(1),sizew(1)) || ~isequal(m(2),sizew(2)))
       error('Warning: Custom weight must be of the same size as x.') 
    end
    if isscalar(w) && ~(w==-1 || w==0 || w==1 || w==2)
        error('Warning: w must either be -1,0,1,2 or a custom weighting matrix')
    end
end
if nu>2 %Check that alpha input is okay
    if ~isscalar(alpha) || ~isnumeric(alpha) || ~isfinite(alpha) || isempty(alpha)
        error('Warning: Alpha must be a numeric, finite and scalar value.');
    end
    if alpha <= 0 || alpha >= 1 %check if alpha is between 0 and 1
        error('Warning: ALPHA must be comprised between 0 and 1.')
    end
end

m=m(1);
tr=repmat('-',1,80);
if isscalar(w) && (w==0 || w==-1)
    f=diag(ones(1,m)); %unweighted
    disp('UNWEIGHTED COHEN''S KAPPA')
    disp(tr)
    rez = arsStatistika.kcomp(x,f,alpha);
    disp(' ')
end
if isscalar(w) && (w==1 || w==-1)
    J=repmat((1:1:m),m,1);
    I=flipud(rot90(J));
    f=1-abs(I-J)./(m-1); %linear weight
    disp('LINEAR WEIGHTED COHEN''S KAPPA')
    disp(tr)
    rez = arsStatistika.kcomp(x,f,alpha);
    disp(' ')
end
if isscalar(w) && (w==2 || w==-1)
    J=repmat((1:1:m),m,1);
    I=flipud(rot90(j));
    f=1-((I-J)./(m-1)).^2; %quadratic weight
    disp('QUADRATIC WEIGHTED COHEN''S KAPPA')
    disp(tr)
    rez = arsStatistika.kcomp(x,f,alpha);
    disp(' ')
end

if ~isscalar(w) 
    % Use custom weightings
    disp('CUSTOM WEIGHTED COHEN''S KAPPA')
    disp(tr)
    rez = arsStatistika.kcomp(x,w,alpha);
return
end
end

function rez = kcomp(x,f,alpha)
m=length(x);
n=sum(x(:)); %Sum of Matrix elements
x=x./n; %proportion
r=sum(x,2); %rows sum
s=sum(x); %columns sum
Ex=r*s; %expected proportion for random agree
pom=sum(min([r';s]));
po=sum(sum(x.*f));
pe=sum(sum(Ex.*f));
k=(po-pe)/(1-pe);
km=(pom-pe)/(1-pe); %maximum possible kappa, given the observed marginal frequencies
ratio=k/km; %observed as proportion of maximum possible
sek=sqrt((po*(1-po))/(n*(1-pe)^2)); %kappa standard error for confidence interval
ci=k+([-1 1].*(abs(-realsqrt(2)*erfcinv(alpha))*sek)); %k confidence interval
wbari=r'*f;
wbarj=s*f;
wbar=repmat(wbari',1,m)+repmat(wbarj,m,1);
a=Ex.*((f-wbar).^2);
var=(sum(a(:))-pe^2)/(n*((1-pe)^2)); %variance
z=k/sqrt(var); %normalized kappa
p=(1-0.5*erfc(-abs(z)/realsqrt(2)))*2;
%display results
fprintf('Observed agreement (po) = %0.4f\n',po)                                        ; rez.ObservedAgreement = po;
fprintf('Random agreement (pe) = %0.4f\n',pe)                                          ; rez.RandomAgreement   = pe;
fprintf('Agreement due to true concordance (po-pe) = %0.4f\n',po-pe)                   ;% rez.ObservedAgreement = po;
fprintf('Residual not random agreement (1-pe) = %0.4f\n',1-pe)                         ;% rez.ObservedAgreement = po;
fprintf('Cohen''s kappa = %0.4f\n',k)                                                  ; rez.kappa             = k ;
fprintf('kappa error = %0.4f\n',sek)                                                   ;% rez.ObservedAgreement = po;
fprintf('kappa C.I. (alpha = %0.4f) = %0.4f     %0.4f\n',alpha,ci)                     ;% rez.ObservedAgreement = po;
fprintf('Maximum possible kappa, given the observed marginal frequencies = %0.4f\n',km);% rez.ObservedAgreement = po;
fprintf('k observed as proportion of maximum possible = %0.4f\n',ratio)
if k<0
    disp('Poor agreement')
elseif k>=0 && k<=0.2
    disp('Slight agreement')
elseif k>0.2 && k<=0.4
    disp('Fair agreement')
elseif k>0.4 && k<=0.6
    disp('Moderate agreement')
elseif k>0.6 && k<=0.8
    disp('Substantial agreement')
elseif k>0.8 && k<=1
    disp('Perfect agreement')
end
fprintf('Variance = %0.4f     z (k/sqrt(var)) = %0.4f    p = %0.4f\n',var,z,p)
if p<0.05
    disp('Reject null hypotesis: observed agreement is not accidental')
else
    disp('Accept null hypotesis: observed agreement is accidental')
end
return
end


    
        
    %% A regret theory approach to decision curve analysis: A novel method for eliciting decision makers' preferences and decision-making
    function [rez] = VickersRegreatDCA(PredictiveModelOutcome, GroundTruth)
        if nargin==1
            GroundTruth            = PredictiveModelOutcome(:,2);
            PredictiveModelOutcome = PredictiveModelOutcome(:,1);            
        end
        %#1 Selektuj vrednost za threshold probability
        i = 0; %brojac
        for pt=0:0.01:1
        %#2 Pretpostavljajuci da pacijent treba da bude tretiran ako je
        %p>=pt, odnosno ne treba u suprotnom, naci #TP i #FP
            [TP FP TN FN] = arsStatistika.izracunajTrueFalsePositiveNegative(PredictiveModelOutcome, GroundTruth, pt);
            n             = numel(GroundTruth)                                                                       ;
            i                              = i+1                          ;%brojac/index
            pt_REZ(i)                      = pt                           ;%verovatnoce za crtanje dijagrama
        %#3 Izracunaj NERD(Treat none, Model) prema jednacini 10. iz rada
            NERD_TreatNone_Model_REZ(i)    = TP/n - (FP/n)*(pt/(1-pt))    ;
        %#4 Izracunaj NERD(Treat All, Model) prema jednacini 11. iz rada
            NERD_TreatAll_Model_REZ(i)     = (TN/n) * (pt/(1-pt)) - (FN/n);
        %#5 Izracunaj NERD(Treat None, Treat Alll) prema jednacini 10. iz rada, uzimajuci da je TP i FP konstantno (koliko stvarno jeste) 
            pomTP = sum(GroundTruth)        ;
            pomFP = numel(GroundTruth)-pomTP;
            NERD_TreatNone_TreatAll_REZ(i) = pomTP/n - (pomFP/n)*(pt/(1-pt))    ;         
        %%6 
            ERg(i)                         = FN/n + (FP/n)*(pt/(1-pt));
        end
    rez.pt_REZ                      = pt_REZ                     ;
    rez.NERD_TreatNone_Model_REZ    = NERD_TreatNone_Model_REZ   ;
    rez.NERD_TreatAll_Model_REZ     = NERD_TreatAll_Model_REZ    ;
    rez.NERD_TreatNone_TreatAll_REZ = NERD_TreatNone_TreatAll_REZ;
    rez.ERg                         = ERg                        ;
    %
    
        % prikaz rezultata
        id = find(NERD_TreatNone_Model_REZ>-0.9 & NERD_TreatNone_Model_REZ<0.9);
        plot(gca,pt_REZ(id),NERD_TreatNone_Model_REZ(id),'Color','black'); hold on;   
        %
        id = find(NERD_TreatAll_Model_REZ>-0.9 & NERD_TreatAll_Model_REZ<0.9);
        plot(gca,pt_REZ(id),NERD_TreatAll_Model_REZ(id),'Color','red');
        %
        id = find(NERD_TreatNone_TreatAll_REZ>-0.9 & NERD_TreatNone_TreatAll_REZ<0.9);
        plot(gca,pt_REZ(id),NERD_TreatNone_TreatAll_REZ(id),'Color','blue');
    legend(gca,'Treat None, Model','Treat All, Model','Treat None, Treat All');
    xlabel(gca,'Risk Treshold');
    ylabel(gca,'NERD');
    end
    %%
    %% Return the exact p value, given a z (standardized distribution) value 
% INPUT:
%       z value 
% OUTPUT:
%       exact p value for that z
%%
    function [pvalue] =  izracunajPValue(z)
        z = abs(z);
        F = @(x)(exp (-0.5*(x.^2))./sqrt (2*pi));
        p = quad (F, z, 100);
        %fprintf ('\nOne tail p-value : %1.6f', p);
        %fprintf ('\nTwo tail p-value : %1.6f\n' ,p*2)
        %Return two tail p-value
        pvalue = p*2; 
    end
    %%
    %ref http://en.wikipedia.org/wiki/Bland%E2%80%93Altman_plot
    %INPUTS
        %S1 - ground truth
        %S2 - proposed
    function [rez] = BlandAltmanPlot(data1,data2,splitID)
        mask =   logical(data1);
        data1=data1(:); data2=data2(:);
        x = (data1+data2)/2; %srednja vrednost
        y = data1-data2    ; %razlika
        %nacrtaj dijagram
        if exist('splitID')
            plot(x(1:splitID),y(1:splitID),'*' );
            hold on; plot(x(splitID:end),y(splitID:end),'s' );
        else
            plot(x,y,'*' );
        end
        % add std-dev lines
        st = std(data2(mask)-data1(mask));
        mn = mean(data2(mask)-data1(mask));
        [h, p] = ttest(data2(mask)-data1(mask),0);
        cr = 2.0*st;
        hold on;
        text(max(x),mn+2*st, [num2str(mn+2*st,2) ' (mean+2.00SD)']); plot([min(x) max(x)], [mn+2*st, mn+2*st ]);
        text(max(x),+mn  ,   [num2str(mn,2)      ' (mean)']       ); plot([min(x) max(x)], [     mn, mn      ]);
        text(max(x),mn-2*st, [num2str(mn-2*st,2) ' (mean-2.00SD)']); plot([min(x) max(x)], [mn-2*st, mn-2*st ]);       
    end
    % izracunaj korelaciju 
    %INPUTS
        %S1,S2 ulazni podaci
    % OUTPUTS
        %  - 'eq'     slope and intercept equation
        %  - 'int%'   intercept as % of mean values
        %  - 'r'      pearson r-value
        %  - 'r2'     pearson r-value squared
        %  - 'rho'    Spearman rho value
        %  - 'SSE'    sum of squared error
        %  - 'n'      number of data points used    
        %[eq, int, r,r2, rho, SSE, n] = 
    function  r2=  izracunajKorelaciju(data1, data2, splitID)
        mask =   logical(data1);
        data1=data1(:); data2=data2(:);
        [polyCoefs, S] = polyfit(data1(mask),data2(mask),1)                ;
        r              = corrcoef(data1(mask),data2(mask))                 ; 
        r              = r(1,2)                                            ;
        rho            = corr(data1(mask),data2(mask),'type','Spearman')   ;
        N              = sum(mask)                                         ;
        SSE            = sqrt(sum((polyval(polyCoefs,data1(mask))-data2(mask)).^2)/(N-2));
        %plot
        if exist('splitID')
            plot(data1(1:splitID)  ,data2(1:splitID)  ,'*');
            hold on; 
            plot(data1(splitID:end),data2(splitID:end),'s');
        else
            plot(data1,data2,'*' );
        end
        axesLimits = [min(min(data1),min(data2)) max(max(data1),max(data2))]; 
        hold on; plot([0 axesLimits(2)], [0 axesLimits(2)],'color',[0.6 0.6 0.6],'linestyle',':');%linija za idealnu korelaciju
        hold on; plot(axesLimits(1:2), polyval(polyCoefs,axesLimits(1:2)),'-k');
        %postavi text
        corrtext{1}= ['y=' num2str(polyCoefs(1),3) 'x+' num2str(polyCoefs(2),3)        ];
        corrtext{2} = ['intercept=' num2str(polyCoefs(2)/mean(data1+data2)*2*100,3) '%'];
        corrtext{3} = ['r^2='       num2str(r^2,4)                                     ];
        corrtext{4} = ['r='         num2str(r,4)                                       ];
        corrtext{5} = ['rho='       num2str(rho,4)                                     ];
        corrtext{6} = ['SSE='       num2str(SSE,2)                                     ];
        corrtext{7} = ['n='         num2str(N)                                         ];
        text(axesLimits(1)+0.01*(axesLimits(2)-axesLimits(1)),axesLimits(1)+0.9*(axesLimits(2)-axesLimits(1)),corrtext);
        xlabel('Ground truth'); ylabel('Predicted');
        axis equal;
        r2 = r*r;
    end
    % 
    function [srednjaVrednost, standardnaDevijacija] = izracunajSrednjuVrednostIDevijaciju(ulaz)
        srednjaVrednost      = mean(ulaz);
        standardnaDevijacija = std(ulaz);
    end
    %% Fja vrsi kFold cross validaciju
    %%INPUTS
        %trainData              - podaci; poslednja kolona je outcome
        %brFoldova              - kFold
        %prediktivniModel       - tip prediktinvog modela
                %prediktivniModel.tipWekaKlasifikatora   - npr 'meta.AttributeSelectedClassifier'
                %prediktivniModel.parametriKlasifikatora - npr '-X 6 -S 1 -W weka.classifiers.trees.J48 -- -C 0.33 -M 2'
        %klasifikacijaRegresija - da li se radi klasifikacij aili regresija
    %%OUTPUTS
        %rez                    - struktura sa usrednjenim performansama
                                %         predvidjeniOutcome: [52×1 double]
                                %        verovatnocaPredvidjeneKlase: [52×1 double]
                                %     predvidjeniOutcome_01PoKlasama: [52×4 double]
                                %     groundtruthOutcome_01PoKlasama: [52×4 double]
                                %                              kappa: 0.2775
                                %                   MatricaKonfuzije: [4×4 double]
                                %              mseUPredvidjanjuKlasa: double
                                %        preciznostPredvidjanjaKlasa: double
                                %                             wa_AUC: double
                                %                        wa_accuracy: double
                                %                              wa_TP: double
                                %                              wa_FP: double
                                %                              wa_TN: double
                                %                              wa_FN: double
                                %                             wa_PPV: double
                                %                             wa_NPV: double
                                %                             wa_mse: double
                                %                           wa_kappa: double
        %arsStatistika          - struktura sa usrednjenim performansama po klasama. Ima iste podatke kao Rez ali za svaku od klasa.        
    function [rez rezPoKlasama] = uradiCrossValidacijuPrediktivnogModelaWeka(trainData, brFoldova, prediktivniModel, klasifikacijaRegresija)
        [rezFold] = arsStatistika.napraviNFoldZaCrossValidaciju(trainData, brFoldova, true);
        for iFolda = 1 : brFoldova
            %obuci na n-1  foldu, n-ti upotrebi za test
            wekaPrediktivniModel                                     = arsStatistika.obuciWekaModel(rezFold{iFolda}.train, prediktivniModel, klasifikacijaRegresija)      ;
            [predictedClass predictedProbability]                    = arsStatistika.testirajWekaModel(wekaPrediktivniModel, rezFold{iFolda}.test, klasifikacijaRegresija);
            [rezPerformanse{iFolda} rezPerformansePoKlasama{iFolda}] = arsStatistika.uradiKompletnuAnalizuKlasifikacija(predictedProbability, rezFold{iFolda}.test(:,end));
            if iFolda == 1                
                rezVerovatnoceZaSveKlase = predictedProbability; 
            else
                rezVerovatnoceZaSveKlase                        = rezVerovatnoceZaSveKlase + predictedProbability;end            
        end
        kFoldVerovatnoca    = rezVerovatnoceZaSveKlase / brFoldova;
        [rez  rezPoKlasama] = arsStatistika.nadjiSrednjuVrednostOd_uradiKompletnuAnalizuKlasifikacija(rezPerformanse, rezPerformansePoKlasama);
    end
    %% Feature selection
    %%INPUTS
        %trainData              - podaci-matrica; poslednja kolona je outcome
        %brFoldova              - kFold
        %prediktivniModel       - tip prediktinvog modela
                %prediktivniModel.tipWekaKlasifikatora   - npr 'meta.AttributeSelectedClassifier'
                %prediktivniModel.parametriKlasifikatora - npr '-X 6 -S 1 -W weka.classifiers.trees.J48 -- -C 0.33 -M 2'
        %klasifikacijaRegresija - da li se radi klasifikacij aili regresija
    %% OUTPUTS
        %rez.idSelektovanihAtributa
        %rez.prediktivniModel      
    function [rez] = uradiFeatureSelectionGenetskimAlgoritmom(trainData, brFoldova, prediktivniModel, klasifikacijaRegresija)
        global featureSelectionGA;
        featureSelectionGA.trainData              = trainData              ;
        featureSelectionGA.brFoldova              = brFoldova              ;
        featureSelectionGA.prediktivniModel       = prediktivniModel       ;
        featureSelectionGA.klasifikacijaRegresija = klasifikacijaRegresija ;
        featureSelectionGA.brPozivanjaFje         = 0;
        
        [brPrimera brAtributa] = size(trainData);     brAtributa = brAtributa - 1;%jer je poslednji OUTCOME!
        gornjaGranica          = ones(1,brAtributa);
        donjaGranica           = zeros(1,brAtributa);
        intCon                 = [1:brAtributa];
        options                = gaoptimset( 'Generations'    , 50,........ br generacija
                                             'PlotFcns'       ,@gaplotbestf,......................... stampaj medju rezultate
                                             'PopulationSize' , 25);.... velicina populacije
                    %                          'PopInitRange'   ,globalSettings.GA.PopInitRange);.... inicijalna populacija?
        [x fval exitflag] = ga(@arsStatistika.uradiFeatureSelectionGenetskimAlgoritmomFitnessFunkcija,........................fja za minimizaciju
                           brAtributa,.....................................br promenljivih za optimizaciju
                           [],[],[],[],....................................
                           donjaGranica, gornjaGranica,....................
                           [],.............................................@nonlcon,... http://www.mathworks.com/help/gads/mixed-integer-optimization.html
                           intCon,.........................................intCon[id promenljivih koje su INT]
                           options);
        rez.idSelektovanihAtributa = x                                  ;
        rez.prediktivniModel       = featureSelectionGA.prediktivniModel;
    end
    
    %ova fja se poziva iz GA
    function rez = uradiFeatureSelectionGenetskimAlgoritmomFitnessFunkcija(idIntKolona)
        idIntKolona = find(idIntKolona==1);
        global featureSelectionGA;
        [rez rezPoKlasama] = arsStatistika.uradiCrossValidacijuPrediktivnogModelaWeka([featureSelectionGA.trainData(:,idIntKolona) featureSelectionGA.trainData(:,end)],...
                                                                                      featureSelectionGA.brFoldova,...
                                                                                      featureSelectionGA.prediktivniModel,...
                                                                                      featureSelectionGA.klasifikacijaRegresija);
        if featureSelectionGA.klasifikacijaRegresija
            rez = 1 - rez.kappa; %fja se minimizjuje a kappa treba da bude sto vece
            featureSelectionGA.brPozivanjaFje = featureSelectionGA.brPozivanjaFje + 1;
        else
            rez = rez.korelacija;
        end
    end
    %%
    %% Funkcija prebacuje matlab matricu u odgovaraju weka data set u zavisnosti od toga da li se radi klasifikacija ili regresije
    %INPUTS
        %matlabDataSet          - matrica[brPricma x brAtribura], poslednji atribut je outcome
        %klasifikacijaRegresija - 1=klasifikacija, 0=regresija
    %OUTPUTS
        %wekaDataSet            - matlabDataSet prebacen u wekaOBJ
    function wekaDataSet = pripremiMatDataSetZaWeku(matlabDataSet,klasifikacijaRegresija)
        featureNames = cell(1,numel(matlabDataSet(1,:))); featureNames(cellfun(@isempty,featureNames)) = {'bla'};
        if klasifikacijaRegresija %outcome treba da bude nominal                
                wekaDataSet        = matlab2weka('arsData',......
                                           featureNames,...
                                           arsStatistika.konvertujKolonuCellUString(num2cell(matlabDataSet),numel(featureNames)),...
                                           numel(featureNames)); %                 
        else                      %outcome treba da bude numerical
                wekaDataSet        = matlab2weka('arsData', featureNames, matlabDataSet, numel(featureNames));
        end
    end
    %% Fja koristi train data da obuci prediktivni model
    %%INPUTS
        %trainData                               - matrica[brPricma x brAtribura], poslednji atribut je outcome
        %prediktivniModel.tipWekaKlasifikatora   - weka klasa za dati klasifier 
        %prediktivniModel.parametriKlasifikatora - string-komanda za dati klasifier
    %OUTPUT
        %prediktivniModel - obuceni Weka model
        %trainData        - wekaObj
    function [prediktivniModel trainData] = obuciWekaModel(trainData, prediktivniModel, klasifikacijaRegresija)
        trainData          = arsStatistika.pripremiMatDataSetZaWeku(trainData,klasifikacijaRegresija);
        prediktivniModel   = trainWekaClassifier(trainData, prediktivniModel.tipWekaKlasifikatora, prediktivniModel.parametriKlasifikatora);
    end
    %%
    %INPUTS
        %prediktivniModel       - prethodno obuceni weka model
        %testData               - matrica[brPricma x brAtribura], poslednji atribut je outcome
        %targetPodaci           - ground truth
        %klasifikacijaRegresija - 1=klasifikacija, 0=regresija
    %OUTPUTS
        %
    function [predictedClass predictedProbability] = testirajWekaModel(prediktivniModel, testData, klasifikacijaRegresija)
        testData                              = arsStatistika.pripremiMatDataSetZaWeku(testData,klasifikacijaRegresija);        
        [predictedClass predictedProbability] = wekaClassify(testData, prediktivniModel); %
    end
    %% Funkcija koristi setA za obuku i nezavisni setB za testiranje
    %INPUTS
        %trainData - set za obuku
        %testData  - set za testiranje
        %prediktivniModel.tipWekaKlasifikatora   - weka klasa za dati klasifier 
        %prediktivniModel.parametriKlasifikatora - string-komanda za dati klasifier
        %klasifikacijaRegresija                  - 1=klasifikacija, 0=regresija
    function [predictedClass predictedProbability prediktivniModel] = obuciWekaModelNaSetAiTestirajNaSetB(trainData, testData, prediktivniModel, klasifikacijaRegresija)
        trainData                             = arsStatistika.izbalansirajKlaseUpotrebomADASYN(trainData)                           ;
        prediktivniModel                      = arsStatistika.obuciWekaModel(trainData, prediktivniModel, klasifikacijaRegresija)  ;
        [predictedClass predictedProbability] = arsStatistika.testirajWekaModel(prediktivniModel, testData, klasifikacijaRegresija);        
    end
    %% 
    function Cell = konvertujKolonuCellUString(Cell, idKolone)
        pom = cell2mat(Cell);
        for i  = 1 : numel(pom(:,1))
            Cell{i,idKolone} = ['Class ' num2str(Cell{i,idKolone})];
        end
    end
    %% Funkcija pravi klase, tako da budu balansirane. Kasnije se one koriste u cross-validaciji
    %%INPUTS
        %inputData - outputi prediktivnih modela
        %brFoldova - koliko foldova treba da se pravi 
        %daLiTrebaBalansirati - obicno, foldovi koji se koriste za train trebaju da budu balansirani dok se foldovi za test ne diraju!
    %%OUTPUTS
        %rezFold{idFolda}.test  - 1, 2... brFoldova
        %rezFold{idFolda}.train - svi osim 1, 2... brFoldova
    function [rezFold] = napraviNFoldZaCrossValidaciju(inputData, brFoldova, daLiTrebaBalansirati)
        %randomizuj data set
        inputData = arsStatistika.randomizujDataSet(inputData, 5);
        if ~exist('daLiTrebaBalansirati')
            daLiTrebaBalansirati = false;
        end
        if numel(inputData(1,:)>1)
            klase = inputData(:,end); % ID klase je zadnja kolona
        else
            klase = inputData(:)    ; % prosledjena je samo 1 kolona
        end        
        klaseTipovi = unique(klase)     ; % vrste klasa, npr {0, 1, 2, 3} 
        brKlasa     = numel(klaseTipovi); % br razliciith klasa u setu
        for idFolda = 1 : brFoldova
            for iKlase = 1 : brKlasa
                %podaci o trenutnoj klasi
                idPrimera       = find(klase==klaseTipovi(iKlase)); 
                brPrimera       = numel(idPrimera)                ;
                %selektuj iz svake klase  (idFolda-1)/brFoldova do (idFolda)/brFoldova procenat elemenata
                idKfoldPrimera  = round((idFolda-1)/brFoldova*brPrimera:(idFolda)/brFoldova*brPrimera); idKfoldPrimera=idKfoldPrimera(2:end);
                idPrimera       = idPrimera(idKfoldPrimera,:)     ;
                if iKlase == 1
                    pomData{idFolda}= inputData(idPrimera,:)                    ;
                else
                    pomData{idFolda}= [pomData{idFolda}; inputData(idPrimera,:)];
                end
            end
        end
        % Napravi k-foldova, svaki ima training i test set (sve je spremno za learning)
        for idFolda = 1 : brFoldova
            rezFold{idFolda}.test  = pomData{idFolda}                          ;  % n-ti fold za test ne diras/nebalansiras
            rezFold{idFolda}.train = arsStatistika.selektujDeloveCella(pomData,[1:idFolda-1,idFolda+1:brFoldova]);
            if daLiTrebaBalansirati                                               % balansiraj n-1 foldova koji sluze za obuku
                rezFold{idFolda}.train = arsStatistika.izbalansirajKlaseUpotrebomADASYN(rezFold{idFolda}.train);
            end
        end
    end
    %%
    function inputDataSet = randomizujDataSet(inputDataSet, brMesanja)
        brPrimera = numel(inputDataSet(:,1));
        for i = 1 : brMesanja
            inputDataSet = inputDataSet(datasample(1:brPrimera,brPrimera,'Replace',false),:);
        end
    end
    %% Ova funkcija selektuje i pakuje niz-id elemenata celija(u kojima se cuvaju matrice)
    function rez = selektujDeloveCella(cell, id)
        for i  =  1:numel(id)
            if i == 1
                rez = cell{id(i)};
            else
                rez = [rez; cell{id(i)}];
            end
        end
    end
    %%
    %% Funkcija balansira podatke upotrebom ADASYN algoritma. 
    % Funkcija automatski nalazi klasu sa max br elemenata, i balansira ostale minority klase u odnosu na nju!
    %INPUTS
        %inputData(:,1:end-1) - atributi
        %inputData(:,    end) - outcome
    %OUTPUTS
        %balansiraniDataSet
    function [balansiraniDataSet] = izbalansirajKlaseUpotrebomADASYN(inputData)
        klaseID      = inputData(:,end)  ; % ID klasa po primerima
        klaseTipovi  = unique(klaseID)   ; % vrste klasa, npr {0, 1, 2, 3} 
        brKlasa      = numel(klaseTipovi); % br razliciith klasa u setu
        for i = 1 : brKlasa
            brElemenataPoKlasama(i) = numel(find(klaseID==klaseTipovi(i))); % zato sto klase ne moraju biti 1 2 3, moze biti 2 4 6 npr
        end
        [brPrimeraMaxKlase klasaSaMaxBrElemenata] = max(brElemenataPoKlasama);
        balansiraniDataSet = inputData(1,:);
        for i  = 1 : brKlasa
            %trenutna klasa
            idPrimeraTrenutneKlase    = find(klaseID==klaseTipovi(i))      ;
            stackTrenutneKlase        = inputData(idPrimeraTrenutneKlase,:); 
            %sve ostale klase
            idPrimeraOstalihKlasa     = find(klaseID~=klaseTipovi(i))      ;
            stackOstalihKlasa         = inputData(idPrimeraOstalihKlasa,:);
            if (i == klasaSaMaxBrElemenata)
                %ne radi se smote                
            else
                %radi se smote za svaku od klasa
                stackTrenutneKlase(:,end)   = 1;
                stackOstalihKlasa (:,end)   = 0;
                stackTrenutneKlase          = [stackTrenutneKlase; stackOstalihKlasa]; 
%               [final_features final_mark] = SMOTE(stackTrenutneKlase(:,1:end-1), stackTrenutneKlase(:,end));
                [final_features final_mark] = ADASYN(stackTrenutneKlase(:,1:end-1), stackTrenutneKlase(:,end), [], [], [], false); %ovaj bolje radi! pogledaj referencu u kodu
                %uzmi samo onoliko koliko treba da bi dostigao brPrimeraMaxKlase
                final_features              = datasample([final_features final_mark],brPrimeraMaxKlase-brElemenataPoKlasama(i));
                stackTrenutneKlase          = [inputData(idPrimeraTrenutneKlase,:); final_features];
                stackTrenutneKlase(:,end)   = klaseTipovi(i);                
            end
            %napakuj na stack
            balansiraniDataSet = [balansiraniDataSet; stackTrenutneKlase];
        end
        balansiraniDataSet = balansiraniDataSet(2:end,:);
    end
    %% Mann-Whitney-Wilcoxon non parametric test for two unpaired groups
    % ref: https://www.mathworks.com/matlabcentral/fileexchange/25830-mwwtest?fbclid=IwAR0OhgNsizLnLheNCN8w6NvBdHVwmJ39nQ1FtCDHOzJulJceVtn196d_q3M
    function STATS=mwwtest(x1,x2)
    % Mann-Whitney-Wilcoxon non parametric test for two unpaired groups.
    % This file execute the non parametric Mann-Whitney-Wilcoxon test to evaluate the
    % difference between unpaired samples. If the number of combinations is less than
    % 20000, the algorithm calculates the exact ranks distribution; else it 
    % uses a normal distribution approximation. The result is not different from
    % RANKSUM MatLab function, but there are more output informations.
    % There is an alternative formulation of this test that yields a statistic
    % commonly denoted by U. Also the U statistic is computed.
    % 
    % Syntax: 	STATS=MWWTEST(X1,X2)
    %      
    %     Inputs:
    %           X1 and X2 - data vectors. 
    %     Outputs:
    %           - T and U values and p-value when exact ranks distribution is used.
    %           - T and U values, mean, standard deviation, Z value, and p-value when
    %           normal distribution is used.
    %        If STATS nargout was specified the results will be stored in the STATS
    %        struct.
    % 
    %      Example: 
    % 
    %         X1=[181 183 170 173 174 179 172 175 178 176 158 179 180 172 177];
    % 
    %         X2=[168 165 163 175 176 166 163 174 175 173 179 180 176 167 176];
    % 
    %           Calling on Matlab the function: mwwtest(X1,X2)
    % 
    %           Answer is:
    % 
    % MANN-WHITNEY-WILCOXON TEST
    %  
    %                        Group_1    Group_2
    %                        _______    _______
    % 
    %     Numerosity          15         15    
    %     Sum_of_Rank_W      270        195    
    %     Mean_Rank           18         13    
    %     Test_variable_U     75        150    
    % 
    % Sample size is large enough to use the normal distribution approximation
    %  
    %     Mean       SD        Z       p_value_one_tail    p_value_two_tails
    %     _____    ______    ______    ________________    _________________
    % 
    %     112.5    24.047    1.5386    0.061947            0.12389      
    % 
    %           Created by Giuseppe Cardillo
    %           giuseppe.cardillo-edta@poste.it
    % 
    % To cite this file, this would be an appropriate format:
    % Cardillo G. (2009). MWWTEST: Mann-Whitney-Wilcoxon non parametric test for two unpaired samples.
    % http://www.mathworks.com/matlabcentral/fileexchange/25830

    %Input Error handling
    p = inputParser;
    addRequired(p,'x1',@(x) validateattributes(x,{'numeric'},{'row','real','finite','nonnan','nonempty'}));
    addRequired(p,'x2',@(x) validateattributes(x,{'numeric'},{'row','real','finite','nonnan','nonempty'}));
    parse(p,x1,x2);

    %set the basic parameter
    n1=length(x1); n2=length(x2); NP=n1*n2; N=n1+n2; N1=N+1; k=min([n1 n2]);

    [A,B]=tiedrank([x1(:); x2(:)]); %compute the ranks and the ties
    R1=A(1:n1); R2=A(n1+1:end); 
    T1=sum(R1); T2=sum(R2);
    U1=NP+(n1*(n1+1))/2-T1; U2=NP-U1;
    disp('MANN-WHITNEY-WILCOXON TEST')
    disp(' ')
    disp(table([n1;T1;T1/n1;U1],[n2;T2;T2/n2;U2],...
        'VariableNames',{'Group_1' 'Group_2'},...
        'RowNames',{'Numerosity' 'Sum_of_Rank_W' 'Mean_Rank' 'Test_variable_U'}))
    if nargout
        STATS.n=[n1 n2];
        STATS.W=[T1 T2];
        STATS.mr=[T1/n1 T2/n2];
        STATS.U=[U1 U2];
    end    
    if round(exp(gammaln(N1)-gammaln(k+1)-gammaln(N1-k))) > 20000
        mU=NP/2;
        if B==0
            sU=realsqrt(NP*N1/12);
        else
            sU=realsqrt((NP/(N^2-N))*((N^3-N-2*B)/12));
        end
        Z1=(abs(U1-mU)-0.5)/sU;
        p=1-normcdf(Z1); %p-value
        disp('Sample size is large enough to use the normal distribution approximation')
        disp(' ')
        disp(table(mU,sU,Z1,p,2*p,'VariableNames',{'Mean' 'SD' 'Z' 'p_value_one_tail' 'p_value_two_tails'}))
        if nargout
            STATS.method='Normal approximation';
            STATS.mU=mU;
            STATS.sU=sU;
            STATS.Z=Z1;
            STATS.p=[p 2*p];
        end
    else
        disp('Sample size is small enough to use the exact Mann-Whitney-Wilcoxon distribution')
        disp(' ')
        if n1<=n2
            w=T1;
        else
            w=T2;
        end
        pdf=sum(nchoosek(A,k),2);
        P = [sum(pdf<=w) sum(pdf>=w)]./length(pdf);
        p = min(P);
        disp(table(w,p,2*p,'VariableNames',{'W' 'p_value_one_tail' 'p_value_two_tails'}))
        if nargout
            STATS.method='Exact distribution';
            STATS.T=w;
            STATS.p=[p 2*p];
        end
    end
    disp(' ')
    end
    %% 
    end%methods   
    
end