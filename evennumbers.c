#include <stdio.h>

int main(void) {
  int count, counter;
  printf("Enter the number upto which the even numbers should be printed:");
  scanf("%d", &count);
  counter = 0;
  printf("The even numbers upto %d are", count);
  for(counter = 0; counter <= count; counter += 2) {
    printf(" %d", counter);
  }
  printf(".");
}