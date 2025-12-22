function mask_cart = cart_dadi(img_input)
    % Usa 'persistent' per caricare il modello UNA volta sola (velocità)
    persistent TreeModel;
    
    % 1. Caricamento Modello (Solo al primo avvio)
    if isempty(TreeModel)
        nome_file = 'Modello_Pixel_Finale.mat';
        if isfile(nome_file)
            fprintf('[CART] Caricamento modello in memoria... ');
            dati = load(nome_file);
            TreeModel = dati.TreeModel;
            fprintf('OK.\n');
        else
            error('Modello %s non trovato! Addestralo prima.', nome_file);
        end
    end

    % 2. Preparazione Dati
    [rows, cols, ~] = size(img_input);
    
    % Conversione RGB -> LAB (Cruciale: deve essere uguale al training)
    lab = rgb2lab(img_input);
    X = reshape(lab, rows*cols, 3);
    
    % 3. Predizione (Il Cervello)
    % Questa è la parte lenta: classifica ogni singolo pixel
    pred_vettore = predict(TreeModel, X);
    
    % 4. Ricostruzione Immagine
    mask_cart = reshape(pred_vettore, rows, cols);
    mask_cart = logical(mask_cart);
    %{
    % --- VISUALIZZAZIONE DEBUG (RICHIESTA) ---
    figure; 
    set(gcf, 'Name', 'DEBUG: CART DADI (Prima e Dopo)', 'NumberTitle', 'off');
    
    % A. L'immagine che il modello sta guardando
    subplot(1, 2, 1); 
    imshow(img_input); 
    title('INPUT al Modello');
    
    % B. Cosa il modello "vede" (Bianco = Dado, Nero = Sfondo)
    subplot(1, 2, 2); 
    imshow(mask_cart); 
    title('OUTPUT Grezzo (Raw Prediction)');
    
    drawnow; % Forza l'aggiornamento grafico immediato
    %}
end