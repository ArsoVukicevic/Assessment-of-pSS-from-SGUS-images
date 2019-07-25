% %% trenutno stanje baze
% grade0 = 18
% grade1 = 9
% grade2 = 56
% grade3 = 20
% grade4 = 1
% grade5 = 1
function napraviBazu()
    listaFoldera = dir;
    iSample = 0;
    odsecanje = [170, 10, 0; 566 866 0];
    for iFoldera = 1:numel(listaFoldera)
        if  listaFoldera(iFoldera).isdir &&  numel(listaFoldera(iFoldera).name)>5 
            iFolderPath  = listaFoldera(iFoldera).name;
%             listaFoldera(iFoldera).name
            iFolderPath
            iFolderListaDicomFajlova = listaFajlovaUFolderu(iFolderPath, '.jpg'); %u ovoj bazi slike se cuvja kao JPG, po potrebi zameniti u DCM!!
            for iDicoma = 1: numel(iFolderListaDicomFajlova) % :2: ako je jpg, jer dva puta pise JPG!!!
                try
                iSample      = iSample + 1;
                pom          = iFolderListaDicomFajlova(iDicoma);
                %
                pom          = pokupiPodatkeZaJedanDICOM(pom,iFolderPath, 0); % 0=JPG, 1=DCM
                pom.odsecanje=odsecanje;
                rez(iSample) = pom;
                catch
                    iSample  = iSample - 1;
                end
                
            end
        end
    end
    save('bazaPacijenata.mat', 'rez');
    db = rez;
    for grade = 0 : 5
        rez = selektujGradeIzBaze(db, grade);
        save(['bazaPacijenataGrade' num2str(grade) '.mat'], 'rez');
        disp(['grade' num2str(grade) ' = ' num2str(numel(rez))]); 
    end
end
%%
function rez = listaFajlovaUFolderu(folder, tipFajla)
    listaFajlova= dir(folder);    
    brFajlova   = 0;
    if exist('tipFajla')
        for i  =  1: numel(listaFajlova)
            if  numel(listaFajlova(i).name)>3 && strcmp( listaFajlova(i).name(end-3:end), tipFajla)
                brFajlova = brFajlova+1;
                rez(brFajlova) =  listaFajlova(i);
            end
        end
    end
end
%%
function rez = pokupiPodatkeZaJedanDICOM(pom,iFolderPath, DICOMorJPG)
    % dicom
	rez.dicomName     = pom.name                             ;
	rez.dicomath      = [iFolderPath '\' pom.name]           ;
	rez.FullDicomPath = [pwd '\' iFolderPath '\' pom.name]   ;
    if DICOMorJPG
        rez.img       = dicomread(rez.FullDicomPath)         ;
    else
        rez.img       = imread(rez.FullDicomPath)            ;
    end
    % kontura
    rez.path2D        = load([rez.FullDicomPath '_path2D.mat']); 
    rez.path2D        = rez.path2D.path2D;
    % grade 
    rez.grade         = load([rez.FullDicomPath '_grade.mat']);   
    rez.grade         = rez.grade.grade;
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
