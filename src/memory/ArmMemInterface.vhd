--------------------------------------------------------------------------------
--  Schnittstelle zur Anbindung des RAM an die Busse des HWPR-Prozessors
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ArmConfiguration.all;
use work.ArmTypes.all;

entity ArmMemInterface is
    generic (
--------------------------------------------------------------------------------
--  Beide Generics sind fuer das HWPR nicht relevant und koennen von
--  Ihnen ignoriert werden.
--------------------------------------------------------------------------------
        SELECT_LINES                          : natural range 0 to 2 := 1;
        EXTERNAL_ADDRESS_DECODING_INSTRUCTION : boolean := false
    );
    port (
        RAM_CLK : in  std_logic;
        --  Instruction-Interface
        IDE     : in  std_logic;
        IA      : in  std_logic_vector(31 downto 2);
        ID      : out std_logic_vector(31 downto 0);
        IABORT  : out std_logic;
        --  Data-Interface
        DDE     : in  std_logic;
        DnRW    : in  std_logic;
        DMAS    : in  std_logic_vector(1 downto 0);
        DA      : in  std_logic_vector(31 downto 0);
        DDIN    : in  std_logic_vector(31 downto 0);
        DDOUT   : out std_logic_vector(31 downto 0);
        DABORT  : out std_logic
    );
end entity ArmMemInterface;

architecture behave of ArmMemInterface is

    component ArmRAMB_4kx32
        generic (
            SELECT_LINES : natural range 0 to 2 := 1
        );
        port (
            RAM_CLK : in  std_logic;
            ENA     : in  std_logic;
            ADDRA   : in  std_logic_vector(11 downto 0);
            WEB     : in  std_logic_vector(3 downto 0);
            ENB     : in  std_logic;
            ADDRB   : in  std_logic_vector(11 downto 0);
            DIB     : in  std_logic_vector(31 downto 0);
            DOA     : out std_logic_vector(31 downto 0);
            DOB     : out std_logic_vector(31 downto 0)
        );
    end component;

    signal s_ia_full     : std_logic_vector(31 downto 0);
    signal s_DOA         : std_logic_vector(31 downto 0);
    signal s_DOB         : std_logic_vector(31 downto 0);
    signal s_web         : std_logic_vector(3 downto 0);
    signal s_dabort_int  : std_logic;

begin

    -- 30 Bit Instruktionsadresse zu 32 Bit Byteadresse ergaenzen
    s_ia_full <= IA & "00";

    RAM_INST : ArmRAMB_4kx32
        generic map (
            SELECT_LINES => SELECT_LINES
        )
        port map (
            RAM_CLK => RAM_CLK,
            ENA     => IDE,
            ADDRA   => IA(13 downto 2),
            DOA     => s_DOA,
            ENB     => DDE,
            WEB     => s_web,
            ADDRB   => DA(13 downto 2),
            DIB     => DDIN,
            DOB     => s_DOB
        );

    -- Misalignment-Erkennung (nur DA(1:0) entscheidet, plus reservierte
    -- Codierung DMAS = "11"). Lesezugriffe werden ebenfalls als abort
    -- gemeldet, sollen aber laut Aufgabenstellung dennoch ausgefuehrt
    -- werden -> der eigentliche Speicherzugriff laeuft, nur das Schreiben
    -- wird unten durch s_web = "0000" unterbunden.
    s_dabort_int <=
        '1' when DMAS = DMAS_RESERVED                          else
        '1' when DMAS = DMAS_WORD  and DA(1 downto 0) /= "00"  else
        '1' when DMAS = DMAS_HWORD and DA(0) /= '0'            else
        '0';

    -- WEB-Ableitung: nur bei aktivem Datenbus, Schreibzugriff und
    -- ohne Misalignment werden tatsaechlich Bytes geschrieben.
    s_web <=
        "0000" when (DDE = '0' or DnRW = '0' or s_dabort_int = '1') else
        "1111" when DMAS = DMAS_WORD                                else
        "1100" when DMAS = DMAS_HWORD and DA(1) = '1'               else
        "0011" when DMAS = DMAS_HWORD                               else
        "1000" when DMAS = DMAS_BYTE and DA(1 downto 0) = "11"      else
        "0100" when DMAS = DMAS_BYTE and DA(1 downto 0) = "10"      else
        "0010" when DMAS = DMAS_BYTE and DA(1 downto 0) = "01"      else
        "0001";

    -- Instruktionsbus-Ausgaenge: Tristate fuer IDE = 0
    ID     <= (others => 'Z') when IDE = '0' else s_DOA;

    IABORT <= 'Z' when IDE = '0' else
              '1' when (unsigned(s_ia_full) < unsigned(INST_LOW_ADDR) or
                        unsigned(s_ia_full) > unsigned(INST_HIGH_ADDR)) else
              '0';

    -- Datenbus-Ausgaenge: Tristate fuer DDE = 0,
    -- DDOUT zusaetzlich Tristate bei Schreibzugriffen (DnRW = 1).
    DDOUT  <= (others => 'Z') when (DDE = '0' or DnRW = '1') else s_DOB;

    DABORT <= 'Z' when DDE = '0' else s_dabort_int;

end architecture behave;
