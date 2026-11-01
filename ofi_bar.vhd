library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- assumes every trade_q < 100

entity ofi_bar is
port (
	clk, rst, ev_valid: in std_logic;
	ev_is_trade : in std_logic; -- 1 = trade, 0 = depth update
	ask_p, ask_q, bid_p, bid_q : in unsigned(7 downto 0);
	trade_q : in unsigned(7 downto 0);
	bar_valid: out std_logic;
	bar_ofi : out signed(15 downto 0)
);
end ofi_bar;

architecture behav of ofi_bar is

signal volume : unsigned(7 downto 0);
signal vol_next : unsigned(8 downto 0);

signal prev_bid_p, prev_bid_q, prev_ask_p, prev_ask_q : unsigned(7 downto 0);
signal have_prev : std_logic;

signal delta : signed(9 downto 0);
signal ofi_acc : signed(15 downto 0);
signal bar_open : std_logic;

begin 
vol_next <= resize(volume, 9) + resize(trade_q, 9);
u_delta: entity work.ofi_delta
	port map (
		bid_p => bid_p, bid_q => bid_q, prev_bid_p => prev_bid_p, prev_bid_q => prev_bid_q,
		ask_p => ask_p, ask_q => ask_q, prev_ask_p => prev_ask_p, prev_ask_q => prev_ask_q,
		delta => delta);

process(clk)
begin
	if rising_edge(clk) then
		bar_valid <= '0';
		if rst = '1' then
			have_prev <= '0';
			bar_open <= '0';
			
			ofi_acc <= (others => '0');
			bar_ofi <= (others => '0');
			
			volume <= (others => '0');
			prev_bid_p <= (others => '0');
			prev_bid_q <= (others => '0');
			prev_ask_p <= (others => '0');
			prev_ask_q <= (others => '0');
		elsif ev_valid = '1' then
			if ev_is_trade = '1' then
				bar_open <= '1';
				if vol_next >= 100 then
					bar_valid <= '1';
					volume <= resize(vol_next-100, 8);
					bar_ofi <= ofi_acc;
					ofi_acc <= (others => '0');
				else
					volume <= resize(vol_next, 8);
				end if;
			else
				prev_bid_p <= bid_p;
				prev_bid_q <= bid_q;
				prev_ask_p <= ask_p;
				prev_ask_q <= ask_q;
				have_prev <= '1';
				
				if have_prev = '1' and bar_open = '1' then
					ofi_acc <= ofi_acc + resize(delta, 16);
				end if;
			end if;
		end if;
	end if;
end process;

end behav;