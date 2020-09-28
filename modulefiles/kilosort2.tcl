#%Module -*- tcl -*-
##
## dot modulefile
##

proc ModulesHelp { } {

  puts stderr "\tAdds Kilosort2 to your environment."
}

module-whatis "Adds Kilosort2 to your environment."
prereq matlab/2018a
prereq cuda@9.0.176

set               root                 /share/apps/kilosort2-cli
prepend-path      PATH                 $root/bin
