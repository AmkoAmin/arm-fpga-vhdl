--------------------------------------------------------------------------------
--  Testbench fuer den 4-Bit ArmBarrelShifter (OPERAND_WIDTH=4, SHIFTER_DEPTH=2).
--
--  Reihenfolge der Testfaelle (entspricht qualitativ Abbildung 1):
--    1.  Kein Shift       (MUX_CTRL="00")
--    2.  Linksshift  LSL  (MUX_CTRL="01")
--    3.  Rechtsshift LSR  (MUX_CTRL="10", ARITH_SHIFT='0')
--    4.  Arithm. RSH ASR  (MUX_CTRL="10", ARITH_SHIFT='1')
--    5.  Rechtsrotation   (MUX_CTRL="11")
--
--  Zusaetzlich werden mehrere Operanden und alle Schiebeweiten (0-3)
--  sowie verschiedene C_IN-Werte getestet.
--
--  HINWEIS zur Toolchain: Es werden bewusst KEINE VHDL-2008-Funktionen
--  to_string/to_hstring verwendet, da diese von Vivado XSim 2017.3 nicht
--  unterstuetzt werden. Stattdessen wandelt die lokale Funktion slv_str
--  einen std_logic_vector in eine Bit-Zeichenkette ('0'/'1') um.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ArmBarrelShifter4Bit_tb is
end entity ArmBarrelShifter4Bit_tb;

