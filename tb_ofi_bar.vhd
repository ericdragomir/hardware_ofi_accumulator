library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Self-checking testbench for ofi_bar (threshold 100, 8-bit values).
-- One event per clock. Expected bar OFI outputs, in order: 30, -80, 45.

entity tb_ofi_bar is
end tb_ofi_bar;

architecture tb of tb_ofi_bar is

    component ofi_bar is
        port (
            clk, rst, ev_valid         : in  std_logic;
            ev_is_trade                : in  std_logic;
            ask_p, ask_q, bid_p, bid_q : in  unsigned(7 downto 0);
            trade_q                    : in  unsigned(7 downto 0);
            bar_valid                  : out std_logic;
            bar_ofi                    : out signed(15 downto 0)
        );
    end component;

    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';
    signal ev_valid    : std_logic := '0';
    signal ev_is_trade : std_logic := '0';
    signal ask_p, ask_q, bid_p, bid_q : unsigned(7 downto 0) := (others => '0');
    signal trade_q     : unsigned(7 downto 0) := (others => '0');
    signal bar_valid   : std_logic;
    signal bar_ofi     : signed(15 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    signal done   : boolean := false;   -- stops the clock so the simulation ends by itself
    signal n_bars : natural := 0;       -- how many bars the checker has seen

begin

    uut : ofi_bar
        port map (
            clk         => clk,
            rst         => rst,
            ev_valid    => ev_valid,
            ev_is_trade => ev_is_trade,
            ask_p       => ask_p,
            ask_q       => ask_q,
            bid_p       => bid_p,
            bid_q       => bid_q,
            trade_q     => trade_q,
            bar_valid   => bar_valid,
            bar_ofi     => bar_ofi
        );

    -- Clock: rising edges at 5, 15, 25 ... ns. Stops when done = true.
    clk_process : process
    begin
        while not done loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    -- Checker: every time bar_valid is high, compare bar_ofi with the expected value.
    check_proc : process (clk)
        variable expected : integer;
    begin
        if rising_edge(clk) then
            if bar_valid = '1' then
                if n_bars > 2 then
                    report "unexpected extra bar" severity error;
                else
                    case n_bars is
                        when 0      => expected := 30;
                        when 1      => expected := -80;
                        when others => expected := 45;
                    end case;
                    assert to_integer(bar_ofi) = expected
                        report "bar " & integer'image(n_bars)
                               & ": expected " & integer'image(expected)
                               & ", got " & integer'image(to_integer(bar_ofi))
                        severity error;
                end if;
                n_bars <= n_bars + 1;
            end if;
        end if;
    end process;

    -- Stimulus: one event per clock period. Inputs change on the falling edge,
    -- so the design samples stable values on the next rising edge.
    stim_proc : process

        procedure depth(bp, bq, ap, aq : natural) is
        begin
            ev_is_trade <= '0';
            ev_valid    <= '1';
            bid_p <= to_unsigned(bp, 8);
            bid_q <= to_unsigned(bq, 8);
            ask_p <= to_unsigned(ap, 8);
            ask_q <= to_unsigned(aq, 8);
            trade_q <= (others => '0');
            wait for CLK_PERIOD;
        end procedure;

        procedure trade(q : natural) is
        begin
            ev_is_trade <= '1';
            ev_valid    <= '1';
            trade_q <= to_unsigned(q, 8);
            bid_p <= (others => '0');
            bid_q <= (others => '0');
            ask_p <= (others => '0');
            ask_q <= (others => '0');
            wait for CLK_PERIOD;
        end procedure;

    begin
        -- reset
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD;

        -- bar 0 (expected OFI = 30)
        depth(100, 50, 101, 40);   -- 1: first update, only stored
        depth(100, 60, 101, 40);   -- 2: no trade yet, must NOT be counted
        trade(60);                 -- 3: bar opens, volume 60
        depth(100, 80, 101, 40);   -- 4: bid qty +20 -> +20
        depth(100, 80, 101, 30);   -- 5: ask qty -10 -> +10 (total 30)
        trade(40);                 -- 6: volume exactly 100 -> bar closes, output 30

        -- bar 1 (expected OFI = -80)
        depth(99, 50, 101, 30);    -- 7: bid price fell -> -prev_bid_q = -80
        trade(60);                 -- 8: volume 60
        trade(40);                 -- 9: volume exactly 100 -> bar closes, output -80

        -- bar 2 (expected OFI = 45)
        depth(101, 40, 102, 40);   -- 10: bid up (+40), ask up (-prev_ask_q = -30) -> +70
        depth(101, 40, 100, 25);   -- 11: bid same, ask price fell -> -25 (total 45)
        trade(50);                 -- 12: volume 50
        trade(50);                 -- 13: volume exactly 100 -> bar closes, output 45

        -- let the last pulse go through the checker
        ev_valid <= '0';
        wait for CLK_PERIOD * 3;

        assert n_bars = 3
            report "expected 3 bars, saw " & integer'image(n_bars)
            severity error;

        report "testbench finished: " & integer'image(n_bars) & " bars seen";
        done <= true;
        wait;
    end process;

end tb;