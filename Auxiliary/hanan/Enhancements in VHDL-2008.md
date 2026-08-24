VHDL-2008: Easier to use

https://www.doulos.com/knowhow/vhdl/vhdl-2008-easier-to-use/#sensitivity

KnowHow
Free Technical Resources

Many of the enhancements in VHDL-2008 are intended to make VHDL easier to use. These

are all fairly minor additions to the language or changes to the syntax. Nevertheless, they will

make a real difference in day-to-day VHDL design.

•
•
•
•
•
•
•
•

New condition operator,

Enhanced bit string literals

Hierarchical names

Vectors in aggregates

Conditional and selected sequential statements

Extensions to

Simplified sensitivity lists

Arithmetic on

New condition operator,

How many times have you wanted to write something like this:

if A and B then
 ...

where A and B are ? You haven’t been able to, because VHDL’s statement requires a boolean

expression, not a STD_LOGIC one. You have to write this instead:

if A = '1' and B = '1' then
 ...

VHDL-2008 introduces a new operator, . It ’s called the condition operator and it converts a

expression to a one:and are considered and everything else . (It also converts to ) So you can

now write this:

if ?? A and B then
 ...

1 of 6

5/21/2025, 10:34 AM

VHDL-2008: Easier to use

https://www.doulos.com/knowhow/vhdl/vhdl-2008-easier-to-use/#sensitivity

or, even better ...

In certain circumstances, is applied implicitly. The condition expression of an statement is

one of those. So you can indeed now write:

if A and B then
 ...

Enhanced bit string literals.

You use string literals as literal values of type or similar. For example,

  signal Count : unsigned(7 downto 0);

...

  Count <= "00000000";

In VHDL-1987, string literals provided, in effect, a way of expressing a vector as a binary

number. VHDL-1993 introduced binary, octal and hexadecimal bit string literals:

  Count <= B"0000_0000"; -- "_" is for readability only
  Count <= X"00";        -- Hex; O"..." is octal

One limitation in VHDL-1993 is that hexadecimal bit-string literals always contain a multiple

of 4 bits, and octal ones a multiple of 3 bits. You can’t have a 10-bit hexadecimal bit-string

literal, or one containing values other than 0, 1 or _, for example.

In VHDL-2008, bit string literals are enhanced:

•
•
•

they may have an explicit width,

they may be declared as signed or unsigned,

they may include meta-values ('U', 'X', etc.)

Here are some examples:

    variable S : std_logic_vector(5 downto 0);
  begin
    S := 6x"0f";  -- specify width 6
    S := 6x"XF";  -- means "XX1111"
    S := 6SX"F";  -- "111111" (sign extension)
    S := 6Ux"f";  -- "001111" (zero extension)
    S := 6sb"11"; -- "111111" (binary format)
    S := 6uO"7";  -- "000111" (octal format)

Note that within bit string literals it is allowed to use either upper or lower case letters, i.e. F

or f.

2 of 6

5/21/2025, 10:34 AM

VHDL-2008: Easier to use

https://www.doulos.com/knowhow/vhdl/vhdl-2008-easier-to-use/#sensitivity

Hierarchical names.

Some of the new features in VHDL-2008 are intended for verification only, not for design.

Verification engineers often want to write self-checking test environments. In VHDL this can

be difficult as there is no easy way to access a signal or variable buried inside the design

hierarchy from the top level of the verification environment.

VHDL-2008 addresses this by introducing external names. An external name may refer to a

(shared) variable, signal, or constant which is in another part of the design hierarchy. External

names are embedded in double angle brackets

Special characters may be used to move up the hierarchy and to root the path in a package .

Some examples:

 << signal .tb.uut.o_n : std_logic >>  -- hierarchical signal name
 << signal ^.^.a : std_logic >>        -- signal a two levels above
 << variable @lib.pack.v : bit >>      -- variable in a package pack

Other uses for external names include injecting errors from a test environment, and forcing

and releasing values (see later).

Vectors in aggregates

VHDL aggregates allow a value to be made up from a collection individual array or record

elements. For arrays, VHDL up to 1076-2002 allows syntax like this:

    variable V : std_logic_vector(7 downto 0);
  begin
    V := (others => '0');                    -- "00000000"
    V := ('1', '0', others => '0');          -- "10000000"
    V := (4 => '1', others => '0');          -- "00010000"
    V := (3 downto 0 => '0', others => '1'); -- "11110000"
    -- V := ("0000", others => '1');         -- illegal!

