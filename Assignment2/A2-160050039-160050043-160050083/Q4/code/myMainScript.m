tic;
% Reference:    https://in.mathworks.com/help/vision/ref/matchfeatures.html
%% CONSTANTS
threshold = 1.0;
%% Monument
origI1 = imread('../input/monument/1.JPG'); % Original Image 1
origI2 = imread('../input/monument/2.JPG'); % Original Image 2
I1 = rgb2gray(origI1);
I2 = rgb2gray(origI2);

% Finding Matching Pixel Correspondences
points1 = detectSURFFeatures(I1);
points2 = detectSURFFeatures(I2);
[f1,vpts1] = extractFeatures(I1,points1);
[f2,vpts2] = extractFeatures(I2,points2);
indexPairs = matchFeatures(f1,f2);
matchedPoints1 = vpts1(indexPairs(:,1)).Location;
matchedPoints2 = vpts2(indexPairs(:,2)).Location;
% figure; showMatchedFeatures(I1,I2,matchedPoints1,matchedPoints2);

% Ransac Homography such that matchedPoints2 = H * matchedPoints1
H = ransacHomography(matchedPoints1, matchedPoints2, threshold);



% Initializing stitched Image with a super Image containing original I1 at
% its centre
height = max(size(I1, 1), size(I2, 1));
width = max(size(I1, 2), size(I2, 2));
superImage = uint8(zeros(3*height, 3*width, 3));
superImage(height+1:2*height, width+1:2*width, :) = origI2(:, :, :);

% Reverse Warping
for i=1:3*height
    for j=1:3*width
        if (~((i >= height + 1) && (i <= 2*height) && (j >= width + 1) && (j <= 2*width)))
            coord = H*[(i-height); (j-width); 1];
            coord = coord./coord(3);
            x = floor(coord(1));
            y = floor(coord(2));
            if ((x <= size(I2, 1)) && (x >= 1) && (y <= size(I2, 2)) && (y >= 1))
                % Valid Point in I2 exists
                superImage(i,j,:) = origI1(x,y,:);
            else
                % No Valid Point in I2 exist
                superImage(i,j,:) = [0 0 0];
            end
        end
    end
end
imshow(superImage);
%%
toc;