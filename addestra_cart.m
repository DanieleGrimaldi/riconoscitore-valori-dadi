clear all; close all; clc;

% --- CONFIGURAZIONE CARTELLE ---
dir_tagliati = 'frame-tagliati'; % Input: Immagini PNG dei dadi (con trasparenza o sfondo nero)
dir_mask     = 'mask';           % Output 1: Dove salvare le maschere binarie
file_texture = 'TEXTURE_DADI_ALL.png';      % Output 2: Immagine pixel compressi
file_mat     = 'dati_dadi_training_all.mat'; % Output 3: Dati .mat per il training

% Crea cartella mask se non esiste
if ~exist(dir_mask, 'dir')
    mkdir(dir_mask);
    fprintf('Cartella "%s" creata.\n', dir_mask);
end

% Ottieni lista file PNG
files = dir(fullfile(dir_tagliati, '*.png')); 
if isempty(files)
    % Se non trova png, prova jpg
    files = dir(fullfile(dir_tagliati, '*.jpg'));
end

if isempty(files)
    error('Nessuna immagine trovata in %s', dir_tagliati);
end

fprintf('Trovati %d file. Inizio elaborazione...\n', length(files));

% Accumulatore per tutti i pixel (L, A, B)
accumulo_pixel_lab = [];
accumulo_pixel_rgb = [];

count = 0;

% --- CICLO DI ELABORAZIONE ---
for k = 1:length(files)
    nome_file = files(k).name;
    full_path = fullfile(dir_tagliati, nome_file);
    
    % 1. Carica Immagine (gestisce anche Alpha channel se PNG)
    [img, ~, alpha] = imread(full_path);
    
    % 2. Crea la Maschera Binaria
    % Se c'è il canale Alpha (trasparenza), usiamo quello
    if ~isempty(alpha)
        mask = alpha > 0;
    else
        % Altrimenti usiamo la luminosità (se lo sfondo è nero)
        % Se la somma dei colori > 10 (per evitare rumore nero assoluto)
        mask = sum(img, 3) > 10;
    end
    
    % 3. Salva la Maschera nella cartella 'mask'
    path_mask = fullfile(dir_mask, nome_file);
    imwrite(mask, path_mask);
    
    % 4. Estrazione Pixel per il Training
    if sum(mask(:)) > 0
        % Converti in LAB
        lab = rgb2lab(img);
        
        % Estrai solo i pixel del dado
        L = lab(:,:,1); A = lab(:,:,2); B = lab(:,:,3);
        R = img(:,:,1); G = img(:,:,2); B_rgb = img(:,:,3);
        
        pixel_validi_lab = [L(mask), A(mask), B(mask)];
        pixel_validi_rgb = [R(mask), G(mask), B_rgb(mask)];
        
        % Aggiungi al mucchio
        accumulo_pixel_lab = [accumulo_pixel_lab; pixel_validi_lab];
        accumulo_pixel_rgb = [accumulo_pixel_rgb; pixel_validi_rgb];
        
        count = count + 1;
    end
    
    if mod(k, 50) == 0, fprintf('.'); end
end

fprintf('\nElaborazione completata.\n');
fprintf('Totale pixel dadi estratti: %d\n', size(accumulo_pixel_lab, 1));

% --- CREAZIONE IMMAGINE COMPRESSA (TEXTURE) ---
num_pixels = size(accumulo_pixel_rgb, 1);
lato = ceil(sqrt(num_pixels));

% Crea tela nera
texture_flat = zeros(lato * lato, 3, 'uint8');
texture_flat(1:num_pixels, :) = accumulo_pixel_rgb;

% Reshape in quadrato
texture_finale = reshape(texture_flat, [lato, lato, 3]);

% Salva Texture e Dati
imwrite(texture_finale, file_texture);

% Salviamo col nome variabile 'pixel_dadi' per compatibilità col training
pixel_dadi = accumulo_pixel_lab; 
save(file_mat, 'pixel_dadi');

fprintf('1. Maschere salvate in: %s/\n', dir_mask);
fprintf('2. Texture visiva salvata: %s\n', file_texture);
fprintf('3. Dati Training salvati: %s\n', file_mat);

% --- MOSTRA RISULTATO ---
figure; 
subplot(1,2,1); imshow(texture_finale); title('Tutti i Dadi Compressi');
subplot(1,2,2); imshow(mask); title(['Esempio Maschera: ' nome_file]);