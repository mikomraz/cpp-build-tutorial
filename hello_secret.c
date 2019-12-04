#include <stdio.h>
#include <secret.h>

int main() {
    const char * const secret = my_secret_message();
    
    printf("secret message: %s\n", secret);
    
    return 0;
}