import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles

@cocotb.test()
async def test_tt_um_dandy_dance(dut):
    dut._log.info("Starting test...")
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Applying reset...")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 9)  # 90us with a 10us clock
    dut.rst_n.value = 1

    # Wait for 10us after reset de-assertion for the design to start its operation
    # await Timer(10, units="us")

    # Check the triangle wave
    dut._log.info("Checking triangle wave...")
    prev_x_value = int(dut.uo_out.value)
    prev_y_value = int(dut.uio_out.value)
    for _ in range(520):  # Enough cycles to see the wave go up and down
        await RisingEdge(dut.clk)
        curr_x_value = int(dut.uo_out.value)
        curr_y_value = int(dut.uio_out.value)
        
        # Check x_out wave
        if prev_x_value == 255:
            assert curr_x_value == prev_x_value - 1
        elif prev_x_value == 0:
            assert curr_x_value == prev_x_value + 1
        else:
            assert abs(curr_x_value - prev_x_value) == 1
        
        # Check y_out wave
        if prev_y_value == 255:
            assert curr_y_value == prev_y_value - 1
        elif prev_y_value == 0:
            assert curr_y_value == prev_y_value + 1
        else:
            assert abs(curr_y_value - prev_y_value) == 1
        
        prev_x_value = curr_x_value
        prev_y_value = curr_y_value

    # Check bidirectional enable path
    assert int(dut.uio_oe.value) == 0xFF

    dut._log.info("Test completed!")
