void bubbleSort( int a[], int n)
{
    int i,j,temp; // for a={1,2,3,4,5} n is 5

    n = n - 1;    // bcz otherwise it will get out of index

    for(i=0; i<n; i++)
    {
        for(j=0; j<n-i; j++)
        {
            if(a[j]>a[j+1])
            {
                temp = a[j+1];
                a[j+1] = a[j];
               a[j] = temp;
            }

        }

    }

}

int another () {
    int myArray[200] = {372, 811, 848, 102, 506, 778, 531, 160, 635, 760, 244, 215, 514, 569, 919, 490, 235, 58, 15, 280, 787, 462, 380, 312, 531, 876, 972, 982, 860, 91, 563, 871, 431, 812, 286, 563, 345, 793, 172, 786, 865, 652, 818, 565, 27, 574, 553, 948, 847, 264, 66, 15, 58, 883, 55, 198, 440, 511, 263, 359, 34, 730, 168, 697, 755, 573, 273, 477, 300, 849, 672, 465, 756, 659, 699, 766, 367, 618, 250, 285, 11, 405, 112, 853, 280, 972, 695, 217, 279, 1000, 965, 802, 366, 161, 123, 796, 115, 86, 624, 735, 556, 889, 530, 136, 701, 878, 785, 793, 957, 166, 299, 521, 165, 66, 388, 130, 561, 657, 548, 661, 506, 266, 750, 739, 103, 907, 236, 776, 860, 156, 811, 149, 245, 539, 569, 525, 3, 192, 85, 413, 670, 29, 35, 105, 984, 787, 291, 380, 60, 278, 644, 194, 472, 675, 320, 181, 537, 979, 252, 39, 773, 830, 504, 823, 721, 835, 574, 535, 528, 224, 510, 888, 827, 831, 550, 204, 346, 41, 577, 212, 368, 978, 384, 446, 709, 934, 550, 232, 923, 54, 887, 684, 236, 740, 919, 944, 695, 300, 738, 464};


    bubbleSort(myArray, 200);
    return 0;
}

int main() {
    another();

    return 0;
}