%% Read Video & Setup Environment
clear
clc
close all hidden
[FileName,PathName] = uigetfile({'*.avi'; '*.mp4'},'Select shaky video file');

cd mmread
vid=mmread(strcat(PathName,FileName));
cd ..
s=vid.frames;

%% Your code here
%display(s);
%displayvideo(s,0.01);

T = size(s,2);
vector_of_transforms=[];
vector_of_transforms_x=[];

vector_of_transforms_y=[];
vector_of_transforms_theta=[];

vector_of_transforms_scale=[];

for i=1:T-1
  prev_frame=rgb2gray(s(i).cdata);
  curr_frame=rgb2gray(s(i+1).cdata);
  prev_frame_points=detectSURFFeatures(prev_frame);
  curr_frame_points=detectSURFFeatures(curr_frame);
%   figure; imshowpair(prev_frame,curr_frame,'ColorChannels','red-cyan');
  [f1,vpts1] = extractFeatures(prev_frame,prev_frame_points);
  [f2,vpts2] = extractFeatures(curr_frame,curr_frame_points);
  indexPairs = matchFeatures(f1,f2) ;
  
  matchedPoints1 = vpts1(indexPairs(:,1));
  matchedPoints2 = vpts2(indexPairs(:,2));
  
  
  
%   figure; showMatchedFeatures(prev_frame, curr_frame, matchedPoints1, matchedPoints2);
%   legend('A', 'B');
%     transformType='similarity';
    
    transformType='affine';
%     transformType='projective';
    [tform,inlier2,inlier1] = estimateGeometricTransform(matchedPoints2,matchedPoints1,transformType);
    matchedPoints1x = matchedPoints1.Location(:,1);
    matchedPoints1y = matchedPoints1.Location(:,2);
    
%     H = cvexEstStabilizationTform(prev_frame,curr_frame);
%     HsRt = cvexTformToSRT(H);
%     mp1 = [matchedPoints1y matchedPoints1x];
%     matchedPoints2x = matchedPoints2.Location(:,1);
%     matchedPoints2y = matchedPoints2.Location(:,2);
%     mp2 = [matchedPoints2y matchedPoints2x];
%     H=ransacHomography(mp1,mp2,5);  
%   
%   H=ransacHomography(matchedPoints1,matchedPoints2,5);
    %   display(tform);
%         vector_of_transforms=[vector_of_transforms tform];

    H = tform.T;
    R = H(1:2,1:2);
    % Compute theta from mean of two possible arctangents
    theta = mean([atan2(R(2),R(1)) atan2(-R(3),R(4))]);
    % Compute scale from mean of two stable mean calculations
    scale = mean(R([1 4])/cos(theta));
    % Translation remains the same:
    translation = H(3, 1:2);
    % Reconstitute new s-R-t transform:
    HsRt = [[scale*[cos(theta) -sin(theta); sin(theta) cos(theta)]; ...
      translation], [0 0 1]'];
    tformsRT = affine2d(HsRt);
    
   vector_of_transforms=[vector_of_transforms tformsRT];

  vector_of_transforms_x=[vector_of_transforms_x H(3,1)];
  
  vector_of_transforms_y=[vector_of_transforms_y H(3,2)];
  
  vector_of_transforms_theta=[vector_of_transforms_theta theta];

  vector_of_transforms_scale=[vector_of_transforms_scale scale];
end
% display(vector_of_transforms);

halfwindow=15;


noisy_sequence_x=vector_of_transforms_x;

noisy_sequence_scale=vector_of_transforms_scale;

noisy_sequence_y=vector_of_transforms_y;

noisy_sequence_theta=vector_of_transforms_theta;

vector_of_transforms_avg = zeros(T-1,3,3);
for i=1:T-1
       lower=max(1,i-halfwindow);
       upper=min(T-1,i+halfwindow);
       x=0;
       y=0;
       theta=0;
       scale=0;
       for j=lower:upper
           x=x+vector_of_transforms_x(j);
           
           y=y+vector_of_transforms_y(j);
           
           theta=theta+vector_of_transforms_theta(j);
           
          scale=scale+vector_of_transforms_scale(j);
       end
       x=x/(upper-lower+1);
       y=y/(upper-lower+1);
%        x=0;
%        y=0;
       scale=scale/(upper-lower+1);
       theta=theta/(upper-lower+1);
%        display (theta);
%        theta=(vector_of_transforms_theta(i));
%        scale=1;
%        matrix = [[scale*[cos(theta) -sin(theta); sin(theta) cos(theta)]; x y], [0 0 1]'];
%        vector_of_transforms=[vector_of_transforms affine2d(matrix)];
%        
       vector_of_transforms_x(i)=x;
       
       vector_of_transforms_y(i)=y;
       
       vector_of_transforms_theta(i)=theta;
       
       
       vector_of_transforms_scale(i)=scale;
       vector_of_transforms_avg(i,:,:) = [[scale*[cos(theta) -sin(theta); sin(theta) cos(theta)]; ...
      [x y]], [0 0 1]'];
end

figure;
plot(noisy_sequence_x);
hold on;
plot(vector_of_transforms_x);
legend('noisy','smoothed')
title('for translation in x');

figure;
plot(noisy_sequence_y);
hold on;
plot(vector_of_transforms_y);
legend('noisy','smoothed')
title('for translation in y');


figure;
plot(noisy_sequence_theta);
hold on;
plot(vector_of_transforms_theta);
legend('noisy','smoothed')
title('for translation in theta');


figure;
plot(noisy_sequence_scale);
hold on;
plot(vector_of_transforms_scale);
legend('noisy','smoothed')
title('for translation in scale');
% pause(2);

H=size(s(1).cdata,1);

W=size(s(1).cdata,2);

outV=s;
H_cum=eye(3);
H_cum_rev = eye(3);
x_cum=0;
y_cum=0;
theta_cum=0;
for j=2:T
%     if mod(j,10)==0
%         H_cum=eye(3);
%     end
    H_cum=squeeze(vector_of_transforms(j-1).T)*H_cum;
    H_cum_rev = squeeze(vector_of_transforms_avg(j-1,:,:))*H_cum_rev;
    H_cum_1 = H_cum/H_cum_rev;
    H_cum_1(:,3) = [0 0 1];
%     H_cum_1(3,1:2) = 0;
    out = imwarp(s(j).cdata,affine2d(H_cum_1),'OutputView',imref2d(size(s(j-1).cdata)));
%     out=imwarp(outV(j-1).cdata,vector_of_transforms(j-1),'OutputView',imref2d(size(s(j-1).cdata)));
%     size(out)
    outV(j).cdata=out;
%     outV(j).cdata=out(1:H,1:W,:);
end
figure;
displayvideo(outV,0.005);



N=T-1;




%% Write Video
[status, msg, msgID] = mkdir('../output');
PathName = '../output/';
vfile=strcat(PathName,'combined_',FileName);
ff = VideoWriter(vfile);
ff.FrameRate = 30;
open(ff)

for i=1:N+1
    f1 = s(i).cdata;
    f2 = outV(i).cdata;
    f2 = imresize(f2,[size(f1,1),size(f1,2)]);
    vframe=cat(1,f1, f2);
    writeVideo(ff, vframe);
end
close(ff)

%% Display Video
figure
msgbox(strcat('Combined Video Written In ', vfile), 'Completed') 
displayvideo(outV,0.01)
