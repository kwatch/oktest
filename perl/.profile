case ":$PATH:" in
*:"$PWD/bin":*)
	;;
*)
	echo 'export PATH=$PWD/bin:$PATH'
	export PATH=$PWD/bin:$PATH
	;;
esac
echo 'export PERL5LIB=$PWD/lib:$PWD/local/lib/perl5'
export PERL5LIB=$PWD/lib:$PWD/local/lib/perl5
