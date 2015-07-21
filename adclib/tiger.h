/*
 * This code is partially copied from 
 *  - DCNet-X ADC Server Project ( http://dcnet-x.sourceforge.net )
 *  - ADCH++ ( http://sourceforge.net/projects/adchpp )
 *  - DC++ ( http://sourceforge.net/projects/dcplusplus )
 * 
 */

#include "includes.h"

#define _ULL(x) x##ull
  
namespace ADCLIB
{
  typedef std::vector < std::string > T_StringList;    
  class TigerHash
  {
  private:
    enum
    {
      BLOCK_SIZE = 512 / 8
    };
    unsigned char tmp[512 / 8];
    unsigned long long res[3];
    unsigned long long pos;
    static unsigned long long table[];
    void tigerCompress( const unsigned long long * data, unsigned long long state[3] );
  public:
    enum
    {
      HASH_SIZE = 24
    };
    TigerHash() : pos( 0 )
    {
      res[0] = _ULL( 0x0123456789ABCDEF );
      res[1] = _ULL( 0xFEDCBA9876543210 );
      res[2] = _ULL( 0xF096A5B4C3B2E187 );
    }
    ~TigerHash()
    {
    }
    void update( const void * data, unsigned long len );
    unsigned char * finalize();
    unsigned char * getResult()
    {
      return ( unsigned char * ) res;
    };
  };
};

