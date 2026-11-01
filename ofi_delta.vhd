library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ofi_delta is
port(
	prev_bid_q, prev_bid_p, bid_q, bid_p : in unsigned(7 downto 0);
	prev_ask_q, prev_ask_p, ask_q, ask_p : in unsigned(7 downto 0);
	delta : out signed(9 downto 0)
);

end ofi_delta;

architecture behav of ofi_delta is
signal i_bid, i_ask : signed(8 downto 0);
begin
-- Compare the previous and current prices
i_bid <= signed('0' & bid_q) when bid_p > prev_bid_p else
			-signed('0' & prev_bid_q) when bid_p < prev_bid_p else
			signed('0' & bid_q) - signed('0' & prev_bid_q);
			
i_ask <= signed('0' & ask_q) when ask_p < prev_ask_p else
			-signed('0' & prev_ask_q) when ask_p > prev_ask_p else
			signed('0' & ask_q) - signed('0' & prev_ask_q);

-- Now we calculate the single-step OFI which we called "delta"
delta <= resize(i_bid, 10) - resize(i_ask, 10);
end behav;