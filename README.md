# pgpwaves
Send PGP encrypted stuff via sound waves

This is based on the excellent

http://www.whence.com/minimodem/

By Kamal Mostafa.

## Prerequisites
- Linux
- Alsa
- Minimodem

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

## How to use
- The idea is to establish a duplex audio path between two machines in order to securely send a text file from A to B.
- You may connect two PC's via audio cables (audio out --> mic in | and vice-versa)
- You may establish a VOIP call (preferred codec: u-law)
- You may use a couple of Walkie-talkies
- You may use telephone landline
- You may use cellular or Whatsapp call

## Syntax
`./pgpwaves.sh [-f, --file FILENAME] [-p, --passphrase PASSPHRASE] [-r, --rate BAUD]`

## Example
- Establish the audio path first
- Check volumes with alsamixer

- On the sending end:

Prepare a text file to be sent:

`$ man -P cat cat >cat-manpage.txt`

- Send it:

`$ ./pgpwaves.sh --rate 1200 --file cat-manpage.txt --passphrase statesecrets101`

- On the receiving end:

`$ ./pgpwaves.sh --rate 1200 --passphrase statesecrets101`

- The script waits for remote party to be ready
- Cyphertext is sent line by line
- After 5 retransmissions of the same line, RX party is cosidered dead
- After 20 seconds of inactivity, TX party is cosidered dead
- A final sha256sum is made to check integrity

## Security considerations
- Sender and receiver stations should be airgapped to render any bugging ineffective (eg: software keylogger).
- By "airgapped" I simply mean "without any connection to any network"
- If the passphrase is kept secret, no MITM should be possible so you won't have to trust the VOIP service provider for example.
- The passphrase must be known beforehand and should never be transmitted via any digital communication medium.
- I'm not a crypto guy, I'm not implying this is totally secure, I'm here to discuss and learn so ANY COMMENT, EVEN THE ONES SUGGESTING THAT THIS SOLUTION IS ABSOLUT BULLSHIT WILL BE WELCOME.
- I'd like to build a small device that acts as a Bluetooth handset pairing with your phone and send/receive audio via BT. Would that compromise security?

Thank you very much,
Telefonorosso
