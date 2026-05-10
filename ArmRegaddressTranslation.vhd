------------------------------------------------------------------------------
--  Paket fuer die Funktionen zur die Abbildung von ARM-Registeradressen
--  auf Adressen des physischen Registerspeichers (5-Bit-Adressen)
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library work;
use work.ArmTypes.all;

package ArmRegaddressTranslation is

    function get_internal_address(
        EXT_ADDRESS : std_logic_vector(3 downto 0);
        THIS_MODE   : std_logic_vector(4 downto 0);
        USER_BIT    : std_logic)
    return std_logic_vector;

end package ArmRegaddressTranslation;

package body ArmRegAddressTranslation is

function get_internal_address(
    EXT_ADDRESS : std_logic_vector(3 downto 0);
    THIS_MODE   : std_logic_vector(4 downto 0);
    USER_BIT    : std_logic)
    return std_logic_vector
is
--------------------------------------------------------------------------------
--  Raum fuer lokale Variablen innerhalb der Funktion
--------------------------------------------------------------------------------

    begin
--------------------------------------------------------------------------------
--  Functionscode
--------------------------------------------------------------------------------
    return <Ihr Rueckgabewert>; -- '<' und '>' sind zu entfernen
end function get_internal_address;

end package body ArmRegAddressTranslation;
