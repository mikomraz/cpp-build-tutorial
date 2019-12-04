all : hello hello_s_static hello_s_dynamic

hello : hello.o
	gcc -o hello hello.o

hello.o : hello.c
	gcc -c hello.c

hello_s_static : hello_secret.o libsecret.a
	gcc -o hello_s_static hello_secret.o -L. -lsecret

hello_s_dynamic : hello_secret.o libsecret.so
	gcc -o hello_s_dynamic hello_secret.o -L. -lsecret

libsecret.a : secret.o
	ar cr libsecret.a secret.o

libsecret.so : secret.o
	ld -shared -o libsecret.so secret.o

secret.o : secret.c secret.h
	gcc -c -I. secret.c

hello_secret.o : hello_secret.c
	gcc -c -I. hello_secret.c

clean :
	rm hello *.o *.a *.so
