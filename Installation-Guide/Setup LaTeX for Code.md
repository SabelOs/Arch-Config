install texlive on system:
sudo pacman -S texlive-meta
(this includes almost everything one could ever need for latex compilation)

Install latex-workshop in code

put the hint to root file on top of .tex file you want to compile:
% !TEX root = .main.tex