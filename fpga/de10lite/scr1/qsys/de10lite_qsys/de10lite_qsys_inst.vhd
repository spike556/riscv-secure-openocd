	component de10lite_qsys is
		port (
			avl_dmem_waitrequest   : out   std_logic;                                        -- waitrequest
			avl_dmem_readdata      : out   std_logic_vector(31 downto 0);                    -- readdata
			avl_dmem_readdatavalid : out   std_logic;                                        -- readdatavalid
			avl_dmem_response      : out   std_logic_vector(1 downto 0);                     -- response
			avl_dmem_burstcount    : in    std_logic_vector(0 downto 0)  := (others => 'X'); -- burstcount
			avl_dmem_writedata     : in    std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			avl_dmem_address       : in    std_logic_vector(31 downto 0) := (others => 'X'); -- address
			avl_dmem_write         : in    std_logic                     := 'X';             -- write
			avl_dmem_read          : in    std_logic                     := 'X';             -- read
			avl_dmem_byteenable    : in    std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable
			avl_dmem_debugaccess   : in    std_logic                     := 'X';             -- debugaccess
			avl_imem_waitrequest   : out   std_logic;                                        -- waitrequest
			avl_imem_readdata      : out   std_logic_vector(31 downto 0);                    -- readdata
			avl_imem_readdatavalid : out   std_logic;                                        -- readdatavalid
			avl_imem_response      : out   std_logic_vector(1 downto 0);                     -- response
			avl_imem_burstcount    : in    std_logic_vector(0 downto 0)  := (others => 'X'); -- burstcount
			avl_imem_writedata     : in    std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			avl_imem_address       : in    std_logic_vector(31 downto 0) := (others => 'X'); -- address
			avl_imem_write         : in    std_logic                     := 'X';             -- write
			avl_imem_read          : in    std_logic                     := 'X';             -- read
			avl_imem_byteenable    : in    std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable
			avl_imem_debugaccess   : in    std_logic                     := 'X';             -- debugaccess
			bld_id_export          : in    std_logic_vector(31 downto 0) := (others => 'X'); -- export
			clk_clk                : in    std_logic                     := 'X';             -- clk
			clk_sdram_clk          : in    std_logic                     := 'X';             -- clk
			pio_hex_1_0_export     : out   std_logic_vector(15 downto 0);                    -- export
			pio_hex_3_2_export     : out   std_logic_vector(15 downto 0);                    -- export
			pio_hex_5_4_export     : out   std_logic_vector(15 downto 0);                    -- export
			pio_led_export         : out   std_logic_vector(9 downto 0);                     -- export
			pio_sw_export          : in    std_logic_vector(9 downto 0)  := (others => 'X'); -- export
			reset_reset_n          : in    std_logic                     := 'X';             -- reset_n
			sdram_addr             : out   std_logic_vector(12 downto 0);                    -- addr
			sdram_ba               : out   std_logic_vector(1 downto 0);                     -- ba
			sdram_cas_n            : out   std_logic;                                        -- cas_n
			sdram_cke              : out   std_logic;                                        -- cke
			sdram_cs_n             : out   std_logic;                                        -- cs_n
			sdram_dq               : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
			sdram_dqm              : out   std_logic_vector(1 downto 0);                     -- dqm
			sdram_ras_n            : out   std_logic;                                        -- ras_n
			sdram_we_n             : out   std_logic;                                        -- we_n
			uart_waitrequest       : in    std_logic                     := 'X';             -- waitrequest
			uart_readdata          : in    std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
			uart_readdatavalid     : in    std_logic                     := 'X';             -- readdatavalid
			uart_burstcount        : out   std_logic_vector(0 downto 0);                     -- burstcount
			uart_writedata         : out   std_logic_vector(31 downto 0);                    -- writedata
			uart_address           : out   std_logic_vector(4 downto 0);                     -- address
			uart_write             : out   std_logic;                                        -- write
			uart_read              : out   std_logic;                                        -- read
			uart_byteenable        : out   std_logic_vector(3 downto 0);                     -- byteenable
			uart_debugaccess       : out   std_logic                                         -- debugaccess
		);
	end component de10lite_qsys;

	u0 : component de10lite_qsys
		port map (
			avl_dmem_waitrequest   => CONNECTED_TO_avl_dmem_waitrequest,   --    avl_dmem.waitrequest
			avl_dmem_readdata      => CONNECTED_TO_avl_dmem_readdata,      --            .readdata
			avl_dmem_readdatavalid => CONNECTED_TO_avl_dmem_readdatavalid, --            .readdatavalid
			avl_dmem_response      => CONNECTED_TO_avl_dmem_response,      --            .response
			avl_dmem_burstcount    => CONNECTED_TO_avl_dmem_burstcount,    --            .burstcount
			avl_dmem_writedata     => CONNECTED_TO_avl_dmem_writedata,     --            .writedata
			avl_dmem_address       => CONNECTED_TO_avl_dmem_address,       --            .address
			avl_dmem_write         => CONNECTED_TO_avl_dmem_write,         --            .write
			avl_dmem_read          => CONNECTED_TO_avl_dmem_read,          --            .read
			avl_dmem_byteenable    => CONNECTED_TO_avl_dmem_byteenable,    --            .byteenable
			avl_dmem_debugaccess   => CONNECTED_TO_avl_dmem_debugaccess,   --            .debugaccess
			avl_imem_waitrequest   => CONNECTED_TO_avl_imem_waitrequest,   --    avl_imem.waitrequest
			avl_imem_readdata      => CONNECTED_TO_avl_imem_readdata,      --            .readdata
			avl_imem_readdatavalid => CONNECTED_TO_avl_imem_readdatavalid, --            .readdatavalid
			avl_imem_response      => CONNECTED_TO_avl_imem_response,      --            .response
			avl_imem_burstcount    => CONNECTED_TO_avl_imem_burstcount,    --            .burstcount
			avl_imem_writedata     => CONNECTED_TO_avl_imem_writedata,     --            .writedata
			avl_imem_address       => CONNECTED_TO_avl_imem_address,       --            .address
			avl_imem_write         => CONNECTED_TO_avl_imem_write,         --            .write
			avl_imem_read          => CONNECTED_TO_avl_imem_read,          --            .read
			avl_imem_byteenable    => CONNECTED_TO_avl_imem_byteenable,    --            .byteenable
			avl_imem_debugaccess   => CONNECTED_TO_avl_imem_debugaccess,   --            .debugaccess
			bld_id_export          => CONNECTED_TO_bld_id_export,          --      bld_id.export
			clk_clk                => CONNECTED_TO_clk_clk,                --         clk.clk
			clk_sdram_clk          => CONNECTED_TO_clk_sdram_clk,          --   clk_sdram.clk
			pio_hex_1_0_export     => CONNECTED_TO_pio_hex_1_0_export,     -- pio_hex_1_0.export
			pio_hex_3_2_export     => CONNECTED_TO_pio_hex_3_2_export,     -- pio_hex_3_2.export
			pio_hex_5_4_export     => CONNECTED_TO_pio_hex_5_4_export,     -- pio_hex_5_4.export
			pio_led_export         => CONNECTED_TO_pio_led_export,         --     pio_led.export
			pio_sw_export          => CONNECTED_TO_pio_sw_export,          --      pio_sw.export
			reset_reset_n          => CONNECTED_TO_reset_reset_n,          --       reset.reset_n
			sdram_addr             => CONNECTED_TO_sdram_addr,             --       sdram.addr
			sdram_ba               => CONNECTED_TO_sdram_ba,               --            .ba
			sdram_cas_n            => CONNECTED_TO_sdram_cas_n,            --            .cas_n
			sdram_cke              => CONNECTED_TO_sdram_cke,              --            .cke
			sdram_cs_n             => CONNECTED_TO_sdram_cs_n,             --            .cs_n
			sdram_dq               => CONNECTED_TO_sdram_dq,               --            .dq
			sdram_dqm              => CONNECTED_TO_sdram_dqm,              --            .dqm
			sdram_ras_n            => CONNECTED_TO_sdram_ras_n,            --            .ras_n
			sdram_we_n             => CONNECTED_TO_sdram_we_n,             --            .we_n
			uart_waitrequest       => CONNECTED_TO_uart_waitrequest,       --        uart.waitrequest
			uart_readdata          => CONNECTED_TO_uart_readdata,          --            .readdata
			uart_readdatavalid     => CONNECTED_TO_uart_readdatavalid,     --            .readdatavalid
			uart_burstcount        => CONNECTED_TO_uart_burstcount,        --            .burstcount
			uart_writedata         => CONNECTED_TO_uart_writedata,         --            .writedata
			uart_address           => CONNECTED_TO_uart_address,           --            .address
			uart_write             => CONNECTED_TO_uart_write,             --            .write
			uart_read              => CONNECTED_TO_uart_read,              --            .read
			uart_byteenable        => CONNECTED_TO_uart_byteenable,        --            .byteenable
			uart_debugaccess       => CONNECTED_TO_uart_debugaccess        --            .debugaccess
		);

