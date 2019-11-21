#!/bin/bash

### ARGUMENT PARSING
POSITIONAL=(); while [[ $# -gt 0 ]]; do key="$1"
case $key in
-f|--file) FILE="$2"; shift; shift ;;
-p|--passphrase) PASS="$2"; shift; shift ;;
-r|--rate) RATE="$2"; shift; shift ;;
*) POSITIONAL+=("$1"); shift ;;
esac; done; set -- "${POSITIONAL[@]}"


### ENCODER MODE BREAK
encbrk () {
echo "TERMINATING"
while pidof minimodem >/dev/null; do sleep 1; done
echo BRK | gpg -c --batch --passphrase $1 -o - | base64 -w0 | \
awk '{printf "----"$1}' | minimodem --alsa=plughw:0,0 --tx 1200
exit 1 ; }


### DECODER MODE BREAK
decbrk () {
echo "TERMINATING"
while pidof minimodem >/dev/null; do sleep 1; done
yes "BRK" | head -n 200 | minimodem --alsa=plughw:0,0 --tx 1200
exit 1 ; }


### TERMINAL SYNCING
wait_4_remote () {
echo "Waiting for remote terminal to be ready..."
while true; do
yes "TRRDY" | head -n 100 | minimodem --alsa=plughw:0,0 --tx 1200 2>/dev/null &
RETVAL=$(timeout 1 minimodem -q --alsa=plughw:0,0 --print-filter --rx 1200)
if echo $RETVAL | grep -q TRRDY; then echo "READY"; break; fi
done ; }


### SEND ROUTINE
send_routine () {
E=0
while pidof minimodem >/dev/null; do sleep 1; done
while read line; do
((I=I+1))
for ITER in 1 2 3 4 5; do
echo "sending line $I try $ITER..."
echo "$line" | gpg -c --batch --passphrase $2 -o - | base64 -w0 | awk '{printf "----"$1}' | minimodem --alsa=plughw:0,0 --tx $3 2>/dev/null
RETVAL=$(timeout 2 minimodem -q --alsa=plughw:0,0 --print-filter --rx 1200)
if echo $RETVAL | grep -q ACK; then sleep 1; break; else ((E=E+1)); fi
if echo $RETVAL | grep -q BRK; then echo "REMOTE GAVE UP"; exit 1; fi
done
if [[ $ITER = "5" ]]; then echo "REMOTE IS LOST"; exit 1; fi
done <$1
echo "EOF $(sha256sum $1)" | gpg -c --batch --passphrase $2 -o - | base64 -w0 | awk '{printf "----"$1}' | minimodem --alsa=plughw:0,0 --tx 1200
echo "TXERR : $E" ; }


### RECEIVE ROUTINE
recv_routine () {
while pidof minimodem >/dev/null; do sleep 1; done
echo -n >/run/plaintext
while true; do
XL="$L"
L=$(timeout 20 minimodem -q --alsa=plughw:0,0 --sync-byte 0x2D --rx-one --print-filter --rx $2 | base64 -d | gpg -q --decrypt --batch --yes --passphrase $1 -)
if [ $? -eq 0 ]; then
yes "ACK" | head -n 20 | minimodem --alsa=plughw:0,0 --tx 1200
if [[ "$L" == "BRK" ]]; then echo "REMOTE GAVE UP"; exit 1; fi
if [[ "$XL" != "$L" ]]; then echo "$L" | tee -a /run/plaintext; fi
if echo $L | grep -q "EOF "; then break; fi
else
echo "REMOTE IS LOST"; exit 1
fi
done ; }


### HASH COMPARE
compare () {
sum_remote=$(tail -n1 /run/plaintext | cut -d' ' -f2); sed -i '$ d' /run/plaintext
sum_local=$(sha256sum /run/plaintext | cut -d' ' -f1)
if [[ "$sum_remote" == "$sum_local" ]]; then
echo "SHA256SUM OK"; else
echo "INTEGRITY CHECK FAILED"; fi ; }


### MAIN LOOP
trap "rm -f /run/plaintext" EXIT
if [ -z "$RATE" ]; then echo "Using default rate 1200 baud"; RATE="1200"; fi
if [ -z "$PASS" ]; then echo "Passphrase not supplied. QUITTING"; exit 1; fi
if [ -z "$FILE" ]; then
echo "Decoder mode"; trap "decbrk" INT; wait_4_remote; recv_routine $PASS $RATE; compare; exit 0; else
echo "Encoder mode"; trap "encbrk $PASS" INT; wait_4_remote; send_routine $FILE $PASS $RATE; exit 0; fi


### THIS SHOULD NEVER RUN
echo "EXCEPTION OCCURRED"
exit 1
