library ieee;
use ieee.std_logic_1164.all;
use work.aux_package.all;

entity Control is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        ena          : in  std_logic;
        
        -- OpCode Input from Datapath's Instruction Register (IR[15:12])
        OPC          : in  std_logic_vector(3 downto 0);
        
        -- Status signals from Datapath
        Cflag        : in  std_logic;
        Zflag        : in  std_logic;
        Nflag        : in  std_logic;
        
        -- Control signals to Datapath
        PCin         : out std_logic;
        IRin         : out std_logic;
        PCsel        : out std_logic;                     -- '0': PC+1, '1': PC+1+offset
        Imm1_in      : out std_logic;
        Imm2_in      : out std_logic;
        RFout        : out std_logic;
        RFin         : out std_logic;
        RFaddr_rd    : out std_logic_vector(1 downto 0);  -- "00": rb, "01": rc, "10": ra
        RFaddr_wr    : out std_logic;                     -- '1' selects ra for writing
        Ain          : out std_logic;
        Cin          : out std_logic;
        Cout         : out std_logic;
        ALUFN        : out std_logic_vector(3 downto 0);
        
        -- Memory control signals (DTCM)
        DTCM_addr_in : out std_logic;
        DTCM_out     : out std_logic;
        DTCM_wr      : out std_logic;
        
        -- Done signal to TB
        done         : out std_logic
    );
end Control;

architecture fsm of Control is

    -- FSM states definition (Mealy Synchronized)
    type state_type is (
        st_reset,
        st_fetch,
        st_decode,
        st_rtype_1,
        st_rtype_2,
        st_rtype_3,
        st_imm_mov,
        st_ld_1,
        st_ld_2,
        st_ld_3,
        st_ld_4,
        st_ld_5,
        st_st_1,
        st_st_2,
        st_st_3,
        st_st_4,
        st_jmp_exec,
        st_halt
    );
    
    signal state, next_state : state_type;

