#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define NAME_MAX 256
#define TA_NUMBER_MAX 20
#define HEADER_SIZE (TA_NUMBER_MAX*1024)
#define OUTPUT "ta.bin"

/* Flash bin struct*/
struct test_ta_bin {
	char name[NAME_MAX];
	unsigned int size;
	unsigned int offset;
	char describe[NAME_MAX];
};

struct ta_bin_header {
	unsigned int ta_number;
	struct test_ta_bin ta[TA_NUMBER_MAX];
};

int g_offset = HEADER_SIZE;
struct ta_bin_header *g_header;


/* PC struct*/
struct process_ta_bin {
	char path[NAME_MAX];
	char name[NAME_MAX];
	char describe[NAME_MAX];
};

struct process_ta_bin g_p_ta_bin[] = {
	/* examples hello world ta*/
	{"./optee/optee_examples/hello_world/ta/8aaaf200-2450-11e4-abe2-0002a5d5c51b.ta",
	"8aaaf200-2450-11e4-abe2-0002a5d5c51b.ta", "examples hello world ta"},
	/* examples secure storage ta*/
	{"./optee/optee_examples/secure_storage/ta/f4e750bb-1437-4fbf-8785-8d3580c34994.ta",
	"f4e750bb-1437-4fbf-8785-8d3580c34994.ta", "examples secure storage ta"},
	/* xtest crypto ta*/
	{"./optee/optee_test/out/ta/crypt/cb3e5ba0-adf1-11e0-998b-0002a5d5c51b.ta",
	"cb3e5ba0-adf1-11e0-998b-0002a5d5c51b.ta", "xtest crypto ta"},
	/* xtest concurrent ta*/
	{"./optee/optee_test/out/ta/concurrent/e13010e0-2ae1-11e5-896a-0002a5d5c51b.ta",
	"e13010e0-2ae1-11e5-896a-0002a5d5c51b.ta", "xtest concurrent ta"},
	/* xtest create fail test ta*/
	{"./optee/optee_test/out/ta/create_fail_test/c3f6e2c0-3548-11e1-b86c-0800200c9a66.ta",
	"c3f6e2c0-3548-11e1-b86c-0800200c9a66.ta", "xtest create fail test ta"},
	/* xtest concurrent large ta*/
	{"./optee/optee_test/out/ta/concurrent_large/5ce0c432-0ab0-40e5-a056-782ca0e6aba2.ta",
	"5ce0c432-0ab0-40e5-a056-782ca0e6aba2.ta", "xtest concurrent large ta"},
	/* xtest os test ta*/
	{"./optee/optee_test/out/ta/os_test/5b9e0e40-2636-11e1-ad9e-0002a5d5c51b.ta",
	"5b9e0e40-2636-11e1-ad9e-0002a5d5c51b.ta", "xtest  os test ta"},
	/* xtest os test lib ta*/
	{"./optee/optee_test/out/ta/os_test_lib/ffd2bded-ab7d-4988-95ee-e4962fff7154.ta",
	"ffd2bded-ab7d-4988-95ee-e4962fff7154.ta", "xtest  os test lib ta"},
	/* xtest os test lib dl ta*/
	{"./optee/optee_test/out/ta/os_test_lib_dl/b3091a65-9751-4784-abf7-0298a7cc35ba.ta",
	"b3091a65-9751-4784-abf7-0298a7cc35ba.ta", "xtest  os test lib dl ta"},
	/* xtest rpc test ta*/
	{"./optee/optee_test/out/ta/rpc_test/d17f73a0-36ef-11e1-984a-0002a5d5c51b.ta",
	"d17f73a0-36ef-11e1-984a-0002a5d5c51b.ta", "xtest rpc test ta"},
	/* xtest miss ta*/
	{"./optee/optee_test/out/ta/miss/528938ce-fc59-11e8-8eb2-f2801f1b9fd1.ta",
	"528938ce-fc59-11e8-8eb2-f2801f1b9fd1.ta", "xtest miss ta"},
	/* xtest sims ta*/
	{"./optee/optee_test/out/ta/sims/e6a33ed4-562b-463a-bb7e-ff5e15a493c8.ta",
	"e6a33ed4-562b-463a-bb7e-ff5e15a493c8.ta", "xtest sims ta"},
	/* xtest sims keepalive ta*/
	{"./optee/optee_test/out/ta/sims_keepalive/a4c04d50-f180-11e8-8eb2-f2801f1b9fd1.ta",
	"a4c04d50-f180-11e8-8eb2-f2801f1b9fd1.ta", "xtest sims keepalive ta"},
	/* xtest storage ta*/
	{"./optee/optee_test/out/ta/storage/b689f2a7-8adf-477a-9f99-32e90c0ad0a2.ta",
	"b689f2a7-8adf-477a-9f99-32e90c0ad0a2.ta", "xtest storage ta"},
};


