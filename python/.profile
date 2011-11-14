##
## helper function
##
function _eval {
    echo $1
    eval $1
}


##
## mkdir $PWD/local
##
sitedir="local/lib/python/site-packages"
[ -d "$sitedir" ] || _eval "mkdir -p $sitedir"

for i in 2.4 2.5 2.6 2.5 3.0 3.1 3.2 3.3; do
    [ -e "local/lib/python$i" ] || (cd local/lib; ln -s python python$i)
done

bindir="local/bin"
[ -d "$bindir" ] || _eval "mkdir -p $bindir"

unset sitedir i bindir


##
## add $PWD/local/bin to $PATH
##
case :$PATH: in
    *:$PWD/local/bin:*)  ;;
    *)  echo export PATH='$PWD/local/bin:$PATH'
        export PATH=$PWD/local/bin:$PATH
        ;;
esac


##
## add $PWD/bin to $PATH
##
case :$PATH: in
    *:$PWD/bin:*)  ;;
    *)  echo export PATH='$PWD/bin:$PATH'
        export PATH=$PWD/bin:$PATH
        ;;
esac


##
## set $PYTHONPATH
##
pyver=`python -c 'import sys; print("%s.%s"%sys.version_info[:2])'`
sitedir="local/lib/python$pyver/site-packages"
if [ -d "$PWD/lib" ]; then
    echo export PYTHONPATH=.:'$PWD'/$sitedir:'$PWD'/lib
    export PYTHONPATH=.:$PWD/$sitedir:$PWD/lib
else
    echo export PYTHONPATH=.:'$PWD'/$sitedir:'$PWD'
    export PYTHONPATH=.:$PWD/$sitedir:$PWD
fi
unset pyver
unset sitedir


##
## enforce easy_install to install packages into $PWD/local
##
echo alias easy_install='\easy_install --prefix=$PWD/local'
alias easy_install='\easy_install --prefix='$PWD/local


##
##
##
alias hg_summary='hg log --template "[{rev}] {desc|firstline}\n"'
