

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity VGA is
    Port ( CLK : in STD_LOGIC;
           RESET : in STD_LOGIC;
           HSYNC : out STD_LOGIC;
           VSYNC : out STD_LOGIC;
           BLANK : out STD_LOGIC;
           SYNC : out STD_LOGIC;
           CLKVGA : out STD_LOGIC;
           R, G, B : out STD_LOGIC_VECTOR (7 downto 0);


       segX_high, segX_low, segY_high, segY_low : out std_logic_vector(6 downto 0);

          UP_BTN, DOWN_BTN, LEFT_BTN, RIGHT_BTN : in STD_LOGIC;
          R_SW : in STD_LOGIC;
          G_SW : in STD_LOGIC;  
          B_SW : in STD_LOGIC;
          PAINT_SW : in STD_LOGIC;
          CLEAR_SW : in STD_LOGIC);
end VGA;

architecture Behavioral of VGA is


signal cursorX : integer range 0 to 5;
signal cursorY : integer range 0 to 10;

signal clk25MHz : std_logic := '0';
signal clk5Hz : std_logic := '0';
signal clkCounter : integer := 0;
signal hCounter : integer range 0 to 799 := 0;
signal vCounter : integer range 0 to 524 := 0;

-- Sync pulse and display time constants
constant hSyncPulse : integer := 96;
constant hBackPorch : integer := 48;
constant hFrontPorch : integer := 16;
constant vSyncPulse : integer := 2;
constant vBackPorch : integer := 33;
constant vFrontPorch : integer := 10;
constant hDisplay : integer := 640;
constant vDisplay : integer := 480;

constant Hb : integer := 19;      --width of block horizontal
constant Hw : integer := 1;       --width of border horizontal
constant Ha : integer := 20;      --width of both horizontal

constant Vb : integer := 19;      --width of block horizontal
constant Vw : integer := 1;       --width of border horizontal
constant Va : integer := 20;      --width of both horizontal

signal digitX_high, digitX_low, digitY_high, digitY_low : std_logic_vector(7 downto 0);

type a is array ( 0 to 10, 5 downto 0) of integer range 0 to 7;
signal board : a := (others =>(others => 0));

begin

BLANK <= '1';
SYNC <= '1';

    -- Clock division to generate 25MHz clock from the input clock
    clkDiv: process(CLK)
    begin
        if rising_edge(CLK) then
            clk25MHz <= not clk25MHz;
            CLKVGA <= clk25MHZ;
            if (clkCounter = 5000000) then
              clk5Hz <= not clk5Hz;
              clkCounter <= 0;  
            else
              clkCounter <= clkCounter + 1;
            end if;
        end if;
    end process;

    -- Horizontal counter
    hCounterProcess: process(clk25MHz, RESET)
    begin
        if RESET = '1' then
            hCounter <= 0;
        elsif rising_edge(clk25MHz) then
            if hCounter = 799 then
                hCounter <= 0;
            else
                hCounter <= hCounter + 1;
            end if;
        end if;
    end process;

    -- Vertical counter
    vCounterProcess: process(clk25MHz, RESET)
    begin
        if RESET = '1' then
            vCounter <= 0;
        elsif rising_edge(clk25MHz) then
            if hCounter = 799 then
                if vCounter = 524 then
                    vCounter <= 0;
                else
                    vCounter <= vCounter + 1;
                end if;
            end if;
        end if;
    end process;

    -- Generating HSYNC and VSYNC signals
    HSYNC <= '0' when (hCounter < hSyncPulse) else '1';
    VSYNC <= '0' when (vCounter < vSyncPulse) else '1';

    -- Generating RGB signals
    process(clk25MHz, RESET, cursorX, cursorY)
    begin
        if RESET = '1' then
            R <= (others => '0');
            G <= (others => '0');
            B <= (others => '0');
        elsif rising_edge(clk25MHz) then
                R <= (others => '0');
                G <= (others => '0');
                B <= (others => '0');
            if hCounter > 143 and hCounter < (hDisplay + 144) and vCOunter > 32 and vCounter < (vDisplay + 32) then
              R <= (others => '0');
              G <= (others => '0');
              B <= (others => '0');
              for i in 0 to 10 loop
                for j in 0 to 5 loop

                  if (Hcounter > (i+1)*HB + i*Hw + 142 and Hcounter < (i+1)*Hb + (i+1)*Hw + 142) or(i < 5 and Vcounter > i*Vb + (i-1)*Vw + 32 and Vcounter < i*Vb + i*Vw + 32) then
                    R <= "11111111";  --grid
                    G <= "11111111";
                    B <= "11111111";
                  elsif (board(i, j) > 0 and (Hcounter > (i*Ha) + 142) AND (Hcounter < (i+1)*Ha - Hw + 142) AND (Vcounter > j*Va + 32) AND (Vcounter < (j+1)*Va - Vw + 32)) then
                    if ((board(i, j) = 1) or (board(i, j) = 5) or (board(i, j) = 6) or (board(i, j) = 7)) then
                      R <= "11111111";
                    else 
                      R <= "00000000";
                    end if;

                    if ((board(i, j) = 2) or (board(i, j) = 4) or (board(i, j) = 6) or (board(i, j) = 7)) then
                      G <= "11111111";
                    else 
                      G <= "00000000";
                    end if;
      
                    if ((board(i, j) = 3) or (board(i, j) = 4) or (board(i, j) = 5) or (board(i, j) = 7)) then
                      B <= "11111111";
                    else 
                      B <= "00000000";
                    end if;
                  end if;
                end loop;
              end loop;
            end if;
        end if;
    end process;


