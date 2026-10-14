# Collegamento di moduli TXS0108E alla scheda video

14 ottobre 2026. Variante di prototipo da collaudare, non sostituzione gia'
verificata dell'interfaccia con partitori/HCT244. Le posizioni fisiche sui
moduli dipendono dal PCB acquistato: usare le sigle, non l'ordine dei piedini.

## Funzionamento e alimentazioni

Ogni modulo traduce otto linee, ciascuna fra `An` e `Bn`, riconoscendo
automaticamente la direzione. Non ha DIR. `VCCA` va a 3,3 V e `VCCB` a 5 V;
GND e' comune con CPU e Tang. Sul modulo possono comparire anche le sigle
VA/VB o LV/HV: verificarne la corrispondenza prima di alimentarlo.

```text
Tang Nano 9K, 3,3 V       Modulo TXS0108E          CPU HC, 5 V

3V3 -------------------- VCCA
                                                 +5 V
                         VCCB ---------------------+
GND -------------------- GND -------------------- GND

GPIO D0 ---------------- A1 <-----> B1 ----------- bus D0
GPIO D1 ---------------- A2 <-----> B2 ----------- bus D1
GPIO D2 ---------------- A3 <-----> B3 ----------- bus D2
GPIO D3 ---------------- A4 <-----> B4 ----------- bus D3
GPIO D4 ---------------- A5 <-----> B5 ----------- bus D4
GPIO D5 ---------------- A6 <-----> B6 ----------- bus D5
GPIO D6 ---------------- A7 <-----> B7 ----------- bus D6
GPIO D7 ---------------- A8 <-----> B8 ----------- bus D7
```

In scrittura la CPU pilota B e la FPGA riceve A. In lettura video valida
la FPGA pilota A e la CPU riceve B. La logica CPU deve disabilitare i propri
driver dati durante la lettura; il traduttore non arbitra il bus.
Togliere partitori e HCT244 dalle otto linee sostituite dal modulo.
Non mantenere due percorsi di traduzione attivi in parallelo.

## OE: abilita entrambe le direzioni

`OE=0` disabilita tutte le otto linee; `OE=3,3 V` le abilita. OE non sceglie
la direzione e non equivale alla selezione della VRAM.

Per una prima prova con controllo manuale:

```text
3V3 ---- interruttore / jumper ----+---- OE
                                  |
                                10 kΩ
                                  |
                                 GND
```

Tenere aperto il jumper fino a quando le due alimentazioni sono stabili,
la FPGA e' configurata e LED1 indica memoria pronta e la CPU e' in pausa a bus inattivo;
poi chiuderlo prima di avviare la CPU. OE puo' restare alto per l'intera
prova con entrambe le alimentazioni presenti. Aprirlo prima di spegnere
una delle due parti. Verificare eventuali pull-up/jumper OE gia' sul modulo:
il disegno presuppone che OE sia accessibile e non forzato alto dal PCB.
I condensatori di bypass su VCCA/VCCB devono essere presenti sul modulo.

**Questa variante TXS non e' la scelta finale del progetto.** La build del
14 ottobre usa SN74LVC8T245 con /OE al pin 32 e DIR al pin 63. Il TXS ha
OE attivo alto, quindi non collegarlo direttamente a `cpu_buffer_oe_n`.
Il controllo automatico TXS non e' stato verificato; lo schema qui usa
l'abilitazione manuale indipendente. Il pin 32 resta scollegato in questa
variante, e anche il DIR al pin 63 non si collega al TXS.
L'indicazione memoria pronta e' ora sul LED1 onboard, non sul pin 63.

## Quattro moduli per l'interfaccia CPU

| Modulo | Lato B a 5 V | Lato A a 3,3 V |
| --- | --- | --- |
| 1 | A0–A7 del bus indirizzi CPU | `cpu_addr[0]`–`cpu_addr[7]` FPGA |
| 2 | A8–A15 del bus indirizzi CPU | `cpu_addr[8]`–`cpu_addr[15]` FPGA |
| 3 | D0–D7 del bus dati CPU | `cpu_data[0]`–`cpu_data[7]` FPGA |
| 4 | `/RD`, `/WR`, `CPU_ENABLE` | `cpu_rd_n`, `cpu_wr_n`, `cpu_enable` FPGA |

Sul modulo 4 usare, ad esempio, canali 1, 2 e 3 rispettivamente per RD,
WR ed ENABLE. I canali rimanenti non si collegano al bus. Non collegare
il GPIO 10 (LED1, livello 1,8 V) a un lato A alimentato a 3,3 V.

Tutti i moduli hanno VCCA=3,3 V, VCCB=5 V e massa comune; per la prima prova
i loro OE possono condividere l'abilitazione manuale a 3,3 V. `CPU_ENABLE`
sulla FPGA deve mantenere lo stato inattivo quando l'interfaccia e' isolata,
come previsto nel cablaggio principale. Non usare un GPIO senza stato definito.

La sigla A del TXS indica il **lato a bassa tensione**, non il bus indirizzi:
per esempio A1 sul primo modulo si collega al GPIO `cpu_addr[0]` e B1
all'indirizzo CPU A0. Il pinout Tang resta quello nel
[README FPGA](../hardware/tang-nano-9k-video/README.md#pinout-cpu).
I due moduli indirizzi e quello controlli traducono segnali solo CPU → FPGA,
anche se il chip e' bidirezionale.

## Limiti della prova

Il costo basso e il modulo saldato semplificano il montaggio, ma non
garantiscono la compatibilita' con la capacita' di un bus su breadboard.
Usare collegamenti corti e verificare fronti, livelli e turnaround con
oscilloscopio. Il clock CPU lento non elimina oscillazioni sui fronti.
Il decoder RAM locale, il contratto temporale CPU e l'esclusione delle
periferiche condivise sulla Tang restano necessari.

Riferimento: [datasheet TI TXS0108E](https://www.ti.com/lit/ds/symlink/txs0108e.pdf),
sezioni 7.3.2–7.3.5 e 8.2, per carico, enable e resistenze interne.
