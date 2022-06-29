# Relazione dell’Elaborato
## Architettura degli Elaboratori 2021 / 2022

# Indice
1. [Specifiche](#Specifiche)
2. [Architettura generale del circuito](#Architettura-generale-del-circuito)
3. [Diagramma della macchina a stati finiti](#Diagramma-della-macchina-a-stati-finiti)
4. [Architettura del Data-Path](#Architettura-del-DataPath)
   - [Elaboratore del valore di pH](#Elaboratore-del-valore-di-pH)
   - [Contatore dei cicli di clock](#Contatore-dei-cicli-di-clock)
5. [Statistiche del circuito](#Statistiche-del-circuito)
   - [Prima dell’ottimizzazione](#Prima-dell’ottimizzazione)
   - [Dopo l’ottimizzazione](#Dopo-l’ottimizzazione)
6. [Mapping: gate e ritardi](#Mapping-gate-e-ritardi)
7. [Scelte progettuali](#Scelte-progettuali)



## Specifiche
Si progetti il circuito sequenziale che controlla un macchinario chimico il cui scopo è portare una soluzione iniziale a pH noto, ad un pH di neutralità. Il valore del pH viene espresso in valori compresi tra 0 e 14.
Il circuito controlla due valvole di erogazione: una di soluzione acida e una di soluzione basica.
Se la soluzione iniziale è acida, il circuito dovrà procedere all’erogazione della soluzione basica fintanto che la soluzione finale non raggiunga la soglia di neutralità (pH compreso tra 7 e 8).
Analogamente, se la soluzione iniziale è basica, il circuito procederà all’erogazione di soluzione acida fino al raggiungimento della soglia di neutralità.
Per pH acido si intende un valore strettamente inferiore a 7, mentre per basico si intende una soluzione con pH strettamente maggiore a 8.
Il pH viene codificato in fixed-point, con 4 bit riservati per la parte intera e gli altri per la parte decimale. 
Le due valvole hanno flussi differenti di erogazione. 
La valvola relativa alla soluzione basica eroga una quantità di soluzione che permette di alzare il pH della iniziale di 0.25 ogni ciclo di clock. 
La valvola relativa alla soluzione acida eroga una quantità di soluzione che permette di abbassare il pH della soluzione iniziale di 0.5 ogni ciclo di clock. 

Il circuito ha 3 ingressi nel seguente ordine:
- `RST` (1 bit)
- `START`(1 bit)
- `pH` (8 bit, 4 parte intera e 4 per la parte decimale)
Gli output sono i seguenti e devono seguire il seguente ordine:
- `FINE_OPERAZIONE` (1 bit)
- `ERRORE_SENSORE` (1 bit)
- `VALVOLA_ACIDO` (1 bit)
- `VALVOLA_BASICO` (1 bit)
- `PH_FINALE` (8 bit)
- `NCLK` (8 bit)

Input e output devono essere definiti nell’ordine sopra specificato (da sinistra verso destra). Le porte con più bit devono essere descritte utilizzando la codifica con il bit più significativo a sinistra.
Il meccanismo è guidato come segue:
Quando il segnale `RST` viene alzato, il sistema torna da un qualsiasi stato allo stato di `RESET`, mettendo tutte le porte in output a zero.
Per procedere, Il sistema riceve in input il segnale di `START`, con valore 1, e il segnale del `pH` iniziale per un solo ciclo di clock. Il sistema potrà quindi procedere con la fase di elaborazione.
Se la soluzione iniziale è acida, viene aperta la valvola della soluzione basica, mettendo a 1 il relativo output. Analogamente, se la soluzione iniziale è basica, viene aperta la valvola della soluzione acida mettendo a 1 la porta `VALVOLA_ACIDO`.
Il sistema mantiene aperte le valvole per il tempo necessario al raggiungimento della soglia di neutralità (calcolata dal sistema).
Una volta terminata l’operazione, il sistema deve chiudere tutte le valvole aperte, riportare il pH finale sulla porta in output `PH_FINALE` e alzare la porta di `FINE_OPERAZIONE`.
La porta `NCLK` riporta quanti cicli di clock sono stati necessari per portare la soluzione a neutralità.
Se il valore del pH non è valido (> 14) il sistema deve riportare l’errore alzando l’output `ERRORE_SENSORE`.

Lo schema generale del circuito deve rispettare la FSMD riportata di seguito:

<img src="https://github.com/Francesco146/elaborato-sis/blob/main/images/image6.png?raw=true" width="530" height="350">

È possibile aggiungere degli ulteriori segnali interni per la comunicazione tra FSM e DATAPATH
Le porte di input e di output devono rispettare l’ordine definito ed essere collegate al rispettivo sotto modulo
Il DATAPATH deve essere unico: se volete definire più DATAPATH, questi devono essere inglobati in un unico modello.
E’ compito della FSM identificare se il pH della soluzione iniziale sia acido o basico

## Architettura generale del circuito
Il circuito è composto da una FSM (controllore) e un DATAPATH (elaboratore) che comunicano tra loro.
I file che contengono la rappresentazione di queste componenti sono presenti nella
cartella con i nomi di `fsm.blif` e `datapath.blif`.
Il file che permette il collegamento tra la macchina a stati finiti e l’elaboratore ha il nome di `FSMD.blif`.
Nelle pagine seguenti verranno descritte nel dettaglio analizzando le componenti
utilizzate.

## Diagramma della macchina a stati finiti
Il controllore del macchinario chimico è una macchina a stati finiti del tipo Mealy.
Si presentano i seguenti segnali:

| Segnali di input |  Segnali di output  |
|:----------------:|:-------------------:|
| RST[1]           |  FINE_OPERAZIONE[1] |
| START[1]         |  ERRORE_SENSORE[1]  |
| pH[8]            |  VALVOLA_ACIDO[1]   |
| FINE_datapath[1] |  VALVOLA_BASICO[1]  |
|                  | START_datapath[1]   |


La FSM presenta 5 stati:
- `RESET`: In questo stato si attende il comando di `START` e il `pH` iniziale della soluzione chimica. 
Nel momento in cui viene alzato `START` la FSM analizza il valore del pH iniziale e si sposta nel relativo stato. Le transizioni da questo stato sono molteplici, qui sotto elencate:
  - a `ERRORE`: se ci si trova con un valore pH non corretto, ovvero un valore di pH > 14 .
  - a `ACIDO`: se ci si trova con un valore di pH nel range 0 ≤ pH < 7. In questa transizione inoltre apriamo la valvola della soluzione basica e si comanda al Data-Path di iniziare l’elaborazione.
  - a `BASICO`:  se ci si trova con un valore di pH nel range 8 < pH ≤ 14. In questa transizione inoltre apriamo la valvola della soluzione acida e si comanda al Data-Path di iniziare l’elaborazione.
  - a `FINE`:  se ci si trova con un valore di pH già neutro, ovvero nel range 7 ≤ pH ≤ 8, in questo particolare caso il Data-Path non effettua elaborazioni e restituisce immediatamente il valore inserito.

- `ERRORE`: Qui si segnala che è avvenuto un errore e si attende finchè non viene ripristinato l’impianto.
- `ACIDO`: In questo stato viene mantenuta aperta la valvola che eroga la soluzione basica fino a quando il Data-Path, tramite il bit `FINE_datapath`, non segnala che si è raggiunta la neutralità.
- `BASICO`: In questo stato viene mantenuta aperta la valvola che eroga la soluzione acida fino a quando il Data-Path, tramite il bit `FINE_datapath`, non segnala che si è raggiunta la neutralità.
- `FINE`: Qui si comunica tramite il bit di `FINE_OPERAZIONE` che la soluzione ha raggiunto la neutralità e si rimane in attesa di un nuovo valore di `pH`. Il comportamento è simile allo stato di `RESET`, poiché è possibile effettuare una nuova sottomissione senza dover ripristinare l’impianto.

Infine in qualunque momento è possibile ripristinare il macchinario tramite il bit di `RESET`.

<img src="https://github.com/Francesco146/elaborato-sis/blob/main/images/image5.png?raw=true" width="600" height="430">



## Architettura del DataPath
Il Data-Path è composto da due sezioni:
- La prima, la più consistente, si occupa dell’elaborazione del valore del pH, ovvero l’aggiunta di sostanza acida o basica fino al raggiungimento della neutralità.
- La seconda invece conta i cicli di clock necessari per neutralizzare la soluzione.

### Elaboratore del valore di pH
Le componenti utilizzate sono:
- Un MULTIPLEXER (`MUX_PH_START`): questo multiplexer dotato di due ingressi a 8 bit ha la funzione di leggere il `pH` iniziale quando il valore di `START` è 1.
- due COMPARATORI e una porta AND: Questi due comparatori a 8 bit hanno il compito di determinare se il pH sia o no neutro. Il comparatore “Maggiore” prende in input il valore del pH e restituisce 1 se il pH è maggiore di 6.99. L’altro comparatore è una negazione del “Maggiore”. Così facendo si ottiene il “Minore Uguale”. Il risultato dei due comparatori verrà poi consumato da una porta logica AND per ottenere il segnale `FINE`.
- Un MULTIPLEXER (`MUX_PH_VA`): questo multiplexer dotato di due ingressi a 8 bit ha la funzione di leggere il valore della valvola acida e sottrarre dal pH iniziale 0.5 unità.
- Un MULTIPLEXER (`MUX_PH_VB`): questo multiplexer dotato di due ingressi a 8 bit ha la funzione di leggere il valore della valvola basica e portarla verso la neutralità sommando 0.25 unità al pH iniziale.
- Un REGISTRO (`REG_PH`): la funzione di questo registro a 8 bit è di mantenere in memoria il valore di pH modificato.
- Un SOMMATORE e un SOTTRATTORE: questi due circuiti hanno il compito di sommare 0.25 unità di pH o sottrarre 0.5 unità di pH dal valore pH in ingresso.
- Un MULTIPLEXER (`MUX_PH_DIPLAY`): serve a mostrare il risultato. Il selettore è il bit `FINE_OPERAZIONE` proveniente dalla FSM.

<img src="https://github.com/Francesco146/elaborato-sis/blob/main/images/image9.png?raw=true" width="620" height="900">


### Contatore dei cicli di clock
Le componenti utilizzate sono:
- Un SOMMATORE: serve ad incrementare di uno il contatore. Riceve in input il valore in uscita di `MUX_START_CLK`.
- Un MULTIPLEXER (`MUX_CLK_FINE`): ha lo scopo di mantenere il contatore invariato nel caso la soluzione fosse arrivata a neutralità. Questo MUX ha due ingressi ad 8 bit codificati in modulo. Riceve in ingresso il valore di ritorno di `MUX_CLK_START` e il valore in uscita del SOMMATORE. Il selettore è il bit `FINE` proveniente dall’elaboratore del pH.
- Un REGISTRO (`REG_CLK`):  la funzione di questo registro a 8 bit è di mantenere in memoria il contatore relativo ai cicli di clock trascorsi.
- Un MULTIPLEXER (`MUX_CLK_START`): serve ad azzerare il contatore e ha come input il valore contenuto nel registro `REG_CLK` e la costante 0. Il selettore è il bit START proveniente dalla FSM.
- Un MULTIPLEXER (`MUX_CLK_DIPLAY`): serve a mostrare il risultato. Il selettore è il bit `FINE_OPERAZIONE` proveniente dalla FSM.


## Statistiche del circuito
### Prima dell’ottimizzazione
Le statistiche del circuito prima di effettuare l’ottimizzazione indicano:

<img src="https://github.com/Francesco146/elaborato-sis/blob/main/images/image7.png?raw=true" width="600" height="100">

- Numero di nodi: 224
- Numero di letterali: 1888
### Dopo l’ottimizzazione
L’ottimizzazione è stata eseguita lanciando tre volte il comando `source script.rugged` che permette la distruzione e ricostruzione della FSMD.
<img src="https://github.com/Francesco146/elaborato-sis/blob/main/images/image8.png?raw=true" width="600" height="250">
- Numero di nodi: 71
- Numero di letterali: 282

## Mapping gate e ritardi
Dopo aver ottimizzato il circuito lo si mappa così da visualizzare le statistiche verosimili riguardo area e ritardo. È stata assegnata la libreria `synch.genlib`.
Il circuito mappato presenta le seguenti statistiche:

<img src="https://github.com/Francesco146/elaborato-sis/blob/main/images/image11.png?raw=true" width="520" height="600">


Il `total gate area` (area) è 5960.00 mentre l’`arrival time` (cammino critico) è 49.80. 

## Scelte progettuali
- È stato introdotto un segnale `DISPLAY` che ha lo scopo di mostrare il risultato del datapath solo quando si è nello stato di `FINE`.
- Il sistema rimane nello stato di `ERRORE` fino al compiuto `RESET` del circuito. Questo impedisce di poter elaborare una sostanza senza aver ripristinato in modo corretto l’impianto.
- Per velocizzare il processo di elaborazione della sostanza chimica è possibile richiedere una nuova elaborazione direttamente dallo stato di `FINE`, senza dover resettare il macchinario ad ogni iterazione.
- Nella macchina a stati finiti l’input `FINE_datapath` è a `don’t care` ovunque tranne nelle transizioni che originano dagli stati `ACIDO` e `BASICO` perchè il segnale è rilevante solo quando il datapath sta effettivamente processando un pH basico/acido. In questo modo si ottiene un circuito con una minore area.
- Durante la progettazione ci siamo scontrati con diverse implementazioni per quanto riguarda il datapath in modo da raggiungere l’area minima. Di seguito riportiamo le due implementazioni alternative che davano un ritardo minore ma un’area maggiore.

<img src="https://github.com/Francesco146/elaborato-sis/blob/main/images/image12.png?raw=true" width="600" height="200">

