-------------------------------------------------------------------------------
--  Datenreplikationseinheit fuer den Kern des ARM-SoC
--------------------------------------------------------------------------------
--  Die Datenreplikationseinheit kann in der EX- oder MEM-Stufe
--  verwendet werden. In der gegenwaertigen Pipeline bietet sich die
--  EX-Stufe an, Worte werden unveraendert weitergegeben,
--  Halbworte (immer die niederwertigen 16 Bit eines Datums aus einem ARM-
--  Register) werden auf dem niederwertigen und hochwertigen Halbwort
--  des Datenbus ausgegeben und Bytes auf alle 4 Bytes des Datenbus
--  repliziert. Aunn ohne weitere Anpassungen
--  in Little Endian und Big Endian Speicher geschrieben werden.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library work;
use work.armtypes.all;

entity ArmDataReplication is
    port (
        DRP_INPUT  : in  std_logic_vector(31 downto 0);
        DRP_DMAS   : in  std_logic_vector( 1 downto 0);
        DRP_OUTPUT : out std_logic_vector(31 downto 0)
    );
end entity ArmDataReplication;

architecture behave of ArmDataReplication is
begin

    process(DRP_INPUT, DRP_DMAS)
    begin
        case DRP_DMAS is

            -- Wort unveraendert weitergeben
            when DMAS_WORD  =>
                DRP_OUTPUT <= DRP_INPUT;

            -- Niederwertiges Halbwort auf beide Halbworte replizieren
            when DMAS_HWORD =>
                DRP_OUTPUT <= DRP_INPUT(15 downto 0) &
                              DRP_INPUT(15 downto 0);

            -- Niederwertigstes Byte auf alle vier Bytes replizieren
            when DMAS_BYTE =>
                DRP_OUTPUT <= DRP_INPUT(7 downto 0) &
                              DRP_INPUT(7 downto 0) &
                              DRP_INPUT(7 downto 0) &
                              DRP_INPUT(7 downto 0);

            -- Sicherheitsfall
            when others =>
                DRP_OUTPUT <= DRP_INPUT;

        end case;
    end process;

end architecture behave;