%% Class file for writing Chalmers KAW proposals
%%
%% Compiled by Anders Logg (Mathematical Sciences) based
%% on a template proposal by Paul Erhart (Applied Physics).
%%
%% First added:  2013-11-06
%% Last changed: 2014-05-19
%%
%% Notes:
%%
%% - Document needs to be compiled with xelatex
%% - Document requires style file titlesec.sty
%% - Document requires font Linux Libertine
%% - Document requires some special math packages
%% - Use \section{} and \paragraph{} (skip \subsection{})
%%
%% On Debian/Ubuntu, these are available via the packages
%%
%%   texlive-xetex texlive-latex-extra texlive-fonts-extra texlive-math-extra

% Basic setup
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{kaw}
\LoadClass[11pt,a4paper,twoside,twocolumn]{article}

% Geometry
\usepackage[a4paper, margin=2.5cm, top=1.0cm, bottom=2.5cm]{geometry}
\setlength{\parindent}{0pt}
\setlength{\voffset}{0.8cm}
\pagestyle{empty}
\renewcommand{\indent}[0]{\hspace{10pt}}
\setlength{\parskip}{7pt}
\widowpenalty=500

% Colors
\usepackage{color}
\definecolor{ChalmersBlue}{cmyk}{1.00,.70,.00,.10}
\definecolor{ChalmersGray}{cmyk}{.25,.10,.10,.00}
\definecolor{ChalmersSilver}{RGB}{207,207,207}

% Fonts and section headings
\usepackage[compact]{titlesec}
\usepackage{titletoc}
\usepackage[no-math]{fontspec}
\defaultfontfeatures{Scale=MatchLowercase,Mapping=tex-text}
%\setmainfont[Ligatures={Common}]{Linux Libertine O}
\setmainfont[Ligatures={Common}]{Times New Roman}
\newfontfamily\sectitlefont{Times New Roman}
%\newfontfamily\sectitlefont{Times}
\titleformat{\section}
            {\vspace{-0.5em}\Large\bf\sectitlefont}
            {}{0em}{\vspace{-0.5em}}
\titleformat{\subsection}
            {\vspace{-0.5em}\large\bf\sectitlefont}
            {}{0em}{\vspace{-0.5em}}
\titleformat{\paragraph}[runin]
            {\vspace{-0.5em}\normalfont\normalsize\it\bfseries}
            {\theparagraph}{}{}

% Header and footer
\usepackage{fancyhdr}
\pagestyle{fancy}
\fancyhf{}
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0pt}
\newcommand{\lastpage}{100}
\rfoot{\small\sectitlefont \applicant\ | Research plan | \thepage/\lastpage}
\lhead{\setlength{\unitlength}{1mm}
  \begin{picture}(0,0)
    \put(0,-4){\includegraphics[width=\linewidth]{chalmers_header}}
  \end{picture}
  \hspace{2mm} \small\sectitlefont VR Project grant within natural and engineering sciences}

% Bibliography
\usepackage[]{natbib}
\setlength{\bibsep}{0pt}

% Some useful packages
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{stmaryrd}
\usepackage{graphicx}
\usepackage{url}
\usepackage{hyperref}

% Macro for title
\newcommand{\kawapplication}[3]{
  \twocolumn[
   \begin{center}
      {\color{ChalmersBlue}\Huge\bf\sectitlefont #1}

      %\bigskip

      %\begin{minipage}{0.9\textwidth}
      %  \textbf{\textit{Summary.}} #3
      %\end{minipage}
    \end{center}
  ]
  \newcommand{\applicant}{#2}
  \renewcommand{\lastpage}{\pageref{lastpage}}
}

% Macro for inserting notes
\newcommand{\fixme}[1]{%
  \noindent
  \begin{minipage}{0.5\textwidth}
    $\blacktriangleright$$\blacktriangleright$$\blacktriangleright$
    \emph{\textbf{FIXME:} #1}
\end{minipage}}

% Misc notation
\newcommand{\emp}[1]{\texttt{#1}}
\newcommand{\empb}[1]{\textbf{#1}}

% Macros for dummy text
\newcommand{\augustI}{Han kom som ett yrväder en aprilafton och hade
  ett höganäskrus i en svångrem om halsen. Clara och Lotten voro inne
  med sköt-ekan att hämta honom på Dalarö brygga; men det dröjde
  evigheter, innan de kommo i båt. De skulle till handelsman och ha en
  tunna tjära och på abeteket och hämta gråsalva åt grisen, och så
  skulle de på posten och få ett frimärke, och så skulle de ner till
  Fia Lövström i Kroken och låna tuppen mot ett halvpund småtärna till
  notbygget, och sist hade de hamnat på gästgivaregården, där Carlsson
  bjudit på kaffe med dopp. Och så kommo de äntligen i båt, men
  Carlsson ville styra, och det kunde han inte, för han hade aldrig
  sett en råseglare förr, och därför skrek han, att de skulle hissa
  focken, som inte fanns.}

\newcommand{\augustII}{Och på tullbryggan stodo lotsar och vaktmästare
  och grinade åt manövern, när ekan gick över stag och länsade ner åt
  Saltsäcken. Hörru, du har hål i båten!  skrek en lotslärling genom
  vinden; stopp till! stopp till! och medan Carlsson tittade efter
  hålen, hade Clara knuffat undan honom och tagit roret, och med
  årorna lyckades Lotten få ekan opp i vinden igen, så att nu strök
  det ner åt Aspösund med god gång.}

\newcommand{\augustIII}{Carlsson var en liten fyrkantig värmländing
  med blå ögon och näsa krokig som en syskonhake. Livlig, lekfull och
  nyfiken var han, men sjöaffärerna förstod han inte alls, och han var
  också kallad ut till Hemsö för att ta hand om åker och kreatur, som
  ingen annan ville ta befattning med, sedan gubben Flod gått ur livet
  och änkan satt ensam vid gården. Men när Carlsson nu ville börja
  pumpa flickorna om ställningar och förhållanden, så fick han riktiga
  skärkarlssvar: — Ja si, det vet jag inte! Ja si, det kan jag inte
  säga! Ja si, det vet jag rakt inte. Så dem blev han inte klok på!}