architecture behave of ArmBarrelShifter4Bit_tb is

    --------------------------------------------------------------------------------
    --  Komponenten-Deklaration des DUT
    --------------------------------------------------------------------------------
    component ArmBarrelShifter
        generic (
            OPERAND_WIDTH : integer;
            SHIFTER_DEPTH : integer
        );
        port (
            OPERAND     : in  std_logic_vector(OPERAND_WIDTH-1 downto 0);
            MUX_CTRL    : in  std_logic_vector(1 downto 0);
            AMOUNT      : in  std_logic_vector(SHIFTER_DEPTH-1 downto 0);
            ARITH_SHIFT : in  std_logic;
            C_IN        : in  std_logic;
            DATA_OUT    : out std_logic_vector(OPERAND_WIDTH-1 downto 0);
            C_OUT       : out std_logic
        );
    end component ArmBarrelShifter;

    --------------------------------------------------------------------------------
    --  Konstanten
    --------------------------------------------------------------------------------
    constant CLK_PERIOD   : time    := 20 ns;
    constant OPERAND_W    : integer := 4;
    constant SHIFTER_D    : integer := 2;  -- 2^2 = 4

    --------------------------------------------------------------------------------
    --  Hilfsfunktion: std_logic_vector -> Bit-Zeichenkette (XSim-2017.3-tauglich)
    --------------------------------------------------------------------------------
    function slv_str (v : std_logic_vector) return string is
        variable s   : string(1 to v'length);
        variable idx : integer := 1;
    begin
        for i in v'range loop
            case v(i) is
                when '1'    => s(idx) := '1';
                when '0'    => s(idx) := '0';
                when others => s(idx) := 'X';
            end case;
            idx := idx + 1;
        end loop;
        return s;
    end function slv_str;

    --------------------------------------------------------------------------------
    --  Stimulus- und Ergebnissignale
    --------------------------------------------------------------------------------
    signal OPERAND     : std_logic_vector(OPERAND_W-1 downto 0) := (others => '0');
    signal MUX_CTRL    : std_logic_vector(1 downto 0)           := "00";
    signal AMOUNT      : std_logic_vector(SHIFTER_D-1 downto 0) := (others => '0');
    signal ARITH_SHIFT : std_logic := '0';
    signal C_IN        : std_logic := '0';
    signal DATA_OUT    : std_logic_vector(OPERAND_W-1 downto 0);
    signal C_OUT       : std_logic;

    --------------------------------------------------------------------------------
    --  Hilfsprozedur: Stimuli setzen und Ergebnis pruefen
    --------------------------------------------------------------------------------
    procedure apply_and_check (
        signal   s_OPERAND     : out std_logic_vector(OPERAND_W-1 downto 0);
        signal   s_MUX_CTRL    : out std_logic_vector(1 downto 0);
        signal   s_AMOUNT      : out std_logic_vector(SHIFTER_D-1 downto 0);
        signal   s_ARITH_SHIFT : out std_logic;
        signal   s_C_IN        : out std_logic;
        constant v_OPERAND     : in  std_logic_vector(OPERAND_W-1 downto 0);
        constant v_MUX_CTRL    : in  std_logic_vector(1 downto 0);
        constant v_AMOUNT      : in  std_logic_vector(SHIFTER_D-1 downto 0);
        constant v_ARITH_SHIFT : in  std_logic;
        constant v_C_IN        : in  std_logic;
        constant v_EXPECTED    : in  std_logic_vector(OPERAND_W-1 downto 0);
        constant v_C_EXPECTED  : in  std_logic;
        signal   r_DATA_OUT    : in  std_logic_vector(OPERAND_W-1 downto 0);
        signal   r_C_OUT       : in  std_logic
    ) is
    begin
        s_OPERAND     <= v_OPERAND;
        s_MUX_CTRL    <= v_MUX_CTRL;
        s_AMOUNT      <= v_AMOUNT;
        s_ARITH_SHIFT <= v_ARITH_SHIFT;
        s_C_IN        <= v_C_IN;
        wait for CLK_PERIOD;

        assert r_DATA_OUT = v_EXPECTED
            report "DATA_OUT-Fehler: OPERAND=" & slv_str(v_OPERAND)
                & " MUX=" & slv_str(v_MUX_CTRL)
                & " AMT=" & slv_str(v_AMOUNT)
                & " ARITH=" & std_logic'image(v_ARITH_SHIFT)
                & " CIN=" & std_logic'image(v_C_IN)
                & "  => erwartet " & slv_str(v_EXPECTED)
                & " erhalten " & slv_str(r_DATA_OUT)
            severity error;

        assert r_C_OUT = v_C_EXPECTED
            report "C_OUT-Fehler:   OPERAND=" & slv_str(v_OPERAND)
                & " MUX=" & slv_str(v_MUX_CTRL)
                & " AMT=" & slv_str(v_AMOUNT)
                & " ARITH=" & std_logic'image(v_ARITH_SHIFT)
                & " CIN=" & std_logic'image(v_C_IN)
                & "  => erwartet C=" & std_logic'image(v_C_EXPECTED)
                & " erhalten C=" & std_logic'image(r_C_OUT)
            severity error;
    end procedure apply_and_check;

begin

    --------------------------------------------------------------------------------
    --  DUT-Instanziierung
    --------------------------------------------------------------------------------
    DUT : ArmBarrelShifter
        generic map (
            OPERAND_WIDTH => OPERAND_W,
            SHIFTER_DEPTH => SHIFTER_D
        )
        port map (
            OPERAND     => OPERAND,
            MUX_CTRL    => MUX_CTRL,
            AMOUNT      => AMOUNT,
            ARITH_SHIFT => ARITH_SHIFT,
            C_IN        => C_IN,
            DATA_OUT    => DATA_OUT,
            C_OUT       => C_OUT
        );

    --------------------------------------------------------------------------------
    --  Stimulusprozess
    --------------------------------------------------------------------------------
    stimulus : process

        -- Konstante Testwerte fuer einfachen Zugriff
        --  Operanden
        constant OP_A  : std_logic_vector(3 downto 0) := "1010";  -- 0xA
        constant OP_B  : std_logic_vector(3 downto 0) := "0101";  -- 0x5
        constant OP_C  : std_logic_vector(3 downto 0) := "1111";  -- 0xF (alle 1)
        constant OP_D  : std_logic_vector(3 downto 0) := "0000";  -- 0x0 (alle 0)
        constant OP_E  : std_logic_vector(3 downto 0) := "1001";  -- 0x9
        constant OP_F  : std_logic_vector(3 downto 0) := "0110";  -- 0x6

        -- Schiebeweiten als 2-Bit-Vektoren
        constant AMT0  : std_logic_vector(1 downto 0) := "00";
        constant AMT1  : std_logic_vector(1 downto 0) := "01";
        constant AMT2  : std_logic_vector(1 downto 0) := "10";
        constant AMT3  : std_logic_vector(1 downto 0) := "11";

    begin

        --------------------------------------------------------------------------------
        --  Initialzustand
        --------------------------------------------------------------------------------
        OPERAND <= (others => '0'); MUX_CTRL <= "00";
        AMOUNT  <= (others => '0'); ARITH_SHIFT <= '0'; C_IN <= '0';
        wait for CLK_PERIOD;

        report "============================================================";
        report " Test 1: Kein Shift (MUX_CTRL = 00)";
        report "============================================================";

        -- Kein Shift: Operand bleibt unveraendert, C_OUT = C_IN
        -- Weite 0, C_IN=0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"00",AMT0,'0','0',  OP_A,'0',  DATA_OUT,C_OUT);
        -- Weite 0, C_IN=1 => C_OUT muss = C_IN = '1'
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"00",AMT0,'0','1',  OP_A,'1',  DATA_OUT,C_OUT);
        -- Weite 1: MUX_CTRL=00 => trotzdem kein Shift
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"00",AMT1,'0','0',  OP_A,'0',  DATA_OUT,C_OUT);
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_B,"00",AMT2,'0','1',  OP_B,'1',  DATA_OUT,C_OUT);
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_C,"00",AMT3,'0','0',  OP_C,'0',  DATA_OUT,C_OUT);


        report "============================================================";
        report " Test 2: Linksshift LSL (MUX_CTRL = 01)";
        report "============================================================";

        --  OP_A = 1010
        --  LSL 0: 1010, C_OUT = C_IN
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"01",AMT0,'0','0',  "1010",'0',  DATA_OUT,C_OUT);
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"01",AMT0,'0','1',  "1010",'1',  DATA_OUT,C_OUT);

        --  OP_A = 1010, LSL 1: 0100, C_OUT = herausgeschobenes Bit = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"01",AMT1,'0','0',  "0100",'1',  DATA_OUT,C_OUT);

        --  OP_A = 1010, LSL 2: 1000, C_OUT = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"01",AMT2,'0','0',  "1000",'0',  DATA_OUT,C_OUT);

        --  OP_A = 1010, LSL 3: 0000, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"01",AMT3,'0','0',  "0000",'1',  DATA_OUT,C_OUT);

        --  OP_B = 0101, LSL 1: 1010, C_OUT = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_B,"01",AMT1,'0','0',  "1010",'0',  DATA_OUT,C_OUT);

        --  OP_B = 0101, LSL 2: 0100, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_B,"01",AMT2,'0','0',  "0100",'1',  DATA_OUT,C_OUT);

        --  OP_C = 1111, LSL 1: 1110, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_C,"01",AMT1,'0','0',  "1110",'1',  DATA_OUT,C_OUT);

        --  OP_C = 1111, LSL 3: 1000, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_C,"01",AMT3,'0','0',  "1000",'1',  DATA_OUT,C_OUT);

        --  OP_E = 1001, LSL 1: 0010, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_E,"01",AMT1,'0','1',  "0010",'1',  DATA_OUT,C_OUT);

        --  OP_E = 1001, LSL 3: 1000, C_OUT = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_E,"01",AMT3,'0','0',  "1000",'0',  DATA_OUT,C_OUT);


        report "============================================================";
        report " Test 3: Logischer Rechtsshift LSR (MUX_CTRL = 10, ARITH='0')";
        report "============================================================";

        --  OP_A = 1010, LSR 0: 1010, C_OUT = C_IN
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"10",AMT0,'0','0',  "1010",'0',  DATA_OUT,C_OUT);
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"10",AMT0,'0','1',  "1010",'1',  DATA_OUT,C_OUT);

        --  OP_A = 1010, LSR 1: 0101, C_OUT = 0 (herausgeschobenes LSB)
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"10",AMT1,'0','0',  "0101",'0',  DATA_OUT,C_OUT);

        --  OP_A = 1010, LSR 2: 0010, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"10",AMT2,'0','0',  "0010",'1',  DATA_OUT,C_OUT);

        --  OP_A = 1010, LSR 3: 0001, C_OUT = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"10",AMT3,'0','0',  "0001",'0',  DATA_OUT,C_OUT);

        --  OP_B = 0101, LSR 1: 0010, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_B,"10",AMT1,'0','0',  "0010",'1',  DATA_OUT,C_OUT);

        --  OP_C = 1111, LSR 1: 0111, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_C,"10",AMT1,'0','0',  "0111",'1',  DATA_OUT,C_OUT);

        --  OP_C = 1111, LSR 3: 0001, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_C,"10",AMT3,'0','0',  "0001",'1',  DATA_OUT,C_OUT);

        --  OP_F = 0110, LSR 2: 0001, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_F,"10",AMT2,'0','0',  "0001",'1',  DATA_OUT,C_OUT);


        report "============================================================";
        report " Test 4: Arithmetischer Rechtsshift ASR (MUX_CTRL=10, ARITH='1')";
        report "============================================================";

        --  OP_A = 1010 (MSB=1, negativ): Fuellbit = 1
        --  ASR 0: 1010, C_OUT = C_IN
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"10",AMT0,'1','0',  "1010",'0',  DATA_OUT,C_OUT);

        --  ASR 1: 1101, C_OUT = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"10",AMT1,'1','0',  "1101",'0',  DATA_OUT,C_OUT);

        --  ASR 2: 1110, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"10",AMT2,'1','0',  "1110",'1',  DATA_OUT,C_OUT);

        --  ASR 3: 1111, C_OUT = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"10",AMT3,'1','0',  "1111",'0',  DATA_OUT,C_OUT);

        --  OP_B = 0101 (MSB=0, positiv): Fuellbit = 0 => wie LSR
        --  ASR 1: 0010, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_B,"10",AMT1,'1','0',  "0010",'1',  DATA_OUT,C_OUT);

        --  ASR 2: 0001, C_OUT = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_B,"10",AMT2,'1','0',  "0001",'0',  DATA_OUT,C_OUT);

        --  OP_C = 1111 (MSB=1): ASR 2: 1111, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_C,"10",AMT2,'1','0',  "1111",'1',  DATA_OUT,C_OUT);

        --  OP_E = 1001 (MSB=1): ASR 1: 1100, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_E,"10",AMT1,'1','0',  "1100",'1',  DATA_OUT,C_OUT);

        --  OP_E = 1001: ASR 3: 1111, C_OUT = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_E,"10",AMT3,'1','0',  "1111",'0',  DATA_OUT,C_OUT);


        report "============================================================";
        report " Test 5: Rechtsrotation ROR (MUX_CTRL = 11)";
        report "============================================================";

        --  OP_A = 1010, ROR 0: 1010, C_OUT = C_IN
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"11",AMT0,'0','0',  "1010",'0',  DATA_OUT,C_OUT);
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"11",AMT0,'0','1',  "1010",'1',  DATA_OUT,C_OUT);

        --  OP_A = 1010, ROR 1: 0101, C_OUT = 0 (herausgeschobenes Bit 0)
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"11",AMT1,'0','0',  "0101",'0',  DATA_OUT,C_OUT);

        --  OP_A = 1010, ROR 2: 1010, C_OUT = 1
        --  (1010 ROR 2 => 10|10 -> 10|10 = 1010, letztes herausgeschobenes Bit war Bit1 = 1)
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"11",AMT2,'0','0',  "1010",'1',  DATA_OUT,C_OUT);

        --  OP_A = 1010, ROR 3: 0101...
        --  1010 ROR 3: nehme die unteren 3 Bits (010) und schiebe sie nach oben
        --  => 010|1 => 0101, C_OUT = Bit2 = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_A,"11",AMT3,'0','0',  "0101",'0',  DATA_OUT,C_OUT);

        --  OP_B = 0101, ROR 1: 1010, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_B,"11",AMT1,'0','0',  "1010",'1',  DATA_OUT,C_OUT);

        --  OP_B = 0101, ROR 2: 0101, C_OUT = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_B,"11",AMT2,'0','0',  "0101",'0',  DATA_OUT,C_OUT);

        --  OP_C = 1111, ROR 1: 1111, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_C,"11",AMT1,'0','0',  "1111",'1',  DATA_OUT,C_OUT);

        --  OP_D = 0000, ROR 1: 0000, C_OUT = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_D,"11",AMT1,'0','0',  "0000",'0',  DATA_OUT,C_OUT);

        --  OP_E = 1001, ROR 1: 1100, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_E,"11",AMT1,'0','0',  "1100",'1',  DATA_OUT,C_OUT);

        --  OP_E = 1001, ROR 3: 0011, C_OUT = 0
        --  1001 ROR 3: (001) -> high, (1) -> low => 0011, C_OUT = Bit2 = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_E,"11",AMT3,'0','0',  "0011",'0',  DATA_OUT,C_OUT);


        report "============================================================";
        report " Test 6: Zusaetzliche Operanden / Sonderfaelle";
        report "============================================================";

        --  Alle Nullen, jede Operation, jede Weite => immer 0000, C_OUT = 0 oder C_IN
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_D,"01",AMT0,'0','1',  "0000",'1',  DATA_OUT,C_OUT);
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_D,"01",AMT1,'0','0',  "0000",'0',  DATA_OUT,C_OUT);
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_D,"10",AMT2,'0','0',  "0000",'0',  DATA_OUT,C_OUT);
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_D,"11",AMT3,'0','0',  "0000",'0',  DATA_OUT,C_OUT);

        --  OP_F = 0110: Verschiedene Operationen
        --  LSL 1: 1100, C_OUT = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_F,"01",AMT1,'0','0',  "1100",'0',  DATA_OUT,C_OUT);
        --  LSR 1: 0011, C_OUT = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_F,"10",AMT1,'0','0',  "0011",'0',  DATA_OUT,C_OUT);
        --  ASR 1 (MSB=0): 0011, C_OUT = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_F,"10",AMT1,'1','0',  "0011",'0',  DATA_OUT,C_OUT);
        --  ROR 1: 0011, C_OUT = 0
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_F,"11",AMT1,'0','0',  "0011",'0',  DATA_OUT,C_OUT);
        --  ROR 2: 1001, C_OUT = 1
        apply_and_check(OPERAND,MUX_CTRL,AMOUNT,ARITH_SHIFT,C_IN,
            OP_F,"11",AMT2,'0','0',  "1001",'1',  DATA_OUT,C_OUT);

        -- Reset am Ende
        OPERAND <= (others => '0'); MUX_CTRL <= "00";
        AMOUNT  <= (others => '0'); ARITH_SHIFT <= '0'; C_IN <= '0';
        wait for CLK_PERIOD;

        report "============================================================";
        report " ArmBarrelShifter4Bit_tb: Alle Testfaelle abgeschlossen.";
        report "============================================================";
        report "EOT" severity failure;  -- Simulation beenden

        wait;
    end process stimulus;

end architecture behave;
