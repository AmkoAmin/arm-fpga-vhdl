library ieee;
use ieee.std_logic_1164.all;

entity PISOShiftReg_tb is
end PISOShiftReg_tb;

architecture testbench of PISOShiftReg_tb is
    constant test_width : integer := 4; --STUDENT: SET TO ARBITRARY VALUE THAT FITS YOUR TESTDATA

    signal tb_in       : std_logic_vector(test_width-1 downto 0) := (others => '0');
    signal tb_out      : std_logic;
    signal tb_load     : std_logic := '0';
    signal tb_last_bit : std_logic;

    signal clk : std_logic;
    signal ce  : std_logic;

    component PISOShiftReg
        generic (
            WIDTH : integer
        );
        port (
            CLK      : in std_logic;
            CLK_EN   : in std_logic;
            LOAD     : in std_logic;
            D_IN     : in std_logic_vector(WIDTH-1 downto 0);
            D_OUT    : out std_logic;
            LAST_BIT : out std_logic
        );
    end component;
begin
    --generate basic clock
    clk_gen : process
    begin
        clk <= '1';
        wait for 1 ns;
        clk <= '0';
        wait for 1 ns;
    end process clk_gen;

    --generate clock enable signal
    clk_en_gen : process
    begin
        ce <= '1';
        wait for 1 ns;
        ce <= '0';
        wait for 9 ns;
    end process clk_en_gen;

    uut : PISOShiftReg
    generic map (WIDTH => test_width)
    port map (
        CLK      => clk,
        CLK_EN   => ce,
        LOAD     => tb_load,
        D_IN     => tb_in,
        D_OUT    => tb_out,
        LAST_BIT => tb_last_bit
    );

    --STUDENT: INSERT TESTBENCH CODE HERE (SIGNAL ASSIGNMENTS ETC.)
    stimuli : process
    begin
        -- Defaultwerte, etwas Zeit zum Einschwingen
        tb_load <= '0';
        tb_in   <= (others => '0');
        wait for 15 ns;

        -- Testfall 1: Datum 0101 laden und vollstaendig herausschieben.
        --   Erwartet: D_OUT-Sequenz 1,0,1,0; LAST_BIT='1' beim MSB, bleibt sticky.
        tb_in   <= "0101";
        tb_load <= '1';
        wait for 10 ns;        -- ein CE-Puls -> Laden
        tb_load <= '0';
        wait for 50 ns;        -- mehrere Shifts + Idle-Zustand pruefen

        -- Testfall 2: gleiches Datum erneut laden -> LAST_BIT muss zurueck auf '0'.
        tb_in   <= "0101";
        tb_load <= '1';
        wait for 10 ns;
        tb_load <= '0';
        wait for 40 ns;

        -- Testfall 3: anderes Bitmuster (MSB = 1).
        --   Erwartet: D_OUT-Sequenz 0,0,1,1; LAST_BIT='1' wenn MSB ausgegeben.
        tb_in   <= "1100";
        tb_load <= '1';
        wait for 10 ns;
        tb_load <= '0';
        wait for 50 ns;

        -- Testfall 4: All-Ones (Grenzfall, jedes Bit '1').
        tb_in   <= "1111";
        tb_load <= '1';
        wait for 10 ns;
        tb_load <= '0';
        wait for 50 ns;

        -- Testfall 5: All-Zeros (Grenzfall, jedes Bit '0').
        tb_in   <= "0000";
        tb_load <= '1';
        wait for 10 ns;
        tb_load <= '0';
        wait for 50 ns;

        -- Testfall 6: LOAD ueber mehrere Takte hoch halten -> jeden Takt neu laden.
        --   D_IN wechselt zwischendurch, das jeweils letzte Datum muss gewinnen.
        tb_in   <= "1010";
        tb_load <= '1';
        wait for 10 ns;
        tb_in   <= "0110";    -- aendert sich noch waehrend LOAD='1'
        wait for 20 ns;       -- weitere CE-Pulse mit LOAD='1'
        tb_load <= '0';
        wait for 50 ns;

        -- Simulation beenden
        report "PISOShiftReg-Testbench beendet." severity note;
        wait;
    end process stimuli;
end testbench;
