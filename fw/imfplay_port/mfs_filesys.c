/* 
   Dummy mfs that just returns data from a single file which is compiled
   into the application.
 
   open/close/read/seek are the only routines
*/ 
#include <stdint.h>
#include <string.h>
#include "xilmfs.h"
// #define DEBUG_LOGGING
// #define VERBOSE_DEBUG_LOGGING
// #define LOG_TO_BOTH
#include "log.h"

#include "mfs_file.h"

static long gCurrentOffset;

/**
 * open a file
 * @param filename is the name of the file to open
 * @param mode is MFS_MODE_READ or MFS_MODE_WRITE or MFS_MODE_CREATE
 * this function should be used for FILEs and not DIRs
 * no error checking (is this FILE and not DIR?) is done for MFS_MODE_READ
 * MFS_MODE_CREATE automatically creates a FILE and not a DIR
 * MFS_MODE_WRITE fails if the specified file is a DIR
 * @return index of file in array mfs_open_files or -1
 */
int mfs_file_open(const char *filename, int mode) 
{
   VLOG("Called\n");
   gCurrentOffset = 0;
   return 0;
}

/**
 * read characters to a file
 * @param fd is a descriptor for the file from which the characters are read
 * @param buf is a pre allocated buffer that will contain the read characters
 * @param buflen is the number of characters from buf to be read
 * fd should be a valid index in mfs_open_files array
 * Works only if fd points to a file and not a dir
 * buf should be a pointer to a pre-allocated buffer of size buflen or more
 * buflen chars are read and placed in buf
 * if fewer than buflen chars are available then only that many chars are read
 * @return num bytes read or 0 for error=no bytes read
*/
int mfs_file_read(int fd, char *buf, int buflen) 
{
   int ReadLen = buflen;
   if(gCurrentOffset +  ReadLen > sizeof(gMfsFile)) {
      ReadLen = sizeof(gMfsFile) - gCurrentOffset;
   }
   memcpy(buf,&gMfsFile[gCurrentOffset],ReadLen);

   VLOG("Read %d bytes from offset %d\n",ReadLen,gCurrentOffset);
   gCurrentOffset += ReadLen;

   return ReadLen;
}

/**
 * close an open file and
 * recover the file table entry in mfs_open_files corresponding to the fd
 * if the fd is not valid, return 0
 * fd is not valid if the index in mfs_open_files is out of range, or
 * if the corresponding entry is not an open file
 * @param fd is the file descriptor for the file to be closed
 * @return 1 on success, 0 otherwise
 */
int mfs_file_close(int fd) 
{
   VLOG("Called\n");
   return 0;
}

/**
 * seek to a given offset within the file
 * @param fd should be a valid file descriptor for an open file
 * @param whence is one of MFS_SEEK_SET, MFS_SEEK_CUR or MFS_SEEK_END
 * @param offset is the offset from the beginning, end or current position as specified by the whence parameter
 * if MFS_SEEK_END is specified, the offset can be either 0 or negative
 * otherwise offset should be positive or 0
 * it is an error to seek before beginning of file or after the end of file
 * @return -1 on failure, value of offset from beginning of file on success
 */
long mfs_file_lseek(int fd, long offset, int whence) 
{
   long Ret = gCurrentOffset;
   const char *Whence = "Invalid";

   switch(whence) {
      case MFS_SEEK_SET:
         Ret = offset;
         Whence = "MFS_SEEK_SET";
         break;

      case MFS_SEEK_CUR:
         Ret += offset;
         Whence = "MFS_SEEK_CUR";
         break;

      case MFS_SEEK_END:
         Ret = sizeof(gMfsFile) + offset;
         Whence = "MFS_SEEK_END";
         break;
   }
   VLOG("%s, offset %d\n",offset);

   if(Ret < 0 || Ret > sizeof(gMfsFile)) {
      Ret = -1;
   }
   else {
      gCurrentOffset = Ret;
   }

   return Ret;
}

