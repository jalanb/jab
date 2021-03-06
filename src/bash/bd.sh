#! /bin/sh

# From https://github.com/vigneshwaranr/bd

usage_error () {
  cat << EOF
------------------------------------------------------------------
Name: bd

------------------------------------------------------------------
Description: Go back to a specified directory up in the hierarchy.

------------------------------------------------------------------
How to use:

If you are in this path /home/user/project/src/org/main/site/utils/file/reader/whatever
and you want to go to site directory quickly, then just type:
     . bd site

If there are more than one directories with same name up in the hierarchy,
bd will take you to the closest. (Not considering the immediate parent.)

If you don't want to type the full directory name, then you can use 
the -s switch (meaning starts with) and just give the starting few characters
     . bd -s si

------------------------------------------------------------------
Extra settings:

To get the most out of it, put this line: 
     alias bd='. bd -s'
in your ~/.bashrc file so that it is no longer necessary to put a dot and space.

You can simply type 'bd <starting few letters>' to go back quickly.

So in the case of the given example, it would be
     'bd s' or 'bd si'

For case-insensitive directory matching, using -si instead of -s, after bd:
     '. bd -si'
Note: this requires GNU sed to be installed (BSD sed on OS X 10.8.2 won't work).
EOF
}

newpwd() {
  OLDPWD=$1
  if [ "$2" = "-s" ]
  then
    NEWPWD=`echo $OLDPWD | sed 's|\(.*/'$3'[^/]*/\).*|\1|'`
    index=`echo $NEWPWD | awk '{ print index($0,"/'$3'"); }'`
  elif [ "$2" = "-si" ]
  then
    NEWPWD=`echo $OLDPWD | sed 's|\(.*/'$3'[^/]*/\).*|\1|I'`
    index=`echo $NEWPWD | awk '{ print index(tolower($0),tolower("/'$3'")); }'`
  else
    NEWPWD=`echo $OLDPWD | sed 's|\(.*/'$2'/\).*|\1|'`
    index=`echo $NEWPWD | awk '{ print index($1,"/'$2'/"); }'`
  fi
}

if [ $# -eq 0 ]
then
  usage_error
elif [ $# -eq 1 -a "$1" = "-s" ]
then
  usage_error
else
  OLDPWD=`pwd`

  newpwd "$OLDPWD" "$@"
  
  if [ $index -eq 0 ]
  then
    echo "No such occurrence."
  fi
  
  echo $NEWPWD
  cd "$NEWPWD"
  unset NEWPWD
fi
