function pixel_totali_cambiati = calcola_movimento(lab1, lab2)

    a1 = lab1(:,:,2); 
    b1 = lab1(:,:,3);
    
    a2 = lab2(:,:,2); 
    b2 = lab2(:,:,3);


    distanza_pixel = sqrt( (a1 - a2).^2 + (b1 - b2).^2 );
    SOGLIA_COLORE = 10;
    pixel_cambiati = distanza_pixel > SOGLIA_COLORE;
    pixel_totali_cambiati = sum(pixel_cambiati(:));% Somma tutti gli 1
end