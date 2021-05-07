CC = nvcc
FLAGS = -O2 -Wall

all: cleanall imagen_neg
	@ echo "Compilado "

cleanall: clean
	@rm -f *~ imagen_neg

clean:
	@rm -f *.o core *~

imagen_neg: imagen_neg.cu
	$(CC) -arch compute_20 -o imagen_neg imagen_neg.cu -I/usr/local/cuda/include/ -L/usr/local/cuda/include/lib
