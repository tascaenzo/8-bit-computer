# Graphite Notebook

Un quaderno a quadretti con scrittura a matita: carta avorio, griglia azzurra leggera, margine rosso spento, tre fori e schizzi grafite. Non usare colori saturi, card digitali o titoli geometrici salvo richiesta esplicita di rebranding.

## Fondazioni

- Canvas 1600 × 900; griglia 28 px; margine verticale rosso a x=132 px.
- Contenuto da x=192 a x=1514, header y=62, footer a 35 px dal fondo.
- Caveat locale in `fonts/Caveat.ttf`, pesi 400–700. Titoli 82–117 px (copertina 112 px), corpo 31–36 px, caption 22–28 px. La licenza SIL OFL è inclusa in `fonts/OFL.txt`: conservarla distribuendo il font.
- Carta #f7f3e8; grafite #393832; secondario #5c584f; griglia #adc6d1 al 34%; margine #cd9992.
- Rotazioni leggere (0.5–2 gradi) e tratti duplicati imperfetti per l’effetto matita. La texture usa SVG inline e non richiede rete.

## Layout e personalizzazione

Otto slide: copertina con lampadina e matita, agenda, testo e foto applicata con nastro, tre indicatori, confronto, processo, citazione e chiusura. Sostituire i campi tra parentesi quadre e il titolo dimostrativo della copertina. Le etichette narrative in minuscolo fanno parte del tono, ma si possono adattare.

I dati XX sono segnaposto. La citazione non è una testimonianza reale. Per la foto, sostituire `.photo-inner` con un'immagine con alt descrittivo; conservarne riquadro e didascalia. Per duplicare slide con SVG che hanno ID, aggiornare gli ID e i riferimenti; le decorazioni attuali non hanno ID condivisi. Aggiornare i contatori manuali.

Navigazione e stampa sono gestite dal runtime locale deck-stage di Zara Zhang (MIT). Il template funziona offline con tutti i file della cartella. Non è un PPTX.

Le anteprime in galleria sono illustrazioni statiche con gli stessi elementi visivi, non screenshot del rendering HTML. La verifica strutturale non certifica l'assenza di overflow nel browser.

Impostare esplicitamente `color: var(--graphite)` e `font-family: var(--hand)` sulle slide: il runtime deck-stage ha un colore bianco e un font sans-serif sul proprio host che altrimenti vengono ereditati. Testo secondario #5c584f; corpo peso 500 per leggibilità.
