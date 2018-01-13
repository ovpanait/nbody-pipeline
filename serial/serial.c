#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <error.h>
#include <unistd.h>
#include <fcntl.h>

#define IN_CNT 4
#define RES_CNT 1
#define BYTES_NR 8

#define SERIAL_PORT "/dev/ttyUSB0"

static int serial_fd;
static struct termios tty;

int serial_setup(void)
{
	/* Open serial port */
	serial_fd = open(SERIAL_PORT, O_RDWR | O_NOCTTY | O_SYNC);
	if (serial_fd < 0) {
		perror("Open serial port:");
		return EXIT_FAILURE;
	}

	/*
	 * Set up serial interface
	 * baud rate: 9600
	 * 8 bits
	 * no parity
	 * 1 stop bit
	 */
	if (tcgetattr(serial_fd, &tty) < 0) {
		perror("tcgetattr");
		exit(0);
	}

	cfsetospeed(&tty, B9600);
	cfsetispeed(&tty, B9600);

	tty.c_cflag |= (CLOCAL | CREAD);    /* ignore modem controls */
	tty.c_cflag &= ~CSIZE;

	tty.c_cflag |= CS8;         /* 8-bit characters */
	tty.c_cflag &= ~PARENB;     /* no parity bit */
	tty.c_cflag &= ~CSTOPB;     /* only need 1 stop bit */
	/*tty.c_cflag |= CRTSCTS;  */  /* no hardware flowcontrol */

	/* setup for non-canonical mode */
	tty.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
	tty.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
	tty.c_oflag &= ~OPOST;

	/* fetch bytes as they become available */
	tty.c_cc[VMIN] = 1;
	tty.c_cc[VTIME] = 100;

	if (tcsetattr(serial_fd, TCSANOW, &tty) != 0) {
		perror("tcsetattr");
		return EXIT_FAILURE;
	}

	return EXIT_SUCCESS;
}

int main(int argc, char **argv)
{
	int ret, i;
	char c;

	int bytes_cnt, in_cnt, res_cnt;
	unsigned char rxa[BYTES_NR] = { 0x40, 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
	unsigned char rxb[BYTES_NR] = { 0x40, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
	unsigned char rya[BYTES_NR] = { 0x40, 0x88, 0x88, 0x00, 0x00, 0x00, 0x00, 0x00 };
	unsigned char ryb[BYTES_NR] = { 0x40, 0x7B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
	unsigned char uart_result[BYTES_NR];
	size_t r_ret;

	ret = serial_setup();
	if (ret == EXIT_FAILURE)
		return EXIT_FAILURE;


	/* Send input data */
	for (in_cnt = 0; in_cnt < IN_CNT; ++in_cnt) {
		unsigned char *out_buf;

		switch(in_cnt) {
		case 0:
			out_buf = rxa;
			break;
		case 1:
			out_buf = rya;
			break;
		case 2:
			out_buf = rxb;
			break;
		case 3:
			out_buf = ryb;
			break;
		}

		for (bytes_cnt = 0; bytes_cnt < BYTES_NR; ++bytes_cnt) {
			r_ret = write(serial_fd, out_buf + bytes_cnt, 1);
			if (r_ret == -1) {
				perror("write");
				exit(EXIT_FAILURE);
			}
		}
	}

	/* Read computation result from FPGA */
	for (res_cnt = 0; res_cnt < RES_CNT; ++res_cnt)
		for (bytes_cnt = 0; bytes_cnt < BYTES_NR; ++bytes_cnt) {
			r_ret = read(serial_fd,  uart_result + bytes_cnt, 1);
			if (r_ret == -1) {
				perror("read");
				exit(EXIT_FAILURE);
			}
		}


	/* Print computation result */
	printf("Result: 0x");
	for (i = 0; i < BYTES_NR; ++i)
		printf("%x", uart_result[i]);
	printf("\n");

	return EXIT_SUCCESS;
}
