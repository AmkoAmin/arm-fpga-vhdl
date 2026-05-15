------------------------------------------------------------------------------
--  Xilinx Artix-7 Distributed RAM Primitive RAM32M
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity DistRAM32M is
  port (
    WCLK  : in std_logic;
    ADDRA : in std_logic_vector(4 downto 0);
    ADDRB : in std_logic_vector(4 downto 0);
    ADDRC : in std_logic_vector(4 downto 0);
    ADDRD : in std_logic_vector(4 downto 0);
    DID   : in std_logic_vector(1 downto 0);
    DOA   : out std_logic_vector(1 downto 0);
    DOB   : out std_logic_vector(1 downto 0);
    DOC   : out std_logic_vector(1 downto 0);
    DOD   : out std_logic_vector(1 downto 0);
    WED   : in std_logic
  );
end entity;

architecture rtl of DistRAM32M is
begin

end architecture;
