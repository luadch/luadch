/*
 * This code is partially copied from 
 *  - DCNet-X ADC Server Project ( http://dcnet-x.sourceforge.net )
 *  - ADCH++ ( http://sourceforge.net/projects/adchpp )
 *  - DC++ ( http://sourceforge.net/projects/dcplusplus )
 * 
 */

#include "includes.h"
#include <stdint.h>

namespace ADCLIB
{
  typedef std::vector < std::string > T_StringList;
  class BASE32
  {
  public:
    static const char BASE32_alpha[];
    static const int8_t BASE32_table[];
    static std::string TOBASE32( const unsigned char * src, unsigned long size );
    static void FROMBASE32( const char * src, unsigned char * buffer, unsigned long size );
  };
}
