In block transfers, each request results in tape movement and
a transfer of an information block to or from a location in
memory. SOLOS uses block-by-block access to provide the tape
commands.

In byte transfers, on the other hand, SOLOS buffers the data
into 256 byte blocks, doing cassette operations only once per
256 transfers. BASIC uses byte-by-byte access for data files.
Other programs--such as editors, assemblers or special userwritten programs--can also call the byte-by-byte routines if a
few specific conventions and calling sequences are followed.


cassette_read_block
	Reads a file, including the header, from tape.
	Turns the tape on (if using CUTS)

	The entry point for RDBLK is C013.
	
	SOLOS/CUTER:
	On entry: Register A contains Unit and Speed data with bit 5 (speed) 0 for 1200 baud (or 1 for 300 baud); bit 7=1
for Tape 1; bit 6=1 for Tape 2; and all other bits=0.
	
	CUTEST:
	On entry: Tape speed and unit from SET is used

	Registers H & L contain the address of file header information.
	Registers D & E contain the address-of where the file is to be loaded into memory. (If set to 0, this information is taken from file header information on tape.)


	On exit: Normal return: Carry Flag is cleared, and data has been transferred into memory.
	Error return: On errors, or user pressing MODE (or Control-@) from keyboard, the Carry Flag is set.



cassette_write_block
	Writes a file, including the header, to tape
	Call write_header which calls tape_on



Byte access:

cassette_write_byte
	Must be called _after_ a file is opened with cassette_open (FOPEN entry point)



	Writes a byte
