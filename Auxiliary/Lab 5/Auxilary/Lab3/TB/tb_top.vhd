library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_top is
end tb_top;

architecture sim of tb_top is
    signal clk, rst, ena, done, TBactive : std_logic := '0';
    signal TB_ITCM_en, TB_DTCM_en, TB_DTCM_wr : std_logic := '0';
    signal TB_ITCM_addr, TB_DTCM_addr : std_logic_vector(5 downto 0) := (others => '0');
    signal TB_ITCM_din, TB_DTCM_din : std_logic_vector(15 downto 0) := (others => '0');
    signal TB_DTCM_dout : std_logic_vector(15 downto 0);

begin
    uut: entity work.top port map (
        clk => clk, rst => rst, ena => ena, done => done, TBactive => TBactive,
        TB_ITCM_en => TB_ITCM_en, TB_ITCM_addr => TB_ITCM_addr, TB_ITCM_din => TB_ITCM_din,
        TB_DTCM_en => TB_DTCM_en, TB_DTCM_wr => TB_DTCM_wr, TB_DTCM_addr => TB_DTCM_addr,
        TB_DTCM_din => TB_DTCM_din, TB_DTCM_dout => TB_DTCM_dout
    );

    clk <= not clk after 50 ns;

    process
        -- File paths for EX4
        file itcm_file   : text open read_mode is "SW-QA/Ex5/bin/ITCMinit.txt";
        file dtcm_file   : text open read_mode is "SW-QA/Ex5/bin/DTCMinit.txt";
        file dtcm_out    : text open write_mode is "SW-QA/Ex5/output/DTCMcontent.txt";
        
        variable row     : line;
        variable val     : std_logic_vector(15 downto 0);
        variable i       : integer := 0;
    begin
        -----------------------------------------------------
        -- Step 1: Reset
        -----------------------------------------------------
        rst <= '1';
        TBactive <= '1';
        ena <= '0';
        wait for 100 ns;
        rst <= '0';
        
        -----------------------------------------------------
        -- Step 2: Load Instruction Memory (ITCM)
        -----------------------------------------------------
        TB_ITCM_en <= '1';
        i := 0;
        while not endfile(itcm_file) loop
            readline(itcm_file, row);
            hread(row, val);
            TB_ITCM_addr <= std_logic_vector(to_unsigned(i, 6));
            TB_ITCM_din <= val;
            wait for 100 ns; 
            i := i + 1;
        end loop;
        TB_ITCM_en <= '0';

        -----------------------------------------------------
        -- Step 3: Load Data Memory (DTCM)
        -----------------------------------------------------
        TB_DTCM_en <= '1';
        TB_DTCM_wr <= '1';
        i := 0;
        while not endfile(dtcm_file) loop
            readline(dtcm_file, row);
            hread(row, val);
            TB_DTCM_addr <= std_logic_vector(to_unsigned(i, 6));
            TB_DTCM_din <= val;
            wait for 100 ns; 
            i := i + 1;
        end loop;
        TB_DTCM_wr <= '0';
        
        -----------------------------------------------------
        -- Step 4: CPU Execution
        -----------------------------------------------------
        TBactive <= '0';
        ena <= '1';
        
        -- Timeout mechanism
        wait until done = '1' for 2 ms;
        if done = '0' then
            report "SIMULATION TIMEOUT: Processor did not reach DONE state!" severity failure;
        end if;
        
        ena <= '0';
        
        -----------------------------------------------------
        -- Step 5: Read Results (Print ALL 64 words with padding)
        -----------------------------------------------------
        TBactive <= '1';
        
        for j in 0 to 62 loop 
            TB_DTCM_addr <= std_logic_vector(to_unsigned(j, 6));
            wait for 100 ns; 
            
            -- If the memory is empty/uninitialized, pad with 0000
            if is_X(TB_DTCM_dout) then
                hwrite(row, std_logic_vector(to_unsigned(0, 16)));
            else
                hwrite(row, TB_DTCM_dout);
            end if;
            
            writeline(dtcm_out, row);
        end loop;
        
        assert false report "Simulation Completed Successfully" severity failure;
        wait;
    end process;
end sim;