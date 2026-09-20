# Indice delle specifiche FPGA

> **Versione:** 1.0
> **Data:** 3 settembre 2026

La Tang Nano 9K e' il dispositivo programmabile che collega la CPU TTL ai
sottosistemi video, tastiera e timer. Le specifiche inizialmente raccolte in
questo file sono state divise per rendere indipendenti firmware, test e
cablaggio dei due blocchi.

- [Specifica video HDMI](video-hdmi.md): VRAM, formato delle celle, protocollo
  di bus e uscita HDMI.
- [Specifica I/O, PS/2 e timer](io-ps2-timer.md): registri memory-mapped,
  conversione PS/2 e timer.

## Convenzioni comuni

La CPU espone `A[15:0]`, `D[7:0]`, `/RD`, `/WR` e `CLK_CPU`. Le periferiche
sono **memory-mapped**: il software usa `LDA` e `STA`, non le istruzioni `IN`
e `OUT`.

| Intervallo | Proprietario | Riferimento |
| --- | --- | --- |
| `0x0000-0x3FFF` | RAM/ROM di sistema | piattaforma CPU |
| `0x4000-0x7FFF` | VRAM Tang Nano 9K | [video](video-hdmi.md#3-mappa-e-semantica-della-vram) |
| `0x8000-0xFEFF` | riservato | espansioni future |
| `0xFF00-0xFF0F` | registri Tang Nano 9K | [I/O](io-ps2-timer.md#2-mappa-dei-registri) |
| `0xFF10-0xFFFF` | riservato | espansioni future |

La Tang abilita le proprie uscite su `D[7:0]` soltanto per una lettura del suo
spazio di indirizzi. Durante ogni scrittura la CPU rimane l'unico pilota del
bus dati.

## Vincoli elettrici comuni

La CPU TTL e la Tang Nano 9K non devono essere collegate pin-a-pin. Tutti i
segnali CPU -> FPGA passano attraverso traslatori di livello da 5 V a 3,3 V;
`D[7:0]` usa inoltre un transceiver bidirezionale con uscita disabilitabile.
Il suo `OE` e' controllato da `FPGA_D_OE` e puo' essere attivo solo in una
lettura FPGA selezionata. Le masse devono essere comuni.

I pin concreti del connettore 2x24 e le rispettive banche I/O non fanno parte
di questa ABI: vanno assegnati nel file `.cst` dopo verifica sullo schema della
revisione fisica posseduta. Evitare JTAG, `MODE0/1` e `DONE`; rispettare la
tensione della banca. La documentazione Sipeed segnala espressamente che i
GPIO non possono superare la tensione indicata nello schema e che le linee
HDMI hanno pull-up propri.

Riferimenti hardware: [Tang Nano 9K Sipeed](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K) e [progetto HDMI ufficiale](https://github.com/sipeed/TangNano-9K-example/tree/main/hdmi).
