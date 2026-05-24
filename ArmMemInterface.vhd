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

begin
  s_ia_full <= IA(31 downto 2) & "00";

    RAM_INST : ArmRAMB_4kx32
        generic map (
            SELECT_LINES => SELECT_LINES
        )
        port map (
            RAM_CLK => RAM_CLK,
            ENA     => IDE,
            ADDRA   => s_ia_full(13 downto 2),
            DOA     => s_DOA,
            ENB     => DDE,
            WEB     => s_web,
            ADDRB   => DA(13 downto 2),
            DIB     => DDIN,
            DOB     => s_DOB
        );

    -- Misalignment detection
    s_dabort_int <=
        '1' when DMAS = "11"                                       else
        '1' when DMAS = DMAS_TYPE_HALFWORD and DA(0) /= '0'       else
        '1' when DMAS = DMAS_TYPE_WORD and DA(1 downto 0) /= "00" else
        '0';

    -- Byte-lane write enable: only on aligned writes
    s_web <=
        "0000" when (DDE = '0' or DnRW = '0' or s_dabort_int = '1') 
        else
        "1111" when DMAS = DMAS_TYPE_WORD                            
        else
        "1100" when DMAS = DMAS_TYPE_HALFWORD and DA(1) = '1'        
        else
        "0011" when DMAS = DMAS_TYPE_HALFWORD                        
        else
        "1000" when DMAS = DMAS_TYPE_BYTE and DA(1 downto 0) = "11"  
        else
        "0100" when DMAS = DMAS_TYPE_BYTE and DA(1 downto 0) = "10"  
        else
        "0010" when DMAS = DMAS_TYPE_BYTE and DA(1 downto 0) = "01"  
        else
        "0001";

    -- DABORT: high-Z for DDE=0
    DABORT <= 'Z' when DDE = '0' else s_dabort_int;

    -- ID: high-Z for IDE=0
    ID <= (others => 'Z') when IDE = '0' else s_DOA;

    -- IABORT: high-Z for IDE=0, address range check for IDE=1
    IABORT <= 'Z' when IDE = '0' else
              '1' when (unsigned(s_ia_full) < unsigned(INST_LOW_ADDR) or
                        unsigned(s_ia_full) > unsigned(INST_HIGH_ADDR)) else
              '0';

    -- DDOUT: high-Z unless DDE=1 and read access
    DDOUT <= (others => 'Z') when (DDE = '0' or DnRW = '1') else s_DOB;
end architecture behave;
