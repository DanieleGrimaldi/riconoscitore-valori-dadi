per trovare i frame ho inizialmente spostato la mia immagine nello spazio lab é ho calcolato la differenza tra i pixel del frame precedente e di quello attuale.
se mi ritrovavo sotto ad una soglia allora i pixel erano uguali e segnavo 0 altrimenti 1 successivamente sommavo i pixel cambiati.
ottenuto questo valore con una soglia vedevo se le immagini erano simili.
se erano simili aumentavo un contatore altrimenti lo azzeravo.
quando il contatore arrivava a 35 salvavo l'immagine ed andavo avanti.
l'esecuzione non era nemmeno troppo cattiva ho trovato tutti i lanci ma mi portavo a dietro le immagini dello sfondo e le tempistiche per tutti e 10 i video erano di circa 15/20 min.
ho successivamente provato una resize all'inizio di 0.25 aumentando subito un notevole miglioramento all'incirca 1:30, fino ad arrivare alla soluzione attuale con una riduzione dello 0,625 e guardando solamente un frame su 2 ottenendo un tempo di 45 secondi.
successivamente ho notato che il primo frame ha sempre come soggetto lo sfondo, cosi ho deciso di salvarlo in una variabile e confrontarlo con l'immagine che stavo salvando in modo da eliminare tutti i frame di sfondo.


