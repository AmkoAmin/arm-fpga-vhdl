--------------------------------------------------------------------------------
--  Shifter des HWPR-Prozessors, instanziiert einen Barrelshifter.
--
--  Der Barrelshifter (Aufgabe 2) fuehrt alle LSL/LSR/ASR/ROR-Operationen mit
--  Schiebeweiten von 0 bis 31 aus. Saemtliche Sonderfaelle werden hier im
--  ArmShifter formuliert:
--    * RRX                       (Rotate Right with Extend, um genau 1 Stelle)
--    * Schiebeweiten > 31 Bit    (Weiten 0..255 sind moeglich)
--
--  Abbildung SHIFT_TYPE_IN -> MUX_CTRL des Barrelshifters:
--    SHIFT_TYPE_IN steht IMMER fuer eine Veraenderung des Operanden, waehrend
--    MUX_CTRL="00" "kein Shift" bedeutet. Die Weite 0 muss daher nicht ueber
--    MUX_CTRL="00" abgebildet werden: bei AMOUNT=0 leitet der Barrelshifter den
--    Operanden ohnehin unveraendert durch (C_OUT = C_IN). Es genuegt deshalb,
--    die Schiebeart auf MUX_CTRL abzubilden:
--      SH_LSL -> "01"
--      SH_LSR -> "10"  (ARITH_SHIFT='0')
--      SH_ASR -> "10"  (ARITH_SHIFT='1')
--      SH_ROR -> "11"
--
--  Carry- und Ergebnisverhalten der Sonderfaelle (ARM-Konvention):
--    LSL  = 32 : Ergebnis 0,            C_OUT = OPERAND(0)
--    LSL  > 32 : Ergebnis 0,            C_OUT = '0'
--    LSR  = 32 : Ergebnis 0,            C_OUT = OPERAND(31)
--    LSR  > 32 : Ergebnis 0,            C_OUT = '0'
--    ASR >= 32 : Ergebnis = Vorzeichen, C_OUT = OPERAND(31)
--    ROR Vielfaches von 32 (>0): Ergebnis = OPERAND, C_OUT = OPERAND(31)
--                                (ROR um m = AMOUNT mod 32 mit m/=0 erledigt
--                                 der Barrelshifter direkt)
--    RRX       : Ergebnis = C_IN & OPERAND(31:1), C_OUT = OPERAND(0)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ArmTypes.all;

entity ArmShifter is
    port (
        SHIFT_OPERAND : in  std_logic_vector(31 downto 0);
        SHIFT_AMOUNT  : in  std_logic_vector(7 downto 0);
        SHIFT_TYPE_IN : in  std_logic_vector(1 downto 0);
        SHIFT_C_IN    : in  std_logic;
        SHIFT_RRX     : in  std_logic;
        SHIFT_RESULT  : out std_logic_vector(31 downto 0);
        SHIFT_C_OUT   : out std_logic
    );
end entity ArmShifter;

architecture behave of ArmShifter is

    component ArmBarrelShifter
        generic (
            OPERAND_WIDTH : integer;
            SHIFTER_DEPTH : integer
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
    end component ArmBarrelShifter;

    --  Steuer- und Ergebnissignale des instanziierten Barrelshifters.
    signal BS_MUX_CTRL : std_logic_vector(1 downto 0);
    signal BS_ARITH    : std_logic;
    signal BS_DATA     : std_logic_vector(31 downto 0);
    signal BS_CARRY    : std_logic;

    --  Die unteren 5 Bit der Weite (= AMOUNT mod 32) steuern den Barrelshifter.
    signal AMOUNT_LOW  : std_logic_vector(4 downto 0);

begin

    AMOUNT_LOW <= SHIFT_AMOUNT(4 downto 0);

    --  Schiebeart auf MUX_CTRL abbilden (Weite-0-Fall erledigt der Barrelshifter).
    with SHIFT_TYPE_IN select BS_MUX_CTRL <=
        "01" when SH_LSL,
        "10" when SH_LSR,
        "10" when SH_ASR,
        "11" when SH_ROR,
        "00" when others;

    BS_ARITH <= '1' when SHIFT_TYPE_IN = SH_ASR else '0';

    --  Barrelshifter (Aufgabe 2): fuehrt die Operation fuer Weiten 0..31 aus.
    BARREL : ArmBarrelShifter
        generic map (
            OPERAND_WIDTH => 32,
            SHIFTER_DEPTH => 5
        )
        port map (
            OPERAND     => SHIFT_OPERAND,
            MUX_CTRL    => BS_MUX_CTRL,
            AMOUNT      => AMOUNT_LOW,
            ARITH_SHIFT => BS_ARITH,
            C_IN        => SHIFT_C_IN,
            DATA_OUT    => BS_DATA,
            C_OUT       => BS_CARRY
        );

    --  Auswahl zwischen Barrelshifter-Ergebnis und den Sonderfaellen.
    SELECT_PROC : process (SHIFT_RRX, SHIFT_TYPE_IN, SHIFT_OPERAND, SHIFT_C_IN,
                           SHIFT_AMOUNT, AMOUNT_LOW, BS_DATA, BS_CARRY)
        variable amt : unsigned(7 downto 0);
    begin
        amt := unsigned(SHIFT_AMOUNT);

        --  Standardfall: Ergebnis des Barrelshifters (Weiten 0..31).
        SHIFT_RESULT <= BS_DATA;
        SHIFT_C_OUT  <= BS_CARRY;

        if SHIFT_RRX = '1' then
            --  RRX: um genau eine Stelle nach rechts, C_IN rueckt ins MSB.
            SHIFT_RESULT <= SHIFT_C_IN & SHIFT_OPERAND(31 downto 1);
            SHIFT_C_OUT  <= SHIFT_OPERAND(0);
        else
            case SHIFT_TYPE_IN is
                when SH_LSL =>
                    if amt = 32 then
                        SHIFT_RESULT <= (others => '0');
                        SHIFT_C_OUT  <= SHIFT_OPERAND(0);
                    elsif amt > 32 then
                        SHIFT_RESULT <= (others => '0');
                        SHIFT_C_OUT  <= '0';
                    end if;

                when SH_LSR =>
                    if amt = 32 then
                        SHIFT_RESULT <= (others => '0');
                        SHIFT_C_OUT  <= SHIFT_OPERAND(31);
                    elsif amt > 32 then
                        SHIFT_RESULT <= (others => '0');
                        SHIFT_C_OUT  <= '0';
                    end if;

                when SH_ASR =>
                    if amt >= 32 then
                        SHIFT_RESULT <= (others => SHIFT_OPERAND(31));
                        SHIFT_C_OUT  <= SHIFT_OPERAND(31);
                    end if;

                when SH_ROR =>
                    --  Vielfaches von 32 (>0): Operand unveraendert, Carry = MSB.
                    --  ROR um m = AMOUNT mod 32 mit m/=0 erledigt der Barrelshifter.
                    if amt /= 0 and AMOUNT_LOW = "00000" then
                        SHIFT_RESULT <= SHIFT_OPERAND;
                        SHIFT_C_OUT  <= SHIFT_OPERAND(31);
                    end if;

                when others =>
                    null;
            end case;
        end if;
    end process SELECT_PROC;

end architecture behave;