begin

    -----------------------------------------------------------------
    -- Synchronous process - state update
    -----------------------------------------------------------------
    sync_proc: process(clk, rst)
    begin
        if rst = '1' then
            state <= st_reset;
        elsif rising_edge(clk) then
            if ena = '1' then
                state <= next_state;
            end if;
        end if;
    end process;

    -----------------------------------------------------------------
    -- Combinatorial process - transition logic and outputs
    -----------------------------------------------------------------
    comb_proc: process(state, OPC, Cflag, Zflag, Nflag)
    begin
        -- Reset all control signals to prevent Latch
        PCin         <= '0';
        IRin         <= '0';
        PCsel        <= '0';
        Imm1_in      <= '0';
        Imm2_in      <= '0';
        RFout        <= '0';
        RFin         <= '0';
        RFaddr_rd    <= "00";
        RFaddr_wr    <= '1';  -- Default write to ra
        Ain          <= '0';
        Cin          <= '0';
        Cout         <= '0';
        ALUFN        <= (others => '0');
        DTCM_addr_in <= '0';
        DTCM_out     <= '0';
        DTCM_wr      <= '0';
        done         <= '0';
        
        next_state   <= state;

        case state is
            when st_reset =>
                next_state <= st_fetch;
                
            when st_fetch =>
                -- Fetch stage: read instruction from memory to IR and increment PC
                IRin  <= '1'; 
                PCin  <= '1'; 
                PCsel <= '0'; 
                next_state <= st_decode;
                
            when st_decode =>
                -- Route based on OpCode
                case OPC is
                    when OPC_ADD | OPC_SUB | OPC_AND | OPC_OR | OPC_XOR =>
                        next_state <= st_rtype_1;
                        
                    when OPC_MOV => 
                        next_state <= st_imm_mov;
                        
                    when OPC_LD => 
                        next_state <= st_ld_1;
                        
                    when OPC_ST => 
                        next_state <= st_st_1;
                        
                    when OPC_JMP | OPC_JC | OPC_JNC => 
                        next_state <= st_jmp_exec;
                        
                    when OPC_DONE => 
                        next_state <= st_halt;
                        
                    when others =>
                        -- If instruction is unrecognized, return to Fetch (fallback)
                        next_state <= st_fetch;
                end case;
                
            -----------------------------------------------------------------
            -- R-Type instructions (ADD, SUB, AND, OR, XOR) - includes NOP which is ADD R0,R0,R0
            -----------------------------------------------------------------
            when st_rtype_1 =>
                -- Read rb (bits 7-4) into register A
                RFaddr_rd <= "00"; 
                RFout     <= '1'; 
                Ain       <= '1'; 
                next_state <= st_rtype_2;
                
            when st_rtype_2 =>
                -- Read rc (bits 3-0) to bus, execute ALU operation, and save in C
                RFaddr_rd <= "01"; 
                RFout     <= '1'; 
                ALUFN     <= OPC; 
                Cin       <= '1'; 
                next_state <= st_rtype_3;
                
            when st_rtype_3 =>
                -- Output result from C and write back to register ra
                Cout      <= '1'; 
                RFaddr_wr <= '1'; 
                RFin      <= '1'; 
                next_state <= st_fetch;
                
            -----------------------------------------------------------------
            -- I-Type instruction: MOV (mov ra, imm)
            -----------------------------------------------------------------
            when st_imm_mov =>
                -- Load Imm (8 bits) into ra
                Imm1_in   <= '1'; 
                RFaddr_wr <= '1'; 
                RFin      <= '1'; 
                next_state <= st_fetch;
                
            -----------------------------------------------------------------
            -- Memory instruction: LD (ld ra, imm(rb))
            -----------------------------------------------------------------
            when st_ld_1 =>
                -- Read base address from rb into register A
                RFaddr_rd <= "00"; 
                RFout     <= '1'; 
                Ain       <= '1'; 
                next_state <= st_ld_2;
                
            when st_ld_2 =>
                -- Add address with Imm (4 bits)
                Imm2_in   <= '1'; 
                ALUFN     <= OPC_ADD; 
                Cin       <= '1'; 
                next_state <= st_ld_3;
                
            when st_ld_3 =>
                -- Move calculated address (from C) to Data Memory address register
                Cout         <= '1'; 
                DTCM_addr_in <= '1'; 
                next_state   <= st_ld_4;
                
            when st_ld_4 =>
                -- Wait cycle to allow memory (Synchronous RAM) to read data
                next_state <= st_ld_5;
                
            when st_ld_5 =>
                -- Route data from memory to bus and write to register ra
                DTCM_out  <= '1'; 
                RFaddr_wr <= '1'; 
                RFin      <= '1'; 
                next_state <= st_fetch;
                
            -----------------------------------------------------------------
            -- Memory instruction: ST (st ra, imm(rb))
            -----------------------------------------------------------------
            when st_st_1 =>
                -- Read base address from rb into register A
                RFaddr_rd <= "00"; 
                RFout     <= '1'; 
                Ain       <= '1'; 
                next_state <= st_st_2;
                
            when st_st_2 =>
                -- Add address with Imm (4 bits)
                Imm2_in   <= '1'; 
                ALUFN     <= OPC_ADD; 
                Cin       <= '1'; 
                next_state <= st_st_3;
                
            when st_st_3 =>
                -- Move calculated address to Data Memory address register
                Cout         <= '1'; 
                DTCM_addr_in <= '1'; 
                next_state   <= st_st_4;
                
            when st_st_4 =>
                -- Read from ra and issue memory write command
                RFaddr_rd <= "10"; -- Select ra!
                RFout     <= '1'; 
                DTCM_wr   <= '1'; 
                next_state <= st_fetch;
                
            -----------------------------------------------------------------
            -- J-Type Jump instructions (JMP, JC, JNC)
            -----------------------------------------------------------------
            when st_jmp_exec =>
                -- Check jump condition
                if (OPC = OPC_JMP) or 
                   (OPC = OPC_JC and Cflag = '1') or 
                   (OPC = OPC_JNC and Cflag = '0') then
                    PCin  <= '1';
                    PCsel <= '1'; -- PC = PC + 1 + offset
                else
                    -- If condition is not met, processor continues to next instruction without jumping
                    PCin  <= '0';
                end if;
                next_state <= st_fetch;
                
            -----------------------------------------------------------------
            -- End of program (DONE)
            -----------------------------------------------------------------
            when st_halt =>
                done <= '1';
                next_state <= st_halt; -- Full stop
                
            when others =>
                next_state <= st_reset;
        end case;
    end process;

end fsm;