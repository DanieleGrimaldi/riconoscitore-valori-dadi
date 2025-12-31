clear; clc; close all;

% --- 1. CONFIGURAZIONE PERCORSI ---
% Assicurati che le cartelle esistano
path_frames = fullfile('frame'); % Contiene .jpg
path_masks  = fullfile('mask');  % Contiene .png

% Ottieni la lista dei file JPG
files_jpg = dir(fullfile(path_frames, '*.jpg'));

if isempty(files_jpg)
    error('Nessun file JPG trovato in %s', path_frames);
end

% --- 2. INIZIALIZZAZIONE STATISTICHE ---
TP_tot = 0; % Veri Positivi
FP_tot = 0; % Falsi Positivi
FN_tot = 0; % Falsi Negativi
TN_tot = 0; % Veri Negativi

fprintf('Inizio Test su %d immagini...\n', length(files_jpg));
fprintf('--------------------------------------------------\n');

% --- 3. CICLO DI TEST ---
for k = 1:length(files_jpg)
    % A. Gestione Nomi File
    nome_jpg = files_jpg(k).name;                 % es. "frame_01.jpg"
    [~, nome_base, ~] = fileparts(nome_jpg);      % es. "frame_01"
    nome_png = strcat(nome_base, '.png');         % es. "frame_01.png"
    
    path_img_input = fullfile(path_frames, nome_jpg);
    path_mask_gt   = fullfile(path_masks, nome_png);
    
    % B. Controllo esistenza maschera
    if ~isfile(path_mask_gt)
        warning('Maschera PNG mancante per: %s. Salto.', nome_jpg);
        continue;
    end
    
    % C. Caricamento Immagini
    img_rgb = imread(path_img_input); % Immagine originale
    gt_raw  = imread(path_mask_gt);   % Ground Truth
    
    % D. Preparazione Ground Truth (Logical)
    % Se la maschera PNG è RGB o Index, la portiamo a logical
    if size(gt_raw, 3) == 3
        mask_gt = rgb2gray(gt_raw) > 0;
    else
        mask_gt = gt_raw > 0;
    end
    
    % --- PIPELINE ALGORITMO ---
    
    % E. Trova Maschera Vassoio
    % (Si assume che questa funzione esista nel tuo workspace)
    mask_vassoio = trova_maschera_vassoio(img_rgb);
    
    % F. Applica Maschera Vassoio all'immagine originale
    % Dobbiamo "spegnere" (mettere a nero) tutto ciò che è fuori dal vassoio
    img_masked = img_rgb; 
    
    if size(img_rgb, 3) == 3
        % Espandiamo la maschera vassoio su 3 canali per l'immagine RGB
        mask_vassoio_3ch = repmat(mask_vassoio, [1 1 3]);
        img_masked(~mask_vassoio_3ch) = 0;
    else
        img_masked(~mask_vassoio) = 0;
    end
    
    % G. Trova i Dadi (Funzione CART) sulla immagine pulita
    mask_predetta = cart_dadi(img_masked);
    mask_predetta = logical(mask_predetta); % Assicuriamoci sia logical
    
    % --- CONFRONTO (Pixel-wise) ---
    
    TP = sum(mask_predetta(:) & mask_gt(:));     % Predetto=1, Vero=1
    FP = sum(mask_predetta(:) & ~mask_gt(:));    % Predetto=1, Vero=0
    FN = sum(~mask_predetta(:) & mask_gt(:));    % Predetto=0, Vero=1
    TN = sum(~mask_predetta(:) & ~mask_gt(:));   % Predetto=0, Vero=0
    
    TP_tot = TP_tot + TP;
    FP_tot = FP_tot + FP;
    FN_tot = FN_tot + FN;
    TN_tot = TN_tot + TN;
    
    % --- VISUALIZZAZIONE RISULTATI ---
    % Creo una mappa errore RGB:
    % Verde = OK (TP)
    % Rosso = Errore: Ho visto un dado che non c'era (FP)
    % Blu   = Errore: Ho perso un dado (FN)
    error_map = zeros([size(mask_gt), 3], 'uint8');
    error_map(:,:,1) = uint8((mask_predetta & ~mask_gt) * 255); % R: FP
    error_map(:,:,2) = uint8((mask_predetta & mask_gt) * 255);  % G: TP
    error_map(:,:,3) = uint8((~mask_predetta & mask_gt) * 255); % B: FN
    
    figure;
    subplot(2,2,1); imshow(img_rgb); title(['Input: ' nome_base], 'Interpreter', 'none');
    subplot(2,2,2); imshow(img_masked); title('Dopo Maschera Vassoio');
    subplot(2,2,3); imshow(mask_predetta); title('Output Cart Dadi');
    subplot(2,2,4); imshow(error_map); title('Verde=OK, Rosso=FP, Blu=Perso');
    
    % Opzionale: Pausa per vedere ogni frame
    % pause(0.2); 
end

% --- 4. CALCOLO E STAMPA METRICHE ---
Accuracy = (TP_tot + TN_tot) / (TP_tot + TN_tot + FP_tot + FN_tot);
Precision = TP_tot / (TP_tot + FP_tot + eps); 
Recall = TP_tot / (TP_tot + FN_tot + eps);
IoU = TP_tot / (TP_tot + FP_tot + FN_tot + eps);

fprintf('\n========================================\n');
fprintf('RISULTATI TEST SU %d FILES\n', length(files_jpg));
fprintf('========================================\n');
fprintf('MATRICE DI CONFUSIONE (Totale Pixel):\n');
fprintf('\t\t\t\t| Reale: DADO \t| Reale: SFONDO\n');
fprintf('Predetto: DADO \t| TP: %d \t| FP: %d\n', TP_tot, FP_tot);
fprintf('Predetto: SFONDO\t| FN: %d \t| TN: %d\n', FN_tot, TN_tot);
fprintf('----------------------------------------\n');
fprintf('METRICHE CHIAVE:\n');
fprintf('Accuracy:  %.2f%%\n', Accuracy * 100);
fprintf('IoU:       %.4f (Obiettivo > 0.7)\n', IoU);
fprintf('Precision: %.2f%% (Affidabilità rilevamento)\n', Precision * 100);
fprintf('Recall:    %.2f%% (Capacità di non perdere dadi)\n', Recall * 100);

% Grafico Matrice
figure('Name', 'Matrice di Confusione Finale');
cm = [TP_tot, FP_tot; FN_tot, TN_tot];
heatmap({'Dado', 'Sfondo'}, {'Dado', 'Sfondo'}, cm, ...
    'Title', 'Confusion Matrix Pixel-based', ...
    'XLabel', 'Classe Reale', 'YLabel', 'Classe Predetta', ...
    'ColorbarVisible', 'on');