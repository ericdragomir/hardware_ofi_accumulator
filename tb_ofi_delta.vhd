library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ofi_delta is
end entity;

architecture sim of tb_ofi_delta is
  signal bid_p, bid_q, prev_bid_p, prev_bid_q : unsigned(7 downto 0) := (others => '0');
  signal ask_p, ask_q, prev_ask_p, prev_ask_q : unsigned(7 downto 0) := (others => '0');
  signal delta : signed(9 downto 0);
begin
  dut : entity work.ofi_delta
    port map (
      bid_p => bid_p, bid_q => bid_q, prev_bid_p => prev_bid_p, prev_bid_q => prev_bid_q,
      ask_p => ask_p, ask_q => ask_q, prev_ask_p => prev_ask_p, prev_ask_q => prev_ask_q,
      delta => delta);

  stim : process
    -- one check = set all inputs, wait, compare
    procedure check(
      pbp, pbq, pap, paq : natural;    -- previous book: bid price, bid qty, ask price, ask qty
      bp, bq, ap, aq     : natural;    -- new book, same order
      expected           : integer;
      name               : string) is
    begin
      prev_bid_p <= to_unsigned(pbp, 8);  prev_bid_q <= to_unsigned(pbq, 8);
      prev_ask_p <= to_unsigned(pap, 8);  prev_ask_q <= to_unsigned(paq, 8);
      bid_p <= to_unsigned(bp, 8);  bid_q <= to_unsigned(bq, 8);
      ask_p <= to_unsigned(ap, 8);  ask_q <= to_unsigned(aq, 8);
      wait for 1 ns;
      assert to_integer(delta) = expected
        report name & ": expected " & integer'image(expected)
               & ", got " & integer'image(to_integer(delta))
        severity error;
    end procedure;
  begin
    check(100,50,101,40,  101,40,102,40,  80, "case 1");
    check(100,50,101,40,  100,80,101,40,   30, "case 2");
    check(100,50,101,40,   99,70,101,40,  -50, "case 3");
    check(100,50,101,40,  100,50,100,25,  -25, "case 4");
    check(100,50,101,40,  100,50,101,10,   30, "case 5");
    check(100,50,101,255, 101,255,102,40, 510, "case 6");
    check(100,50,101,200, 100,50,101,50,  150, "case 7");
    report "testbench finished";
    wait;
  end process;
end architecture;