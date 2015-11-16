#! /bin/bash
#
#
# colours
#
# http://en.wikipedia.org/wiki/ANSI_escape_sequences#Colors
#
if [[ -z $JAB_COLOUR_ENVIRON_SOURCED ]]; then
    export          NO_COLOUR="\[\033[0m\]"
    export                RED="\[\033[0;31m\]"
    export          LIGHT_RED="\[\033[1;31m\]"
    export              GREEN="\[\033[0;32m\]"
    export        LIGHT_GREEN="\[\033[1;32m\]"
    export              BROWN="\[\033[0;33m\]"
    export             YELLOW="\[\033[1;33m\]"
    export               BLUE="\[\033[0;34m\]"
    export         LIGHT_BLUE="\[\033[1;34m\]"
    export            MAGENTA="\[\033[0;35m\]"
    export      LIGHT_MAGENTA="\[\033[1;35m\]"
    export               CYAN="\[\033[0;36m\]"
    export         LIGHT_CYAN="\[\033[1;36m\]"
    export              WHITE="\[\033[1;37m\]"
    export         LIGHT_GRAY="\[\033[0;37m\]"
    export               GRAY="\[\033[1;38m\]"
    export           GRAY_TOO="\[\033[0;38m\]"
    export     PROMPT_NO_COLOUR="\033[0m"
    export           PROMPT_RED="\033[0;31m"
    export     PROMPT_LIGHT_RED="\033[1;31m"
    export         PROMPT_GREEN="\033[0;32m"
    export   PROMPT_LIGHT_GREEN="\033[1;32m"
    export         PROMPT_BROWN="\033[0;33m"
    export        PROMPT_YELLOW="\033[1;33m"
    export          PROMPT_BLUE="\033[0;34m"
    export    PROMPT_LIGHT_BLUE="\033[1;34m"
    export       PROMPT_MAGENTA="\033[1;35m"
    export PROMPT_LIGHT_MAGENTA="\033[0;35m"
    export          PROMPT_CYAN="\033[0;36m"
    export    PROMPT_LIGHT_CYAN="\033[1;36m"
    export         PROMPT_WHITE="\033[1;37m"
    export    PROMPT_LIGHT_GRAY="\033[0;37m"
    export           PROMPT_GRAY="\033[1;38m"
    export       PROMPT_GRAY_TOO="\033[0;38m"
fi
export JAB_COLOUR_ENVIRON_SOURCED=1