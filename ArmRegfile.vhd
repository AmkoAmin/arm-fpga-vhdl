------------------------------------------------------------------------------
--  Registerspeichers des ARM-SoC
------------------------------------------------------------------------------

library work;
use work.ArmTypes.all;
use work.ArmRegAddressTranslation.all;
use work.ArmConfiguration.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity ArmRegfile is
    port (
        REF_CLK : in std_logic;
        REF_RST : in  std_logic;

        REF_W_PORT_A_ENABLE  : in std_logic;
        REF_W_PORT_B_ENABLE  : in std_logic;
        REF_W_PORT_PC_ENABLE : in std_logic;

        REF_W_PORT_A_ADDR : in std_logic_vector(4 downto 0);
        REF_W_PORT_B_ADDR : in std_logic_vector(4 downto 0);

        REF_R_PORT_A_ADDR : in std_logic_vector(4 downto 0);
        REF_R_PORT_B_ADDR : in std_logic_vector(4 downto 0);
        REF_R_PORT_C_ADDR : in std_logic_vector(4 downto 0);

        REF_W_PORT_A_DATA  : in std_logic_vector(31 downto 0);
        REF_W_PORT_B_DATA  : in std_logic_vector(31 downto 0);
        REF_W_PORT_PC_DATA : in std_logic_vector(31 downto 0);

        REF_R_PORT_A_DATA : out std_logic_vector(31 downto 0);
        REF_R_PORT_B_DATA : out std_logic_vector(31 downto 0);
        REF_R_PORT_C_DATA : out std_logic_vector(31 downto 0)
    );
end entity ArmRegfile;

architecture behavioral of ArmRegfile is

    -- Physische Adresse von R15 (PC); ueber die Adressuebersetzung bestimmt,
    -- damit der PC-Schreibport an der korrekten Stelle landet.
    constant PHY_PC_ADDR : std_logic_vector(4 downto 0) :=
        get_internal_address("1111", USER, '0');

    -- Datenausgaenge der drei Saetze fuer die drei Leseports.
    -- Jeder Satz besteht aus 16 DistRAM32M-Modulen, die zusammen ein
    -- 32-Bit-Wort an allen drei Leseports zur Verfuegung stellen.
    signal RD_A_SETA, RD_A_SETB, RD_A_SETPC : std_logic_vector(31 downto 0);
    signal RD_B_SETA, RD_B_SETB, RD_B_SETPC : std_logic_vector(31 downto 0);
    signal RD_C_SETA, RD_C_SETB, RD_C_SETPC : std_logic_vector(31 downto 0);

    -- Kennzeichnung des aktuell gueltigen Satzes pro Registeradresse.
    -- 32 Eintraege fuer die 5-Bit-Adresse; tatsaechlich genutzt 0..30.
    type set_id is (SET_A, SET_B, SET_PC);
    type valid_set_array is array(0 to 31) of set_id;
    signal valid_set : valid_set_array := (others => SET_A);

