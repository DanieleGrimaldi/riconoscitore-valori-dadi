function diff_score = calcola_movimento(lab1, lab2)
    % Questa funzione riceve due immagini e restituisce un SOLO numero.
    % Più il numero è alto, più c'è movimento.
    % Più è vicino a 0, più la scena è ferma.

    % 2. Isoliamo i canali (Scartiamo la L)    
    a1 = lab1(:,:,2); 
    b1 = lab1(:,:,3);
    
    a2 = lab2(:,:,2); 
    b2 = lab2(:,:,3);

    % 3. Calcolo della Distanza (Teorema di Pitagora)
    distanza_pixel = sqrt( (a1 - a2).^2 + (b1 - b2).^2 );

    diff_score = mean(distanza_pixel(:));
end
