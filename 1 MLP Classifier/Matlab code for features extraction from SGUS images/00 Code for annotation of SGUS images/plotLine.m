%crta duz Po P1
function []= plotLine(Po, P1 , debljinaLinije)
hold on;
if ~exist('debljinaLinije')
    debljinaLinije = 1; 
end
if  nargin >1  && numel(P1) ==1 
    debljinaLinije = P1;
end
if nargin == 1 || numel(P1) ==1
    if numel(Po(1,:))>2%3D
         x=Po(:,1,:);
         y=Po(:,2,:);
         z=Po(:,3,:);
         line(x,y,z, 'LineWidth',debljinaLinije);
    else%2D
         x=Po(:,1);
         y=Po(:,2);
         line(x,y, 'LineWidth',debljinaLinije);
    end
         return;
end
if ~isstr(Po) 
    if nargin ==2%prosledjene su dve tacke
      if numel(Po)==2%2D
          x = [Po(1), P1(1)];
          y = [Po(2), P1(2)];
          line(x,y, 'LineWidth',debljinaLinije);
      else%3D
          x = [Po(1), P1(1)];
          y = [Po(2), P1(2)];
          z = [Po(3), P1(3)];
          line(x,y,z, 'LineWidth',debljinaLinije);
      end
    elseif nargin==1%matrica tacaka(niz tacaka)
     dim = size(Po);
     %napravi da budu vertikalno poredjane 
     if dim(2)==3 %3D, poredjane su vertikalno
         x=Po(:,1,:);
         y=Po(:,2,:);
         z=Po(:,3,:);
         line(x,y,z, 'LineWidth',debljinaLinije);
     elseif dim(2)==2
         x=Po(:,1);
         y=Po(:,2);
         line(x,y, 'LineWidth',debljinaLinije);     
     end
    end
end
