classdef arsAngioSegmentacija
    properties(SetAccess = public, GetAccess = public)
    end%properties 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Static=true)
    %% Rucno nacrtaj centralne linije
    %INPUTS 
        %dicomPath - putanja ka jpg frejmu koji se segmentise
     function rucnoNaznaciCentralneLinijeAngio(dicomPath, brCentralnihLinija, konektivnostCentralnihLinija, path2D)
        img = imread([dicomPath '.jpg']);
        if modRada==1%crtanje centralnih linija
            for i = 1:brCentralnihLinija    
                i  %id centrale linije
                h = figure  ;
                hold on     ;
                x = 0       ;
                while(numel(x)<2)
                 imshow(img);
                 if exist('path2D')
                     if iscell(path2D)
                         for i=1:numel(path2D)
                             plotLine(path2D{i});
                         end
                     else
                         plotLine(path2D);
                     end
                 end
                 hold     on;          
                 axis    off;
                 text(16,36,'Left click to get points, right click to get end point','FontSize',[12],'Color', 'r');
                 [region x y]       = roipoly ;      
                 close(h);
                 centralneLinije{i}      = [x(:) y(:) y(:)]             ;
                 centralneLinije{i}(:,3) = 0                            ;
                 centralneLinije{i}      = centralneLinije{i}(1:end-1,:);
                end%while
            end
            save(['centralneLinije_' dicomPath '.mat'],'centralneLinije');
%             return;
        end
        %prikaz segmentacije
        imshow(img); hold on; 
        for i = 1:numel(centralneLinije)
            plotLine(centralneLinije{i});
        %     centralneLinije{i} = centralneLinije{i}(1:end-1,:);
        end
        if exist(konektivnostCentralnihLinija)
        % pokupi bifurkacije sa centralnih linija
%             konektivnostCentralnihLinija = [1 2 3; 3 4 5; 5 6 7; 7 8 9];
            for i =1:numel(konektivnostCentralnihLinija(:,1))
                bifurkacije(i,:)=(centralneLinije{konektivnostCentralnihLinija(i,1)}(end,:)+...
                                  centralneLinije{konektivnostCentralnihLinija(i,2)}(1,:)+...
                                  centralneLinije{konektivnostCentralnihLinija(i,3)}(1,:))/3;
            end
            plotLine(bifurkacije);
            save(['bifurkacije_' dicomPath '.mat'],'bifurkacije');
        end
     end%rucnoNaznaciCentralneLinijeAngio
     %%
     function rucnoNaznaciBifurkacijeAngio(dicomPath, brBifurkacija)
        img = imread([dicomPath '.jpg']);
        for i = 1:brBifurkacija    
        	i  %id centrale linije
        	h = figure  ;
        	hold on     ;
        	x = 0       ;
       	    while(numel(x)<2)
             imshow(img);
             hold     on;          
             axis    off;
             text(16,36,'Left click to get points, right click to get end point','FontSize',[12],'Color', 'r');
             [region x y]     = roipoly ;      
             close(h);
             pom              = [x(:) y(:) y(:)];
             pom(:,3)         = 0               ;
             bifurkacije(i,:) = pom(1:end-1,:)  ;
           end%while
        end
        save(['bifurkacije_' dicomPath '.mat'],'bifurkacije');
        %prikaz segmentacije
        imshow(img); hold on; 
        plotLine(bifurkacije);
     end%rucnoNaznaciCentralneLinijeAngio
     %% 
     function rucnoNaznaciBorderLinije(dicomPath,brCentralnihLinija, paht2D)
%         dicomPath = '7'; 
%         brCentralnihLinija=19;
        img = load(['proj' dicomPath '.mat']);
        img = img.projCoroMatLab             ; img=img/max(max(img)); %Serkan
        %ucitaj centralne linije
        centralneLinije = load(['centralneLinije_' dicomPath '.mat']);
        centralneLinije = centralneLinije.centralneLinije            ;
        for iCentralneLinije=1:brCentralnihLinija
            iCentralneLinije
            for i = 1:2    
                i
                %%
                h = figure  ;
                hold on     ;
                x = 0       ;
                while(numel(x)<2)
                 imshow(img);
                 %iscrtaj centralne linije
        %          for j = 1:numel(centralneLinije)
                    plotLine(centralneLinije{iCentralneLinije});
        %          end
                 hold     on;          
                 axis    off;
                 text(16,36,'Left click to get points, right click to get end point','FontSize',[12],'Color', 'r');
                 [region x y] = roipoly ;      
                 close(h);
                 borderLinije{iCentralneLinije}{i}      = [x(1:end-1) y(1:end-1) y(1:end-1)];
                 borderLinije{iCentralneLinije}{i}(:,3) = 0;
                end%while
            end
        end
        save(['borderLinije_' dicomPath '.mat'],'borderLinije');
        %prikaz segmentacije
        imshow(img);
        borderLinije     = load(['borderLinije_' dicomPath '.mat']);
        borderLinije     = borderLinije.borderLinije;
        imshow(img); hold on; 
        for i = 1:numel(borderLinije)
            plotLine(centralneLinije{iCentralneLinije});
            for j=1:2
                plotLine(borderLinije{i}{j});
            %     centralneLinije{i} = centralneLinije{i}(1:end-1,:);
                borderLinije{i}{j} = [borderLinije{i}{j}(:,[1 2]) zeros(numel(borderLinije{i}{j}(:,1)),1)];
            end
        end
     end
     %% pomocna funkcija
     %INPUTS
        %img     - slika za iscrtavanje
        %brTacki - koliko tacki treba da se iscrta
        %h       - handles figure gde se iscrtava
        %path2D  - tacke-linije koje treba da budu iscrtane tokom segmentacije
     %OUTPOTS
        %rez     - tacke
     function [rez] = rucnoNaznaciNTacki(img, brTacki, h, path2D)
             if ~exist('h')
             	h = figure  ;
                ugasiFigure = 1;
             else
                 axes(h)  ;
             end
                hold on     ;
                x = 0       ;
                imshow(mat2gray(img));
                 if exist('path2D')
                     if iscell(path2D) && ~isempty(path2D)
                         for i=1:numel(path2D)
                             plotLine(path2D{i});
                         end
                     elseif ~isempty(path2D)
                         plotLine(path2D);
                     end
                 end
                 
                 hold     on;          
                 axis    off;
                 text(16,36,'Left click to get points, right click to get end point','FontSize',[12],'Color', 'r');
                 [region x y] = roipoly ;
                 x = x(1:end-1); y = y(1:end-1);
                 if exist('ugasiFigure')
                    close(h);
                 end
                 if exist('brTacki') && brTacki>0
                    rez      = [x(1:brTacki) y(1:brTacki) y(1:brTacki)];
                 else
                    rez      = [x            y	          y           ]; 
                 end
                 rez(:,3) = 0;
%                 end%while            
     end
    end
end