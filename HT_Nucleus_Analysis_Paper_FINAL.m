%% Prior to using this script, the following variables need to be changed:
% Code may need modification to work with your microscope. This code was
% written for a stack of tiff files exported from Nikon Elements.
% Written by Caitlin E. Jones, PhD and Joe Sharick, PhD
clear; clc;

%Prior to using this script, the following variables that may need to be
%changed:

%Modify with location of mij.jar
javaaddpath '';

%Modify line below to the folder the Miji is in - should be the scripts
%folder of FIJI
addpath '';

%Modify line below to the folder containing the images to be analyzed
addpath '';

%modify location to folder containing the images to be analyzed (same as
%line above)
location = '';

%Modify location and name of output spreadsheet
output_name = '';

%Modify with the name of the experiment
expName = ''; 

%modify slices to the number of slices in each z stack
slices = ;

%% Setting up MIJI

% setup unpivoted data structure
data = struct('Experiment',{},'Well',{},'FOV',{},'Num_Nuclei',{});

%the next two lines determine how many images are in the directory
images = dir([location '/*.tif']);
imagenum = numel(images);

%opens Miji interface
Miji; 

%generate an empty matrix for nuclei counting data
nucleicount = zeros(1,imagenum/slices);

%j iterates over each FOV
for j = 1:imagenum/slices
    
    %n iterates over the slices in the FOV and opens them
    for n=((j-1)*slices+1):(j*slices)
        
        %fullFileName = fullfile(location, images(n).name);
    
        im = images(n).name;
    
        %this opens images in MATLAB
        afm = imread(fullfile(location,im));
    
        %opens the image in ImageJ
        MIJ.createImage(afm); 
    
        %Z-project the multi-tiff format to single tiff
        MIJ.run("Z Project...", "projection=[Max Intensity]"); 
   
    end
    
    %This section labels data structure entries using the filename of
    %each image being analyzed
    data(j).Experiment = expName;
    tags = split(im,'_');
    data(j).Well = tags(2); %may need to be modified for your filename
    data(j).FOV = tags(9); %may need to be modified for your filename

%This code Z-projects the images and counts the number of nuclei
    
    % Converts individual images into a stack
    MIJ.run("Images to Stack", "name=Stack title=[] use");
    
    % Z-projects stack into one image based on maximum intensity for each
    % pixel
    MIJ.run("Z Project...", "projection=[Max Intensity]");
    
    % Makes the image 32-bit
    MIJ.run("32-bit"); 
    
    % Blurs the image, removes speckly background
    MIJ.run("Gaussian Blur...", "sigma=2"); 
    
    % Picks out the nuclei from the background
    MIJ.run("Threshold...","BlackBackground"); 
    MIJ.run("Convert to Mask");
    
    % Separates touching nuclei
    MIJ.run("Watershed"); 
    
    % Counts nuclei, adds to data structure. 
    % May need to change size for your images
    MIJ.run("Analyze Particles...", "size=500-7000 display");
    count=MIJ.getResultsTable;
    data(j).Num_Nuclei = length(count);
    
    MIJ.run("Clear Results");
    ij.IJ.selectWindow("Results");
    MIJ.run("Close");
    MIJ.run("Close All")
end

% Output data to image location, 
% change to alternative location if desired 
% change to desired file type
writetable(struct2table(data),append(location,"\",output_name,".xlsx"));

MIJ.closeAllWindows()
MIJ.exit()

