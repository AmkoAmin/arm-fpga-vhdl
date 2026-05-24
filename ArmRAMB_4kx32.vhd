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
    signal RAM : ram_type;
begin
    -- Port A: reiner Lesezugriff
    process(RAM_CLK)
    begin
        if rising_edge(RAM_CLK) then
            if ENA = '1' then
                -- Lese den aktuellen Speicherwert an der angelegten Adresse aus
                DOA <= RAM(to_integer(unsigned(ADDRA)));
            end if;
            -- Wenn ENA = '0', bleibt DOA unverändert (hält letzten Wert)
        end if;
    end process;

    -- Port B: Lese-/Schreibzugriff, Read-First, byteweises Write-Enable
    process(RAM_CLK)
        variable addr_int : integer;
        variable word : std_logic_vector(31 downto 0);  -- Zwischenspeicher für Read-First
    begin
        if rising_edge(RAM_CLK) then
            if ENB = '1' then
                addr_int := to_integer(unsigned(ADDRB));
                word := RAM(addr_int);          -- alten Wert lesen
                DOB <= word;                    -- Read-First: alter Wert erscheint
                -- Bytes gemäß WEB überschreiben
                for i in 0 to 3 loop
                    if WEB(i) = '1' then
                        word(i*8+7 downto i*8) := DIB(i*8+7 downto i*8);
                    end if;
                end loop;
                RAM(addr_int) <= word;          -- neuen Wert schreiben
            end if;
        end if;
    end process;
    
end behavioral;
