%% ACR Intensity Gradient Correction
% by Yassine Azma (Dec 2021)
%
% This script takes the ACR data and models it as a flat constant value
% plus added orthogonal gradients and parabolas. Solving the regression 
% problem using weighted linear least squares allows for the production of 
% an image which is much flatter and more easily thresholded. 
% This is used in the ACR_Centroid script.

function corr_img_ACR = ACR_IntensityGradientCorrection(img_ACR,obj_ACR)

res_ACR = ACR_RetrievePixelSpacing(obj_ACR);

dims = size(img_ACR,[1 2]);

I0 = ones(dims); % offset
Ix = repmat(-0.5:1/(dims(1)-1):0.5,dims(2),1); % col gradient
Ix2 = Ix.*Ix; % quadratic 
Iy = repmat(-0.5:1/(dims(1)-1):0.5,dims(2),1)'; % row gradient
Iy2 = Iy.*Iy; % quadratic
Ir2 = Ix2+Iy2; % radial quadratic

% H = [I0(:) Ix(:) Iy(:) Ix2(:) Iy2(:)]; % model matrix
H = [I0(:) Ix(:) Iy(:) Ir2(:)];

for k = 1:size(img_ACR,3)
    img = img_ACR(:,:,k);
    wm = im2double(img)/im2double(max(img,[],'all')); % weighting based on mag
    wv = wm(:); % vectorise

%     HpWH = H'*((wv*ones(1,5)).*H); % First order
    HpWH = H'*((wv*ones(1,4)).*H);
    aw = HpWH \ (H'*(wv.*img(:))); % Ordinary least squares for coefficients

    if abs(aw(2)) > 2*abs(aw(3))
        corr_img = img-imfill(wm>0.04,'holes').*reshape(H(:,[2 4])*aw([2,4]),dims);
        edge_img(:,:,k) = ACR_Threshold(corr_img,res_ACR);
        corr_img_ACR(:,:,k) = edge_img(:,:,k).*corr_img;
    elseif abs(aw(3)) > 2*abs(aw(2))
        corr_img = img-imfill(wm>0.04,'holes').*reshape(H(:,[3 4])*aw([3,4]),dims);
        edge_img(:,:,k) = ACR_Threshold(corr_img,res_ACR);
        corr_img_ACR(:,:,k) = edge_img(:,:,k).*corr_img;
    else
        corr_img_ACR(:,:,k) = img;
    end
end