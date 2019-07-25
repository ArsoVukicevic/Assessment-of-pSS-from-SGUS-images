function skripta_showDicom()
% dcmName = 'dicom1.dcm'
% 
% dcm     = dicomread(dcmName);
% img     = dcm(:,:,:);
% imshow(img);
% end


files = dir();
aviobj = VideoWriter('a.avi'); %creating a movie object
aviobj.FrameRate = 1;
open(aviobj);
for i=1:numel(files) %number of images to be read
    if numel(files(i).name) > 6  
        try
            a = dicomread(files(i).name); 
            for j = 1:numel(a(1,1,:))
                a = a(:,:,j);
                a = imresize(a, [ 800, 800 ]);
    %             figure; imshow(a);
                f.cdata = cat(3, a,a,a);%convert the images into unit8 type
                f.colormap = [];
                writeVideo(aviobj,f);%add the frames to the avi object created previously
                fprintf('adding frame = %i\n', i);
            end
        catch
        end
    end
end
disp('Closing movie file...')
close(aviobj);
disp('Playing movie file...')
implay('a.avi');