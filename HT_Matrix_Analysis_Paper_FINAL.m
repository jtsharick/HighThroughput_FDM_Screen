%% Prior to using this script, the following variables need to be changed:
% Code may need modification to work with your microscope. This code was
% written for a stack of tiff files exported from Nikon Elements.
% Written by Caitlin E. Jones, PhD and Joe Sharick, PhD

clear; clc;

%Modify with location of mij.jar
javaaddpath '';

%Modify line below to the folder the Miji.m is in - should be the scripts
%folder of FIJI
addpath '';

%Modify line below to the folder containing the images to be analyzed
addpath '';

%Modify location to folder containing the images to be analyzed (same as
%line above)
input_location = '';

%Modify location and name of output spreadsheet
output_name = '';

%Modify with the name of the experiment
expName = ''; 

%Modify slices to the number of slices in each z stack
slices = ;

%Set the total number of pixels in FOV, used to calculate % area (Example = 512*512)
maxArea = ; 

% select intensity value to use for background thresholding
background = ;

%% Setting up MIJI

% setup unpivoted data structure
data = struct('Experiment',{},'Well',{},'FOV',{},'Frac_Within_10deg',{},'Frac_Within_20deg',{},'Area_Under_Background',{});

%the next two lines determine how many images are in the directory
images = dir([input_location '/*.tif']);
imagenum = numel(images);

%open Miji interface
Miji; 

%generate an empty matrix for fiber alignment data
fullres=zeros(180,imagenum/slices);

%j iterates over each FOV
for j = 1:imagenum/slices 
    
    %n iterates over the slices in the FOV and opens them
    for n=((j-1)*slices+1):(j*slices) 
        
        im = images(n).name;
        
        %this opens images in MATLAB
        afm = imread(fullfile(input_location,im)); 
        
        %opens the image in ImageJ
        MIJ.createImage(afm); 
        
        %If needed, Z-project the multi-tiff format to single tiff
        MIJ.run("Z Project...", "projection=[Max Intensity]");
    
    end

% This code Z-projects the slices, turns them into a 32-bit format, and runs
% OrientationJ

    %This section labels data structure entries using the filename of
    %each image being analyzed
    data(j).Experiment = expName;
    tags = split(im,'_');
    data(j).Well = tags(8); %may need to be modified for your filename
    data(j).FOV = tags(9); %may need to be modified for your filename
    
    % Converts individual images into a stack
    MIJ.run("Images to Stack", "name=Stack title=[] use");
    
    % Z-projects stack into one image based on maximum intensity for each
    % pixel
    MIJ.run("Z Project...", "projection=[Max Intensity]");
  
    % Run OrientationJ
    MIJ.run("32-bit"); 
    MIJ.run("OrientationJ Distribution", "tensor=3.0 gradient=4 radian=on histogram=on table=on min-coherency=0.0 min-energy=0.0 ");
    ij.IJ.selectWindow("OJ-Distribution-1");
    
    % Renames results table to "Results" instead of "OJ-Distribution-1"
    ij.IJ.renameResults("Results") 
    
    %returns the results table w/ degrees in column 1 and frequency in column 2
    res=MIJ.getResultsTable; 
    
    %will add frequency values for a-th image to a-th column in fullres matrix
    fullres(:,j)=res(:,2); 
    
    MIJ.selectWindow("MAX_Stack");
    MIJ.setThreshold(0,background)
    MIJ.run("NaN Background");
    MIJ.run("Set Measurements...", "area redirect=None decimal=3");
    MIJ.run("Measure");    
    area=MIJ.getResultsTable;
    data(j).Area_Under_Background = area(1)/maxArea;
    
    MIJ.run("Clear Results");
    ij.IJ.selectWindow("Results");
    MIJ.run("Close");
    
    MIJ.run("Close All")
end

%this finds the row with the maximum value in each column
[~,mac] = max(fullres); 

%this is to center the distributions of the fullres so the mode is at 90
for a = 1:j 
    if mac(a)<90
        center(:,a)=circshift(fullres(:,a),(90-mac(a)));
    elseif mac(a)>90
        center(:,a)=circshift(fullres(:,a),(270-mac(a)));
    else
        center(:,a)=fullres(:,a);
    end
end

%gives the fraction of fibers within 10 degrees and 20 degrees of mode in a table called "frac"
for a = 1:j 
    data(a).Frac_Within_10deg = sum(center(80:100,a))/sum(center(:,a));
    data(a).Frac_Within_20deg = sum(center(70:110,a))/sum(center(:,a));
end

% Output data, change to desired location
writetable(struct2table(data),output_name);

MIJ.closeAllWindows()
MIJ.exit()
