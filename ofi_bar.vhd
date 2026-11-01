library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- assumes every trade_q < 100

entity ofi_bar is
port (
	clk, rst, ev_valid: in std_logic;
	trade_q : in unsigned(7 downto 0);
	bar_valid: out std_logic
);
end ofi_bar;

architecture behav of ofi_bar is
signal volume : unsigned(7 downto 0);
signal vol_next : unsigned(8 downto 0);
begin 
vol_next <= resize(volume, 9) + resize(trade_q, 9);
process(clk)
begin
	if rising_edge(clk) then
		bar_valid <= '0';
		if rst = '1' then
			volume <= to_unsigned(0, 8);
		elsif ev_valid = '1' then
			if vol_next >= 100 then
				bar_valid <= '1';
				volume <= resize(vol_next-100, 8);
			else
				volume <= resize(vol_next, 8);
			end if;
		end if;
	end if;
end process;

end behav;