begin
--------------------------------------------------------------------------------
-- Auswahl und Einstellung der Registerspeicher-Implementierung
-- Version 2 des Registerspeichers nutzt Distributed RAM
-- Im HWPTI wird Version 2 implementiert, die ARM_SIM_LIB stellt
-- zu Debugging-Zwecken auch Version 1 zur Verfügung
--------------------------------------------------------------------------------
    REGFILE_VERSION : if USE_REGFILE_V2 generate
        -- Registerspeicher auf Basis von Distributed RAM

        ------------------------------------------------------------------------
        --  Iterative Instanziierung der drei Saetze.
        --  Pro Satz 16 DistRAM32M-Module, jedes haelt 2 Bit eines Registers.
        --  Port D = Lese-/Schreibport, Ports A/B/C = die drei Leseports.
        ------------------------------------------------------------------------
        GEN_SLICE : for i in 0 to 15 generate

            -- Satz A: wird durch Schreibport A beschrieben
            U_SETA : entity work.DistRAM32M
                port map (
                    WCLK  => REF_CLK,
                    ADDRA => REF_R_PORT_A_ADDR,
                    ADDRB => REF_R_PORT_B_ADDR,
                    ADDRC => REF_R_PORT_C_ADDR,
                    ADDRD => REF_W_PORT_A_ADDR,
                    DID   => REF_W_PORT_A_DATA(2*i+1 downto 2*i),
                    DOA   => RD_A_SETA(2*i+1 downto 2*i),
                    DOB   => RD_B_SETA(2*i+1 downto 2*i),
                    DOC   => RD_C_SETA(2*i+1 downto 2*i),
                    DOD   => open,
                    WED   => REF_W_PORT_A_ENABLE
                );

            -- Satz B: wird durch Schreibport B beschrieben
            U_SETB : entity work.DistRAM32M
                port map (
                    WCLK  => REF_CLK,
                    ADDRA => REF_R_PORT_A_ADDR,
                    ADDRB => REF_R_PORT_B_ADDR,
                    ADDRC => REF_R_PORT_C_ADDR,
                    ADDRD => REF_W_PORT_B_ADDR,
                    DID   => REF_W_PORT_B_DATA(2*i+1 downto 2*i),
                    DOA   => RD_A_SETB(2*i+1 downto 2*i),
                    DOB   => RD_B_SETB(2*i+1 downto 2*i),
                    DOC   => RD_C_SETB(2*i+1 downto 2*i),
                    DOD   => open,
                    WED   => REF_W_PORT_B_ENABLE
                );

            -- Satz PC: schreibt ausschliesslich auf die physische Adresse
            -- von R15.
            U_SETPC : entity work.DistRAM32M
                port map (
                    WCLK  => REF_CLK,
                    ADDRA => REF_R_PORT_A_ADDR,
                    ADDRB => REF_R_PORT_B_ADDR,
                    ADDRC => REF_R_PORT_C_ADDR,
                    ADDRD => PHY_PC_ADDR,
                    DID   => REF_W_PORT_PC_DATA(2*i+1 downto 2*i),
                    DOA   => RD_A_SETPC(2*i+1 downto 2*i),
                    DOB   => RD_B_SETPC(2*i+1 downto 2*i),
                    DOC   => RD_C_SETPC(2*i+1 downto 2*i),
                    DOD   => open,
                    WED   => REF_W_PORT_PC_ENABLE
                );

        end generate GEN_SLICE;

        ------------------------------------------------------------------------
        --  Aktualisierung der Satz-Markierung pro Register.
        --  Die Reihenfolge der Zuweisungen innerhalb des Prozesses bildet die
        --  Prioritaeten ab: zuerst PC (niedrigste), dann B, zuletzt A
        --  (hoechste). Bei Adresskonflikten gewinnt damit immer Port A.
        ------------------------------------------------------------------------
        VALID_SET_UPDATE : process(REF_CLK)
        begin
            if rising_edge(REF_CLK) then
                if REF_W_PORT_PC_ENABLE = '1' then
                    valid_set(to_integer(unsigned(PHY_PC_ADDR))) <= SET_PC;
                end if;
                if REF_W_PORT_B_ENABLE = '1' then
                    valid_set(to_integer(unsigned(REF_W_PORT_B_ADDR))) <= SET_B;
                end if;
                if REF_W_PORT_A_ENABLE = '1' then
                    valid_set(to_integer(unsigned(REF_W_PORT_A_ADDR))) <= SET_A;
                end if;
            end if;
        end process VALID_SET_UPDATE;

        ------------------------------------------------------------------------
        --  Asynchrone Auswahl des gueltigen Satzes pro Leseport.
        ------------------------------------------------------------------------
        MUX_READ_A : process(valid_set, REF_R_PORT_A_ADDR,
                             RD_A_SETA, RD_A_SETB, RD_A_SETPC)
        begin
            case valid_set(to_integer(unsigned(REF_R_PORT_A_ADDR))) is
                when SET_A  => REF_R_PORT_A_DATA <= RD_A_SETA;
                when SET_B  => REF_R_PORT_A_DATA <= RD_A_SETB;
                when SET_PC => REF_R_PORT_A_DATA <= RD_A_SETPC;
                when others => REF_R_PORT_A_DATA <= RD_A_SETA;
            end case;
        end process MUX_READ_A;

        MUX_READ_B : process(valid_set, REF_R_PORT_B_ADDR,
                             RD_B_SETA, RD_B_SETB, RD_B_SETPC)
        begin
            case valid_set(to_integer(unsigned(REF_R_PORT_B_ADDR))) is
                when SET_A  => REF_R_PORT_B_DATA <= RD_B_SETA;
                when SET_B  => REF_R_PORT_B_DATA <= RD_B_SETB;
                when SET_PC => REF_R_PORT_B_DATA <= RD_B_SETPC;
                when others => REF_R_PORT_B_DATA <= RD_B_SETA;
            end case;
        end process MUX_READ_B;

        MUX_READ_C : process(valid_set, REF_R_PORT_C_ADDR,
                             RD_C_SETA, RD_C_SETB, RD_C_SETPC)
        begin
            case valid_set(to_integer(unsigned(REF_R_PORT_C_ADDR))) is
                when SET_A  => REF_R_PORT_C_DATA <= RD_C_SETA;
                when SET_B  => REF_R_PORT_C_DATA <= RD_C_SETB;
                when SET_PC => REF_R_PORT_C_DATA <= RD_C_SETPC;
                when others => REF_R_PORT_C_DATA <= RD_C_SETA;
            end case;
        end process MUX_READ_C;

    end generate;
end architecture;
