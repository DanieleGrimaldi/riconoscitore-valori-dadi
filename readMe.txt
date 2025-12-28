per trovare i frame ho inizialmente spostato la mia immagine nello spazio lab é ho calcolato la differenza tra i pixel del frame precedente e di quello attuale.
se mi ritrovavo sotto ad una soglia allora i pixel erano uguali e segnavo 0 altrimenti 1 successivamente sommavo i pixel cambiati.
ottenuto questo valore con una soglia vedevo se le immagini erano simili.
se erano simili aumentavo un contatore altrimenti lo azzeravo.
quando il contatore arrivava a 35 salvavo l'immagine ed andavo avanti.
l'esecuzione non era nemmeno troppo cattiva ho trovato tutti i lanci ma mi portavo a dietro le immagini dello sfondo e le tempistiche per tutti e 10 i video erano di circa 15/20 min.
ho successivamente provato una resize all'inizio di 0.25 aumentando subito un notevole miglioramento all'incirca 1:30, fino ad arrivare alla soluzione attuale con una riduzione dello 0,625 e guardando solamente un frame su 2 ottenendo un tempo di 45 secondi.
successivamente ho notato che il primo frame ha sempre come soggetto lo sfondo, cosi ho deciso di salvarlo in una variabile e confrontarlo con l'immagine che stavo salvando in modo da eliminare tutti i frame di sfondo.


cart su dati di training                 
TABELLA RISULTATI (PIXEL)
------------------------------------------------------------
                  | PREDETTO: SFONDO | PREDETTO: DADO
------------------|------------------|------------------
REALE: SFONDO     |      6265439     |         3196
                  | (Corretti)       | (Errori)
------------------|------------------|------------------
REALE: DADO       |         9229     |       576845
                  | (Errori)         | (Corretti)
------------------------------------------------------------

Il modello riconosce il 99.95% dello sfondo correttamente.
Il modello riconosce il 98.43% dei dadi correttamente. 


bilanciando con il random 

                TABELLA RISULTATI (PIXEL)
------------------------------------------------------------
                  | PREDETTO: SFONDO | PREDETTO: DADO
------------------|------------------|------------------
REALE: SFONDO     |       584447     |         1627
                  | (Corretti)       | (Errori)
------------------|------------------|------------------
REALE: DADO       |         4644     |       581430
                  | (Errori)         | (Corretti)
------------------------------------------------------------

Il modello riconosce il 99.72% dello sfondo correttamente.
Il modello riconosce il 99.21% dei dadi correttamente.


test su dati di test 

MATRICE DI CONFUSIONE (Totale Pixel):
				| Reale: DADO 	| Reale: SFONDO
Predetto: DADO 	| TP: 100189 	| FP: 37690
Predetto: SFONDO	| FN: 11774 	| TN: 7223147
----------------------------------------
METRICHE CHIAVE:
Accuracy:  99.33%
IoU:       0.6695 (Obiettivo > 0.7)
Precision: 72.66% (Affidabilità rilevamento)
Recall:    89.48% (Capacità di non perdere dadi)


con post processing
========================================
RISULTATI TEST SU 8 FILES
========================================
MATRICE DI CONFUSIONE (Totale Pixel):
				| Reale: DADO 	| Reale: SFONDO
Predetto: DADO 	| TP: 102792 	| FP: 19834
Predetto: SFONDO	| FN: 9171 	| TN: 7241003
----------------------------------------
METRICHE CHIAVE:
Accuracy:  99.61%
IoU:       0.7799 (Obiettivo > 0.7)
Precision: 83.83% (Affidabilità rilevamento)
Recall:    91.81% (Capacità di non perdere dadi)