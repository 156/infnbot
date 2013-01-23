infnbot
=======

Infinity Network IRC Bot based on POE::Component::IRC and AI::MegaHAL

First copy megahal.brn megahal.trn and megahal.dic to the working directory of your bot

These can be found in ~/.megahal/ after running megahal for the first time.

If you need to install megahal on debian just type sudo apt-get install megahal

You might also need to do the following:

sudo apt-get install cpanm
sudo cpanm POE::Component::IRC
sudo cpanm AI::MegaHAL


Then edit infbot.config and run infnbot.pl
