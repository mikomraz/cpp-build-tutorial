# C/C++ Build Tutorial

## Compilation

### Install the gcc compiler and build utilities

`sudo apt install gcc g++ binutils make autoconf cmake`

### Building a simple app in one go

1. compile & link the app in one go using `gcc -o hello hello.c`.
2. run `./hello`.

### Building the app, in two seperate stages

1. compile only first: `gcc -c -o hello.o hello.c`
2. `hello.o` is not an executable! (try running with `./hello.o`).
3. We need a seperate stage, called "linking". This stage transforms a compiled binary into an *executable*. Let's try: `gcc -o hello hello.o` + `./hello`.
4. Some LL comparison of `hello.o` and `hello`, using: `nm` (symbols list), `objdump -d` (machine code). `readelf`, `file`
5. What is the difference between `.o` and executables?

### Let's build the app again, tracing the LL steps

```sh
rm hello hello.o
strace -s 1000 -f -o trace -e execve gcc -o hello hello.c
vim trace
```

notice the `cc1` compiler and `ld` the linker.

## Libraries

### Building an app with a dependency

1. `gcc -o hello hello_secret.c` fails, but `gcc -c -o hello.o hello_secret.c` succeeds. Why? clue: `objdump -t hello.o`
2. Let's build the dependency:

```sh
gcc -c -o secret.o secret.c
gcc -o hello secret.o hello.o
./hello
```

### Building a static library

create a static lib:

```sh
ar cr libsecret.a secret.o
ar t libsecret.a
rm secret.o
```

and use when building the app:

```sh
gcc -o hello hello.o -L. -lsecret
```

lets examine the last step with strace:

```sh
strace -s 1000 -e execve -f -o trace gcc -o hello hello.o -L. -lsecret
vim trace
```

and the resulting file:

```sh
nm hello
objdump -d hello
```

### Building a dynamic library

```sh
gcc -c -o secret.o secret.c
ld -shared -o libsecret.so secret.o
nm libsecret.so
objdump -d libsecret.so
```

and using it in the app. But first, lets look at the list of runtime dependencies of `hello`:

```sh
ldd hello
```

and build `hello`:

```sh
gcc -o hello hello.o -L. -lsecret
ldd hello
LD_LIBRARY_PATH=$(pwd) ldd hello
```

lets examine `hello`:

```sh
nm hello
objudmp -d hello
```

## Build Tools

Using `gcc` and `ld` all the time is not that nice, isn't it?
Let's automate this a bit by creating a *Makefile*.

### (Plain) Makefiles

1. Take a look at `Makefile`. What do you see?
2. Build the app:

```sh
make clean
make
```

3. run again: `make`
4. re-save `secret.c`, and run again: `make`
5. run each of `./hello`, `./hello_s_static` and `LD_LIBRARY_PATH=$(pwd) ./hello_secret`.
6. Lets trace what happens when running `make`:

```sh
make clean
strace -s 1000 -f -o trace -e execve make
vim trace
```

### autoconf

Maintaining big Makefiles isn't cool either (even though we couldv'e done the previous one better). That's why people came up with *Makefile generators*.

1. Check out `configure.ac` and `Makefile.am`.
2. Create a *configure* script: `autoreconf -i`. Examine resultant script: `vim ./configure`.
3. Use the `./configure` to generate a *Makefile*: `./configure`. Examine resultant *Makefile*: `vim Makefile`
4. Build the app using good old make: `make`.
5. run `./hello_secret`
6. Trace what happens when running `make`:

```sh
make clean
strace -s 1000 -f -o trace -e execve make
vim trace
```

### CMake

CMake is fancier and more modern makefile-generator for c/c++.

1. Examine the `CMakeLists.txt`: `vim CMakeLists.txt`. What do you see?
2. build the app:

```sh
mkdir build
cd build
cmake ..
```
Take a moment to examine the resultant Makefile: `vim Makefile`.
Proceed to build the app: `make`. Note the different stages in the output.

3. inspect the different files produced:
   1. `libSecretStatic.a` using `ar t libSecretStatic.a`
   2. `libSecretDynamic.so` using `nm libSecretDynamic.so` and `objdump -d libSecretDynamic.so`
   3. `HelloSecretStatic` using `ldd HelloSecretStatic`, `nm HelloSecretStatic`, `ldd HelloSecretStatic`.
   4. `HelloSecretDynamic` using `ldd HelloSecretDynamic`, `nm HelloSecretDynamic`, `ldd HelloSecretDynamic`.

4. Trace what happens when running `make`:

```sh
make clean
strace -s 1000 -f -o trace -e execve make
vim trace
```

## Using OS pkgs

Ubuntu provides lots and lots of pre-built packages, both dynamic (shared objects, to be used when running an executable) and static (archives, to link statically during build).

1. Take a look at the folder `/usr/lib/x86_64-linux-gnu/` using `ls`.
2. Install the dev-packages of `zlib` with `sudo apt install zlib1g-dev`.
3. Examine: `ls -al /usr/lib/x86_64-linux-gnu/libz*`.
4. What is inside `zlib.a`? check using `ar t /usr/lib/x86_64-linux-gnu/libz.a`.
5. What does `libz.so` provide? check using `readelf -s /usr/lib/x86_64-linux-gnu/libz.so`.
6. How can those `zlib` be used when building an app now?

## Cross-Compilation

Used to build applications for an architecture different that of the build machine. For example, building on a Ubuntu x86_64 machine to run on RapberryPi, ARM based device. Or Xbox 360, or an Android Phone.

For that one needs: A cross-compiler toolchain, that produces target-based binaries.
Lets install one for ARM: `sudo apt-get install gcc-arm-linux-gnueabi g++-arm-linux-gnueabi binutils-arm-linux-gnueabi`.

1. Lets build `hello` for an ARM cpu, directly using the cross-compiler:

```sh
arm-linux-gnueabi-gcc -o hello-arm hello.c
file hello-arm
./hello-arm
```

2. Doing cross-compilation with autoconf is very easy, and a matter of supplyin the target to the `./configure` script:

```sh
make clean
make distclean
./configure --build x86_64-pc-linux-gnueabi --host arm-linux-gnueabi
make
file hello_secret
```

Rerun with strace to see the cross-compiler in use:

```sh
make clean
strace -s 1000 -f -o trace -e execve make
vim trace
```

3. Doing this with `CMake` is actually not much different than the usual, and is a matter of only specifying which gcc toolchain to use:
```
rm -rf build
mkdir build
cd build
cmake -DCMAKE_TOOLCHAIN_FILE=../arm.cmake ..
```

Run and inspect the CLIs being used:

```sh
make clean
strace -s 1000 -f -o trace -e execve make
vim trace
```

Inspect the resultant file with `arm-linux-gnueabi-objdump -d HelloSecretStatic` (why `objdump` wouldn't work?). Notice the different instruction set.