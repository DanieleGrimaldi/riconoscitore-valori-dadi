clear all; close all; clc;

% --- CONFIGURAZIONE ---
dataset_dir = 'numeri'; 
num_samples = 4;
min_area_pixels = 40; % Soglia minima area

fprintf('--- AVVIO TEST (RECUPERO TOTALE - NO TAGLIO ALPHA) ---\n');

for classe = 1:6
    folder_path = fullfile(dataset_dir, num2str(classe));
    
    if ~exist(folder_path, 'dir'), continue; end
    
    files = dir(fullfile(folder_path, '*.png'));
    num_files = length(files);
    
    if num_files == 0, continue; end
    
    n_to_show = min(num_samples, num_files);
    perm = randperm(num_files);
    idx_scelti = perm(1:n_to_show);
    
    figure('Name', sprintf('Classe %d - Recupero Totale', classe), ...
           'Color', 'w', 'Position', [100, 100, 800, 200 * n_to_show]);
    
    for i = 1:n_to_show
        file_idx = idx_scelti(i);
        filename = fullfile(folder_path, files(file_idx).name);
        [img, ~, alpha] = imread(filename);
        
        % --- ESECUZIONE ---
        [mask, cluster_img, bg_id] = estrazione_recupero(img, alpha, min_area_pixels);
        
        % --- VISUALIZZAZIONE ---
        subplot(n_to_show, 3, (i-1)*3 + 1);
        imshow(img);
        title(['Img ' num2str(file_idx)]);
        
        subplot(n_to_show, 3, (i-1)*3 + 2);
        imshow(label2rgb(cluster_img)); 
        title(['K-Means (Sfondo ID=' num2str(bg_id) ')']);
        
        subplot(n_to_show, 3, (i-1)*3 + 3);
        imshow(mask);
        title('Maschera (No Alpha Cut)');
    end
    drawnow;
end
fprintf('--- TEST COMPLETATO ---\n');

% ---------------------------------------------------------
% FUNZIONE RECUPERO TOTALE (CONN 4 + BARICENTRO)
% ---------------------------------------------------------
function [mask_finale, pixel_labels, bg_cluster] = estrazione_recupero(img_rgb, alpha, min_area)

    % 1. Pulizia input
    if size(img_rgb, 3) == 4
        img_rgb = img_rgb(:,:,1:3);
    end
    
    % Se manca l'alpha, ne creiamo uno finto solo sui bordi per campionare lo sfondo
    if isempty(alpha)
        alpha = ones(size(img_rgb,1), size(img_rgb,2)); 
        alpha(1,:) = 0; alpha(end,:) = 0; alpha(:,1) = 0; alpha(:,end) = 0;
    end

    % 2. K-Means (LAB) su TUTTA l'immagine
    lab = rgb2lab(img_rgb);
    ab = double(lab);
    nrows = size(ab,1);
    ncols = size(ab,2);
    data = reshape(ab, nrows*ncols, 3);
    
    [idx, ~] = kmeans(data, 2, 'Distance', 'sqeuclidean', 'Replicates', 3);
    pixel_labels = reshape(idx, nrows, ncols);
    
    % 3. Identificazione Sfondo (Usiamo Alpha SOLO per capire chi è lo sfondo)
    mask_trasparente = (alpha == 0);
    
    if sum(mask_trasparente(:)) > 0
        % Guardiamo che numero (1 o 2) c'è dove è trasparente
        pixel_nella_trasparenza = pixel_labels(mask_trasparente);
        bg_cluster = mode(pixel_nella_trasparenza);
    else
        % Fallback angoli se l'alpha è tutto pieno
        corners = [pixel_labels(1,1); pixel_labels(1,end); pixel_labels(end,1); pixel_labels(end,end)];
        bg_cluster = mode(corners);
    end
    
    % 4. Creazione Maschera Grezza
    % QUI LA MODIFICA: Non tagliamo più con "& (alpha > 0)"
    % Se il K-Means dice che è "Oggetto", lo teniamo anche se era fuori dall'alpha.
    mask_raw = (pixel_labels ~= bg_cluster);

    % --- FASE DI SELEZIONE BARICENTRO (CONN 4) ---
    
    % A. Connessione a 4 lati (croce)
    cc = bwconncomp(mask_raw, 4); 
    stats = regionprops(cc, 'Area', 'Centroid', 'PixelIdxList');
    
    % B. Filtro Area (elimina briciole < 40px)
    valid_indices = find([stats.Area] >= min_area);
    
    if isempty(valid_indices)
        mask_finale = false(nrows, ncols);
        return;
    end
    
    % C. Trova il più centrale
    img_center = [ncols/2, nrows/2]; 
    
    best_idx = -1;
    min_dist = Inf;
    
    for k = valid_indices
        centro_isola = stats(k).Centroid;
        dist = norm(centro_isola - img_center);
        
        if dist < min_dist
            min_dist = dist;
            best_idx = k;
        end
    end
    
    % D. Ricostruisci
    mask_finale = false(nrows, ncols);
    mask_finale(stats(best_idx).PixelIdxList) = true;

end