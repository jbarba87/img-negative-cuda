#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <malloc.h>

// Estructura que contiene datos de la imagen
typedef struct image{
	char *data;
	int cols;
	int rows;
	int depth;
} image;



// Funcion ejecutada en la GPU
__global__ void negativo(char *input_image, char *output_image, int nRows, int nCols){

	int r = blockIdx.x + threadIdx.x;
	int i;

	// Cada thread ejecuta una fila completa
	for (i = 0; i < nCols; i++){
		output_image[nCols*r + i] = 255 - input_image[nCols*r + i];
	}

}

// Functiones utiles
int read_pgm(char *input_name, image *img);
int write_pgm(char *output_name, image *img);



// Function main
int main(int argc, char **argv){

	image lena;

	// Lee imagen
	read_pgm(argv[1], &lena);

	char *pt = lena.data;
	int ndata = lena.rows*lena.cols;

/*
	//	Programa en C
	int i;
	for (i = 0; i < lena.rows*lena.cols; i++){
		pt[i] = 255 - pt[i];
	}
*/

	// Programa en CUDA

	char *device_input_image = NULL;
	char *device_output_image = NULL;
	cudaMalloc((void **) &device_input_image , ndata*sizeof(char));
	cudaMalloc((void **) &device_output_image , ndata*sizeof(char));

	cudaMemcpy(device_input_image, pt, ndata*sizeof(char), cudaMemcpyHostToDevice);

	// Invocando a la funcion (blocks, threads)
	int nBlocks = lena.rows/512;
	int nThreads = 512;
	negativo<<<nBlocks, nThreads>>>(device_input_image, device_output_image, lena.rows, lena.cols);

	cudaMemcpy(pt, device_output_image, ndata*sizeof(char), cudaMemcpyDeviceToHost);


	// Guarda imagen
	write_pgm(argv[2], &lena);

	return 0;

}

int read_pgm(char *input_name, image *img){

	FILE *input_fd = fopen(input_name, "r+");

	if(input_fd == NULL) {
		printf("Error al abrir el archivo : %s\n", input_name);
		exit(1);
	}

	char row[256];

	fscanf(input_fd, "%s\n", row);

	if (strncmp(row, "P5", 2) != 0){
		printf("El archivo no es PGM\n");
		exit(1);
	}

	char s_rows[3], s_cols[3], s_depth[3];
	int rows, cols, depth; 

	fscanf(input_fd,"%s\n",row);
	fgets(row, 256, input_fd);
	fscanf(input_fd,"%s\n", s_cols);
	fscanf(input_fd,"%s\n", s_rows);
	fscanf(input_fd,"%s\n", s_depth);


	rows = atoi(s_rows); 	cols = atoi(s_cols);  depth = atoi(s_depth);

	img->data = (char*) malloc(rows*cols);
	img->cols = cols;
	img->rows = rows;
	img->depth = depth;

	fread(img->data, sizeof(char), rows*cols, input_fd);

	fclose(input_fd);

	return 1;
}

int write_pgm(char *output_name, image *img){

	FILE *output_fd;
	int ndata = img->rows*img->cols;

	output_fd = fopen(output_name, "w");

	fprintf(output_fd, "%s\n", "P5");
	fprintf(output_fd, "#\n");
	fprintf(output_fd, "%i %i\n", img->rows, img->cols);
	fprintf(output_fd, "%i\n", img->depth);

	fwrite(img->data, sizeof(char), ndata, output_fd);

	fclose(output_fd);

	return 1;
}