VHDL-2008 allows the use of a slice in an array aggregate. So for instance the examples

above could be written:

    V := (others => '0');                    -- "00000000"
    V := ("10", others => '0');              -- "10000000"
    V := (4 => '1', others => '0');          -- "00010000"
    V := (3 downto 0 => '0', others => '1'); -- "11110000"
    V := ("0000", others => '1');            -- "00001111"

It is also possible to use aggregates as the target of an assignment, like this:

    ( S(3 downto 0), S(7 downto 4)) <= S;      -- swap nibbles
    ( 3 downto 0 => S, 7 downto  4 => S) <= S; -- using named associatio
n

3 of 6

5/21/2025, 10:34 AM

VHDL-2008: Easier to use

https://www.doulos.com/knowhow/vhdl/vhdl-2008-easier-to-use/#sensitivity

Conditional and selected sequential statements.

Historically there have been two styles of writing "decision" statements in VHDL - concurrent

and sequential. And you had to get them correct - you could not use a conditional signal

assignment such as...

 z <= x when x > y else y;

in a process. VHDL-2008 relaxes this and allows a flip-flop to be modelled like this:

process(clock)
begin
  if rising_edge(clock) then
    q <= '0' when reset else d;  -- not allowed in VHDL 2002
  end if;
end process;

It is also permitted to use the selected signal assignment in a process:

process(clock)
begin
  if rising_edge(clock) then
    with s select              -- equivalent to a case statement
      q <= a when "00",
            b when "01",
            c when "10",
            d when "11";
  end if;
end process;

Extensions to .

VHDL-2008 makes the statement much more flexible. It is now allowed to use and . Also

there is a version of .

This makes easier to use. Instead of writing

  g1: if mode = 0 generate
    c1 : entity work.comp(rtl1)
         port map (a => a, b => b);
  end generate;
  g2: if mode = 1 generate
    c1 : entity work.comp(rtl2)
         port map (a => a, b => b);
  end generate;
  g3: if mode = 2 generate
    c1 : entity work.comp(rtl3)
         port map (a => a, b => b);
  end generate;

4 of 6

5/21/2025, 10:34 AM

VHDL-2008: Easier to use

https://www.doulos.com/knowhow/vhdl/vhdl-2008-easier-to-use/#sensitivity

you can write :

  g1: case mode generate
    when 0 =>
      c1 : entity work.comp(rtl1)
           port map (a => a, b => b);
    when 1 =>
      c1 : entity work.comp(rtl2)
           port map (a => a, b => b);
    when 2 =>
      c1 : entity work.comp(rtl3)
           port map (a => a, b => b);
    when others =>

  end generate;

or you can write :

  g1: if mode = 0 generate
        c1 : entity work.comp(rtl1)
             port map (a => a, b => b);
      elsif mode = 1 generate
        c1 : entity work.comp(rtl2)
             port map (a => a, b => b);
      elsif mode = 2 generate
        c1 : entity work.comp(rtl3)
             port map (a => a, b => b);
      else generate

  end generate;

Note that within each branch, you can still declare local names which will not clash with

names in the other branches (such as label above). It is still possible to declare local objects

within the branch using .

The and branches can be empty (do nothing) or may contain statements like the other

branches.

Simplified sensitivity lists.

The keyword may be used in the context of a sensitivity list, to mean that all signals read in

the process should be added to the sensitivity list, for example:

5 of 6

5/21/2025, 10:34 AM

VHDL-2008: Easier to use

https://www.doulos.com/knowhow/vhdl/vhdl-2008-easier-to-use/#sensitivity

process(all)
begin
  case state is
  when idle =>
    if in1 then
      nextState <= Go1;
    end if;
  when Go1 =>
    nextState <= Go2;
  when Go2 =>
    nextState <= Idle;
  end case;
end process;

This avoids a common problem where the author modifies a combination process and then

forgets to update the sensitivity list, leading to a simulation/synthesis mis-match.

Arithmetic on

VHDL has a well-designed package which creates two new data types and . However it would

sometimes be convenient to do arithmetic on directly - treating it as either two's

complement or unsigned.

In the past this has mainly been achieved by using the non-standard and . VHDL-2008

addresses this issue by adding two new standard arithmetic packages, and .

Previous    Next

Go back to the main VHDL-2008 page.

6 of 6

5/21/2025, 10:34 AM

