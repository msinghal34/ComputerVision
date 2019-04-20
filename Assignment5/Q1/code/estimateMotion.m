function p = estimateMotion(frame1, frame2, point, TEMPLATE_SIZE, Ix, Iy)
    pointx = point(1);
    pointy = point(2);

    num_points = (2*TEMPLATE_SIZE+1)*(2*TEMPLATE_SIZE+1);
    coords = zeros(3, num_points);
    
    for i=1:(2*TEMPLATE_SIZE+1)
        coords(1,(i-1)*(2*TEMPLATE_SIZE+1)+1:i*(2*TEMPLATE_SIZE+1)) = pointx-TEMPLATE_SIZE+i-1;
        coords(2,(i-1)*(2*TEMPLATE_SIZE+1)+1:i*(2*TEMPLATE_SIZE+1)) = pointy-TEMPLATE_SIZE:pointy+TEMPLATE_SIZE;
        coords(3,(i-1)*(2*TEMPLATE_SIZE+1)+1:i*(2*TEMPLATE_SIZE+1)) = 1;
    end

    dwdp = zeros(num_points, 2, 6);
    for i=1:num_points
        dwdp(i,:,:) = [coords(1, i), coords(2, i), 1, 0, 0, 0; 0, 0, 0, coords(1, i), coords(2, i), 1];
    end
    
    template = getPatch(frame1, coords);
    p = [1 0 0; 0 1 0];  % Initial Guess
    for t=1:30 %TODO for better convergenece
        dI = [getPatch(Ix, round(p*coords)); getPatch(Iy, round(p*coords))];
        dIdwdp = zeros(num_points, 6);
        H = zeros(6,6);
        for i=1:num_points
            dIdwdp(i, :) = reshape(dI(:,i), 1, 2)*squeeze(dwdp(i,:,:));
            H = H + dIdwdp(i, :)'*dIdwdp(i, :);
        end
        warp = getPatch(frame2, round(p*coords));
        error = template-warp;
        temp = error*dIdwdp;
        delP = (temp*inv(H))';
        p = p + reshape(delP, 3, 2)';
    end
end

function patch = getPatch(I, coords)
    ind = sub2ind(size(I), max(min(coords(1,:), size(I,1)), 1), max(min(coords(2,:), size(I,2)), 1));
    patch = I(ind);
end