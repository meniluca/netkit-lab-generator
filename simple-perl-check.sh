#!/bin/bash
if [ "`command -v perl`" != "" ]
then 
  if [ "`perldoc -l Switch`" != "" ]
    then echo "è tutto ok" 
  else  echo "hai bisogno di installare il modulo Switch di Perl! "
  fi 
else echo "hai bisogno di installare Perl! "
fi