void merge_flash(char *binfile, char *flashfile, int flash_pos, int index)
{
	FILE *fbin;
	FILE *fflash;
	unsigned char *tmp_data;
	int j = 0;

	int file_size = 0;
	int flash_size = 0;

	fbin = fopen(binfile, "rb");
	if (fbin == NULL) {
		printf("   Can't open '%s' for reading.\n", binfile);
		return;
	}

	if (fseek(fbin, 0, SEEK_END) != 0) {
		printf("   Can't seek end of '%s'.\n", binfile);
		/* Handle Error */
	}
	file_size = ftell(fbin);

	/* Update offset and header*/
	g_header->ta[index].size = file_size;
	g_header->ta[index].offset = flash_pos;
	g_offset += file_size;
	printf("merge %s, size %d bytes, write to offset:%d\n", binfile, file_size, flash_pos);

	if (fseek(fbin, 0, SEEK_SET) != 0) {
		printf("   Can't seek end of '%s'.\n", binfile);
		/* Handle Error */
	}

	fflash  = fopen(flashfile, "rb+");
	if (fflash == NULL) {
		printf("   Can't open '%s' for writing.\n", flashfile);
		return;
	}
	if (fseek(fflash, 0, SEEK_END) != 0) {
		printf("   Can't seek end of '%s'.\n", flashfile);
		/* Handle Error */
	}
	flash_size = ftell(fflash);
	rewind(fflash);
	fseek(fflash, flash_pos, SEEK_SET);


	tmp_data = malloc((1+file_size)*sizeof(char));

	if (file_size <= 0)
		printf("Not able to get file size %s", binfile);


	int len_read = fread(tmp_data, sizeof(char), file_size, fbin);
	int len_write = fwrite(tmp_data, sizeof(char), file_size, fflash);

	if (len_read != len_write)
		printf("Not able to merge %s, %d bytes read,%d to write,%d file_size\n", binfile, len_read, len_write, file_size);

	/* Last ta is write, write header to flash*/
	if (index == sizeof(g_p_ta_bin)/sizeof(struct process_ta_bin) - 1) {
		rewind(fflash);
		g_header->ta_number = sizeof(g_p_ta_bin)/sizeof(struct process_ta_bin);
		len_write = fwrite(g_header, sizeof(char), sizeof(struct ta_bin_header), fflash);
		printf("write header size %d\n", len_write);
	}


	fclose(fbin);

	fclose(fflash);

	free(tmp_data);
}


int main(int argc, char *argv[])
{
		// Flash size, can spread by write
		system("dd if=/dev/zero bs=200K count=1 > ta.bin");
		g_header = (struct ta_bin_header *)malloc(sizeof(struct ta_bin_header));

		int ta_number = sizeof(g_p_ta_bin)/sizeof(struct process_ta_bin);

		for (int i = 0; i < ta_number; i++) {
			memcpy(g_header->ta[i].name, g_p_ta_bin[i].name, NAME_MAX);
			memcpy(g_header->ta[i].describe, g_p_ta_bin[i].describe, NAME_MAX);
			merge_flash(g_p_ta_bin[i].path, OUTPUT, g_offset, i);
		}

		free(g_header);
}

