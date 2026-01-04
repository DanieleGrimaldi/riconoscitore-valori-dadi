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
RISULTATI TEST SU 32 FILES
========================================
MATRICE DI CONFUSIONE (Totale Pixel):
				| Reale: DADO 	| Reale: SFONDO
Predetto: DADO 	| TP: 502649 	| FP: 80323
Predetto: SFONDO	| FN: 45359 	| TN: 28862869
----------------------------------------
METRICHE CHIAVE:
Accuracy:  99.57%
IoU:       0.8000 (Obiettivo > 0.7)
Precision: 86.22% (Affidabilità rilevamento)
Recall:    91.72% (Capacità di non perdere dadi)


bilanciando con il random 

MATRICE DI CONFUSIONE (Totale Pixel):
				| Reale: DADO 	| Reale: SFONDO
Predetto: DADO 	| TP: 521146 	| FP: 144939
Predetto: SFONDO	| FN: 26862 	| TN: 28798253
----------------------------------------
METRICHE CHIAVE:
Accuracy:  99.42%
IoU:       0.7521 (Obiettivo > 0.7)
Precision: 78.24% (Affidabilità rilevamento)
Recall:    95.10% (Capacità di non perdere dadi)


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

con features texture
train 
MATRICE DI CONFUSIONE (Totale Pixel):
				| Reale: DADO 	| Reale: SFONDO
Predetto: DADO 	| TP: 513956 	| FP: 48289
Predetto: SFONDO	| FN: 34052 	| TN: 28894903
----------------------------------------
METRICHE CHIAVE:
Accuracy:  99.72%
IoU:       0.8619 (Obiettivo > 0.7)
Precision: 91.41% (Affidabilità rilevamento)
Recall:    93.79% (Capacità di non perdere dadi)

test
MATRICE DI CONFUSIONE (Totale Pixel):
				| Reale: DADO 	| Reale: SFONDO
Predetto: DADO 	| TP: 104586 	| FP: 10699
Predetto: SFONDO	| FN: 7377 	| TN: 7250138
----------------------------------------
METRICHE CHIAVE:
Accuracy:  99.75%
IoU:       0.8526 (Obiettivo > 0.7)
Precision: 90.72% (Affidabilità rilevamento)
Recall:    93.41% (Capacità di non perdere dadi)


 RISULTATI train knn riconoscimento cifra semi pulito
========================================
Totale Immagini:    226
Corrette:           148
ACCURACY:           65.49%
----------------------------------------

test 
========================================
Totale Immagini:    46
Corrette:           24
ACCURACY:           52.17%
----------------------------------------