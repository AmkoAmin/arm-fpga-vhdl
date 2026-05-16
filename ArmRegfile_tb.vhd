--------------------------------------------------------------------------------
--  Test Bench fuer den Registerspeicher des ARM-Kerns mit 3 vollstaendigen
--  Leseports, 2 vollstaendigen Schreibports und einem PC-Schreibport
--  Kompatibel mit Registerspeicher V2
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.hwrite;
use std.textio.all;
library work;
use work.TB_Tools.all;
use work.ArmTypes.all;
use work.ArmConfiguration.all;
use work.ArmRegAddressTranslation.all;

entity ArmRegfile_tb is
end ArmRegfile_tb;

architecture behave of ArmRegfile_tb is

signal REF_CLK                                          : std_logic := '0';
signal SIMULATION_RUNNING                               : boolean := false;
signal SYS_RST                                          : std_logic := '0';
signal W_EN                                             : std_logic_vector(2 downto 0) := "000";
signal W_A_ADDR, W_B_ADDR, R_A_ADDR, R_B_ADDR, R_C_ADDR : std_logic_vector(4 downto 0) := "00000";
signal W_A_DATA, W_B_DATA, W_PC_DATA                    : std_logic_vector(31 downto 0) := (others => '0');
signal R_A_DATA, R_B_DATA, R_C_DATA                     : std_logic_vector(31 downto 0);
signal W_A_TDATA, W_B_TDATA, R_PC_TDATA                 : std_logic_vector(31 downto 0);

type ALL_REGISTERS_TYPE is array(0 to 30) of std_logic_vector(31 downto 0);


begin
    -- Taktsignal erzeugen solange die Simulation laeuft
    REF_CLK <= NOT REF_CLK after ARM_SYS_CLK_PERIOD/2 when SIMULATION_RUNNING else '0';

