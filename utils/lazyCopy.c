#include "stdio.h"
#include "errno.h"
#include "string.h"

#define MAX_BUFFER_LEN 512
#define MAX_PATH_LEN 128
#define MIN_SIZE 512
#define DISK_SIZE 0x168000 //1.44MB

int main(int argc, char *argv[])
{
  FILE *tgtfp, *srcfp;
  char buffer[MAX_BUFFER_LEN], path[MAX_PATH_LEN];
  int len, totalSize = 0;

  if (argc <= 2)
  {
    printf("No path to be copied!");
    return 1;
  }

  const char *targetPath = argv[1];
  printf("Start coying to %s\n", targetPath);
  if ((tgtfp = fopen(targetPath, "wb")) != NULL)
  {

    for (int i = 2; i < argc; i++)
    {
      strcpy(path, argv[i]);
      if ((srcfp = fopen(path, "rb")) != NULL)
      {
        while ((len = fread(buffer, sizeof(char), MAX_BUFFER_LEN, (FILE *)srcfp)) >= MAX_BUFFER_LEN)
        {
          totalSize += len;
          fwrite(buffer, sizeof(char), len, tgtfp);
        }
        totalSize += len;
        fwrite(buffer, sizeof(char), len, tgtfp);
        fclose(srcfp);

        printf("Current total space using: %d Bytes\n", totalSize);
        if (totalSize % MIN_SIZE != 0)
        {
          int remain = totalSize + MIN_SIZE - 1;
          remain = remain / MIN_SIZE * MIN_SIZE;
          remain -= totalSize;
          totalSize += remain;
          printf("fill with zero %d\n", remain);

          while (remain > 0)
          {
            remain--;
            fputc(0, tgtfp);
          }
        }

        printf("Path %s copy successful!(to %d block)\n", path, totalSize / MIN_SIZE);
      }
      else
      {
        printf("Cannot open file(errno:%d): %s\nMessage: %s\n", errno, argv[i], strerror(errno));
        return 1;
      }
    }

    printf("Using space:%d\nFill wiht zero:%d\n", totalSize, DISK_SIZE - totalSize);
    totalSize = DISK_SIZE - totalSize;
    while (totalSize > 0)
    {
      totalSize--;
      fputc(0, tgtfp);
    }

    fclose(tgtfp);

    printf("Copy done!\n");
  }
  else
  {
    printf("Cannot open target file!");
    return 1;
  }

  return 0;
}