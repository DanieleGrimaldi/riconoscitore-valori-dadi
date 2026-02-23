function somma_totale = estrai_dadi(frame_rgb)
    
    somma_totale = 0;

    lista_valori = [];
    lista_bboxes = {};

    mask_raw = cart_dadi(frame_rgb); 
    [L, num_blob] = bwlabel(mask_raw);
    
    for k = 1:num_blob
        mask_blob = (L == k);
       
        [maschere_finali, immagini_finali, bboxes_finali] = gestione_blob(mask_blob, frame_rgb);
        
        for m = 1:length(maschere_finali)
            mask_dado = maschere_finali{m};
            img_dado = immagini_finali{m};
            bbox_corrente = bboxes_finali{m};

            valore = processa_dado(img_dado, mask_dado);
            somma_totale = somma_totale + valore;

            lista_valori(end+1) = valore;
            lista_bboxes{end+1} = bbox_corrente;
        end
    end
    stampa(frame_rgb, lista_valori, lista_bboxes, somma_totale);
end

function [lista_maschere, lista_immagini, lista_bboxes] = gestione_blob(mask_blob,img)
    
    lista_maschere = {};
    lista_immagini = {};
    lista_bboxes = {};

    SOGLIA_MULTIPLA = 3500; 
    
    props = regionprops(mask_blob, 'BoundingBox', 'Area');    
    bbox = props(1).BoundingBox;
    area_blob = props(1).Area; 
    
    mask_crop = imcrop(mask_blob, bbox);
    img_crop = imcrop(img, bbox);
    
    if area_blob < SOGLIA_MULTIPLA

        lista_maschere{1} = mask_crop;
        lista_immagini{1} = img_crop;
        lista_bboxes{1} = bbox;

    else
        maschere_separate = dividi_dadi(mask_crop,img_crop);

        for i = 1:length(maschere_separate)
            mask_singolo_pezzo = maschere_separate{i};
            
            props_pezzo = regionprops(mask_singolo_pezzo, 'BoundingBox');
            if ~isempty(props_pezzo)
                bbox_pezzo = props_pezzo(1).BoundingBox;
                
                x_assoluto = bbox(1) + bbox_pezzo(1) - 1;
                y_assoluto = bbox(2) + bbox_pezzo(2) - 1;
                bbox_finale = [x_assoluto, y_assoluto, bbox_pezzo(3), bbox_pezzo(4)];

                % Secondo ritaglio millimetrico sul singolo dado estratto
                lista_maschere{end+1} = imcrop(mask_singolo_pezzo, bbox_pezzo);
                lista_immagini{end+1} = imcrop(img_crop, bbox_pezzo);
                lista_bboxes{end+1} = bbox_finale;
            end
        end
    end
end

function valore = processa_dado(frame_rgb, mask_dado)
    valore = 0;

    %mask_cifra = estrai_cifra_bordi(frame_rgb,mask_dado);
    mask_cifra = estrai_cifra(frame_rgb, mask_dado);

    valore = decodifica_cifra(mask_cifra);

end

function stampa(img_originale, lista_valori, lista_bboxes, somma_totale)
    % STAMPA: Ricostruisce l'immagine inserendo la Realtà Aumentata
    
    img_annotata = img_originale;
    
    
    % Cicliamo sui vettori per disegnare le etichette su ogni dado
    for i = 1:length(lista_valori)
        box = lista_bboxes{i};
        valore = lista_valori(i);
        
        % Disegniamo il rettangolo giallo
        img_annotata = insertShape(img_annotata, 'Rectangle', box, ...
            'Color', 'yellow', 'LineWidth', 3);
        
        % Calcoliamo le coordinate per il testo (subito sopra il rettangolo)
        posizione_testo = [box(1), max(1, box(2) - 35)];
        
        % Inseriamo il numero previsto con uno sfondo verde
        img_annotata = insertText(img_annotata, posizione_testo, num2str(valore), ...
            'FontSize', 24, 'BoxColor', 'green', 'BoxOpacity', 0.8, 'TextColor', 'white');
    end
    
    % Creiamo la figura e mostriamo l'immagine finale ricostruita
    figure;
    imshow(img_annotata);
    
    % Aggiungiamo un titolo in alto con la somma totale
    title(sprintf('SOMMA TOTALE SUL TAVOLO: %d', somma_totale), 'FontSize', 26, 'Color', 'red');
end


