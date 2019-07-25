%% << Sta skripta radi >>
% Podaci se nalaze u foldere, hronoloski je prikazano kako su podaci dostavljani.
% Pojedine grupe poadataka nisu upotreblijve.
% Svaka od upotrebljivih grupa podataka je procesirana (Feature extraction)
% i ti podaci u u mat fajlovima po folderima ('bazaPacijenata.mat').
% Ova skripta kupi te fajlove i spaja ih u jedinstveni fajl, za dalju obradu-machine learning.
function Skripta01_napraviJedinstvenuBazuPacijenata()
listaFoldera = {
                'Centre1',...
                'Centre2'};
            
odsecanjeSlikePoBazi = {};            

for i = 1 : numel(listaFoldera)
    pom = load([listaFoldera{i}  '/bazaPacijenata.mat']);
    pom = pom.rez;
    for j = 1 : numel(pom)
        pom(j).DataSetName = [listaFoldera{i}  '/bazaPacijenata.mat'];
        pom(j).DataSetID   = i                                       ;
    end
    if i == 1
        rez = pom; 
    else        
        for j = 1:numel(pom)
            rez(end+1) = pom(j);
        end
    end
end
save('HarmonicSS_bazaPacijenata.mat','rez');      

%% Sacuvaj za svaki gradeID posebno
% db = rez;
% for grade = 0 : 3
% 	rez = selektujGradeIzBaze(db, grade);
%     save(['HarmonicSS_bazaPacijenata' num2str(grade) '.mat'], 'rez');
%     disp(['grade' num2str(grade) ' = ' num2str(numel(rez))]); 
%     %Cuvanje slika po fajlovima
%     for i = 1 : numel(rez)
%         fname = ['Grade' num2str(grade) '/' rez(i).FullDicomPath(5:end) '.jpg'];
%         fname = replace(fname,'\','_');
%         imwrite(rez(i).img, fname);
%     end
% end
end

function rez = selektujGradeIzBaze(baza, grade)
    grade0count = 0;
    for i=1:numel(baza)
        if baza(i).grade == grade
            grade0count      = grade0count + 1;
            rez(grade0count) = baza(i);
        end
    end
    if ~exist('rez')
        rez = 0;
    end
end