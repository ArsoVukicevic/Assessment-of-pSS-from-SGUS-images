function varargout = DicomViewerUSound(varargin)
% DICOMVIEWERUSOUND MATLAB code for DicomViewerUSound.fig
%      DICOMVIEWERUSOUND, by itself, creates a new DICOMVIEWERUSOUND or raises the existing
%      singleton*.
%
%      H = DICOMVIEWERUSOUND returns the handle to a new DICOMVIEWERUSOUND or the handle to
%      the existing singleton*.
%
%      DICOMVIEWERUSOUND('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DICOMVIEWERUSOUND.M with the given input arguments.
%
%      DICOMVIEWERUSOUND('Property','Value',...) creates a new DICOMVIEWERUSOUND or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DicomViewerUSound_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DicomViewerUSound_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DicomViewerUSound

% Last Modified by GUIDE v2.5 27-Sep-2017 10:19:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DicomViewerUSound_OpeningFcn, ...
                   'gui_OutputFcn',  @DicomViewerUSound_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before DicomViewerUSound is made visible.
function DicomViewerUSound_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DicomViewerUSound (see VARARGIN)

% Choose default command line output for DicomViewerUSound
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DicomViewerUSound wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = DicomViewerUSound_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in btnOpenDICOM.
function btnOpenDICOM_Callback(hObject, eventdata, handles)
% hObject    handle to btnOpenDICOM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[FileName,PathName,FilterIndex] = uigetfile('*.*','Selektuj DICOM');
handles.txtOpenDicomPath.String = [PathName FileName];
global arsUSdata;
arsUSdata.dcmPath = [PathName FileName];
try % UCITAJ SLIKU
    arsUSdata.dcmImg  = imread(arsUSdata.dcmPath);
    % Cuvam sva tri da bi posle lakse detektovao ivicus
    arsUSdata.dcmImg  = arsUSdata.dcmImg;
    axes(handles.axesVelikaSlika); cla; imshow(arsUSdata.dcmImg);
    
catch % UCITAJ DICOM 
    arsUSdata.dcm     = dicomread(arsUSdata.dcmPath);
    arsUSdata.dcmImg  = arsUSdata.dcm               ;
    axes(handles.axesVelikaSlika); imshow(arsUSdata.dcmImg);
end
    %%---------------
    % UCITAVANJE LINIJE
    try
        arsUSdata.path2D = load([arsUSdata.dcmPath '_path2D.mat']);
        arsUSdata.path2D = arsUSdata.path2D.path2D;
        path2D           = arsUSdata.path2D;
        axes(handles.axesVelikaSlika); cla; imshow(arsUSdata.dcmImg); hold on; plotLine([path2D; path2D(1:2,:)],3);
    catch
        arsUSdata.path2D = [0 0 0; 1 1 1];
    end
    % UCITAVANJE GRADEa
    try
        arsUSdata.grade = load([arsUSdata.dcmPath '_grade.mat']);
        arsUSdata.grade = arsUSdata.grade.grade;
        set(handles.popupGrade, 'Value', arsUSdata.grade+1);
    %     handles.popupGrade.
    end   
%OSVEZI GUI
set(handles.txtGrade0Score, 'String',  ['']);
set(handles.txtGrade1Score, 'String',  ['']);
set(handles.txtGrade2Score, 'String',  ['']);
set(handles.txtGrade3Score, 'String',  ['']);

%%---------------
% Update handles structure
guidata(hObject, handles);

function txtOpenDicomPath_Callback(hObject, eventdata, handles)
% hObject    handle to txtOpenDicomPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtOpenDicomPath as text
%        str2double(get(hObject,'String')) returns contents of txtOpenDicomPath as a double


% --- Executes during object creation, after setting all properties.
function txtOpenDicomPath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtOpenDicomPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnNacrtajLiniju.
function btnNacrtajLiniju_Callback(hObject, eventdata, handles)
% hObject    handle to btnNacrtajLiniju (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global arsUSdata;
path2D           = arsAngioSegmentacija.rucnoNaznaciNTacki(arsUSdata.dcmImg);
axes(handles.axesVelikaSlika); imshow(arsUSdata.dcmImg); hold on; plotLine([path2D; path2D(1:2,:)],3);
arsUSdata.path2D = path2D; 
% Update handles structure
guidata(hObject, handles);




% --- Executes on button press in btnSacuvaj.
function btnSacuvaj_Callback(hObject, eventdata, handles)
% hObject    handle to btnSacuvaj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global arsUSdata;
path2D = arsUSdata.path2D; 
img    = arsUSdata.dcmImg; 
save([arsUSdata.dcmPath '_path2D.mat'], 'path2D');
imwrite(img, [arsUSdata.dcmPath '_img.jpg']);
grade = get(handles.popupGrade,'Value') - 1; 
save([arsUSdata.dcmPath '_grade.mat'], 'grade');
% Update handles structure
guidata(hObject, handles);


% --- Executes on selection change in popupGrade.
function popupGrade_Callback(hObject, eventdata, handles)
% hObject    handle to popupGrade (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupGrade contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupGrade


% --- Executes during object creation, after setting all properties.
function popupGrade_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupGrade (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnGradeAutomatic.
function btnGradeAutomatic_Callback(hObject, eventdata, handles)
% hObject    handle to btnGradeAutomatic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% Automatska klasifikacija
global arsUSdata;

% input data
baza.img    = arsUSdata.dcmImg;
baza.path2D = arsUSdata.path2D;
baza.grade  = -1;
annInputs   = Skripta_1_napraviMatricuOdBaze(baza);
idSelektovanihFeatura = [1,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,38,40,44,46,48,52,54,56,60,62,64,86,88,92,96,112,120,128,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,276,277,278,279];
annInputs   =  annInputs(idSelektovanihFeatura);
%% ucitaj ann
net = load('ann_NET.mat');
net = net.net;
outputs = net(annInputs(1:end-1)');
%OSVEZI GUI
set(handles.txtGrade0Score, 'String',  num2str( outputs(1)));
set(handles.txtGrade1Score, 'String',  num2str( outputs(2)));
set(handles.txtGrade2Score, 'String',  num2str( outputs(3)));
set(handles.txtGrade3Score, 'String',  num2str( outputs(4)));



function txtGrade0Score_Callback(hObject, eventdata, handles)
% hObject    handle to txtGrade0Score (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtGrade0Score as text
%        str2double(get(hObject,'String')) returns contents of txtGrade0Score as a double


% --- Executes during object creation, after setting all properties.
function txtGrade0Score_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtGrade0Score (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtGrade1Score_Callback(hObject, eventdata, handles)
% hObject    handle to txtGrade1Score (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtGrade1Score as text
%        str2double(get(hObject,'String')) returns contents of txtGrade1Score as a double


% --- Executes during object creation, after setting all properties.
function txtGrade1Score_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtGrade1Score (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtGrade2Score_Callback(hObject, eventdata, handles)
% hObject    handle to txtGrade2Score (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtGrade2Score as text
%        str2double(get(hObject,'String')) returns contents of txtGrade2Score as a double


% --- Executes during object creation, after setting all properties.
function txtGrade2Score_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtGrade2Score (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtGrade3Score_Callback(hObject, eventdata, handles)
% hObject    handle to txtGrade3Score (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtGrade3Score as text
%        str2double(get(hObject,'String')) returns contents of txtGrade3Score as a double


% --- Executes during object creation, after setting all properties.
function txtGrade3Score_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtGrade3Score (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnNacrtajLinijuSnake.
function btnNacrtajLinijuSnake_Callback(hObject, eventdata, handles)
% hObject    handle to btnNacrtajLinijuSnake (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global arsUSdata;
% path2D  = arsAngioSegmentacija.rucnoNaznaciNTacki(arsUSdata.dcmImg);
% axes(handles.axesVelikaSlika); imshow(arsUSdata.dcmImg); hold on; plotLine([path2D; path2D(1:2,:)],3);
axes(handles.axesVelikaSlika); imshow(arsUSdata.dcmImg);
% figure; imshow(arsUSdata.dcmImg(:,:,1));
% figure; imshow(arsUSdata.dcmImg(:,:,2));
% figure; imshow(arsUSdata.dcmImg(:,:,3));
%---
R = arsUSdata.dcmImg(:,:,1);
G = arsUSdata.dcmImg(:,:,2); % if error ocurs there you are not using DICOM 
B = arsUSdata.dcmImg(:,:,3); 
IMG = abs(G - R) + abs(G - B) + abs(B - R);
IMG = mat2gray(IMG);
IMG = IMG / max(IMG(:)); %figure; imshow(IMG);
IMG = abs(1-IMG);
% se = strel('ball',5,5);
% IMG = imerode(IMG,se);
% IMG = abs(IMG);
%% GRAF
graf    = arsGraph                          ;
graf    = graf.napraviGrafOdSlike(graf, IMG);
path2D  = arsAngioSegmentacija.rucnoNaznaciNTacki(arsUSdata.dcmImg);
path2D  = path2D(:,[2 1]);
path2D  = [path2D; path2D(1,:)];
rezPath = [0 0];
for i = 1:numel(path2D(:,1))-1             
    startNodeID      = arsGraph.imgPixelToGraphNodeID(IMG, path2D(i  ,:))         ;
    endNodeID        = arsGraph.imgPixelToGraphNodeID(IMG, path2D(i+1,:))         ;
	%
	[dist,path,pred] = graf.graphshortestpath(graf, startNodeID, endNodeID)    ;
	%
	rezPath          = [rezPath; graf.imghNodeIdToPixelCoordinate(IMG, path)];    
end
path2D      = rezPath(2:end,:);
path2D(:,3) = 0;
arsUSdata.path2D = path2D;
%% SNAKE 
% % IMG(end-1:end+11,end-1:end+11)=1;
% % snake = arsClosedSnake;
% % snake = snake.setSettingsDefault(snake);
% % snake = snake.setImg(snake, IMG);
% % path2D  = arsAngioSegmentacija.rucnoNaznaciNTacki(arsUSdata.dcmImg);
% % snake = snake.setContourPoints(snake, path2D);
% % % snake = snake.setContourPoints(snake);
% % snake = snake.snakeIterate(snake);
% % snake(:,3) = 0;
% % arsUSdata.path2D = snake; 
path2D = arsUSdata.path2D;
axes(handles.axesVelikaSlika); imshow(arsUSdata.dcmImg); hold on; plotLine(path2D,3);
% Update handles structure
guidata(hObject, handles);
