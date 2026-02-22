function maschera_bordi = estrai_cifra_bordi(img, mask)

    mask_3d = repmat(~mask, [1, 1, 3]);
    img(mask_3d) = 0;

    img_gray = rgb2gray(img);
    
    img_mediana = medfilt2(img_gray, [3 3]);
    
    % 1. Calcoli il Laplaciano (matrice con numeri negativi e positivi)
    filtro_lap = fspecial('laplacian', 0.2);
    img_lap = imfilter(double(img_mediana), filtro_lap, 'replicate');
    
    % 2. Prendi il valore assoluto (i -80 diventano +80)
    lap_abs = abs(img_lap);
    
    % 3. Binarizzazione con Soglia manuale
    % Scegliamo un valore di "taglio". Tutto ciò che "salta" meno di 15 
    % lo consideriamo texture del dado e lo mettiamo a 0.
    soglia = 90; 
    maschera_bordi = lap_abs > soglia;

    figure;
    subplot(1,3,1);
    imshow(img);
    subplot(1,3,2);
    imshow(img_mediana);
    subplot(1,3,3);
    imshow(maschera_bordi);

end
