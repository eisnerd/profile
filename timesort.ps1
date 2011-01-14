$j=[System.DateTime]"1 Jan 2011";$n=0;ls -recurse |where {$_.mode -match "d" }|%{pushd $_.FullName; ls|sort|%{$n=$n-1; $_.CreationTime = $j.AddSeconds($n)}; popd}
