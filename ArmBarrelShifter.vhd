--------------------------------------------------------------------------------
--  Barrelshifter fuer LSL, LSR, ASR, ROR mit Shiftweiten von 0 bis 3 (oder
--  generisch n-1) Bit.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ArmBarrelShifter is
    --------------------------------------------------------------------------------
    --  Breite der Operanden (n) und die Zahl der notwendigen
    --  Multiplexerstufen (m) um Shifts von 0 bis n-1 Stellen realisieren zu
    --  koennen. Es muss gelten: 2^m = n.
    --------------------------------------------------------------------------------
    generic (
        OPERAND_WIDTH : integer := 4;
        SHIFTER_DEPTH : integer := 2
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
end entity ArmBarrelShifter;

architecture structure of ArmBarrelShifter is

begin

end architecture structure;
