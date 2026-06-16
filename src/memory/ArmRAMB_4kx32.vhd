--------------------------------------------------------------------------------
--  Wrapper um Basys3-Blockram fuer den RAM des HWPR-Prozessors.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ArmRAMB_4kx32 is
    generic (
--------------------------------------------------------------------------------
--  SELECT_LINES ist fuer das HWPR irrelevant, wird aber in einer
--  komplexeren Variante dieses Speichers zur Groessenauswahl
--  benoetigt. Im Hardwarepraktikum bitte ignorieren und nicht aendern.
--------------------------------------------------------------------------------
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
end entity ArmRAMB_4kx32;

architecture behavioral of ArmRAMB_4kx32 is

    type ram_type is array (0 to 4095) of std_logic_vector(31 downto 0);
    signal ram : ram_type;

begin

    -- Port A: synchroner Lesezugriff
    process (RAM_CLK)
    begin
        if rising_edge(RAM_CLK) then
            if ENA = '1' then
                DOA <= ram(to_integer(unsigned(ADDRA)));
            end if;
        end if;
    end process;
    -- Port B: synchroner Lese-/Schreibzugriff mit byteweisem Write-Enable.
    -- Read-First: der Lesezugriff liefert den unveraenderten Wert; das
    -- ergibt sich durch Signal-Semantik (alle Zuweisungen wirken erst
    -- nach Prozessende, das Lesen sieht also den alten Speicherinhalt).
    process (RAM_CLK)
    begin
        if rising_edge(RAM_CLK) then
            if ENB = '1' then
                DOB <= ram(to_integer(unsigned(ADDRB)));
                for i in 0 to 3 loop
                    if WEB(i) = '1' then
                        ram(to_integer(unsigned(ADDRB)))(8*i+7 downto 8*i)
                            <= DIB(8*i+7 downto 8*i);
                    end if;
                end loop;
            end if;
        end if;
    end process;
end architecture behavioral;