--------------------------------------------------------------------------------
--  Alternative Schnittstelle fuer fortschrittlicheren
--  Registerspeicher bereits vorgesehen, irrelevant
--  fuer das HWPR.
--------------------------------------------------------------------------------
    uut: entity WORK.ArmRegfile(behavioral)
    port map(
        REF_CLK              => REF_CLK,
        REF_RST              => SYS_RST,
        REF_W_PORT_A_ENABLE  => W_EN(2),
        REF_W_PORT_B_ENABLE  => W_EN(1),
        REF_W_PORT_PC_ENABLE => W_EN(0),
        REF_W_PORT_A_ADDR    => W_A_ADDR,
        REF_W_PORT_B_ADDR    => W_B_ADDR,
        REF_R_PORT_A_ADDR    => R_A_ADDR,
        REF_R_PORT_B_ADDR    => R_B_ADDR,
        REF_R_PORT_C_ADDR    => R_C_ADDR,
        REF_W_PORT_A_DATA    => W_A_DATA,
        REF_W_PORT_B_DATA    => W_B_DATA,
        REF_W_PORT_PC_DATA   => W_PC_DATA,
        REF_R_PORT_A_DATA    => R_A_DATA,
        REF_R_PORT_B_DATA    => R_B_DATA,
        REF_R_PORT_C_DATA    => R_C_DATA
    );

    TEST_UUT : process is
        constant PHY_PC_ADDR : std_logic_vector(4 downto 0) := GET_INTERNAL_ADDRESS("1111",USER,'0');
        variable V_W_EN : std_logic_vector(2 downto 0) := "000";
        constant NR_OF_TESTCASES : natural := 8;
        variable TESTCASE_NR : natural range 1 to NR_OF_TESTCASES := 1;
        type TESTCASES_NAMES_TYPE is array(1 to NR_OF_TESTCASES) of line;
        variable TESTCASES_NAMES : TESTCASES_NAMES_TYPE;

        variable ALL_REGISTERS_A, ALL_REGISTERS_B, ALL_REGISTERS_C, ALL_REGISTERS_CMP : ALL_REGISTERS_TYPE;

        variable V_RESET : std_logic := '0';
        variable V_W_A_ADDR, V_W_B_ADDR, V_R_A_ADDR, V_R_B_ADDR, V_R_C_ADDR : std_logic_vector(4 downto 0) := "00000";
        variable V_W_A_DATA, V_W_B_DATA, V_W_PC_DATA : std_logic_vector(31 downto 0) := (others => '0');
        variable V_R_A_DATA, V_R_B_DATA, V_R_C_DATA : std_logic_vector(31 downto 0);
        variable NR_OF_ERRORS : integer := 0;
        variable ERROR_IN_TESTCASE : BOOLEAN := FALSE;
        variable CURRENT_VALUE_0 : std_logic_vector(31 downto 0);
        variable CURRENT_VALUE_1 : std_logic_vector(31 downto 0);
        variable CURRENT_VALUE_2 : std_logic_vector(31 downto 0);
        constant PIPE : STRING(1 to 1) := "|";
         type ERRORS_IN_TESTCASES_TYPE is array (1 to NR_OF_TESTCASES) of boolean;
        variable ERRORS_IN_TESTCASES : ERRORS_IN_TESTCASES_TYPE := (others => FALSE);
        type REG_CHECKED_TYPE is array (0 to 31) of boolean;
        variable REG_CHECKED : REG_CHECKED_TYPE := (others => FALSE);
        variable Points : natural := 0;
        variable NEW_ERROR : boolean := FALSE;

        impure function GENERATE_DATA(THIS_REGADDRESS : std_logic_vector(4 downto 0)) return std_logic_vector is
            variable NEW_DATA :std_logic_vector(31 downto 0);
        begin
            NEW_DATA := std_logic_vector(to_unsigned(TESTCASE_NR,8)) & X"0810" & "000" & THIS_REGADDRESS;
            return NEW_DATA;
        end function GENERATE_DATA;

        impure function GENERATE_DATA(THIS_TESTCASE_NR : natural range 1 to NR_OF_TESTCASES; THIS_REGADDRESS : std_logic_vector(4 downto 0)) return std_logic_vector is
            variable NEW_DATA :std_logic_vector(31 downto 0);
        begin
            NEW_DATA := std_logic_vector(to_unsigned(THIS_TESTCASE_NR,8)) & X"0810" & "000" & THIS_REGADDRESS;
            return NEW_DATA;
        end function GENERATE_DATA;

        procedure SET_VALUES is
        begin
            SYS_RST <= V_RESET;
            W_EN <= V_W_EN;
            W_A_ADDR <= V_W_A_ADDR; W_B_ADDR <= V_W_B_ADDR; R_A_ADDR <= V_R_A_ADDR; R_B_ADDR <= V_R_B_ADDR; R_C_ADDR <= V_R_C_ADDR;
            W_A_DATA <= GENERATE_DATA(V_W_A_ADDR);
            W_B_DATA <= GENERATE_DATA(V_W_B_ADDR);
            W_PC_DATA <=GENERATE_DATA(PHY_PC_ADDR);
        end SET_VALUES;

        procedure GET_ALL_REGISTERS_A(ALL_REGISTERS : out ALL_REGISTERS_TYPE) is
        begin
            for i in 0 to 30 loop
                R_A_ADDR <= std_logic_vector(to_unsigned(i, 5));
                wait for ARM_SYS_CLK_PERIOD/1024;
                ALL_REGISTERS(i) := R_A_DATA;
            end loop;
        end GET_ALL_REGISTERS_A;

        procedure GET_ALL_REGISTERS_B(ALL_REGISTERS : out ALL_REGISTERS_TYPE) is
        begin
            for i in 0 to 30 loop
                R_B_ADDR <= std_logic_vector(to_unsigned(i, 5));
                wait for ARM_SYS_CLK_PERIOD/1024;
                ALL_REGISTERS(i) := R_B_DATA;
            end loop;
        end GET_ALL_REGISTERS_B;

        procedure GET_ALL_REGISTERS_C(ALL_REGISTERS : out ALL_REGISTERS_TYPE) is
        begin
            for i in 0 to 30 loop
                R_C_ADDR <= std_logic_vector(to_unsigned(i, 5));
                wait for ARM_SYS_CLK_PERIOD/1024;
                ALL_REGISTERS(i) := R_C_DATA;
            end loop;
        end GET_ALL_REGISTERS_C;


        procedure INC(ARG : inout integer) is
        begin
            if ARG = integer'high then
                ARG := 0;
            else
                ARG := ARG + 1;
            end if;
        end procedure INC;


        procedure PRINT_REGFILE is
            variable TX_LOC : line;
        begin
            report SEPARATOR_LINE;
            GET_ALL_REGISTERS_A(ALL_REGISTERS_A);
            for i in 0 to 30 loop
                std.textio.write(TX_LOC, "R" & integer'image(i) & ":" & TAB_CHAR); hwrite(TX_LOC, ALL_REGISTERS_B(i));
                report TX_LOC.all;
                Deallocate(TX_LOC);
            end loop;
            report SEPARATOR_LINE;
        end procedure PRINT_REGFILE;

        function IMG(THIS_INTEGER : integer) return string is
        begin
            return integer'image(THIS_INTEGER);
        end function IMG;

        procedure EVAL(THIS_TESTCASE : inout natural range 1 to NR_OF_TESTCASES; THIS_ERROR : inout boolean; THIS_ERRORS_ARRAY : inout ERRORS_IN_TESTCASES_TYPE) is
        begin
            if THIS_ERROR then
                report "Fehler in Testcase " & integer'image(THIS_TESTCASE) severity error;
                report "Fehler in Testcase " & integer'image(THIS_TESTCASE) severity note;
                THIS_ERRORS_ARRAY(THIS_TESTCASE) := TRUE;
                PRINT_REGFILE;
            else
                report "Testcase " & integer'image(THIS_TESTCASE) & " korrekt" severity note;
                THIS_ERRORS_ARRAY(THIS_TESTCASE) := FALSE;
            end if;
            if THIS_TESTCASE < NR_OF_TESTCASES then INC(THIS_TESTCASE); end if;
            REG_CHECKED := (others => FALSE);
            THIS_ERROR := FALSE;
            NEW_ERROR := false;
            report SEPARATOR_LINE;
            report SEPARATOR_LINE;
        end procedure EVAL;

        procedure INIT_TESTCASES_NAMES is
        begin
            STD.textio.write(TESTCASES_NAMES(1),TAB_CHAR & "Schreiben und Lesen aller Register, jeweils ueber Port A"& TAB_CHAR & TAB_CHAR);
            STD.textio.write(TESTCASES_NAMES(2),TAB_CHAR & "Schreiben und Lesen aller Register, jeweils ueber Port B"& TAB_CHAR & TAB_CHAR);
            STD.textio.write(TESTCASES_NAMES(3),TAB_CHAR & "Bei nicht gesetzten Enable-Signalen sind keine Schreibzugriffe moeglich");
            STD.textio.write(TESTCASES_NAMES(4),TAB_CHAR & "Schreiben und Lesen aller Register unter Verwendung aller Ports" & TAB_CHAR);
            STD.textio.write(TESTCASES_NAMES(5),TAB_CHAR & "Lesezugriffe erfolgen asynchron"& TAB_CHAR & TAB_CHAR & TAB_CHAR & TAB_CHAR);
            STD.textio.write(TESTCASES_NAMES(6),TAB_CHAR & "Test der Priorisierung durch Zugriffe auf den PC"& TAB_CHAR & TAB_CHAR & TAB_CHAR);
            STD.textio.write(TESTCASES_NAMES(7),TAB_CHAR & "Schreibzugriffe wirken erst nach Taktflanke auf Ausgang"& TAB_CHAR & TAB_CHAR);
            STD.textio.write(TESTCASES_NAMES(8),TAB_CHAR & "Simultane Nutzung aller Schreibport möglich"& TAB_CHAR & TAB_CHAR);
        end procedure INIT_TESTCASES_NAMES;


    begin
        INIT_TESTCASES_NAMES;
        -- Reset
        report SEPARATOR_LINE;
        report SEPARATOR_LINE;
        report "Start der Simulation...";
        report SEPARATOR_LINE;
        report SEPARATOR_LINE;
        -- report "Register file:";
        -- PRINT_REGFILE_NAMES;
        SIMULATION_RUNNING <= TRUE;
        wait until REF_CLK'event and REF_CLK = '1';
        wait until REF_CLK'event and REF_CLK = '0';
        wait until REF_CLK'event and REF_CLK = '1';
        V_RESET := '1'; SET_VALUES;
        wait until REF_CLK'event and REF_CLK = '1';
        wait until REF_CLK'event and REF_CLK = '0';
        wait until REF_CLK'event and REF_CLK = '1';
        V_RESET := '0'; SET_VALUES;
        ERROR_IN_TESTCASE := FALSE;
        wait until REF_CLK'event and REF_CLK = '0';
        wait until REF_CLK'event and REF_CLK = '1';
        wait until REF_CLK'event and REF_CLK = '0';
        report SEPARATOR_LINE;
        report SEPARATOR_LINE;
        report "Format der waehrend des Tests in den Registerspeicher geschriebenen Daten:" severity note;
        report " " & TAB_CHAR;
        report "| Nummer des Testcase (2 Ziffern) | 0810 (hex) | 000 | Registeradresse (2 Ziffern, hex) |";
        report SEPARATOR_LINE;
        report SEPARATOR_LINE;
        wait until REF_CLK'event and REF_CLK = '1';
        V_RESET := '1'; SET_VALUES;
        wait until REF_CLK'event and REF_CLK = '1';
        V_RESET := '0'; SET_VALUES;
        wait until REF_CLK'event and REF_CLK = '1';

        --------------------------------------------------------------------------------
        -- jeweils Lesen und Schreiben aller Register, erst ueber Port A, dann Port B
        LOOP_PORTS: for PORTS in 0 to 1 loop
        if PORTS = 0 then
            -- Beschreiben und Lesen aller Register ueber Port A
            report "Testcase " & integer'image(TESTCASE_NR) & ": Beschreiben und Lesen aller Register ueber Schreibport A und Leseport A.";
            V_W_EN := "100";
        else
            -- Beschreiben und Lesen aller Register ueber Port B
            report "Testcase " & integer'image(TESTCASE_NR) & ": Beschreiben und Lesen aller Register ueber Schreibport B und Leseport B.";
            V_W_EN := "010";
        end if;
        wait until REF_CLK'event and REF_CLK = '1';--
        NEW_ERROR := FALSE;
        for i in 0 to 30 loop
            if PORTS = 0 then
                V_W_A_ADDR := std_logic_vector(to_unsigned(i,5));
                V_R_A_ADDR := std_logic_vector(to_unsigned(i,5));
            else
                V_W_B_ADDR := std_logic_vector(to_unsigned(i,5));
                V_R_B_ADDR := std_logic_vector(to_unsigned(i,5));
            end if;
            SET_VALUES;
            wait until REF_CLK'event and REF_CLK = '1';
            wait for ARM_SYS_CLK_PERIOD/4;
            -- REG_CHECKED(i) := TRUE;
            if PORTS = 0 then
                if R_A_DATA /= GENERATE_DATA(std_logic_vector(to_unsigned(i,5))) then
                        report "Gelesenes Datum an Port A nicht korrekt, Register " & IMG(i);
                        ERROR_IN_TESTCASE := TRUE;
                        NEW_ERROR := TRUE;
                    else
                        null;
                    end if;
                else
                    if R_B_DATA /= GENERATE_DATA(std_logic_vector(to_unsigned(i,5))) then
                        report "Gelesenes Datum an Port B nicht korrekt, Register " & IMG(i);
                        ERROR_IN_TESTCASE := TRUE;
                        NEW_ERROR := TRUE;
                    else
                        null;
                    end if;
                end if;
                wait until REF_CLK'event and REF_CLK = '1';
            end loop;
            -- if NEW_ERROR then PRINT_REGFILE; end if;
            NEW_ERROR := false;
            V_W_EN := "000"; SET_VALUES;
            -- Zuruecksetzen aller Registerinhalte damit im naechsten Schleifendurchlauf wieder alle Register sinnvoll
            -- ueberprueft werden koennen
            -- wait until REF_CLK'event and REF_CLK = '1';
            -- V_RESET := '1'; SET_VALUES;
            -- wait until REF_CLK'event and REF_CLK = '1';
            -- V_RESET := '0'; SET_VALUES;
            -- wait until REF_CLK'event and REF_CLK = '1';
            EVAL(TESTCASE_NR, ERROR_IN_TESTCASE, ERRORS_IN_TESTCASES);
        end loop LOOP_PORTS;
        wait for ARM_SYS_CLK_PERIOD/4;

        --------------------------------------------------------------------------------
        -- Signale fuer den Schreibzugriff werden kurz nach der fallenden Flanke des Systemtakts erzeugt
        -- Alle drei Enablesignale gleichzeitig inaktiv, blockieren alle Schreibzugriffe
        wait until REF_CLK'event and REF_CLK = '0';
        -- Alle Register speichern
        GET_ALL_REGISTERS_A(ALL_REGISTERS_A);
        GET_ALL_REGISTERS_B(ALL_REGISTERS_B);
        GET_ALL_REGISTERS_C(ALL_REGISTERS_C);
        for i in ALL_REGISTERS_A'range loop
            if ALL_REGISTERS_A(i) /= ALL_REGISTERS_B(i) or ALL_REGISTERS_B(i) /= ALL_REGISTERS_C(i) or ALL_REGISTERS_A(i) /= ALL_REGISTERS_C(i) then
                report "Register " & integer'image(i) & " ist nicht über alle Leseports identisch" severity note;
                ERROR_IN_TESTCASE := TRUE;
            end if;
        end loop;
        ALL_REGISTERS_CMP := ALL_REGISTERS_A;

        report "Testcase " & integer'image(TESTCASE_NR) & ": Die nicht gesetzten Enablesignale verhinderen Schreibzugriffe";
        V_W_EN := "000";
        for i in 0 to 30 loop
            if (i mod 2) /= 0 then next; end if;
            V_W_A_ADDR := std_logic_vector(to_unsigned(i,5));
            V_W_B_ADDR := std_logic_vector(to_unsigned(i + 1,5));
            SET_VALUES;
            wait until REF_CLK'event and REF_CLK = '1';
            wait for 1 ns;
        end loop;--

        GET_ALL_REGISTERS_A(ALL_REGISTERS_A);
        GET_ALL_REGISTERS_B(ALL_REGISTERS_B);
        GET_ALL_REGISTERS_C(ALL_REGISTERS_C);
        for i in ALL_REGISTERS_A'range loop
            if ALL_REGISTERS_A(i) /= ALL_REGISTERS_CMP(i) then
                report "Register " & integer'image(i) & " hat sich an Leseport A ohne gesetztes Enablesignal veraendert" severity note;
                ERROR_IN_TESTCASE := TRUE;
            end if;
            if ALL_REGISTERS_B(i) /= ALL_REGISTERS_CMP(i) then
                report "Register " & integer'image(i) & " hat sich an Leseport B ohne gesetztes Enablesignal veraendert" severity note;
                ERROR_IN_TESTCASE := TRUE;
            end if;
            if ALL_REGISTERS_C(i) /= ALL_REGISTERS_CMP(i) then
                report "Register " & integer'image(i) & " hat sich an Leseport C ohne gesetztes Enablesignal veraendert" severity note;
                ERROR_IN_TESTCASE := TRUE;
            end if;
        end loop;

        -- if ERROR_IN_TESTCASE then PRINT_REGFILE; end if;
        EVAL(TESTCASE_NR, ERROR_IN_TESTCASE, ERRORS_IN_TESTCASES);
        wait for ARM_SYS_CLK_PERIOD/4;
        --------------------------------------------------------------------------------
        -- -- Testcase: Reset Priority fuer PC
        -- report "Testcase " & integer'image(TESTCASE_NR) & ": Reset hat Prioritaet über W_ENs";
        -- -- Reset-Impuls umgibt eine steigende Taktflanke
        -- wait until REF_CLK'event and REF_CLK = '0';
        -- V_RESET := '1'; V_W_EN := "111"; SET_VALUES;
        -- wait until REF_CLK'event and REF_CLK = '1';
        -- GET_ALL_REGISTERS_A(ALL_REGISTERS_A);
        -- V_RESET := '0'; V_W_EN := "111"; SET_VALUES;
        -- wait until REF_CLK'event and REF_CLK = '0';
        -- if ALL_REGISTERS_A(15) /= X"00000000" then
        --     report "Register " & integer'image(15) & " nicht null sondern: "  & SLV_TO_STRING(ALL_REGISTERS_A(15)) severity note;
        --     ERROR_IN_TESTCASE := TRUE;
        -- end if;
        -- if ERROR_IN_TESTCASE then PRINT_REGFILE; end if;
        -- EVAL(TESTCASE_NR, ERROR_IN_TESTCASE, ERRORS_IN_TESTCASES);

        --------------------------------------------------------------------------------
        -- -- Testcase: alle Register enthalten nach dem Reset Nullen.
        -- report "Testcase " & integer'image(TESTCASE_NR) & ": nach dem Reset enthalten alle Register X" & '"' & "00000000" & '"';
        -- -- Reset-Impuls umgibt eine steigende Taktflanke
        -- wait until REF_CLK'event and REF_CLK = '0';
        -- V_RESET := '1'; V_W_EN := "000"; SET_VALUES;
        -- -- wait until REF_CLK'event and REF_CLK = '1';
        -- wait until REF_CLK'event and REF_CLK = '0';
        -- V_RESET := '0'; SET_VALUES;
        -- for i in ALL_REGISTERS'range loop
        --     if ALL_REGISTERS(i) /= X"00000000" then
        --         report "Register " & integer'image(i) & " nicht null sondern: "  & SLV_TO_STRING(ALL_REGISTERS(i)) severity note;
        --         ERROR_IN_TESTCASE := TRUE;
        --     end if;
        -- end loop;
        -- if ERROR_IN_TESTCASE then PRINT_REGFILE; end if;
        -- EVAL(TESTCASE_NR, ERROR_IN_TESTCASE, ERRORS_IN_TESTCASES);
        --------------------------------------------------------------------------------
        -- Beschreiben und Lesen aller Register ueber alle Ports gleichzeitig, wobei das Lesen nach dem Schreiben einsetzt
        report "Testcase " & integer'image(TESTCASE_NR) & ": Beschreiben und Lesen aller Register ueber alle Schreib- und Leseports.";
        V_W_EN := "111";
        V_R_C_ADDR := PHY_PC_ADDR;
        NEW_ERROR := FALSE;
        for i in 0 to 29 loop
            if (i mod 2) /= 0 then next; end if;
                -- report IMG(i);
                V_W_A_ADDR := std_logic_vector(to_unsigned(i,5));
                V_W_B_ADDR := std_logic_vector(to_unsigned(i + 1,5));
                -- Leseport A wird zum Lesen der Daten verwendet, die Ueber Port B geschrieben wurden und umgekehrt
                V_R_A_ADDR := std_logic_vector(to_unsigned(i + 1,5));
                V_R_B_ADDR := std_logic_vector(to_unsigned(i,5));
                -- report "B_ADDR: " & SLV_TO_STRING(V_W_B_ADDR);
                SET_VALUES;
            wait until REF_CLK'event and REF_CLK = '1';
            wait for ARM_SYS_CLK_PERIOD/4;
            if R_B_DATA /= GENERATE_DATA(std_logic_vector(to_unsigned(i,5))) then
                report "Ueber Port A geschriebene Daten konnten nicht über Leseport B gelesen werden" severity note;
                report "Registeradresse: " & IMG(i);
                ERROR_IN_TESTCASE := TRUE;
                    NEW_ERROR := TRUE;
            end if;
            if R_A_DATA /= GENERATE_DATA(std_logic_vector(to_unsigned(i + 1,5))) then
                report "Ueber Port B geschriebene Daten konnten nicht über Leseport A gelesen werden" severity note;
                report "Registeradresse: " & IMG(i + 1);
                ERROR_IN_TESTCASE := TRUE;
                    NEW_ERROR := TRUE;
            end if;
        end loop;
        wait until REF_CLK'event and REF_CLK = '0';
        V_RESET := '1'; V_W_EN := "000"; SET_VALUES;
        -- wait until REF_CLK'event and REF_CLK = '1';
        wait until REF_CLK'event and REF_CLK = '0';
        V_RESET := '0'; V_W_EN := "111"; SET_VALUES;
        -- Durch die Art der Adressbildung ist sichergestellt, dass die normalen
        -- Schreibports andere Adressen als den PC beschreiben.
        V_W_A_ADDR := PHY_PC_ADDR(4 downto 1) & not PHY_PC_ADDR(0);
          V_W_B_ADDR := PHY_PC_ADDR(4) & not PHY_PC_ADDR(3) & PHY_PC_ADDR(2 downto 0);
        V_R_A_ADDR := PHY_PC_ADDR(4) & not PHY_PC_ADDR(3) & PHY_PC_ADDR(2 downto 0);
        V_R_B_ADDR := PHY_PC_ADDR(4 downto 1) & not PHY_PC_ADDR(0);
        V_R_C_ADDR := PHY_PC_ADDR;
        SET_VALUES;
        wait until REF_CLK'event and REF_CLK = '1';
        wait for ARM_SYS_CLK_PERIOD/4;
        V_W_EN := "000"; SET_VALUES;
        if R_B_DATA /= GENERATE_DATA(V_W_A_ADDR) then
            report "Daten ueber Port A wurden nicht korrekt ueber Leseport B gelesen" severity note;
            report "Registeradresse: " & IMG(to_integer(unsigned(V_W_A_ADDR)));
            ERROR_IN_TESTCASE := TRUE;
                NEW_ERROR := TRUE;
        end if;
        if R_A_DATA /= GENERATE_DATA(V_W_B_ADDR) then
            report "Daten ueber Port B wurden nicht korrekt ueber Leseport A gelesen" severity note;
            report "Registeradresse: " & IMG(to_integer(unsigned(V_W_B_ADDR)));
            ERROR_IN_TESTCASE := TRUE;
                NEW_ERROR := TRUE;
        end if;
        if (R_C_DATA /= GENERATE_DATA(PHY_PC_ADDR)) then
            report "Daten ueber Port PC wurden nicht korrekt ueber Leseport C gelesen" severity note;
            report "Registeradresse: " & IMG(to_integer(unsigned(PHY_PC_ADDR)));
            ERROR_IN_TESTCASE := TRUE;
                NEW_ERROR := TRUE;
        end if;
        -- if NEW_ERROR then PRINT_REGFILE; end if;
        NEW_ERROR := FALSE;
        -- Zuruecksetzen aller Registerinhalte damit im naechsten Schleifendurchlauf wieder alle Register sinnvoll
        -- ueberprueft werden koennen
        wait until REF_CLK'event and REF_CLK = '0';
        V_RESET := '1'; SET_VALUES;
        wait until REF_CLK'event and REF_CLK = '0';
        V_RESET := '0'; V_W_EN := "000"; SET_VALUES;
        -- wait until REF_CLK'event and REF_CLK = '1';
        EVAL(TESTCASE_NR, ERROR_IN_TESTCASE, ERRORS_IN_TESTCASES);
        --------------------------------------------------------------------------------

        wait until REF_CLK'event and REF_CLK = '0';
        report "Testcase " & integer'image(TESTCASE_NR) & ": Lesezugriffe erfolgen asynchron. Zu diesem Zweck werden neue Testdaten in einige Register geschrieben und nach der naechsten steigenden Taktflanke die Leseadresse geaendert. Die geaenderten Adressen sollten sofort wirksam werden, also neue Daten am Ausgang erscheinen.";
        V_W_EN  := "110";
        V_R_A_ADDR := "00000"; V_R_B_ADDR := "00001"; V_R_C_ADDR := "00010";
        V_W_A_ADDR := "00000"; V_W_B_ADDR := "00001";
        SET_VALUES;
        wait until REF_CLK'event and REF_CLK = '1';
        wait for ARM_SYS_CLK_PERIOD/4;
        V_W_A_ADDR := "00010"; V_W_B_ADDR := "00011"; SET_VALUES;
        wait until REF_CLK'event and REF_CLK = '1';
        wait for ARM_SYS_CLK_PERIOD/4;
        V_W_A_ADDR := "00100"; V_W_B_ADDR := "00101"; SET_VALUES;
        wait until REF_CLK'event and REF_CLK = '1';
        wait for ARM_SYS_CLK_PERIOD/10;
        V_W_EN  := "000"; SET_VALUES;
        if R_A_DATA /= GENERATE_DATA("00000") or R_B_DATA /=GENERATE_DATA("00001") or R_C_DATA /= GENERATE_DATA("00010")then
            report "Die aus dem Registerspeicher gelesenen Daten ensprechen nicht den Initialdaten des Testfalls." severity error;
            ERROR_IN_TESTCASE := true;
        end if;
        wait for ARM_SYS_CLK_PERIOD/10;
        V_R_A_ADDR := "00011"; V_R_B_ADDR := "00100"; V_R_C_ADDR := "00101"; SET_VALUES;
        wait for ARM_SYS_CLK_PERIOD/10;
        if R_A_DATA /= GENERATE_DATA("00011") then
            report "Aus Port A gelesenes Datum nicht korrekt, Lesen erfolgt evtl. nicht asynchron" severity error;
            report "Erwartet: " & SLV_TO_STRING(GENERATE_DATA("00011"));
            report "Erhalten: " & SLV_TO_STRING(R_A_DATA);
            ERROR_IN_TESTCASE := true;
        end if;
        if R_B_DATA /= GENERATE_DATA("00100") then
            report "Aus Port B gelesenes Datum nicht korrekt, Lesen erfolgt evtl. nicht asynchron" severity error;
            report "Erwartet: " & SLV_TO_STRING(GENERATE_DATA("00100"));
            report "Erhalten: " & SLV_TO_STRING(R_B_DATA);
            ERROR_IN_TESTCASE := true;
        end if;
        if R_C_DATA /= GENERATE_DATA("00101") then
            report "Aus Port C gelesenes Datum nicht korrekt, Lesen erfolgt evtl. nicht asynchron" severity error;
            report "Erwartet: " & SLV_TO_STRING(GENERATE_DATA("00101"));
            report "Erhalten: " & SLV_TO_STRING(R_C_DATA);
            ERROR_IN_TESTCASE := true;
        end if;
        wait until REF_CLK'event and REF_CLK = '1';
        V_RESET := '1'; SET_VALUES;
        wait until REF_CLK'event and REF_CLK = '1';
        V_RESET := '0'; SET_VALUES;
        wait until REF_CLK'event and REF_CLK = '1';
        EVAL(TESTCASE_NR, ERROR_IN_TESTCASE, ERRORS_IN_TESTCASES);



        --------------------------------------------------------------------------------
        V_W_EN := "111";
        report "Testcase " & integer'image(TESTCASE_NR) & ": Schreiben auf den PC mit allen Schreibports gleichzeitig, die Priorisierung Port A > Port B > Port PC muss greifen. Die Write-Enablesignale der Ports werden schrittweise deaktiviert. Der erste Schreibzugriff muss mit PORT A erfolgen, der zweite mit PORT B und der dritte mit PORT PC";
        V_W_A_ADDR := PHY_PC_ADDR; V_W_B_ADDR := PHY_PC_ADDR;
        V_R_A_ADDR := PHY_PC_ADDR; V_R_B_ADDR := PHY_PC_ADDR; V_R_C_ADDR := PHY_PC_ADDR;
        SET_VALUES;
        -- die durch SET_VALUES gesetzten Daten werden hier einmal ueberschrieben um abweichende Testdaten zu erhalten
        W_A_DATA <= X"AAAAAAAA"; W_B_DATA <= X"BBBBBBBB"; W_PC_DATA <= X"CCCCCCCC";
        wait until REF_CLK'event and REF_CLK = '1';
        wait for ARM_SYS_CLK_PERIOD/4;
        if NOT(R_A_DATA = X"AAAAAAAA" and R_B_DATA = X"AAAAAAAA" and R_C_DATA = X"AAAAAAAA") then
            report "Schreibport A moeglicherweise nicht korrekt priorisiert" severity error;
            report "An allen Leseports erwartet: X" & '"' & "AAAAAAAA" & '"';
            report "Gelesen: Port A = " & SLV_TO_STRING(R_A_DATA);
            report "Gelesen: Port B = " & SLV_TO_STRING(R_B_DATA);
            report "Gelesen: Port C = " & SLV_TO_STRING(R_C_DATA);
            ERROR_IN_TESTCASE := TRUE;
        end if;
        wait until REF_CLK'event and REF_CLK = '0';
        V_W_EN := "011"; SET_VALUES;
        W_A_DATA <= X"AAAAAAAA"; W_B_DATA <= X"BBBBBBBB"; W_PC_DATA <= X"CCCCCCCC";
        wait until REF_CLK'event and REF_CLK = '1';
        wait for ARM_SYS_CLK_PERIOD/4;
        if NOT(R_A_DATA = X"BBBBBBBB" and R_B_DATA = X"BBBBBBBB" and R_C_DATA = X"BBBBBBBB")then
            report "Schreibport B moeglicherweise nicht korrekt priorisiert" severity error;
            report "An allen Leseports erwartet: X" & '"' & "BBBBBBBB" & '"';
            report "Gelesen: Port A = " & SLV_TO_STRING(R_A_DATA);
            report "Gelesen: Port B = " & SLV_TO_STRING(R_B_DATA);
            report "Gelesen: Port C = " & SLV_TO_STRING(R_C_DATA);
            ERROR_IN_TESTCASE := TRUE;
        end if;
        wait until REF_CLK'event and REF_CLK = '0';
        V_W_EN := "001"; SET_VALUES;
        W_A_DATA <= X"AAAAAAAA"; W_B_DATA <= X"BBBBBBBB"; W_PC_DATA <= X"CCCCCCCC";
        wait until REF_CLK'event and REF_CLK = '1';
        wait for ARM_SYS_CLK_PERIOD/4;
        if NOT(R_A_DATA = X"CCCCCCCC" and R_B_DATA = X"CCCCCCCC" and R_C_DATA = X"CCCCCCCC")then
            report "PORT PC nicht korrekt beschrieben waehrend die Schreibsignale der PORTS A und B nicht gesetzt waren" severity error;
            report "An allen Leseports erwartet: X" & '"' & "BBBBBBBB" & '"';
            report "Gelesen: Port A = " & SLV_TO_STRING(R_A_DATA);
            report "Gelesen: Port B = " & SLV_TO_STRING(R_B_DATA);
            report "Gelesen: Port C = " & SLV_TO_STRING(R_C_DATA);
            ERROR_IN_TESTCASE := TRUE;
        end if;
        EVAL(TESTCASE_NR, ERROR_IN_TESTCASE, ERRORS_IN_TESTCASES);
        V_W_EN := "000"; SET_VALUES;
        wait until REF_CLK'event and REF_CLK = '1';


        -------------------------------------------------------------------------------
        report "Testcase " & integer'image(TESTCASE_NR) & ": Test der WRITE-after-READ Funktionalitaet: ein neues Datum wird erst nach der naechsten steigenden REF_CLK-Taktflanke am Ausgang sichtbar";
        GET_ALL_REGISTERS_A(ALL_REGISTERS_A);
        CURRENT_VALUE_0 := ALL_REGISTERS_A(0);
        wait until REF_CLK'event AND REF_CLK = '0';
        V_W_EN := "100"; V_W_A_ADDR := "00000"; V_R_A_ADDR := "00000"; V_W_B_ADDR := "11110"; V_R_B_ADDR := "11110";
        SET_VALUES;
        W_A_DATA <= X"12345678";
        wait for ARM_SYS_CLK_PERIOD/4;
        GET_ALL_REGISTERS_A(ALL_REGISTERS_A);
        if ALL_REGISTERS_A(0) /= CURRENT_VALUE_0 then
            if ALL_REGISTERS_A(0) = W_A_DATA then
                report "Fehler: neues Datum wird unmittelbar sichtbar";
            else
                report "Fehler: Unerwartete Veraenderung eines Registerinhalts vor der Taktflanke";
            end if;
            ERROR_IN_TESTCASE := TRUE;
        end if;
        wait until REF_CLK'event and REF_CLK = '1';
        wait for ARM_SYS_CLK_PERIOD/4;
        GET_ALL_REGISTERS_A(ALL_REGISTERS_A);
        if ALL_REGISTERS_A(0) /= X"12345678" then
            report "Neues Datum nach positiver Registertaktflanke nicht sichtbar." severity error;
            ERROR_IN_TESTCASE := TRUE;
        end if;
        EVAL(TESTCASE_NR, ERROR_IN_TESTCASE, ERRORS_IN_TESTCASES);
        V_W_EN := "000"; SET_VALUES;
        wait until REF_CLK'event and REF_CLK = '0';

        -------------------------------------------------------------------------------
        report "Testcase " & integer'image(TESTCASE_NR) & ": Test von mehreren simultanen Schreibzugriffen auf verschiedene Register";
        wait until REF_CLK'event AND REF_CLK = '0';
        -- set all test registers to zero using different ports (so the priorities will need to be updates)
        V_W_EN := "010";
        V_W_B_ADDR := PHY_PC_ADDR xor "00010";
        SET_VALUES;
        W_B_DATA <= x"00000000";
        wait until REF_CLK'event and REF_CLK = '1';
        wait for ARM_SYS_CLK_PERIOD/4;
        V_W_EN := "100";
        V_W_A_ADDR := PHY_PC_ADDR xor "00100";
        SET_VALUES;
        W_A_DATA <= x"00000000";
        wait until REF_CLK'event and REF_CLK = '1';
        wait for ARM_SYS_CLK_PERIOD/4;
        V_W_EN := "100";
        V_W_A_ADDR := PHY_PC_ADDR;
        SET_VALUES;
        W_A_DATA <= x"00000000";
        wait until REF_CLK'event and REF_CLK = '1';
        wait for ARM_SYS_CLK_PERIOD/4;
        -- actual test
        V_W_EN := "111";
        V_W_A_ADDR := PHY_PC_ADDR xor "00010";
        V_W_B_ADDR := PHY_PC_ADDR xor "00100";
        SET_VALUES;
        wait until REF_CLK'event and REF_CLK = '1';
        wait for ARM_SYS_CLK_PERIOD/4;
        -- check
        GET_ALL_REGISTERS_A(ALL_REGISTERS_A);
        if  ALL_REGISTERS_A(to_integer(unsigned(V_W_A_ADDR))) /= W_A_DATA OR
            ALL_REGISTERS_A(to_integer(unsigned(V_W_B_ADDR))) /= W_B_DATA OR
            ALL_REGISTERS_A(to_integer(unsigned(PHY_PC_ADDR))) /= W_PC_DATA then
            report "Fehler: simultaner Schreibzugriff auf mehrere Register funktioniert nicht.";
            report "Erwartet in Register " & integer'image(to_integer(unsigned(V_W_A_ADDR))) & " (über Schreibport A): " & SLV_TO_STRING(W_A_DATA) & " aber erhalten: " & SLV_TO_STRING(ALL_REGISTERS_A(to_integer(unsigned(V_W_A_ADDR))));
            report "Erwartet in Register " & integer'image(to_integer(unsigned(V_W_B_ADDR))) & " (über Schreibport B): " & SLV_TO_STRING(W_B_DATA) & " aber erhalten: " & SLV_TO_STRING(ALL_REGISTERS_A(to_integer(unsigned(V_W_B_ADDR))));
            report "Erwartet in Register " & integer'image(to_integer(unsigned(PHY_PC_ADDR))) & " (über Schreibport PC): " & SLV_TO_STRING(W_PC_DATA) & " aber erhalten: " & SLV_TO_STRING(ALL_REGISTERS_A(to_integer(unsigned(PHY_PC_ADDR))));
            ERROR_IN_TESTCASE := TRUE;
        end if;
        EVAL(TESTCASE_NR, ERROR_IN_TESTCASE, ERRORS_IN_TESTCASES);
        V_W_EN := "000"; SET_VALUES;
        wait until REF_CLK'event and REF_CLK = '0';
        -------------------------------------------------------------------------------
        report SEPARATOR_LINE;
        report "Simulation beendet...";
        report SEPARATOR_LINE;
        report SEPARATOR_LINE;
        NR_OF_ERRORS := 0;
        for i in 1 to NR_OF_TESTCASES loop
            if ERRORS_IN_TESTCASES(i) then
                report "Testcase " & IMG(i) & " : " & TESTCASES_NAMES(i).all & TAB_CHAR & "...fehlerhaft";
                INC(NR_OF_ERRORS);
            else
                report "Testcase " & IMG(i) & " : " & TESTCASES_NAMES(i).all & TAB_CHAR & "...korrekt";
            end if;
        end loop;
        if NR_OF_ERRORS = 0 then
            report "...Funktionstest bestanden";
        else
            report "...Funktionstest nicht bestanden." severity error;
            report "...Funktionstest nicht bestanden." severity note;
        end if;
        report SEPARATOR_LINE;
        report "Testauswertung:";

        if (NOT ERRORS_IN_TESTCASES(1)) then
            report "Korrekte Schreibzugriffe auf einzelne Ports (Testcase 1): " & TAB_CHAR & "1";
            INC(Points);
        else
            report "Korrekte Schreibzugriffe auf einzelne Ports (Testcases 1): " & TAB_CHAR & "0";
        end if;
        if (NOT ERRORS_IN_TESTCASES(2)) then
            report "Korrekte Schreibzugriffe auf einzelne Ports (Testcase 2): " & TAB_CHAR & "1";
            INC(Points);
        else
            report "Korrekte Schreibzugriffe auf einzelne Ports (Testcases 2): " & TAB_CHAR & "0";
        end if;
        if (NOT ERRORS_IN_TESTCASES(3)) then
            report "Wirkung der Enable-Signale (Testcase 3): " & TAB_CHAR & TAB_CHAR & TAB_CHAR & "1";
            INC(Points);
        else
            report "Wirkung der Enable-Signale (Testcase 3): " & TAB_CHAR & TAB_CHAR & TAB_CHAR & "0";
        end if;
        -- if (NOT ERRORS_IN_TESTCASES(4))then
        --     report "Wirkung des Reset-Signals (Testcase 4): " & TAB_CHAR & TAB_CHAR & TAB_CHAR & "1";
        --     INC(Points);
        -- else
        --     report "Wirkung des Reset-Signals (Testcase 4): " & TAB_CHAR & TAB_CHAR & TAB_CHAR & "0";
        -- end if;
        if (NOT ERRORS_IN_TESTCASES(4)) then
            report "Konfliktfreie Verwendung aller Ports gleichzeitig (Testcase 4): " & TAB_CHAR & "1";
            INC(Points);
        else
            report "Konfliktfreie Verwendung aller Ports gleichzeitig (Testcase 4): " & TAB_CHAR & "0";
        end if;
        if (NOT ERRORS_IN_TESTCASES(5)) then
            report "Asynchroner Lesezugriff (Testcase 5): " & TAB_CHAR & TAB_CHAR  & TAB_CHAR & TAB_CHAR & "1";
            INC(Points);
        else
            report "Asynchroner Lesezugriff (Testcase 5): " & TAB_CHAR & TAB_CHAR &  TAB_CHAR & TAB_CHAR & "0";
        end if;
        if (NOT ERRORS_IN_TESTCASES(6)) then
            report "Korrekte Priorisierung der Schreibports (Testcase 6): " & TAB_CHAR & TAB_CHAR & "1 ";
            INC(Points);
        else
            report "Korrekte Priorisierung der Schreibports (Testcase 6): " & TAB_CHAR & TAB_CHAR & "0 ";
        end if;
        if (NOT ERRORS_IN_TESTCASES(7)) then
            report "Taktflankengesteuerter Schreibzugriff (Testcase 7): " & TAB_CHAR & TAB_CHAR & "1 ";
            INC(Points);
        else
            report "Taktflankengesteuerter Schreibzugriff (Testcase 7): " & TAB_CHAR & TAB_CHAR & "0 ";
        end if;
        if (NOT ERRORS_IN_TESTCASES(8)) then
            report "Simultane Nutzer der Schreibports (Testcase 8): " & TAB_CHAR & TAB_CHAR & "1 ";
            INC(Points);
        else
            report "Simultane Nutzer der Schreibports (Testcase 8): " & TAB_CHAR & TAB_CHAR & "0 ";
        end if;

        NR_OF_ERRORS := 0;
        -- if ERRORS_IN_TESTCASES(1) then INC(NR_OF_ERRORS); end if;
        -- if ERRORS_IN_TESTCASES(3) then INC(NR_OF_ERRORS); end if;
        -- if ERRORS_IN_TESTCASES(4) then INC(NR_OF_ERRORS); end if;
        -- if ERRORS_IN_TESTCASES(6) then INC(NR_OF_ERRORS); end if;
        -- if ERRORS_IN_TESTCASES(7) then INC(NR_OF_ERRORS); end if;
        -- if NR_OF_ERRORS < 3 then
        --     report "Uebrige Funktionalitaet (Testcase 1,3,4,6,7): " & TAB_CHAR  & TAB_CHAR & TAB_CHAR & IMG(3 - NR_OF_ERRORS) & "/3 Punkte";
        --     Points := Points + (3 - NR_OF_ERRORS);
        -- else
        --     report "Uebrige Funktionalitaet (Testcase 1,3,4,6,7): " & TAB_CHAR  & TAB_CHAR & TAB_CHAR & "0/3 Punkte";
        -- end if;
        report "Gesamtauswertung: " &  TAB_CHAR & TAB_CHAR & TAB_CHAR & TAB_CHAR & TAB_CHAR & TAB_CHAR & IMG(Points) & "/8";
        report SEPARATOR_LINE;
        report SEPARATOR_LINE;

        SIMULATION_RUNNING <= FALSE;
        report " EOT (END OF TEST) - Diese Fehlermeldung stoppt den Simulator unabhaengig von tatsaechlich aufgetretenen Fehlern!" severity failure;
        wait;

    end process TEST_UUT;

end architecture behave;
