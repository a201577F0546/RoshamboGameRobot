function result=ORG(A)
%max为最大黑白边界数
% % figure
% imshow(A)
%空间转换
result=0;
[r c]=size(A);
if r>800
    A=imresize(A,[300, 300]);%改变图像的大小
end
% figure
% imshow(A)
%空间转换
%使用YCbCr彩色空间（对亮度不敏感）
se=fspecial('average',[3,3]);%创建平滑均值滤波（3X3）
A=imfilter(A,se);%对任意类型数组或多维图像用上面定义的滤波算子进行滤波
imageR=A(:,:,1);
imageG=A(:,:,2);
imageB=A(:,:,3);
imageY=16+0.2568*imageR+0.5041*imageG+0.0979*imageB;
imageCg=128-0.318*imageR+0.4392*imageG-0.1212*imageB;
imageCr=128+0.4392*imageR-0.3677*imageG-0.0714*imageB;


Y=find(imageY<=230&imageY>=35);%根据统计的数据找出处在该范围的像素的下标
Cg=find(imageCg<=128&imageCg>=80);
Cr=find(imageCr<=173&imageCr>=131);
index=intersect(Cg,intersect(Y,Cr));%找出三个平面的肤色坐标交集
BW=im2bw(A);%构造二值图
BW=zeros(size(BW));%全图置为黑色
BW(index)=1;%把肤色区域置为白色
% figure
% imshow(BW)
IM= bwareaopen(BW,round(1/40*numel(BW)));%把包含像素点少的白色区域去除
% figure
% imshow(IM)
se = strel('disk',round(numel(IM)/15000));
IM=imclose(IM,se);%闭操作
% figure
% imshow(IM)
IM= bwareaopen(IM,round(1/10*numel(IM)));%把包含像素点少的白色区域去除
% figure
% imshow(IM)
se=fspecial('average',[5,5]);%平滑滤波
IM=imfilter(IM,se);
%腐蚀得到重心
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
centerx=r(1);%得到重心
centery=c(1);
IM(centerx,centery)=0;
% figure
% imshow(IM)
%求离重心最远的点
[r c]=find(IM==1);
BW = edge(IM,'sobel');%找到边缘
[r c]=find(BW==1);
max=0;
for k=1:numel(r)
    distance=(r(k)-centerx)^2+(c(k)-centery)^2;
    if distance>max
        max=distance;
        maxx=r(k);maxy=c(k);
    end
end
%找同心圆
d=max^(1/2)/10;
deta=d/4;
angle=0:1/180*(2*pi)/30:2*pi;
for k=1:10
    r=k*d;
    x1(k,:)=round(centerx+sin(angle)*r);%得到圆的坐标
    y1(k,:)=round(centery+cos(angle)*r);
end
[r c]=size(IM);
%找黑白色交界的个数
max=0;
fist=0;%拳头检测标志
for k=1:10
    num=length(x1);
    Qj=1;
    Pj=1;
    for kk=1:num
        if x1(k,kk)<=0|| x1(k,kk)>=r||y1(k,kk)<=0||y1(k,kk)>=c||kk+1>num||x1(k,kk+1)<=0|| x1(k,kk+1)>=r||y1(k,kk+1)<=0||y1(k,kk+1)>=c
            continue;
        end
        if IM(x1(k,kk),y1(k,kk))==0&&IM(x1(k,kk+1),y1(k,kk+1))==1%Q点坐标
            if Qj-Pj>=1
                continue;
            end
            Qx(k,Qj)=x1(k,kk);Qy(k,Qj)=y1(k,kk);Qj=Qj+1;
        end
        if IM(x1(k,kk),y1(k,kk))==1&&IM(x1(k,kk+1),y1(k,kk+1))==0%P点坐标
            if Pj-Qj>=0
                continue;
            end
            Px(k,Pj)=x1(k,kk);Py(k,Pj)=y1(k,kk);Pj=Pj+1;
        end
    end
    Pj=Pj-1;
    Qj=Qj-1;%所得个数
    
    if Qj-Pj>0%多了一个孤立点
        Qj=Qj-1;
    end
    if Qj==0
      continue;
    end
    
    %排除非手指区域,把宽度较小的区域排除
    a=(Qx(k,1:Qj)-Px(k,1:Pj)).^2+(Qy(k,1:Qj)-Py(k,1:Pj)).^2;
    index=find(a<(d/1.6)^2);
    Qj=Qj-numel(index);%删除小区域
    index=find(a>6.4*d^2);
    Qj=Qj-numel(index);%删除大区域
    if fist==1&&Qj==0%已经开始检测拳头
       max=0;
       break;
       
    end
    if Qj~=0
        fist=fist+1;
    end
    if Qj>=max
        max=Qj;%最多交界的个数
        maxc=k;%最多交界的那个同心圆
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
