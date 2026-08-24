In order to orientate in the HDL code of HW design, you are strongly recommended to use the following
conventions for signal name extensions:

Useful names extension

1.  Using name extension for an entity port:

i.  The names of ports’ input have the i extension, that is, port_name_i
ii.  The names of outputs’ port have the o extension, that is, port_name_o

2.  Using name extension for internal SIGNALS:

i.  The name of a signal used as a wire (connection only) has the w extension, that is, signal_name_w
ii.  The name of a signal used as a synchronous register (has a synchronous memory) has q extension, that

is, signal_name_q

iii.  The name of a signal used as an asynchronous/combinational register (has an asynchronous memory)

has r extension, that is, signal_name_r

3.  The very recommended use of VARIABLE names is as follows:

The name of a variable has v extension, that is, variable_name_v

