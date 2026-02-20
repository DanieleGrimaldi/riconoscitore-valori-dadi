function maschera_roi = trova_maschera_vassoio(img_sfondo)
    % --- CONFIGURAZIONE ---
    SOGLIA_SATURAZIONE = 0.25; % Sotto = Grigio (Vassoio), Sopra = Colore (Legno/Dadi)
    MARGINE_LATERALI   = 40;   % Pixel da tagliare SOLO a sinistra e destra
    
    % 1. Analisi Colore (HSV - Canale Saturazione)
    hsv = rgb2hsv(img_sfondo);
    sat = hsv(:,:,2);
    
    % 2. Maschera Binaria Iniziale
    % 1 = Sembra Vassoio, 0 = Sembra Legno
    mask = sat < SOGLIA_SATURAZIONE;
    
    % 3. ANALISI PER COLONNE (La chiave della soluzione)
    % Calcoliamo la media di "grigio" per ogni colonna verticale.
    % Risultato: un vettore riga (1 x LarghezzaImmagine)
    profilo_orizzontale = mean(mask, 1); 
    
    % 4. Determiniamo quali colonne sono "Vassoio"
    % Se più del 50% della colonna è grigia, allora siamo nel vassoio.
    % Questo ignora completamente un dado che tocca il bordo, perché 
    % il dado è piccolo rispetto all'altezza totale dell'immagine.
    colonne_vassoio = profilo_orizzontale > 0.5;
    
    % 5. Troviamo l'inizio e la fine del vassoio (Asse X)
    indici_validi = find(colonne_vassoio);
    
    if isempty(indici_validi)
        warning('Vassoio non rilevato! Restituisco maschera vuota.');
        maschera_roi = false(size(mask));
        return;
    end
    
    x_inizio = indici_validi(1);
    x_fine   = indici_validi(end);
    
    % 6. Applicazione Margine di Sicurezza (Erosione Manuale)
    % Restringiamo i bordi laterali per non includere pezzetti di legno
    x_inizio = x_inizio + MARGINE_LATERALI;
    x_fine   = x_fine   - MARGINE_LATERALI;
    
    % Controllo limiti (per non crashare se l'immagine è stretta)
    x_inizio = max(1, x_inizio);
    x_fine   = min(size(mask, 2), x_fine);
    
    % 7. Creazione Maschera Finale
    % Creiamo una maschera tutta nera...
    maschera_roi = false(size(mask));
    
    % ...e accendiamo TUTTE le righe (da 1 a end) ma solo nelle colonne valide.
    maschera_roi(:, x_inizio:x_fine) = true;
end