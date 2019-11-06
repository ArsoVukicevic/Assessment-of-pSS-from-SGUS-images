classdef arsGraph
    properties(SetAccess = public, GetAccess = public)
        DG;
        dimenzijeSlikeOdKojeJeNapravljenGraf;
    end%properties
    methods(Static=true)
%% Stara verzija koja je radila samo za 2D slike
        function [obj] = napraviGrafOdSlike(obj, inputImg)
            [brRedovaSlike brKolonaSlike] = size(inputImg);
            selektorPiksela1 = [-1, +1, -brRedovaSlike, +brRedovaSlike];   % Pixeli se posmatraju kao img(brPixela)
            brPiskela        = brRedovaSlike * brKolonaSlike           ;   % Ukupan br. pixela
            EdgeList         = [];
            W                = [];
            for iReda = 2 :  brRedovaSlike-1                 
                for iKolone = 2 : brKolonaSlike-1
                    iPiksela         = iReda + brRedovaSlike * (iKolone-1); % id trenutnog piksela (1,2,3.... brReda*brKolone)
                    edges            = iPiksela + selektorPiksela1        ; % edges - okolni pixeli oko trenutnog pixela 
                    pomEdgeList(:,2) = edges(:)                           ; % druga kolona su id okolnih pixela
                    pomEdgeList(:,1) = iPiksela                           ; % prva kolona je trenutni pixel
                    EdgeList         = [EdgeList pomEdgeList']            ; % napakuj u stack
                    W(end+1:end+4)   = inputImg(iPiksela)                 ; % upisi tezine (intenzitet pixela) za kreirane edgeve(ivice)
                end
            end
            
            EdgeList(:,end+1) = [brPiskela brPiskela];
            W(end+1)          = 0                    ; 
            
            obj.DG                                   = sparse(EdgeList(1,:), EdgeList(2,:), W);
            obj.dimenzijeSlikeOdKojeJeNapravljenGraf = [brRedovaSlike brKolonaSlike]          ;
        end
%         %% Funkcija od 2D/3D slike pravi graf --- NIJE ZAVRSENO NE RADI
%         function [obj] = napraviGrafOdSlike(obj, inputData)
%             [brRedova brKolona brSlajseva] = size(inputData);
%             if brSlajseva == 1 % inputData je 2D slika               
%                 selektorPiksela = [-1, +1, -brRedova, +brRedova];   % Pixeli se posmatraju kao img(brPixela). Selektuju se po 2 pixela u svakom pravcu (  gore dole levo desno, ne ide po dijagonali!)
%             else               % inputData je 3D volume
%                 selektorPiksela = [-1, +1, -brRedova, +brRedova, -brRedova*brKolona, +brRedova*brKolona];
%             end
%             %
%             EdgeList         = [];
%             W                = [];
%             for iSlajsa = 1 + (brSlajseva>1) : brSlajseva - (brSlajseva>1)  % + (brSlajseva>1) da bi radilo i za 3D
%                 for iReda = 2 : brRedova-1
%                     for iKolone = 2 : brKolona-1
%                         iPiksela         = iReda + brRedova * (iKolone-1) +...% id trenutnog piksela (1,2,3.... brReda*brKolone*brSlajseva)
%                                                  + brRedova * brKolona * (iSlajsa-1); % za 3D inputData. Ako je inputData 2D ovaj clan je uvek = 0
%                         edges            = iPiksela + selektorPiksela         ; % edges - okolni pixeli oko trenutnog pixela 
%                         pomEdgeList(:,2) = edges(:)                           ; % druga kolona su id okolnih pixela
%                         pomEdgeList(:,1) = iPiksela                           ; % prva kolona je trenutni pixel
%                         EdgeList         = [EdgeList pomEdgeList']            ; % napakuj u stack
%                         W(end+1:end+4)   = inputData(iPiksela)                 ; % upisi tezine (intenzitet pixela) za kreirane edgeve(ivice)
%                     end
%                 end
%             end
%             a = 1;
%         end
        %% Fja za konverziju koordinata slike u ID cvora grafa
        function [iPiksela] =  imgPixelToGraphNodeID(inputImg, pixelKoordinate)      
            pixelKoordinate = round(pixelKoordinate);
            [brRedova brKolona brSlajseva] = size(inputImg);
            if brSlajseva == 1
                pixelKoordinate = pixelKoordinate(:,[1 2]);
            end
            for i=1:numel(pixelKoordinate(:,1))   
                iReda   = pixelKoordinate(i,1);
                iKolone = pixelKoordinate(i,2);
                try 
                    iSlajsa = pixelKoordinate(i,3);
                catch
                    iSlajsa = 1;
                end
                iPiksela(i) = iReda + brRedova * (iKolone-1) +  brRedova * brKolona * (iSlajsa-1);
            end
        end
        %% Fja za konverziju Cvora grafa u koordinate slike/volumea
        function [points2D] = imghNodeIdToPixelCoordinate(inputImg, pathGraphNodeID)  
            [brRedovaSlike brKolonaSlike] = size(inputImg);
            points2D = [];
            for i=1:numel(pathGraphNodeID)   
                iKolone   = mod(pathGraphNodeID(i),brRedovaSlike);
                iReda    =  (pathGraphNodeID(i)-iKolone) / brRedovaSlike + 1;
                points2D(end+1,:) = [ iReda  iKolone];
            end
        end
        %%
        %%
        function [points2D] = imghNodeIdToPixelCoordinate2D3D(inputImg, pathGraphNodeID)  
            [brRedova brKolona brSlajseva] = size(inputImg);
            points2D = [];
            for i=1:numel(pathGraphNodeID)   
                iSlajsa   = mod(pathGraphNodeID(i),brRedova*brKolona);
                iKolone   = mod(pathGraphNodeID(i) - iSlajsa*(brRedova*brKolona), brKolonaSlike);
                iReda     =    (pathGraphNodeID(i) - iSlajsa*(brRedova*brKolona + iKolone)) / brRedova + 1;
                points2D(end+1,:) = [ iReda  iKolone];
            end
        end
        %%
        function [dist,path,pred] = graphshortestpath(obj, startNodeID, endNodeID)
            [dist,path,pred] = graphshortestpath(obj.DG,...
                                     startNodeID,...
                                     endNodeID,...
                                     'Directed', false,....
                                     'Method', 'Dijkstra');
        end
    end%methods
end%bezier class deff