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
if EXT_ADDRESS = "0000" then REG_NUM:=0;
    elsif EXT_ADDRESS="0001" then REG_NUM:=1;
    elsif EXT_ADDRESS="0010" then REG_NUM:=2;
    elsif EXT_ADDRESS="0011" then REG_NUM:=3;
    elsif EXT_ADDRESS="0100" then REG_NUM:=4;
    elsif EXT_ADDRESS="0101" then REG_NUM:=5;
    elsif EXT_ADDRESS="0110" then REG_NUM:=6;
    elsif EXT_ADDRESS="0111" then REG_NUM:=7;
    elsif EXT_ADDRESS="1000" then REG_NUM:=8;
    elsif EXT_ADDRESS="1001" then REG_NUM:=9;
    elsif EXT_ADDRESS="1010" then REG_NUM:=10;
    elsif EXT_ADDRESS="1011" then REG_NUM:=11;
    elsif EXT_ADDRESS="1100" then REG_NUM:=12;
    elsif EXT_ADDRESS="1101" then REG_NUM:=13;
    elsif EXT_ADDRESS="1110" then REG_NUM:=14;
    elsif EXT_ADDRESS="1111" then REG_NUM:=15;
    else
        REG_NUM:=0;
    end if;


    ------------------------------------------------
    -- USER BIT
    ------------------------------------------------

    if USER_BIT='1' then
        MODE_VAR:=USER;
    else
        MODE_VAR:=THIS_MODE;
    end if;


    ------------------------------------------------
    -- R0-R7
    ------------------------------------------------

    if REG_NUM<=7 then

        ADDR:=REG_NUM;


    ------------------------------------------------
    -- R8-R12
    ------------------------------------------------

    elsif REG_NUM<=12 then

        if MODE_VAR=FIQ then
            ADDR:=REG_NUM+8;
        else
            ADDR:=REG_NUM;
        end if;


    ------------------------------------------------
    -- R13
    ------------------------------------------------

    elsif REG_NUM=13 then

        case MODE_VAR is

            when FIQ =>
                ADDR:=21;

            when IRQ =>
                ADDR:=23;

            when SUPERVISOR =>
                ADDR:=25;

            when ABORT =>
                ADDR:=27;

            when UNDEFINED =>
                ADDR:=29;

            when others =>
                ADDR:=13;

        end case;


    ------------------------------------------------
    -- R14
    ------------------------------------------------

    elsif REG_NUM=14 then

        case MODE_VAR is

            when FIQ =>
                ADDR:=22;

            when IRQ =>
                ADDR:=24;

            when SUPERVISOR =>
                ADDR:=26;

            when ABORT =>
                ADDR:=28;

            when UNDEFINED =>
                ADDR:=30;

            when others =>
                ADDR:=14;

        end case;


    ------------------------------------------------
    -- R15
    ------------------------------------------------

    else

        ADDR:=15;

    end if;


    return std_logic_vector(
           to_unsigned(ADDR,5));
   
end function get_internal_address;

end package body ArmRegAddressTranslation;
