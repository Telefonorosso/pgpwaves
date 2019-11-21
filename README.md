# pgpwaves
Send PGP encrypted stuff via sound waves, based on the excellent http://www.whence.com/minimodem/ By Kamal Mostafa.


## Prerequisites
- Linux
- Alsa
- Minimodem
- A decent quality duplex audio communication between both parties


## Minimodem install on Ubuntu
`$ apt-get install minimodem`


## Minimodem build on Centos 7
```
$ yum install sox libsndfile libsndfile-devel alsa-utils alsa-lib alsa-lib-devel

$ yum groupinstall "Development tools"

$ yum install fftw fftw-devel

$ git clone https://github.com/kamalmostafa/minimodem.git

$ cd minimodem/

$ autoreconf -i

$ ./configure --without-pulseaudio

$ make && make install
```

## About
- The idea is to establish a duplex audio path between two machines in order to securely send a text file from A to B.
- You may connect two PC's via audio cables (audio out --> mic in | and vice-versa)
- You may establish a VOIP call (preferred codec: u-law)
- You may use a couple of Walkie-talkies
- You may use telephone landline
- You may use cellular or Whatsapp call


## Syntax
`./pgpwaves.sh [-f, --file FILENAME] [-p, --passphrase PASSPHRASE] [-r, --rate BAUD]`


# Example
- Establish the audio path first
- Check volumes with `alsamixer`

- On the sending end:

Prepare a text file to be sent:

`$ man -P cat cat >cat-manpage.txt`

- Send it:

`$ ./pgpwaves.sh --rate 1200 --file cat-manpage.txt --passphrase statesecrets101`

- On the receiving end:

`$ ./pgpwaves.sh --rate 1200 --passphrase statesecrets101`

- The script waits for remote party to be ready
- Cyphertext is sent line by line
- CTRL+C will stop transmission / reception
- After 5 retransmissions of the same line, RX party is cosidered dead
- After 20 seconds of inactivity, TX party is cosidered dead
- A final sha256sum is made to check integrity


## Theory of operation
The interesting lines in the scripts are this ones:

- Sending end:

`echo "$line" | gpg -c --batch --passphrase $2 -o - | base64 -w0 | awk '{printf "----"$1}' | minimodem --alsa=plughw:0,0 --tx $3`

The line is parsed | is encrypted with PGP and the supplied passphrase | is base64 encoded | is prepended with "----" to sync the receiving end | is FSK encoded and sent as audio signal.

- Receiving end:

`minimodem -q --alsa=plughw:0,0 --sync-byte 0x2D --rx-one --print-filter --rx $2 | base64 -d | gpg -q --decrypt --batch --yes --passphrase $1 -`

The audio is captured and FSK decoded | the "----" sync prefix is stripped | is base64 decoded | is decrypted with PGP and the supplied passphrase.

*NOTE: VIRTUALLY ANY TRANSMISSION ERROR WILL RESULT IN BASE64 BEING UNABLE TO DECODE AND PGP DECRYPTING FAILURE. DIRECT AUDIO LINK WITH CABLE WILL GIVE YOU 100% SUCCESS RATE, EVEN AT LOW VOLUMES. BUT WHAT WILL BE THE POINT OF SENDING ENCRYPTED MESSAGES AT 2 METERS DISTANCE? AUDIO DISTORTION (SENT TOO LOUD, LINE IN TOO SENSITIVE) WILL MAKE THINGS WORSE. I'VE MANAGED TO GET 80% SUCCESS RATE WITH A VOIP CALL USING THE U-LAW CODEC. FOR SOME REASON, 1.200 BAUD GIVES BEST RESULTS AND IT'S NOT INTOLERABLY SLOW.* 


## Security considerations
- Sender and receiver stations should be airgapped to render any bugging ineffective (eg: software keylogger).
- By "airgapped" I simply mean "without any connection to any network"
- If the passphrase is kept secret, no MITM should be possible so you won't have to trust the VOIP service provider for example.
- The passphrase must be known beforehand and should never be transmitted via any digital communication medium.
- I'm not a crypto guy, I'm not implying this is totally secure, I'm here to discuss and learn so ANY COMMENT, EVEN THE ONES SUGGESTING THAT THIS SOLUTION IS ABSOLUT BULLSHIT WILL BE WELCOME.
- I'd like to build a small device that acts as a Bluetooth handset pairing with your phone and send/receive audio via BT. Would that compromise security?


## Video demo
Demo'ing a very basic version of the script and VOIP setup:

https://drive.google.com/file/d/1_NUTUPkv1Z3cLVUW-j4tWaAW7Rwx3P6I/view
