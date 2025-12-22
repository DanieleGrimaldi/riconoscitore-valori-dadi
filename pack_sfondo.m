clear all; close all; clc;

% CONFIGURAZIONE
file_input = 'SFONDO_ROI.jpg'; 
file_output_mat = 'dati_sfondo_training.mat'; 

if ~isfile(file_input)
    error('Manca il file %s! Esegui lo script di preparazione sfondo.', file_input);
end

fprintf('--- PACKAGING SFONDO ---\n');
img = imread(file_input);

% Trova pixel validi (non neri)
mask_validi = sum(img, 3) > 10;

% Converti in LAB
lab = rgb2lab(img);
L = lab(:,:,1); A = lab(:,:,2); B = lab(:,:,3);

% Estrai
pixel_sfondo = [L(mask_validi), A(mask_validi), B(mask_validi)];

fprintf('Totale pixel sfondo: %d\n', size(pixel_sfondo, 1));
save(file_output_mat, 'pixel_sfondo');
fprintf('Salvato: %s\n', file_output_mat);