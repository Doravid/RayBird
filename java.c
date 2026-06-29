#include <stdbool.h>
#include <stdio.h>
struct page_table_entry
{
    int phys_pn;
    char swapped : 1;
    char valid : 1;
    char writeable : 1;
};

int main(int argc, char const *argv[])
{

    struct page_table_entry x;
    x.swapped = 1;
    printf("%d", sizeof(struct page_table_entry));
    return 0;
}