cursorPaintProcess: process(CLK5hz)
begin
  if CLK5hz = '1' then
    if UP_BTN = '0' and cursorY > 0 then
      cursorY <= cursorY - 1;
    elsif DOWN_BTN = '0' and cursorY < 10 then
      cursorY <= cursorY + 1;
    elsif LEFT_BTN = '0' and cursorX > 0 then
      cursorX <= cursorX - 1;
    elsif RIGHT_BTN = '0' and cursorX < 5 then
      cursorX <= cursorX + 1;
    end if;

    if PAINT_SW = '1' then
      if R_SW = '0' and G_SW = '0' and B_SW = '0' then
        board(cursorX, cursorY) <= 0;
      elsif R_SW = '1' and G_SW = '0' and B_SW = '0' then
        board(cursorX, cursorY) <= 1;
      elsif R_SW = '0' and G_SW = '1' and B_SW = '0' then
        board(cursorX, cursorY) <= 2;
      elsif R_SW = '0' and G_SW = '0' and B_SW = '1' then
        board(cursorX, cursorY) <= 3;
      elsif R_SW = '0' and G_SW = '1' and B_SW = '1' then
        board(cursorX, cursorY) <= 4;
      elsif R_SW = '1' and G_SW = '0' and B_SW = '1' then
        board(cursorX, cursorY) <= 5;
      elsif R_SW = '1' and G_SW = '1' and B_SW = '0' then
        board(cursorX, cursorY) <= 6;
      elsif R_SW = '1' and G_SW = '1' and B_SW = '1' then
        board(cursorX, cursorY) <= 7;
      end if;
    end if; 

    -- FORTNITE AND MARK ASS BROWNIE

    if CLEAR_SW = '1' then
      board(cursorX, cursorY) <= 0;
    board <= (others => (others => 0));
    end if;
  end if;
end process;

digitSplitProcess: process(cursorX, cursorY)
begin
    digitX_high <= std_logic_vector(to_unsigned(cursorX / 10, digitX_high'length));
    digitX_low  <= std_logic_vector(to_unsigned(cursorX mod 10, digitX_low'length));
    digitY_high <= std_logic_vector(to_unsigned(cursorY / 10, digitY_high'length));
    digitY_low  <= std_logic_vector(to_unsigned(cursorY mod 10, digitY_low'length));
end process;

displayProcess: process(digitX_high, digitX_low, digitY_high, digitY_low)
begin
    -- Mapping for first digit X
    case digitX_high is
        when "00000000" => segX_high <= "1000000"; -- 0
        when "00000001" => segX_high <= "1111001"; -- 1
        when "00000010" => segX_high <= "0100100"; -- 2
        when "00000011" => segX_high <= "0110000"; -- 3
        when "00000100" => segX_high <= "0011001"; -- 4
        when "00000101" => segX_high <= "0010010"; -- 5
        when "00000110" => segX_high <= "0000010"; -- 6
        when "00000111" => segX_high <= "1111000"; -- 7
        when "00001000" => segX_high <= "0000000"; -- 8
        when "00001001" => segX_high <= "0110000"; -- 9
        when others => segX_high <= "1111111"; -- Blank
    end case;

    -- Mapping for second digit X
    case digitX_low is
        when "00000000" => segX_low <= "1000000"; -- 0
        when "00000001" => segX_low <= "1111001"; -- 1
        when "00000010" => segX_low <= "0100100"; -- 2
        when "00000011" => segX_low <= "0110000"; -- 3
        when "00000100" => segX_low <= "0011001"; -- 4
        when "00000101" => segX_low <= "0010010"; -- 5
        when "00000110" => segX_low <= "0000010"; -- 6
        when "00000111" => segX_low <= "1111000"; -- 7
        when "00001000" => segX_low <= "0000000"; -- 8
        when "00001001" => segX_low <= "0110000"; -- 9
        when others => segX_low <= "1111111"; -- Blank
    end case;

    -- Mapping for first digit Y
    case digitY_high is
        when "00000000" => segY_high <= "1000000"; -- 0
        when "00000001" => segY_high <= "1111001"; -- 1
        when "00000010" => segY_high <= "0100100"; -- 2
        when "00000011" => segY_high <= "0110000"; -- 3
        when "00000100" => segY_high <= "0011001"; -- 4
        when "00000101" => segY_high <= "0010010"; -- 5
        when "00000110" => segY_high <= "0000010"; -- 6
        when "00000111" => segY_high <= "1111000"; -- 7
        when "00001000" => segY_high <= "0000000"; -- 8
        when "00001001" => segY_high <= "0110000"; -- 9
        when others => segY_high <= "1111111"; -- Blank
    end case;

    -- Mapping for second digit Y
    case digitY_low is
        when "00000000" => segY_low <= "1000000"; -- 0
        when "00000001" => segY_low <= "1111001"; -- 1
        when "00000010" => segY_low <= "0100100"; -- 2
        when "00000011" => segY_low <= "0110000"; -- 3
        when "00000100" => segY_low <= "0011001"; -- 4
        when "00000101" => segY_low <= "0010010"; -- 5
        when "00000110" => segY_low <= "0000010"; -- 6
        when "00000111" => segY_low <= "1111000"; -- 7
        when "00001000" => segY_low <= "0000000"; -- 8
        when "00001001" => segY_low <= "0110000"; -- 9
        when others => segY_low <= "1111111"; -- Blank
    end case;
end process;

end Behavioral;

