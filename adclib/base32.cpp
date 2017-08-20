/*
 * This code is partially copied from 
 *  - DCNet-X ADC Server Project ( http://dcnet-x.sourceforge.net )
 *  - ADCH++ ( http://sourceforge.net/projects/adchpp )
 *  - DC++ ( http://sourceforge.net/projects/dcplusplus )
 * 
 */

#include "includes.h"
#include "base32.h"

const char ADCLIB::BASE32::BASE32_table[] = {
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, 26, 27, 28, 29, 30, 31, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
  20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1,
};

const char ADCLIB::BASE32::BASE32_alpha[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

std::string ADCLIB::BASE32::TOBASE32( const unsigned char * src, unsigned long size )
{
  unsigned long key = 0;
  unsigned char chr;
  std::string ret;
  for( unsigned long i = 0; i < size; )
  {
    if( key > 3 )
    {
      chr = ( unsigned char ) ( src[i] & ( 0xFF >> key ) );
      key = ( key + 5 ) % 8;
      chr <<= key;
      if( ( i + 1 ) < size )
        chr |= src[i + 1] >> ( 8 - key );
      ++i;
    }
    else
    {
      chr = ( unsigned char ) ( src[i] >> ( 8 - ( key + 5 ) ) ) & 0x1F;
      key = ( key + 5 ) % 8;
      if( key == 0 )
        ++i;
    }
    ret += BASE32_alpha[chr];
  }
  return ret;
}

void ADCLIB::BASE32::FROMBASE32( const char * src, unsigned char * buffer, unsigned long size )
{
  unsigned long key = 0, set = 0;
  memset( buffer, 0, size );
  for( unsigned long i = 0; src[i]; i++ )
  {
    char temp = BASE32_table[( unsigned char ) src[i]];
    if( temp == -1 )
      continue;
    if( key <= 3 )
    {
      key = ( key + 5 ) % 8;
      if( key == 0 )
      {
        buffer[set] |= temp;
        ++set;
        if( set == size )
          break;
      }
      else
      {
        buffer[set] |= temp << ( 8 - key );
      }
    }
    else
    {
      key = ( key + 5 ) % 8;
      buffer[set] |= ( temp >> key );
      ++set;
      if( set == size )
        break;
      buffer[set] |= temp << ( 8 - key );
    }
  }
}

