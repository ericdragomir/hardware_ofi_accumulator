library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ofi_bar_tb is
end ofi_bar_tb;

architecture tb of ofi_bar_tb is

    component ofi_bar is
        port (
            clk       : in  std_logic;
            rst       : in  std_logic;
            ev_valid  : in  std_logic;
            trade_q   : in  unsigned(7 downto 0);
            bar_valid : out std_logic
        );
    end component;

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    signal ev_valid  : std_logic := '0';
    signal trade_q   : unsigned(7 downto 0) := (others => '0');
    signal bar_valid : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin
    uut: ofi_bar
        port map (
            clk       => clk,
            rst       => rst,
            ev_valid  => ev_valid,
            trade_q   => trade_q,
            bar_valid => bar_valid
        );

    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    stim_proc: process
    begin
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD;

        trade_q  <= to_unsigned(40, 8);
        ev_valid <= '1';
        wait for CLK_PERIOD;

        ev_valid <= '0';
        wait for CLK_PERIOD * 2;

        trade_q  <= to_unsigned(50, 8);
        ev_valid <= '1';
        wait for CLK_PERIOD;

        trade_q  <= to_unsigned(20, 8);
        ev_valid <= '1';
        wait for CLK_PERIOD;

        ev_valid <= '0';
        trade_q  <= to_unsigned(0, 8);
        wait for CLK_PERIOD * 3;


        trade_q  <= to_unsigned(95, 8);
        ev_valid <= '1';
        wait for CLK_PERIOD;

        ev_valid <= '0';
        wait for CLK_PERIOD * 5;

        assert false report "Simulation Finished Successfully" severity failure;
        wait;
    end process;

end tb;