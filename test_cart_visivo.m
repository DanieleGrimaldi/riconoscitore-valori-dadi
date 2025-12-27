clear all; close all; clc;

% --- 1. CONFIGURAZIONE ---
cartella_frame = 'test/frame';
file_sfondo    = 'dati_sfondo_clean.mat';
file_dadi      = 'dati_dadi_clean.mat';

% --- 2. TRAINING DEL MODELLO ---
fprintf('--- FASE 1: TRAINING DEL MODELLO ---\n');

if ~isfile(file_sfondo) || ~isfile(file_dadi)
    error('File dati mancanti! Esegui prima carica_texture.m');
end

% Caricamento dati
load(file_sfondo, 'pixel_sfondo');
load(file_dadi, 'pixel_dadi');

% Preparazione Dataset (Uniamo tutto)
X = [pixel_sfondo; pixel_dadi];
Y = [zeros(size(pixel_sfondo,1), 1); ones(size(pixel_dadi,1), 1)];

fprintf('Addestramento in corso su %d pixel totali... ', length(Y));
% Addestramento CART
treeModel = fitctree(X, Y, 'PredictorNames', {'L', 'A', 'B'});
fprintf('FATTO.\n');

% --- 3. TEST SU 10 IMMAGINI ---
fprintf('\n--- FASE 2: TEST VISIVO SU 10 FRAME ---\n');

files = dir(fullfile(cartella_frame, '*.jpg'));
if isempty(files)
    error('Nessuna immagine trovata in %s', cartella_frame);
end

% Prendiamo solo le prime 10 (o meno se ce ne sono meno)
num_test = min(10, length(files));

for k = 1:num_test
    nome_file = files(k).name;
    full_path = fullfile(cartella_frame, nome_file);
    
    % A. Carica Immagine
    frame_originale = imread(full_path);
    [rows, cols, ch] = size(frame_originale);
    
    % B. Trova Maschera Vassoio (ROI)
    % Questa funzione isola l'interno del vassoio
    mask_vassoio = trova_maschera_vassoio(frame_originale);
    
    % C. Oscura lo sfondo (Tavolo -> Nero)
    img_input_cart = frame_originale;
    mask_3d = repmat(mask_vassoio, [1 1 3]);
    img_input_cart(~mask_3d) = 0; % Mette a 0 i pixel fuori dal vassoio
    
    % D. CART: Predizione
    % Convertiamo in LAB (solo l'immagine mascherata)
    lab = rgb2lab(img_input_cart);
    X_test = reshape(lab, rows*cols, 3);
    
    % Il modello predice (0=Sfondo/Nero, 1=Dado)
    pred_vec = predict(treeModel, X_test);
    mask_predetta = reshape(pred_vec, rows, cols) > 0;
    
    % E. Pulizia Finale
    % Intersechiamo con la mask_vassoio per sicurezza (toglie falsi positivi sul bordo nero)
    mask_finale = mask_predetta & mask_vassoio;
    
    % Riempie i buchi nei dadi e toglie rumore
    mask_finale = imfill(mask_finale, 'holes');
    mask_finale = bwareaopen(mask_finale, 100); 
    
    % --- VISUALIZZAZIONE ---
    figure(k);
    set(gcf, 'Name', ['Test Frame ' num2str(k)], 'NumberTitle', 'off');
    
    % 1. Immagine Originale
    subplot(1, 3, 1);
    imshow(frame_originale);
    title(['Originale: ' nome_file], 'Interpreter', 'none');
    
    % 2. Input al CART (Quello che vede il modello)
    subplot(1, 3, 2);
    imshow(img_input_cart);
    title('Input al CART (Senza Tavolo)');
    
    % 3. Risultato (Maschera Dadi)
    subplot(1, 3, 3);
    imshow(mask_finale);
    title('Output CART (Dadi Trovati)');
    
    drawnow;
end

fprintf('\nTest completato. Controlla le 10 finestre aperte.\n');