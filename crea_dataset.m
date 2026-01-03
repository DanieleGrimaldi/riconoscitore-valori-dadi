clear all; close all; clc;

% --- CONFIGURAZIONE ---
input_folder = 'cifre';       % Cartella dati originali
output_folder = 'cifre_balanced'; % Cartella destinazione
TARGET_NUM = 150;             % Vogliamo 150 campioni per ogni classe

if ~exist(output_folder, 'dir'), mkdir(output_folder); end

fprintf('--- AVVIO BILANCIAMENTO (SOLO DILATE/ERODE) ---\n');

% Usiamo una croce (diamond) piccola per non deformare troppo i numeri piccoli
se_soft = strel('diamond', 1); 

for classe = 1:6
    src_path = fullfile(input_folder, num2str(classe));
    dst_path = fullfile(output_folder, num2str(classe));
    
    if ~exist(dst_path, 'dir'), mkdir(dst_path); end
    
    files = dir(fullfile(src_path, '*.png'));
    num_original = length(files);
    
    fprintf('Classe %d: %d originali. ', classe, num_original);
    
    if num_original == 0
        continue;
    end
    
    % 1. COPIA GLI ORIGINALI
    imgs_cache = {}; 
    for i = 1:num_original
        img = imread(fullfile(src_path, files(i).name));
        img = logical(img > 0); 
        imgs_cache{end+1} = img;
        
        % Salviamo l'originale
        imwrite(uint8(img)*255, fullfile(dst_path, files(i).name));
    end
    
    % 2. GENERAZIONE VARIANTI
    count = num_original;
    
    if count < TARGET_NUM
        needed = TARGET_NUM - count;
        fprintf('Genero %d varianti... ', needed);
        
        for k = 1:needed
            idx_rand = randi(num_original);
            img_base = imgs_cache{idx_rand};
            
            % Scegliamo solo tra 1 (Dilate) e 2 (Erode)
            op_type = randi(2);
            
            img_aug = img_base;
            suffix = '';
            
            switch op_type
                case 1 % DILATAZIONE (Numero più grasso)
                    img_aug = imdilate(img_base, se_soft);
                    suffix = '_dil';
                    
                case 2 % EROSIONE (Numero più magro)
                    img_aug = imerode(img_base, se_soft);
                    suffix = '_ero';
                    
                    % SICUREZZA: Se l'erosione cancella troppi pixel, annulla!
                    if sum(img_aug(:)) < 10 % Soglia minima di sicurezza
                        img_aug = img_base; 
                        suffix = '_orig_copy';
                    end
            end
            
            % Salvataggio
            fname = sprintf('aug_%d%s.png', k, suffix);
            imwrite(uint8(img_aug)*255, fullfile(dst_path, fname));
        end
        fprintf('Fatto -> %d totali.\n', TARGET_NUM);
    else
        fprintf('Già ok.\n');
    end
end

fprintf('--- COMPLETATO ---\n');