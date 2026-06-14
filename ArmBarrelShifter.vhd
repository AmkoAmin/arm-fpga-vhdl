--------------------------------------------------------------------------------
--  Barrelshifter fuer LSL, LSR, ASR, ROR mit Shiftweiten von 0 bis (n-1).
--
--  Implementierung mit verschachtelten Schleifen in einem einzigen Prozess.
--
--    Aeussere Schleife: iteriert ueber die Stufen (0 bis SHIFTER_DEPTH-1).
--                       Stufe i schiebt/rotiert optional um 2^i Stellen.
--    Innere Schleife:   beschreibt alle Bits des Operanden in dieser Stufe.
--
--  Variablen (nicht Signale) werden fuer Zwischenwerte verwendet, damit jede
--  Zuweisung sofort sichtbar ist und die naechste Stufe darauf aufbauen kann.
--
--  MUX_CTRL:
--    "00"  kein Shift   (Operand unveraendert, C_OUT = C_IN)
--    "01"  LSL          (Linksshift, logisch)
--    "10"  LSR/ASR      (Rechtsshift, logisch oder arithmetisch per ARITH_SHIFT)
--    "11"  ROR          (Rechtsrotation)
--
--  Carry (ARM-Konvention):
--    Weite = 0  =>  C_OUT = C_IN  (Carry-Kette reicht C_IN unveraendert durch)
--    LSL        =>  C_OUT = zuletzt nach links herausgeschobenes Bit
--    LSR/ASR    =>  C_OUT = zuletzt nach rechts herausgeschobenes Bit
--    ROR        =>  C_OUT = zuletzt rotiertes rechtes Bit
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity ArmBarrelShifter is
    generic (
        OPERAND_WIDTH : integer := 4;   -- z.B. 4 oder 32
        SHIFTER_DEPTH : integer := 2    -- log2(OPERAND_WIDTH), z.B. 2 oder 5
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

    SHIFT_PROC : process(OPERAND, MUX_CTRL, AMOUNT, ARITH_SHIFT, C_IN)
        --  current: Zwischenwert nach jeder abgeschlossenen Stufe.
        --  Als Variable, damit die naechste Stufe den aktualisierten Wert liest.
        variable current : std_logic_vector(OPERAND_WIDTH-1 downto 0);
        variable saved   : std_logic_vector(OPERAND_WIDTH-1 downto 0);
        variable carry   : std_logic;
        variable fill    : std_logic;  -- Fuellbit fuer Rechtsshift
        variable shift_w : integer;    -- Schiebeweite dieser Stufe (= 2^stage)
    begin

        -- ----------------------------------------------------------------
        --  Kein Shift: Operand und C_IN direkt ausgeben
        -- ----------------------------------------------------------------
        if MUX_CTRL = "00" then
            DATA_OUT <= OPERAND;
            C_OUT    <= C_IN;

        -- ----------------------------------------------------------------
        --  Linksshift (LSL)
        --
        --  Stufe i schiebt um shift_w = 2^i nach links:
        --    - Neue MSBs kommen von Bit (OPERAND_WIDTH-1-shift_w) downto 0
        --    - Untere shift_w Bits werden mit '0' aufgefuellt
        --    - Carry = current(OPERAND_WIDTH - shift_w)  (naechstes MSB)
        --
        --  Innere Schleife laeuft von MSB abwaerts, damit kein Bit
        --  ueberschrieben wird, bevor es gelesen wurde.
        -- ----------------------------------------------------------------
        elsif MUX_CTRL = "01" then
            current := OPERAND;
            carry   := C_IN;

            for stage in 0 to SHIFTER_DEPTH-1 loop
                shift_w := 2**stage;

                if AMOUNT(stage) = '1' then
                    carry := current(OPERAND_WIDTH - shift_w);

                    for j in OPERAND_WIDTH-1 downto shift_w loop
                        current(j) := current(j - shift_w);
                    end loop;
                    for j in 0 to shift_w-1 loop
                        current(j) := '0';
                    end loop;
                end if;
            end loop;

            DATA_OUT <= current;
            C_OUT    <= carry;

        -- ----------------------------------------------------------------
        --  Rechtsshift: logisch (LSR) oder arithmetisch (ASR)
        --
        --  Stufe i schiebt um shift_w = 2^i nach rechts:
        --    - Neue LSBs kommen von Bit (OPERAND_WIDTH-1) downto shift_w
        --    - Obere shift_w Bits werden mit fill aufgefuellt
        --    - Carry = current(shift_w - 1)  (naechstes LSB)
        --
        --  Fuellbit: '0' (LSR) oder urspruengliches MSB des Eingangs (ASR).
        --  Das Eingangs-MSB wird einmalig vor der Schleife gelesen; so
        --  bleibt der Fuellwert bei allen Stufen konstant (ARM-Verhalten).
        --
        --  Innere Schleife laeuft von LSB aufwaerts.
        -- ----------------------------------------------------------------
        elsif MUX_CTRL = "10" then
            current := OPERAND;
            carry   := C_IN;
            if ARITH_SHIFT = '1' then
                fill := OPERAND(OPERAND_WIDTH-1);
            else
                fill := '0';
            end if;

            for stage in 0 to SHIFTER_DEPTH-1 loop
                shift_w := 2**stage;

                if AMOUNT(stage) = '1' then
                    carry := current(shift_w - 1);

                    for j in 0 to OPERAND_WIDTH-1-shift_w loop
                        current(j) := current(j + shift_w);
                    end loop;
                    for j in OPERAND_WIDTH-shift_w to OPERAND_WIDTH-1 loop
                        current(j) := fill;
                    end loop;
                end if;
            end loop;

            DATA_OUT <= current;
            C_OUT    <= carry;

        -- ----------------------------------------------------------------
        --  Rechtsrotation (ROR)
        --
        --  Stufe i rotiert um shift_w = 2^i nach rechts:
        --    - Untere shift_w Bits rotieren nach oben (MSB-Seite)
        --    - Carry = current(shift_w - 1)  (naechstes LSB)
        --
        --  Um Lese-/Schreibkonflikte zu vermeiden, wird der aktuelle Wert
        --  vor der inneren Schleife in 'saved' gesichert.
        --  Dann:
        --    - untere  OPERAND_WIDTH-shift_w Bits kommen aus saved(..+shift_w)
        --    - obere   shift_w Bits           kommen aus saved(shift_w-1..0)
        -- ----------------------------------------------------------------
        else  -- MUX_CTRL = "11"
            current := OPERAND;
            carry   := C_IN;

            for stage in 0 to SHIFTER_DEPTH-1 loop
                shift_w := 2**stage;

                if AMOUNT(stage) = '1' then
                    carry := current(shift_w - 1);

                    saved := current;   -- Schnappschuss vor dem Ueberschreiben

                    for j in 0 to OPERAND_WIDTH-1-shift_w loop
                        current(j) := saved(j + shift_w);
                    end loop;
                    for j in 0 to shift_w-1 loop
                        current(OPERAND_WIDTH-shift_w + j) := saved(j);
                    end loop;
                end if;
            end loop;

            DATA_OUT <= current;
            C_OUT    <= carry;
        end if;

    end process SHIFT_PROC;

end architecture structure;