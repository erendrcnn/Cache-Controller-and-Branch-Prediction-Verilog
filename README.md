## Cache-Controller-and-Branch-Prediction-Verilog
The main memory module implements the memory behavior with a data chunk size of 32 bytes and a 100 cycles operation delay. the cache module contains a state machine that allows 4-byte aligned read/write operations and does not do any caching (all requests are handled).

#• Chapter 1 (onbellek.v):

Module Descriptions:

1) cache module: It is a data routing module that handles read and write requests made by external modules. The cache module forwards requests made by the external module to the main buffer module and forwards the responses processed by the cache module to the external modules. The cache module also processes requests from the main cache module and forwards responses to these requests to external modules.

2) main memory module: It is a data memory module that processes requests made by cache and external modules. The main memory module processes read and write requests, updating data in memory and transmitting necessary data in response to external modules.

3) tb_cache module tb_cache module simulates cache and main memory modules and makes signal connections between these modules. In this module, signals such as request_address_i, request_data_i, request_valid_i, request_write_valid_i from which requests sent to the cache module are made, and signals such as response_data_o, response_valid_o returned from the cache module are defined. Also, a connection is made between the cache module's request_ready_o signal and the cache module's request_ready_i signal.

How does the cache work?

1) is a data routing module that handles read and write requests made by external modules. These requests reach the module via the "request_address_i", "request_data_i", "request_valid_i" and "request_write_valid_i" entries.
2) forwards requests made by external modules to the main memory module. These requests reach the cache module by forwarding them through the outputs "main_request_address_o", "main_request_data_o", "main_request_valid_o" and "main_request_write_valid_o".
3) forwards the responses processed by the main memory module to the external modules. These responses are transmitted to external modules via the "response_data_o" and "response_valid_o" outputs.
4) it waits for responses from external modules and detects these responses via the "response_ready_i" input.
5) The cache module detects the validity of requests made by external modules via the "request_valid_i" input and forwards it to the main cache module.
6) It detects the validity of write requests made by external modules through the "request_write_valid_i" input and forwards it to the main memory module.
7) notifies external modules via output "request_ready_o" that external modules are ready to process their requests.

8) monitors the response states of external modules with the "status_r" and "counter_r" registers. These registers show what state the cache module is in and how long the response time is left. For example, if the "status_r" register gets the value "STATUS_READ", the module is ready to read data from the main buffer module. The "counter_r" register shows how long it takes to read the data.
9) receives the responses sent by the main buffer module via the "response_response_data_i" input and determines the values of the data to be transmitted to the external modules via the "response_data_o" output. It detects whether responses are valid or not via the "main_response_valid_i" input and specifies whether they are valid, which will be forwarded to external modules via the "response_valid_o" output.
10) checks the "response_ready_i" input while waiting for external modules' responses. If this input value is 1, the external module response is accepted and the cache module goes into the "STATUS_BOSTA" state.
11) In the "STATUS_CURRENT" state, it receives requests from external modules via the "request_address_i", "request_data_i", "request_valid_i" and "request_write_valid_i" entries. If the request is valid and the write request is valid, the cache module sends requests to the cache module via the outputs "main_request_address_o", "main_request_data_o", "main_request_valid_o" and "main_request_write_valid_o".
12) In the "STATUS_WAIT" state, it checks the "main_response_valid_i" entry. If the main buffer module's response is valid, the cache module sends a response to external modules via output "response_data_o" and outputs "response_valid_o" to indicate that the response is valid. At this time, the cache module enters the "STATUS_CAMPLE" state and begins to wait for new requests from external modules.
13) When "rst_i" input is 1, it resets all outputs and register circuits and goes to "STATUS_BOSTA" state.

In this way, the cache module receives requests from external modules, forwards them to the main buffer module, and forwards responses from the cache module to external modules. It also checks the validity of requests and responses and resets the logger circuits as needed.

How is the cache speeded up?

If a data is changed in the corresponding row, if the data is in the cache, the cache is modified and the copy in memory is not changed immediately. Therefore, there are two different copies of the information instantaneously.

The dirty bit is also used to show that the two copies of the information are different from each other. So this policy needs an additional bit on the cache.

In the policy, while the data is removed from the cache, it is updated with the data in the memory. In other words, the cache keeps the changed data constantly, when the data is removed from the cache and replaced by new data, this data is overwritten by the data in the memory, making the two copies the same. In this case, also two memory accesses are required if any data is removed from the cache and replaced by new data. The first is for updating the old data with the memory and the second is for loading the new data into the memory. A write-allocation cache makes room for new data on a write error, just as it does on a read error.

Time in initial cache: 51937377ns
Time elapsed on new modified cache module: 2882657ns
Approximately 18 times acceleration was observed.

#• Chapter 2 (ongorucu.v):

The predictor module is a branch predictor module.

The module includes a set of input and output signals, along with an input clock signal clk_i and an input reset signal rst_i, as well as inputs for the current program counter ps_i and the current instruction instruction_i.

The module has several entries for branch updates:
update_valid_i (update active), update_skip_i (branch received), and update_ps_i (program counter of the branch).

The module has two outputs, skipped_ps_o (predicted program counter) and skipped_valid_o (predicted valid).

The module includes several registers and arrays, such as public_history_register (public history register), GShare and GShare_next (arrays for GShare branching predictor), and doubleHeavenTables and doubleHeavenTables_next (arrays for bidirectional branching).

The module makes branch predictions using the global_history_register registrar and the GShare and doublepeakTables arrays. If the current instruction is a branching instruction, the module makes predictions based on past branching decisions held in the double-peakTables array. If the current instruction is not a branch, the module does not guess and resets the values of the skipped_ps_o and skipped_valid_o signals.

If a branch occurs, the module update_valid_ (update enabled) signal becomes active and the module updates the global_history_register register and the GShare and double-peakTables arrays using the update_skipped_i (branch received) signal and update_ps_i (the branch's program counter) inputs. This increases the accuracy of the module's future predictions.
