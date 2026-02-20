function somma_totale = estrai_dadi(frame_rgb)
    
    somma_totale = 0;
    
    mask_raw = cart_dadi(frame_rgb); 
    

    [L, num_blob] = bwlabel(mask_raw);
    
    for k = 1:num_blob
        mask_blob = (L == k);
       
        [maschere_finali, immagini_finali] = gestione_blob(mask_blob, frame_rgb);
        
        for m = 1:length(maschere_finali)
            mask_dado = maschere_finali{m};
            img_dado = immagini_finali{m};
            valore = processa_dado(img_dado, mask_dado);
            
            somma_totale = somma_totale + valore;
        end
    end
end

function [lista_maschere, lista_immagini] = gestione_blob(mask_blob,img)
    
    lista_maschere = {};
    SOGLIA_MULTIPLA = 3500; 
    
    props = regionprops(mask_blob, 'BoundingBox', 'Area');    
    bbox = props(1).BoundingBox;
    area_blob = props(1).Area; 
    
    mask_crop = imcrop(mask_blob, bbox);
    img_crop = imcrop(img, bbox);
    
    if area_blob < SOGLIA_MULTIPLA

        lista_maschere{1} = mask_crop;
        lista_immagini{1} = img_crop;

    else
        maschere_separate = dividi_dadi(mask_crop,img_crop);

        for i = 1:length(maschere_separate)
            mask_singolo_pezzo = maschere_separate{i};
            
            props_pezzo = regionprops(mask_singolo_pezzo, 'BoundingBox');
            if ~isempty(props_pezzo)
                bbox_pezzo = props_pezzo(1).BoundingBox;
                
                % Secondo ritaglio millimetrico sul singolo dado estratto
                lista_maschere{end+1} = imcrop(mask_singolo_pezzo, bbox_pezzo);
                lista_immagini{end+1} = imcrop(img_crop, bbox_pezzo);
            end
        end
    end
end

function valore = processa_dado(frame_rgb, mask_dado)

    valore = 0;
    
    mask_cifra = estrai_cifra(frame_rgb, mask_dado);
   
    valore = decodifica_cifra(mask_cifra);

end