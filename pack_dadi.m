clear all; close all; clc;

% CONFIGURAZIONE
cartella_input = 'dataset_pixel_MASKED'; 
file_output_mat = 'dati_dadi_training.mat'; 

% Cerca file
files = [dir(fullfile(cartella_input, '*.jpg')); dir(fullfile(cartella_input, '*.png'))];
if isempty(files)
    error('Cartella %s vuota o inesistente!', cartella_input);
end

fprintf('--- PACKAGING DADI ---\n');
pixel_dadi = []; % Accumulatore LAB

for k = 1:length(files)
    img = imread(fullfile(files(k).folder, files(k).name));
    
    % Trova pixel validi (non neri)
    mask_validi = sum(img, 3) > 10;
    
    if sum(mask_validi(:)) > 0
        % Converti in LAB e estrai
        lab = rgb2lab(img);
        L = lab(:,:,1); A = lab(:,:,2); B = lab(:,:,3);
        
        pixel_dadi = [pixel_dadi; L(mask_validi), A(mask_validi), B(mask_validi)];
    end
    
    if mod(k, 100) == 0, fprintf('.'); end
end

fprintf('\nTotale pixel dadi: %d\n', size(pixel_dadi, 1));
save(file_output_mat, 'pixel_dadi');
fprintf('Salvato: %s\n', file_output_mat);