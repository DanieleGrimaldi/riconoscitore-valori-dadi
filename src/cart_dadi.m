function mask_final = cart_dadi(img_input)

    persistent treeModel;
    
    if isempty(treeModel)
        cartella_script = fileparts(mfilename('fullpath')); 
        nome_file = fullfile(cartella_script, 'ModelloAlbero.mat');
        if ~isfile(nome_file)
            error('Modello "%s" non trovato!', nome_file);
        end
        
        dati = load(nome_file);
        if isfield(dati, 'tree'), treeModel = dati.tree;
        else, nomi = fieldnames(dati); treeModel = dati.(nomi{1});
        end
    end

    [X_features, mask_validi] = pre_processing(img_input);
    
    [h, w, ~] = size(img_input);
    mask_raw = false(h, w);

    labels = predict(treeModel, X_features);
    
    mask_raw(mask_validi) = labels;

    mask_final = post_processing(mask_raw);

    %visualizza_debug(img_input, mask_raw, mask_final);
    
end



function [X, mask_validi] = pre_processing(img)

    mask_vassoio = trova_maschera_vassoio(img);
    mask_validi = mask_vassoio & sum(img, 3) > 0;
   
    lab_img = rgb2lab(img);
    L = lab_img(:,:,1);
    A = lab_img(:,:,2);
    B = lab_img(:,:,3);
    

    L_norm = rescale(L); 
    Texture = stdfilt(L_norm, true(3));
    X = [L(mask_validi), A(mask_validi), B(mask_validi), Texture(mask_validi)];
end

function mask_out = post_processing(mask_in)

    se = strel('disk', 5); 
    mask_out = imfill(mask_in, 'holes');
    mask_out = imopen(mask_out, se);
    mask_out = bwareaopen(mask_out, 800);
    mask_out = imclearborder(mask_out);
end


function visualizza_debug(img_orig, mask_pre, mask_post)
    % Ricostruisce le immagini applicando le maschere (isolerà i dadi a colori)
    img_no_pp = img_orig .* uint8(mask_pre);
    img_con_pp = img_orig .* uint8(mask_post);
    
    % Crea una singola finestra con i 3 pannelli
    figure;
    
    subplot(1, 3, 1);
    imshow(img_orig);
    title('Originale');
    
    subplot(1, 3, 2);
    imshow(img_no_pp);
    title('Senza PP');
    
    subplot(1, 3, 3);
    imshow(img_con_pp);
    title('Con PP');
end