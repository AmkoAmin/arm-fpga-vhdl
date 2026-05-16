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
begin
--------------------------------------------------------------------------------
-- Auswahl und Einstellung der Registerspeicher-Implementierung
-- Version 2 des Registerspeichers nutzt Distributed RAM
-- Im HWPTI wird Version 2 implementiert, die ARM_SIM_LIB stellt
-- zu Debugging-Zwecken auch Version 1 zur Verfügung
--------------------------------------------------------------------------------
    REGFILE_VERSION : if USE_REGFILE_V2 generate
        -- Registerspeicher auf Basis von Distributed RAM
    end generate;
end architecture;
