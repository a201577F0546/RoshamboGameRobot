function result=ORG(A)
%maxΪ���ڰױ߽���
% % figure
% imshow(A)
%�ռ�ת��
result=0;
[r c]=size(A);
if r>800
    A=imresize(A,[300, 300]);%�ı�ͼ��Ĵ�С
end
% figure
% imshow(A)
%�ռ�ת��
%ʹ��YCbCr��ɫ�ռ䣨�����Ȳ����У�
se=fspecial('average',[3,3]);%����ƽ����ֵ�˲���3X3��
A=imfilter(A,se);%����������������άͼ�������涨����˲����ӽ����˲�
imageR=A(:,:,1);
imageG=A(:,:,2);
imageB=A(:,:,3);
imageY=16+0.2568*imageR+0.5041*imageG+0.0979*imageB;
imageCg=128-0.318*imageR+0.4392*imageG-0.1212*imageB;
imageCr=128+0.4392*imageR-0.3677*imageG-0.0714*imageB;


Y=find(imageY<=230&imageY>=35);%����ͳ�Ƶ������ҳ����ڸ÷�Χ�����ص��±�
Cg=find(imageCg<=128&imageCg>=80);
Cr=find(imageCr<=173&imageCr>=131);
index=intersect(Cg,intersect(Y,Cr));%�ҳ�����ƽ��ķ�ɫ���꽻��
BW=im2bw(A);%�����ֵͼ
BW=zeros(size(BW));%ȫͼ��Ϊ��ɫ
BW(index)=1;%�ѷ�ɫ������Ϊ��ɫ
% figure
% imshow(BW)
IM= bwareaopen(BW,round(1/40*numel(BW)));%�Ѱ������ص��ٵİ�ɫ����ȥ��
% figure
% imshow(IM)
se = strel('disk',round(numel(IM)/15000));
IM=imclose(IM,se);%�ղ���
% figure
% imshow(IM)
IM= bwareaopen(IM,round(1/10*numel(IM)));%�Ѱ������ص��ٵİ�ɫ����ȥ��
% figure
% imshow(IM)
se=fspecial('average',[5,5]);%ƽ���˲�
IM=imfilter(IM,se);
%��ʴ�õ�����
se = strel('disk',3);
% figure;
% imshow(IM);
IM1=imerode(IM,se);
[r c]=find(IM1==1);
while numel(r)>=500
    IM1=imerode(IM1,se);
    [r c]=find(IM1==1);
end
% figure
% imshow(IM1)
centerx=r(1);%�õ�����
centery=c(1);
IM(centerx,centery)=0;
% figure
% imshow(IM)
%����������Զ�ĵ�
[r c]=find(IM==1);
BW = edge(IM,'sobel');%�ҵ���Ե
[r c]=find(BW==1);
max=0;
for k=1:numel(r)
    distance=(r(k)-centerx)^2+(c(k)-centery)^2;
    if distance>max
        max=distance;
        maxx=r(k);maxy=c(k);
    end
end
%��ͬ��Բ
d=max^(1/2)/10;
deta=d/4;
angle=0:1/180*(2*pi)/30:2*pi;
for k=1:10
    r=k*d;
    x1(k,:)=round(centerx+sin(angle)*r);%�õ�Բ������
    y1(k,:)=round(centery+cos(angle)*r);
end
[r c]=size(IM);
%�Һڰ�ɫ����ĸ���
max=0;
fist=0;%ȭͷ����־
for k=1:10
    num=length(x1);
    Qj=1;
    Pj=1;
    for kk=1:num
        if x1(k,kk)<=0|| x1(k,kk)>=r||y1(k,kk)<=0||y1(k,kk)>=c||kk+1>num||x1(k,kk+1)<=0|| x1(k,kk+1)>=r||y1(k,kk+1)<=0||y1(k,kk+1)>=c
            continue;
        end
        if IM(x1(k,kk),y1(k,kk))==0&&IM(x1(k,kk+1),y1(k,kk+1))==1%Q������
            if Qj-Pj>=1
                continue;
            end
            Qx(k,Qj)=x1(k,kk);Qy(k,Qj)=y1(k,kk);Qj=Qj+1;
        end
        if IM(x1(k,kk),y1(k,kk))==1&&IM(x1(k,kk+1),y1(k,kk+1))==0%P������
            if Pj-Qj>=0
                continue;
            end
            Px(k,Pj)=x1(k,kk);Py(k,Pj)=y1(k,kk);Pj=Pj+1;
        end
    end
    Pj=Pj-1;
    Qj=Qj-1;%���ø���
    
    if Qj-Pj>0%����һ��������
        Qj=Qj-1;
    end
    if Qj==0
      continue;
    end
    
    %�ų�����ָ����,�ѿ�Ƚ�С�������ų�
    a=(Qx(k,1:Qj)-Px(k,1:Pj)).^2+(Qy(k,1:Qj)-Py(k,1:Pj)).^2;
    index=find(a<(d/1.6)^2);
    Qj=Qj-numel(index);%ɾ��С����
    index=find(a>6.4*d^2);
    Qj=Qj-numel(index);%ɾ��������
    if fist==1&&Qj==0%�Ѿ���ʼ���ȭͷ
       max=0;
       break;
       
    end
    if Qj~=0
        fist=fist+1;
    end
    if Qj>=max
        max=Qj;%��ཻ��ĸ���
        maxc=k;%��ཻ����Ǹ�ͬ��Բ
    end
    
end

 if max>3
     result=3;
 end
 if max<=1
     result=2;
 end
 if max>1&&max<=3
     result=1;
 end
end
