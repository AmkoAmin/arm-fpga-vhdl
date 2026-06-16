--------------------------------------------------------------------------------
-- PISO-Schieberegister als mögliche Grundlage für die Implementierung der RS232-
-- Schnittstelle im Hardwarepraktikum
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity PISOShiftReg is
    generic (
        WIDTH    : integer := 8
    );
    port (
        CLK      : in  std_logic;
        CLK_EN   : in  std_logic;
        LOAD     : in  std_logic;
        D_IN     : in  std_logic_vector(WIDTH-1 downto 0);
        D_OUT    : out std_logic;
        LAST_BIT : out std_logic
    );
end entity PISOShiftReg;

architecture behavioral of PISOShiftReg is
    -- Internes Schieberegister: enthaelt das geladene Datum und wird taktweise
    -- nach rechts geschoben, sodass die Bits vom LSB zum MSB seriell ausgegeben
    -- werden.
    signal shift_reg    : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

    -- Marker-Register als One-Hot-Zeiger: zu Beginn steht das gesetzte Bit an
    -- der MSB-Position und wandert mit jedem Shift mit. Erreicht es Position 0,
    -- liegt das MSB des Datums am Ausgang an.
    signal marker       : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

    -- Sticky-Flag: bleibt nach dem Ausgeben des MSB '1', bis ein neues Datum
    -- geladen wird.
    signal last_bit_reg : std_logic := '0';
begin
    D_OUT    <= shift_reg(0);
    LAST_BIT <= last_bit_reg;

    SHIFT_PROC : process(CLK) is
        variable new_marker : std_logic_vector(WIDTH-1 downto 0);
    begin
        if rising_edge(CLK) then
            if CLK_EN = '1' then
                if LOAD = '1' then
                    -- Datum uebernehmen, Marker auf MSB-Position setzen,
                    -- LAST_BIT zuruecksetzen.
                    shift_reg                  <= D_IN;
                    marker                     <= (others => '0');
                    marker(WIDTH-1)            <= '1';
                    last_bit_reg               <= '0';
                else
                    -- Logischer Rechtsshift im Daten- und Marker-Register.
                    shift_reg  <= '0' & shift_reg(WIDTH-1 downto 1);
                    new_marker := '0' & marker(WIDTH-1 downto 1);
                    marker     <= new_marker;
                    -- MSB liegt am Ausgang, sobald die '1' im Marker an
                    -- Position 0 angekommen ist. Danach Flag haengen lassen.
                    if new_marker(0) = '1' or last_bit_reg = '1' then
                        last_bit_reg <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process SHIFT_PROC;
end architecture behavioral;
