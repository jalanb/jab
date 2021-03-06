#! /bin/cat

type same_dir >/dev/null 2>&1 || . ~/bash/paths.sh

# x
# xx

py () {
    local __doc__="""Run python, or a python script or directory"""
    local _path=
    if [[ -n "$@" ]]; then
        local all_args="$*"
        local _path=$(pyth ~/python/scripts.py -m "$@" 2> ~/fd2)
        if [[ "$all_args" =~ "--help" || "$all_args" =~ "-[hU]" || $? != 0 ]]; then
            _path=
        elif [[ -z $_path ]]; then
            _path=${1/%./.py}
            shift
        fi
        [[ -e $_path ]] || _path=
    fi
    pyth $_path $*
}

# xxx

ppi () {
    [[ $1 == install ]] && shift
    ppip install "$@"
}

ppu () {
    ppip uninstall "$@"
}

# xxxx

ppid () {
    pip_install_develop "$@"
}

ppie () {
    if [[ -d "$1" ]]; then
        (
            cd "$1"
            ppi -e .
        )
    else
        ppi -e . 
    fi
}

ppii () {
    local _ipython=$(which ipython)
    [[ -n $IPYTHON ]] && _ipython=$IPYTHON
    pypath $_ipython "$@"
}

ppip () {
    [[ "$@" ]] || return 1
    show_command python -m pip "$@"
    python3 -m pip "$@" > ~/fd1
    grep -v -e already.satisfied -e upgrade.pip ~/fd1
    if grep -q "pip install --upgrade pip" ~/fd1; then
        python3 -m pip install --upgrade pip &
    fi
}

ppir () {
    ppi -r "$@"
}

ppiu () {
    ppi --upgrade "$@" | grep -v already.satisfied
}

pipv () {
    local _dir=$PWD _setups=
    [[ -d "$1" ]] && _dir="$1" && shift
    [[ -f $_dir/setup.py ]] && _setups=$_dir/setup.py
    [[ -f $_dir/setup.cfg ]] && _setups=$_dir/setup.cfg
    [[ -f $_dir/requirements.txt ]] && _setups="$_setups $_dir/requirements.txt"
    [[ -d $_dir/requirements ]] && _setups="$_setups $_dir/requirements/*"
    vim -p $_setups "$@"
}

_pipy_setup () {
    local dir_="$1" force_="$2"; shift 2
    local dev_=
    _install_requirements_there $dir_ "$force_"
    local script_dir_=
    local mode_=--editable
    local which_python_=$(which python)
    if [[ $which_python_ =~ ^/usr/local ]]; then
        script_dir_="--script-dir=/usr/local/bin"
        mode_=
    elif [[ ! $which_python_ =~ ^$HOME ]]; then
        show_error Cannot pipy $(which python), which is outside $HOME
        return 1
    fi
    [[ -f $dir_/setup.py ]] || echo "$dir_/setup.py is not a file" >&2
    [[ -f $dir_/setup.py ]] || return 1
    set -x
    pip install $force_ $mode_ $script_dir_ $dir_
    set +x
}

pipy () {
    local __doc__="""Install a python project dir

    [path] : path to the project (defaults to \$PWD)
    -v : edit the setup files first
    -V : only edit the setup files
    -f : force
    -u : upgrade
    """
    piup >/dev/null 2>&1
    local _dir=$PWD
    [[ -d "$1" ]] && _dir="$1" && shift
    local force_=
    [[ $1 =~ -u*fu* ]] && force_=--force-reinstall
    [[ $1 =~ -f*uf* ]] && force_="$force_ --upgrade"
    [[ $force_ ]] && shift
    [[ -d "$1" ]] && _dir="$1" && shift
    _pipy_setup $_dir $force_ 2>&1 | grep -v already.satisfied  | grep -e ^Installed -e '^Installing .* script' -e pip.install | grep -e 'g [a-z_]+\>' -e '/\<[a-z0-9.-]*[^/]+$'
}

pirr () {
    _install_requirements_there "$@"
}

piup () {
    show_blue_line "python3 -m pip install --upgrade pip"
    python3 -m pip install --upgrade pip
}

vipy () {
    pipy -V "$@"
}

venv () {
    local activate_="$ACTIVATE"
    make_venv "$@" 2>/dev/null
    local venv_=.venv
    [[ -d "$1" ]] && venv_="$1/.venv"
    cde_activate_there $venv_ || return 1
    [[ "$activate_" != "$ACTIVATE" ]] && show_blue_line "cde_activate_there $venv_"
    whyp python 2>/dev/null
}

# _xxxx

_install_requirements_here () {
    local force_=$1 requirement_=
    [[ -f requirements.txt ]] && ppir requirements.txt $force_ && return 0
    [[ -d requirements ]] && for requirement_ in requirements/*.txt; do ppir ${requirement_} $force_ ; done
}

_install_requirements_there () {
    local _dir="$1"; shift
    same_dir "$_dir" . && _install_requirements_here "$@" || (cd $_dir; _install_requirements_here "$@")
}

# xxxxxxx
pythoni () {
    python -c "import $1; print($1.__file__)"
}

pythonv () {
    python -V "$@"
}

# xxxxxxx

pylinum () {
    local string=$(pylint --help-msg $1 | hd1 | cut -d\: -f2 | cut -d\  -f1 | sed -e "s/^/# pylint: disable=/")
    [[ $string != "# pylint: disable=No" ]] && echo $string
}

# xxxxxxxxx

make_venv () {
    local __doc__="""Make a .venv"""
    local root_=. venv_=.venv venv_dir_=.venv
    if [[ -d "$1" ]]; then
        root_="$1"
        venv_dir_="$1/$venv_"
        shift
    fi
    local python_=$venv_dir_/bin/python3
    local force_=
    if [[ -d $venv_dir_ ]]; then
        if [[ $1 =~ ^-(f|-force)$ ]]; then
            show_command "rm -rf $venv_dir_"
            rm -rf $venv_dir_
        else
            . $python_ -m pip install --upgrade pip
            return 0
        fi
    fi
    show_command "python3 -m venv $venv_"
    [[ $VIRTUAL_ENV ]] && deactivate
    python3 -m venv --copies $venv_
    $python_ -m ensurepip
    $python_ -m pip install --upgrade pip
    local requirements_=
    [[ -f requirements.txt ]] && requirements_=requirements.txt
    [[ -f requirements/requirements.txt ]] && requirements_=requirements/requirements.txt
    [[ -f requirements/testing.txt ]] && requirements_=requirements/testing.txt
    [[ -f requirements/development.txt ]] && requirements_=requirements/development.txt
    [[ -f $requirements_ ]] && $python_ -m pip install -r $requirements_
}

# xxxxxxx*

pip_install_develop () {
    local __doc__="""pip install a directory for development"
    piup >/dev/null 2>&1
    local _dir=.
    if [[ -d "$1" ]]; then
        _dir="$1"
        shift
        local force_=
        [[ $1 == "-f" ]] && force_=--force-reinstall
        _install_requirements_there $_dir $force_
        if [[ -f setup.py ]]; then
            [[ $force_ ]] && force_=--upgrade
            ppi $force_ -e .
        fi
    fi 2>&1 | grep -v already.satisfied
}

