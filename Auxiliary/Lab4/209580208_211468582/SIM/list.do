onerror {resume}
add list /tb/Y_i
add list /tb/X_i
add list /tb/ALUFN_i
add list /tb/ALUout_o
add list /tb/Nflag_o
add list /tb/Cflag_o
add list /tb/Zflag_o
add list /tb/Vflag_o
add list /tb/PWMout_o
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta collapse
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
